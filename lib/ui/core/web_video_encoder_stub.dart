import 'dart:typed_data';

class WebVideoEncoder {
  WebVideoEncoder({
    required int width,
    required int height,
    required int fps,
    required int bitrate,
  });

  Future<void> start() async {}
  Future<void> addFrame(Uint8List rgbaBytes) async {}
  Future<Uint8List> finalize() async => Uint8List(0);
}
