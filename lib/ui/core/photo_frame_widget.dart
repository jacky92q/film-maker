import 'dart:io';
import 'package:film_maker/domain/models/slide.dart';
import 'package:flutter/material.dart';

/// Builds a photo widget with the given shape clip and frame decoration.
/// Returns SizedBox.shrink() if [imagePath] is null.
Widget buildShapedPhoto({
  required String? imagePath,
  required PhotoShape shape,
  required PhotoFrame frame,
  BoxFit fit = BoxFit.cover,
  ColorFilter? colorFilter,
}) {
  if (imagePath == null) {
    return Container(color: Colors.black26);
  }

  Widget img = Image.file(
    File(imagePath),
    fit: fit,
    width: double.infinity,
    height: double.infinity,
    errorBuilder: (_, __, ___) => Container(color: Colors.black26),
  );

  if (colorFilter != null) {
    img = ColorFiltered(colorFilter: colorFilter, child: img);
  }

  // Apply shape
  Widget shaped;
  switch (shape) {
    case PhotoShape.none:
      shaped = img;
      break;
    case PhotoShape.rounded:
      shaped = ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: img,
      );
      break;
    case PhotoShape.circle:
      shaped = ClipOval(child: img);
      break;
    case PhotoShape.heart:
      shaped = ClipPath(clipper: _HeartClipper(), child: img);
      break;
  }

  // Apply frame
  switch (frame) {
    case PhotoFrame.none:
      return shaped;
    case PhotoFrame.white:
      return _buildBorderFrame(shaped, Colors.white, shape);
    case PhotoFrame.gold:
      return _buildBorderFrame(shaped, const Color(0xFFD4AF37), shape);
    case PhotoFrame.polaroid:
      return Container(
        decoration: const BoxDecoration(color: Colors.white),
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 30),
        child: shaped,
      );
  }
}

Widget _buildBorderFrame(Widget child, Color color, PhotoShape shape) {
  BorderRadius? radius;
  if (shape == PhotoShape.rounded) radius = BorderRadius.circular(22);
  return Container(
    decoration: BoxDecoration(
      border: Border.all(color: color, width: 4),
      borderRadius: radius,
      shape: shape == PhotoShape.circle ? BoxShape.circle : BoxShape.rectangle,
    ),
    child: Padding(padding: const EdgeInsets.all(4), child: child),
  );
}

class _HeartClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size s) {
    final w = s.width;
    final h = s.height;
    final path = Path();
    path.moveTo(w * 0.5, h * 0.85);
    // Left curve
    path.cubicTo(w * 0.0,  h * 0.60, w * -0.1, h * 0.25, w * 0.2,  h * 0.15);
    path.cubicTo(w * 0.35, h * 0.06, w * 0.5,  h * 0.22, w * 0.5,  h * 0.30);
    // Right curve
    path.cubicTo(w * 0.5,  h * 0.22, w * 0.65, h * 0.06, w * 0.8,  h * 0.15);
    path.cubicTo(w * 1.1,  h * 0.25, w * 1.0,  h * 0.60, w * 0.5,  h * 0.85);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> old) => false;
}
