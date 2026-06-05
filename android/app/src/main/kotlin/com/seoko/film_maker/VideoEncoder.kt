package com.seoko.film_maker

import android.content.ContentValues
import android.content.Context
import android.media.MediaCodec
import android.media.MediaCodecInfo
import android.media.MediaExtractor
import android.media.MediaFormat
import android.media.MediaMuxer
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import java.io.File
import java.io.FileInputStream
import java.io.FileOutputStream
import java.nio.ByteBuffer

/**
 * Encodes raw RGBA frames → H.264 MP4 using MediaCodec + MediaMuxer.
 * Optional audio track is muxed from an existing audio file via MediaExtractor.
 */
class VideoEncoder(
    private val context: Context,
    private val width: Int,
    private val height: Int,
    private val fps: Int,
    private val bitrate: Int,
) {
    private val codec: MediaCodec
    private val muxer: MediaMuxer
    private val tempFile: File

    private var videoTrack = -1
    private var muxerStarted = false
    private val bufInfo = MediaCodec.BufferInfo()
    private val frameDurationUs = 1_000_000L / fps

    init {
        tempFile = File(context.cacheDir, "vex_${System.currentTimeMillis()}.mp4")
        muxer = MediaMuxer(tempFile.absolutePath, MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4)

        val fmt = MediaFormat.createVideoFormat(MediaFormat.MIMETYPE_VIDEO_AVC, width, height).apply {
            setInteger(MediaFormat.KEY_BIT_RATE, bitrate)
            setInteger(MediaFormat.KEY_FRAME_RATE, fps)
            setInteger(MediaFormat.KEY_I_FRAME_INTERVAL, 1)
            setInteger(
                MediaFormat.KEY_COLOR_FORMAT,
                MediaCodecInfo.CodecCapabilities.COLOR_FormatYUV420SemiPlanar,
            )
        }

        codec = MediaCodec.createEncoderByType(MediaFormat.MIMETYPE_VIDEO_AVC)
        codec.configure(fmt, null, null, MediaCodec.CONFIGURE_FLAG_ENCODE)
        codec.start()
    }

    fun addFrame(rgba: ByteArray, frameIndex: Long) {
        val nv12 = rgbaToNV12(rgba)
        val pts  = frameIndex * frameDurationUs

        // Keep trying until an input buffer is free, draining output in between
        // so a momentarily-full pipeline never silently drops a frame.
        while (true) {
            val inputId = codec.dequeueInputBuffer(10_000L)
            if (inputId >= 0) {
                val buf = codec.getInputBuffer(inputId)!!
                buf.clear()
                buf.put(nv12)
                codec.queueInputBuffer(inputId, 0, nv12.size, pts, 0)
                break
            }
            drainEncoder(false)
        }
        drainEncoder(false)
    }

    fun finalize(musicPath: String?, outputName: String): String {
        signalEndOfStream()
        drainEncoder(true)
        codec.stop()
        codec.release()
        if (muxerStarted) muxer.stop()
        muxer.release()

        return if (musicPath != null) {
            val withAudio = File(context.cacheDir, "vex_a_${System.currentTimeMillis()}.mp4")
            muxVideoWithAudio(tempFile, musicPath, withAudio)
            val uri = saveToGallery(withAudio, outputName)
            withAudio.delete()
            tempFile.delete()
            uri
        } else {
            val uri = saveToGallery(tempFile, outputName)
            tempFile.delete()
            uri
        }
    }

    fun cancel() {
        runCatching { codec.stop() }
        runCatching { codec.release() }
        if (muxerStarted) runCatching { muxer.stop() }
        runCatching { muxer.release() }
        tempFile.delete()
    }

    // ── Encoder drain ────────────────────────────────────────────────────────

    /**
     * Signals end-of-stream for a byte-buffer-input encoder by queuing an empty
     * input buffer flagged with [MediaCodec.BUFFER_FLAG_END_OF_STREAM].
     * (signalEndOfInputStream() is only valid for Surface-input encoders.)
     */
    private fun signalEndOfStream() {
        while (true) {
            val inputId = codec.dequeueInputBuffer(10_000L)
            if (inputId >= 0) {
                codec.queueInputBuffer(
                    inputId, 0, 0, 0, MediaCodec.BUFFER_FLAG_END_OF_STREAM,
                )
                return
            }
        }
    }

    private fun drainEncoder(endOfStream: Boolean) {
        val timeoutUs = if (endOfStream) 10_000L else 0L
        while (true) {
            val outId = codec.dequeueOutputBuffer(bufInfo, timeoutUs)
            when {
                outId == MediaCodec.INFO_TRY_AGAIN_LATER -> {
                    // No output yet. When flushing the final stream we must keep
                    // waiting for the EOS buffer; otherwise we're done for now.
                    if (!endOfStream) break
                }
                outId == MediaCodec.INFO_OUTPUT_FORMAT_CHANGED -> {
                    videoTrack = muxer.addTrack(codec.outputFormat)
                    muxer.start()
                    muxerStarted = true
                }
                outId < 0 -> {
                    // Other negative codes (e.g. deprecated buffers-changed): ignore.
                }
                else -> {
                    val buf = codec.getOutputBuffer(outId)!!
                    if (bufInfo.flags and MediaCodec.BUFFER_FLAG_CODEC_CONFIG != 0) {
                        bufInfo.size = 0
                    }
                    if (bufInfo.size > 0 && muxerStarted) {
                        buf.position(bufInfo.offset)
                        buf.limit(bufInfo.offset + bufInfo.size)
                        muxer.writeSampleData(videoTrack, buf, bufInfo)
                    }
                    codec.releaseOutputBuffer(outId, false)
                    if (bufInfo.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM != 0) break
                }
            }
        }
    }

    // ── Audio mux ────────────────────────────────────────────────────────────

    private fun muxVideoWithAudio(videoFile: File, musicPath: String, out: File) {
        val mux = MediaMuxer(out.absolutePath, MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4)

        val vExt = MediaExtractor().also { it.setDataSource(videoFile.absolutePath) }
        val vTrack = findTrack(vExt, "video/")
        val vFormat = vExt.getTrackFormat(vTrack)
        val videoDurUs = vFormat.getLong(MediaFormat.KEY_DURATION)
        vExt.selectTrack(vTrack)
        val muxV = mux.addTrack(vFormat)

        val aExt = MediaExtractor().also { it.setDataSource(musicPath) }
        val aTrack = findTrack(aExt, "audio/")
        val muxA = if (aTrack >= 0) {
            aExt.selectTrack(aTrack)
            mux.addTrack(aExt.getTrackFormat(aTrack))
        } else -1

        mux.start()
        val buf = ByteBuffer.allocate(512 * 1024)
        val bi  = MediaCodec.BufferInfo()

        // Copy video
        vExt.seekTo(0, MediaExtractor.SEEK_TO_CLOSEST_SYNC)
        while (true) {
            buf.clear()
            val n = vExt.readSampleData(buf, 0)
            if (n < 0) break
            bi.offset = 0; bi.size = n
            bi.presentationTimeUs = vExt.sampleTime
            bi.flags = vExt.sampleFlags
            mux.writeSampleData(muxV, buf, bi)
            vExt.advance()
        }

        // Copy audio (trimmed to video duration)
        if (muxA >= 0) {
            aExt.seekTo(0, MediaExtractor.SEEK_TO_CLOSEST_SYNC)
            while (true) {
                buf.clear()
                val n = aExt.readSampleData(buf, 0)
                if (n < 0) break
                bi.offset = 0; bi.size = n
                bi.presentationTimeUs = aExt.sampleTime
                bi.flags = aExt.sampleFlags
                if (bi.presentationTimeUs > videoDurUs) break
                mux.writeSampleData(muxA, buf, bi)
                aExt.advance()
            }
        }

        vExt.release(); aExt.release()
        mux.stop(); mux.release()
    }

    private fun findTrack(ext: MediaExtractor, mimePrefix: String): Int {
        for (i in 0 until ext.trackCount) {
            val mime = ext.getTrackFormat(i).getString(MediaFormat.KEY_MIME) ?: continue
            if (mime.startsWith(mimePrefix)) return i
        }
        return -1
    }

    // ── Gallery save ─────────────────────────────────────────────────────────

    private fun saveToGallery(file: File, name: String): String {
        val fileName = "${name}_film.mp4"
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val values = ContentValues().apply {
                put(MediaStore.Video.Media.DISPLAY_NAME, fileName)
                put(MediaStore.Video.Media.MIME_TYPE, "video/mp4")
                put(
                    MediaStore.Video.Media.RELATIVE_PATH,
                    "${Environment.DIRECTORY_MOVIES}/FilmMaker",
                )
                put(MediaStore.Video.Media.IS_PENDING, 1)
            }
            val uri = context.contentResolver
                .insert(MediaStore.Video.Media.EXTERNAL_CONTENT_URI, values)!!
            context.contentResolver.openOutputStream(uri)!!.use { out ->
                FileInputStream(file).use { it.copyTo(out) }
            }
            values.clear()
            values.put(MediaStore.Video.Media.IS_PENDING, 0)
            context.contentResolver.update(uri, values, null, null)
            uri.toString()
        } else {
            @Suppress("DEPRECATION")
            val dir = File(
                Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_MOVIES),
                "FilmMaker",
            )
            dir.mkdirs()
            val dest = File(dir, fileName)
            FileInputStream(file).use { inp -> FileOutputStream(dest).use { inp.copyTo(it) } }
            dest.absolutePath
        }
    }

    // ── RGBA → NV12 conversion ────────────────────────────────────────────────

    private fun rgbaToNV12(rgba: ByteArray): ByteArray {
        val frameSize = width * height
        val nv12 = ByteArray(frameSize * 3 / 2)
        var srcIdx = 0

        for (row in 0 until height) {
            for (col in 0 until width) {
                val r = rgba[srcIdx].toInt() and 0xFF
                val g = rgba[srcIdx + 1].toInt() and 0xFF
                val b = rgba[srcIdx + 2].toInt() and 0xFF
                srcIdx += 4

                // Y luma
                nv12[row * width + col] =
                    (((66 * r + 129 * g + 25 * b + 128) shr 8) + 16)
                        .coerceIn(0, 255).toByte()

                // UV chroma (2×2 sub-sampled)
                if (row % 2 == 0 && col % 2 == 0) {
                    val u = (((-38 * r - 74 * g + 112 * b + 128) shr 8) + 128).coerceIn(0, 255)
                    val v = (((112 * r - 94 * g - 18 * b + 128) shr 8) + 128).coerceIn(0, 255)
                    val uvIdx = frameSize + (row / 2) * width + col
                    nv12[uvIdx]     = u.toByte() // NV12: U first
                    nv12[uvIdx + 1] = v.toByte() // then V
                }
            }
        }
        return nv12
    }
}
