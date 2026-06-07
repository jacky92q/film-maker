import 'dart:js_interop';
import 'dart:typed_data';

@JS('filmMakerEncoder')
external _Enc get _filmMakerEncoder;

extension type _Enc._(JSObject _) implements JSObject {
  external JSPromise<JSAny?> init(int width, int height, int fps, int bitrate);
  external JSPromise<JSAny?> addFrame(JSUint8Array bytes, int width, int height);
  external JSPromise<JSUint8Array> finalize();
}

class WebVideoEncoder {
  WebVideoEncoder({
    required this.width,
    required this.height,
    required this.fps,
    required this.bitrate,
  });

  final int width;
  final int height;
  final int fps;
  final int bitrate;

  Future<void> start() async {
    await _filmMakerEncoder.init(width, height, fps, bitrate).toDart;
  }

  Future<void> addFrame(Uint8List rgbaBytes) async {
    await _filmMakerEncoder.addFrame(rgbaBytes.toJS, width, height).toDart;
  }

  Future<Uint8List> finalize() async {
    final jsArr = await _filmMakerEncoder.finalize().toDart;
    return jsArr.toDart;
  }
}
