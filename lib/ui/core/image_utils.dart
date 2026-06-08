import 'dart:io' show File;
import 'dart:ui' as ui;

import 'package:film_maker/ui/core/web_image_storage.dart';
import 'package:flutter/foundation.dart' show SynchronousFuture, kIsWeb;
import 'package:flutter/material.dart';

/// Returns an [Image] widget that works on both native and web platforms.
///
/// On web, image paths may be:
///   - `web_img://<key>` — persistent image stored in browser IndexedDB
///   - a blob URL (legacy / short-lived)
/// On native, the path is a file-system path.
Widget imageFromPath(
  String? imagePath, {
  BoxFit fit = BoxFit.cover,
  double? width,
  double? height,
  Widget Function(BuildContext, Object, StackTrace?)? errorBuilder,
}) {
  if (imagePath == null || imagePath.isEmpty) {
    return Container(color: Colors.black26);
  }

  final Widget Function(BuildContext, Object, StackTrace?) eb =
      errorBuilder ?? (_, __, ___) => Container(color: Colors.black26);

  if (kIsWeb) {
    if (imagePath.startsWith('web_img://')) {
      return Image(
        image: WebImageProvider(imagePath),
        fit: fit,
        width: width ?? double.infinity,
        height: height ?? double.infinity,
        errorBuilder: eb,
      );
    }
    return Image.network(
      imagePath,
      fit: fit,
      width: width ?? double.infinity,
      height: height ?? double.infinity,
      errorBuilder: eb,
    );
  }
  return Image.file(
    File(imagePath),
    fit: fit,
    width: width ?? double.infinity,
    height: height ?? double.infinity,
    errorBuilder: eb,
  );
}

/// Same as [imageFromPath] but returns an [ImageProvider] instead of a widget.
/// Useful for [precacheImage] and similar APIs.
ImageProvider imageProviderFromPath(String imagePath) {
  if (kIsWeb) {
    if (imagePath.startsWith('web_img://')) return WebImageProvider(imagePath);
    return NetworkImage(imagePath);
  }
  return FileImage(File(imagePath));
}

/// Loads images stored under a `web_img://` key from the browser's IndexedDB.
/// Works across page reloads, unlike short-lived blob URLs from image_picker.
class WebImageProvider extends ImageProvider<WebImageProvider> {
  const WebImageProvider(this.uri);
  final String uri;

  @override
  Future<WebImageProvider> obtainKey(ImageConfiguration config) =>
      SynchronousFuture(this);

  @override
  ImageStreamCompleter loadImage(
      WebImageProvider key, ImageDecoderCallback decode) =>
      MultiFrameImageStreamCompleter(
        codec: _loadAsync(decode),
        scale: 1.0,
      );

  Future<ui.Codec> _loadAsync(ImageDecoderCallback decode) async {
    final storeKey = uri.substring('web_img://'.length);
    final bytes = await webLoadImage(storeKey);
    if (bytes == null) throw Exception('Image not found in storage: $storeKey');
    final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    return decode(buffer);
  }

  @override
  bool operator ==(Object other) =>
      other is WebImageProvider && other.uri == uri;

  @override
  int get hashCode => uri.hashCode;

  @override
  String toString() => 'WebImageProvider($uri)';
}
