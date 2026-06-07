import 'dart:io' show File;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

/// Returns an [Image] widget that works on both native and web platforms.
///
/// On web, [imagePath] is a blob URL (e.g. `blob:https://...`) returned by
/// image_picker, so we load it with [Image.network].
/// On native platforms it is a file-system path and [Image.file] is used.
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
  if (kIsWeb) return NetworkImage(imagePath);
  return FileImage(File(imagePath));
}
