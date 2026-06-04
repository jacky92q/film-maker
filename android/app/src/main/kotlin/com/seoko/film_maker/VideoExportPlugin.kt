package com.seoko.film_maker

import android.content.Context
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

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
                    val outputName = call.argument<String>("outputName") ?: "wedding_film"
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

            else -> result.notImplemented()
        }
    }
}
