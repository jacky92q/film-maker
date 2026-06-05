package com.seoko.film_maker

import android.content.Context
import android.content.Intent
import android.net.Uri
import androidx.core.content.FileProvider
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File

class VideoExportPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {

    private lateinit var channel: MethodChannel
    private lateinit var appContext: Context

    private var encoder: VideoEncoder? = null
    private var frameIndex: Long = 0L

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        appContext = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, "film_maker/video_export")
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "startEncoder" -> {
                try {
                    val width   = call.argument<Int>("width")!!
                    val height  = call.argument<Int>("height")!!
                    val fps     = call.argument<Int>("fps")!!
                    val bitrate = call.argument<Int>("bitrate")!!
                    encoder?.cancel()
                    encoder = VideoEncoder(appContext, width, height, fps, bitrate)
                    frameIndex = 0L
                    result.success(null)
                } catch (e: Exception) {
                    result.error("START_ENCODER", e.message, null)
                }
            }

            "addFrame" -> {
                try {
                    val rgba = call.arguments as ByteArray
                    encoder?.addFrame(rgba, frameIndex++)
                    result.success(null)
                } catch (e: Exception) {
                    result.error("ADD_FRAME", e.message, null)
                }
            }

            "finalize" -> {
                try {
                    val musicPath  = call.argument<String?>("musicPath")
                    val outputName = call.argument<String>("outputName") ?: "film"
                    val path = encoder?.finalize(musicPath, outputName)
                    encoder = null
                    frameIndex = 0L
                    result.success(path)
                } catch (e: Exception) {
                    result.error("FINALIZE", e.message, null)
                }
            }

            "cancelExport" -> {
                encoder?.cancel()
                encoder = null
                frameIndex = 0L
                result.success(null)
            }

            "shareVideo" -> {
                try {
                    val path  = call.argument<String>("path")!!
                    val title = call.argument<String?>("title")
                    shareVideo(path, title)
                    result.success(null)
                } catch (e: Exception) {
                    result.error("SHARE", e.message, null)
                }
            }

            else -> result.notImplemented()
        }
    }

    /**
     * Opens the system share sheet for an exported MP4. [path] is either a
     * MediaStore `content://` URI (API 29+) or an absolute file path (API < 29),
     * the latter wrapped through [FileProvider] to obtain a grantable URI.
     */
    private fun shareVideo(path: String, title: String?) {
        val uri: Uri = if (path.startsWith("content://")) {
            Uri.parse(path)
        } else {
            FileProvider.getUriForFile(
                appContext,
                "${appContext.packageName}.fileprovider",
                File(path),
            )
        }

        val send = Intent(Intent.ACTION_SEND).apply {
            type = "video/mp4"
            putExtra(Intent.EXTRA_STREAM, uri)
            if (!title.isNullOrEmpty()) putExtra(Intent.EXTRA_SUBJECT, title)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }

        val chooser = Intent.createChooser(send, title).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        appContext.startActivity(chooser)
    }
}
