import 'dart:typed_data';

/// No-op on non-web platforms.
void downloadBytes(Uint8List bytes, String filename) {}
