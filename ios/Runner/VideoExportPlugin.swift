import AVFoundation
import Flutter
import Photos
import UIKit

/// Registers the `film_maker/video_export` MethodChannel and delegates to VideoEncoder.
class VideoExportPlugin: NSObject, FlutterPlugin {

    static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "film_maker/video_export",
            binaryMessenger: registrar.messenger()
        )
        let instance = VideoExportPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    private var encoder: VideoEncoder?
    private var frameIndex: Int64 = 0

    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {

        case "startEncoder":
            guard let args = call.arguments as? [String: Any],
                  let width   = args["width"]   as? Int,
                  let height  = args["height"]  as? Int,
                  let fps     = args["fps"]     as? Int,
                  let bitrate = args["bitrate"] as? Int
            else {
                result(FlutterError(code: "BAD_ARGS", message: "Missing encoder args", details: nil))
                return
            }
            encoder?.cancel()
            do {
                encoder = try VideoEncoder(width: width, height: height, fps: fps, bitrate: bitrate)
                frameIndex = 0
                result(nil)
            } catch {
                result(FlutterError(code: "START_ENCODER", message: error.localizedDescription, details: nil))
            }

        case "addFrame":
            guard let rgba = call.arguments as? FlutterStandardTypedData else {
                result(FlutterError(code: "BAD_ARGS", message: "Expected FlutterStandardTypedData", details: nil))
                return
            }
            do {
                try encoder?.addFrame(rgba.data, frameIndex: frameIndex)
                frameIndex += 1
                result(nil)
            } catch {
                result(FlutterError(code: "ADD_FRAME", message: error.localizedDescription, details: nil))
            }

        case "finalize":
            let args = call.arguments as? [String: Any]
            let musicPath  = args?["musicPath"]  as? String
            let outputName = args?["outputName"] as? String ?? "wedding_film"
            encoder?.finalize(musicPath: musicPath, outputName: outputName) { path, error in
                if let error = error {
                    result(FlutterError(code: "FINALIZE", message: error.localizedDescription, details: nil))
                } else {
                    result(path)
                }
            }
            encoder = nil
            frameIndex = 0

        case "cancelExport":
            encoder?.cancel()
            encoder = nil
            frameIndex = 0
            result(nil)

        default:
            result(FlutterMethodNotImplemented)
        }
    }
}

// ── Video Encoder ─────────────────────────────────────────────────────────────

private class VideoEncoder {

    private let width: Int
    private let height: Int
    private let fps: Int
    private let bitrate: Int

    private var assetWriter: AVAssetWriter
    private var videoInput: AVAssetWriterInput
    private var adaptor: AVAssetWriterInputPixelBufferAdaptor
    private let tempURL: URL

    private var cancelled = false

    init(width: Int, height: Int, fps: Int, bitrate: Int) throws {
        self.width   = width
        self.height  = height
        self.fps     = fps
        self.bitrate = bitrate

        tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("vex_\(Int(Date().timeIntervalSince1970)).mp4")

        assetWriter = try AVAssetWriter(outputURL: tempURL, fileType: .mp4)

        let settings: [String: Any] = [
            AVVideoCodecKey:                AVVideoCodecType.h264,
            AVVideoWidthKey:                width,
            AVVideoHeightKey:               height,
            AVVideoCompressionPropertiesKey: [
                AVVideoAverageBitRateKey:        bitrate,
                AVVideoMaxKeyFrameIntervalKey:   fps,
            ],
        ]
        videoInput = AVAssetWriterInput(mediaType: .video, outputSettings: settings)
        videoInput.expectsMediaDataInRealTime = false

        let attrs: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
            kCVPixelBufferWidthKey  as String: width,
            kCVPixelBufferHeightKey as String: height,
        ]
        adaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: videoInput,
            sourcePixelBufferAttributes: attrs
        )

        assetWriter.add(videoInput)
        assetWriter.startWriting()
        assetWriter.startSession(atSourceTime: .zero)
    }

    func addFrame(_ rgbaData: Data, frameIndex: Int64) throws {
        guard !cancelled else { return }

        // Convert RGBA → BGRA and write into CVPixelBuffer
        var pixelBuffer: CVPixelBuffer?
        let attrs: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
            kCVPixelBufferWidthKey  as String: width,
            kCVPixelBufferHeightKey as String: height,
        ]
        CVPixelBufferCreate(kCFAllocatorDefault, width, height,
                            kCVPixelFormatType_32BGRA, attrs as CFDictionary, &pixelBuffer)
        guard let pb = pixelBuffer else { throw EncoderError.pixelBufferFailed }

        CVPixelBufferLockBaseAddress(pb, [])
        let dst = CVPixelBufferGetBaseAddress(pb)!.assumingMemoryBound(to: UInt8.self)
        let count = width * height

        rgbaData.withUnsafeBytes { (src: UnsafeRawBufferPointer) in
            let bytes = src.bindMemory(to: UInt8.self)
            for i in 0 ..< count {
                let s = i * 4
                dst[s]     = bytes[s + 2] // B
                dst[s + 1] = bytes[s + 1] // G
                dst[s + 2] = bytes[s]     // R
                dst[s + 3] = bytes[s + 3] // A
            }
        }
        CVPixelBufferUnlockBaseAddress(pb, [])

        // Wait until the input is ready
        while !videoInput.isReadyForMoreMediaData { Thread.sleep(forTimeInterval: 0.005) }

        let pts = CMTimeMake(value: frameIndex, timescale: Int32(fps))
        adaptor.append(pb, withPresentationTime: pts)
    }

    func finalize(musicPath: String?, outputName: String, completion: @escaping (String?, Error?) -> Void) {
        videoInput.markAsFinished()
        assetWriter.finishWriting {
            if let error = self.assetWriter.error {
                completion(nil, error)
                return
            }
            if let musicPath = musicPath {
                self.muxAudio(videoURL: self.tempURL, musicPath: musicPath,
                               outputName: outputName, completion: completion)
            } else {
                self.saveToPhotos(videoURL: self.tempURL, outputName: outputName,
                                  completion: completion)
            }
        }
    }

    func cancel() {
        cancelled = true
        videoInput.markAsFinished()
        assetWriter.cancelWriting()
        try? FileManager.default.removeItem(at: tempURL)
    }

    // ── Audio mux ────────────────────────────────────────────────────────────

    private func muxAudio(videoURL: URL, musicPath: String, outputName: String,
                          completion: @escaping (String?, Error?) -> Void) {
        let musicURL = URL(fileURLWithPath: musicPath)
        let composition = AVMutableComposition()

        guard
            let videoAsset = AVAsset(url: videoURL) as AVAsset?,
            let musicAsset = AVAsset(url: musicURL) as AVAsset?,
            let videoTrack = composition.addMutableTrack(
                withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid),
            let srcVideoTrack = videoAsset.tracks(withMediaType: .video).first
        else {
            // Fall back: save video without audio
            saveToPhotos(videoURL: videoURL, outputName: outputName, completion: completion)
            return
        }

        let videoDuration = videoAsset.duration
        do {
            try videoTrack.insertTimeRange(
                CMTimeRange(start: .zero, duration: videoDuration),
                of: srcVideoTrack, at: .zero)

            if let srcAudioTrack = musicAsset.tracks(withMediaType: .audio).first,
               let audioTrack = composition.addMutableTrack(
                   withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) {
                let musicDur = musicAsset.duration
                let audioDur = CMTimeCompare(musicDur, videoDuration) < 0 ? musicDur : videoDuration
                try audioTrack.insertTimeRange(
                    CMTimeRange(start: .zero, duration: audioDur),
                    of: srcAudioTrack, at: .zero)
            }
        } catch {
            saveToPhotos(videoURL: videoURL, outputName: outputName, completion: completion)
            return
        }

        let outURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("vex_a_\(Int(Date().timeIntervalSince1970)).mp4")

        guard let session = AVAssetExportSession(asset: composition,
                                                 presetName: AVAssetExportPresetHighestQuality)
        else {
            saveToPhotos(videoURL: videoURL, outputName: outputName, completion: completion)
            return
        }
        session.outputURL = outURL
        session.outputFileType = .mp4
        session.exportAsynchronously {
            try? FileManager.default.removeItem(at: videoURL)
            if session.status == .completed {
                self.saveToPhotos(videoURL: outURL, outputName: outputName) { path, err in
                    try? FileManager.default.removeItem(at: outURL)
                    completion(path, err)
                }
            } else {
                completion(nil, session.error)
            }
        }
    }

    // ── Save to Photos library ────────────────────────────────────────────────

    private func saveToPhotos(videoURL: URL, outputName: String,
                              completion: @escaping (String?, Error?) -> Void) {
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            guard status == .authorized || status == .limited else {
                completion(nil, EncoderError.photoLibraryDenied)
                return
            }
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: videoURL)
            }) { success, error in
                if success {
                    completion(videoURL.path, nil)
                } else {
                    completion(nil, error)
                }
            }
        }
    }
}

private enum EncoderError: LocalizedError {
    case pixelBufferFailed
    case photoLibraryDenied

    var errorDescription: String? {
        switch self {
        case .pixelBufferFailed:    return "Failed to create CVPixelBuffer."
        case .photoLibraryDenied:   return "Photo library access was denied."
        }
    }
}
