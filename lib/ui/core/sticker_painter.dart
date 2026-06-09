import 'package:film_maker/domain/models/sticker.dart';
import 'package:flutter/material.dart';

/// Renders a [StickerKind] as its pre-cut (background-removed) PNG asset.
/// Used in both the editor canvas and the playback/export canvas so what you
/// see is exactly what gets exported.
class StickerWidget extends StatelessWidget {
  const StickerWidget({
    super.key,
    required this.kind,
    this.opacity = 1.0,
  });

  final StickerKind kind;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity.clamp(0.0, 1.0),
      child: Image.asset(
        kind.assetPath,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
      ),
    );
  }
}
