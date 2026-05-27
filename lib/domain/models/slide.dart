import 'package:flutter/material.dart';

enum TransitionEffect { fade, slideLeft, slideRight, zoomIn, kenBurns, blurDissolve, wipeLeft, wipeRight }

enum SlideTextColor { white, gold, cream, black, rose }

enum SlideTextSize { small, medium, large, xlarge }

enum SlideFontStyle { serif, sans, script, display, elegant, modern }

enum PhotoFilter { none, warm, cool, blackAndWhite, vintage, dramatic }

enum SlideTemplate { blank, opening, memory, loveNote, closing }

extension TransitionEffectLabel on TransitionEffect {
  String get label {
    switch (this) {
      case TransitionEffect.fade:
        return 'Fade';
      case TransitionEffect.slideLeft:
        return 'Slide ←';
      case TransitionEffect.slideRight:
        return 'Slide →';
      case TransitionEffect.zoomIn:
        return 'Zoom';
      case TransitionEffect.kenBurns:
        return 'Ken Burns';
      case TransitionEffect.blurDissolve: return 'Blur';
      case TransitionEffect.wipeLeft:     return 'Wipe ←';
      case TransitionEffect.wipeRight:    return 'Wipe →';
    }
  }
}

extension SlideTextColorX on SlideTextColor {
  String get label {
    switch (this) {
      case SlideTextColor.white:
        return 'White';
      case SlideTextColor.gold:
        return 'Gold';
      case SlideTextColor.cream:
        return 'Cream';
      case SlideTextColor.black:
        return 'Black';
      case SlideTextColor.rose:
        return 'Rose';
    }
  }

  Color get color {
    switch (this) {
      case SlideTextColor.white:
        return const Color(0xFFFFFFFF);
      case SlideTextColor.gold:
        return const Color(0xFFC9A84C);
      case SlideTextColor.cream:
        return const Color(0xFFF5F0E8);
      case SlideTextColor.black:
        return const Color(0xFF0D0D0D);
      case SlideTextColor.rose:
        return const Color(0xFFE8B4B8);
    }
  }
}

extension SlideTextSizeX on SlideTextSize {
  String get label {
    switch (this) {
      case SlideTextSize.small:
        return 'S';
      case SlideTextSize.medium:
        return 'M';
      case SlideTextSize.large:
        return 'L';
      case SlideTextSize.xlarge:
        return 'XL';
    }
  }

  double get mainFontSize {
    switch (this) {
      case SlideTextSize.small:
        return 20;
      case SlideTextSize.medium:
        return 28;
      case SlideTextSize.large:
        return 38;
      case SlideTextSize.xlarge:
        return 52;
    }
  }

  double get subFontSize {
    switch (this) {
      case SlideTextSize.small:
        return 14;
      case SlideTextSize.medium:
        return 18;
      case SlideTextSize.large:
        return 22;
      case SlideTextSize.xlarge:
        return 28;
    }
  }
}

extension SlideFontStyleX on SlideFontStyle {
  String get label {
    switch (this) {
      case SlideFontStyle.serif:
        return 'Serif';
      case SlideFontStyle.sans:
        return 'Sans';
      case SlideFontStyle.script:
        return 'Script';
      case SlideFontStyle.display:
        return 'Display';
      case SlideFontStyle.elegant:
        return 'Elegant';
      case SlideFontStyle.modern:
        return 'Modern';
    }
  }
}

extension PhotoFilterX on PhotoFilter {
  String get label {
    switch (this) {
      case PhotoFilter.none:
        return 'None';
      case PhotoFilter.warm:
        return 'Warm';
      case PhotoFilter.cool:
        return 'Cool';
      case PhotoFilter.blackAndWhite:
        return 'B&W';
      case PhotoFilter.vintage:
        return 'Vintage';
      case PhotoFilter.dramatic:
        return 'Dramatic';
    }
  }

  ColorFilter? get colorFilter {
    switch (this) {
      case PhotoFilter.none:
        return null;
      case PhotoFilter.warm:
        return const ColorFilter.matrix(<double>[
          1.2, 0,   0,   0, 15,
          0,   1.0, 0,   0,  8,
          0,   0,   0.7, 0,  0,
          0,   0,   0,   1,  0,
        ]);
      case PhotoFilter.cool:
        return const ColorFilter.matrix(<double>[
          0.8, 0,   0,   0,  0,
          0,   0.9, 0,   0,  5,
          0,   0,   1.3, 0, 15,
          0,   0,   0,   1,  0,
        ]);
      case PhotoFilter.blackAndWhite:
        return const ColorFilter.matrix(<double>[
          0.299, 0.587, 0.114, 0, 0,
          0.299, 0.587, 0.114, 0, 0,
          0.299, 0.587, 0.114, 0, 0,
          0,     0,     0,     1, 0,
        ]);
      case PhotoFilter.vintage:
        return const ColorFilter.matrix(<double>[
          0.9, 0.1, 0.1, 0, 20,
          0.1, 0.8, 0.1, 0, 10,
          0.1, 0.1, 0.6, 0,  0,
          0,   0,   0,   1,  0,
        ]);
      case PhotoFilter.dramatic:
        return const ColorFilter.matrix(<double>[
          1.4,  0,    0,   0, -30,
          0,    1.1,  0,   0, -10,
          0,    0,    0.9, 0, -10,
          0,    0,    0,   1,   0,
        ]);
    }
  }
}

enum SlideOverlay { none, vignette, filmGrain, lightLeak, bokeh }

extension SlideOverlayX on SlideOverlay {
  String get label {
    switch (this) {
      case SlideOverlay.none:      return 'None';
      case SlideOverlay.vignette:  return 'Vignette';
      case SlideOverlay.filmGrain: return 'Grain';
      case SlideOverlay.lightLeak: return 'Light Leak';
      case SlideOverlay.bokeh:     return 'Bokeh';
    }
  }
}

enum SlideTextBg { none, pill, box }

extension SlideTextBgX on SlideTextBg {
  String get label {
    switch (this) {
      case SlideTextBg.none: return 'None';
      case SlideTextBg.pill: return 'Pill';
      case SlideTextBg.box:  return 'Box';
    }
  }
}

extension SlideTemplateX on SlideTemplate {
  String get label {
    switch (this) {
      case SlideTemplate.blank:
        return 'Blank';
      case SlideTemplate.opening:
        return 'Opening';
      case SlideTemplate.memory:
        return 'Memory';
      case SlideTemplate.loveNote:
        return 'Love Note';
      case SlideTemplate.closing:
        return 'Closing';
    }
  }

  String get description {
    switch (this) {
      case SlideTemplate.blank:
        return 'Start from scratch';
      case SlideTemplate.opening:
        return 'Bold title card';
      case SlideTemplate.memory:
        return 'Photo with caption';
      case SlideTemplate.loveNote:
        return 'Centered quote';
      case SlideTemplate.closing:
        return 'Elegant ending card';
    }
  }

  String get emoji {
    switch (this) {
      case SlideTemplate.blank:
        return '✦';
      case SlideTemplate.opening:
        return '🎬';
      case SlideTemplate.memory:
        return '📷';
      case SlideTemplate.loveNote:
        return '💌';
      case SlideTemplate.closing:
        return '🌸';
    }
  }
}

/// A single text element placed at a free (x, y) position on a slide.
/// x/y are fractions: 0.0 = left/top edge, 1.0 = right/bottom edge.
class TextLayer {
  const TextLayer({
    required this.id,
    required this.text,
    this.isSubtitle = false,
    this.x = 0.5,
    this.y = 0.75,
    this.color = SlideTextColor.white,
    this.barColor = SlideTextColor.gold,
    this.size = SlideTextSize.medium,
    this.fontStyle = SlideFontStyle.serif,
    this.textBg = SlideTextBg.none,
    this.strokeWidth = 0.0,
    this.letterSpacing = 0.0,
  });

  final String id;
  final String text;
  final bool isSubtitle;
  final double x;
  final double y;
  final SlideTextColor color;
  final SlideTextColor barColor;
  final SlideTextSize size;
  final SlideFontStyle fontStyle;
  final SlideTextBg textBg;
  final double strokeWidth;
  final double letterSpacing;

  TextLayer copyWith({
    String? text,
    bool? isSubtitle,
    double? x,
    double? y,
    SlideTextColor? color,
    SlideTextColor? barColor,
    SlideTextSize? size,
    SlideFontStyle? fontStyle,
    SlideTextBg? textBg,
    double? strokeWidth,
    double? letterSpacing,
  }) {
    return TextLayer(
      id: id,
      text: text ?? this.text,
      isSubtitle: isSubtitle ?? this.isSubtitle,
      x: x ?? this.x,
      y: y ?? this.y,
      color: color ?? this.color,
      barColor: barColor ?? this.barColor,
      size: size ?? this.size,
      fontStyle: fontStyle ?? this.fontStyle,
      textBg: textBg ?? this.textBg,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      letterSpacing: letterSpacing ?? this.letterSpacing,
    );
  }
}

// ignore: avoid_classes_with_only_static_members
class SlideDefaults {
  static Slide fromTemplate(String id, SlideTemplate template) {
    switch (template) {
      case SlideTemplate.blank:
        return Slide(id: id);
      case SlideTemplate.opening:
        return Slide(
          id: id,
          textLayers: [
            TextLayer(id: '${id}_t', text: 'Our Story', x: 0.5, y: 0.50, size: SlideTextSize.large, fontStyle: SlideFontStyle.serif, color: SlideTextColor.cream),
            TextLayer(id: '${id}_s', text: 'A Wedding Film', isSubtitle: true, x: 0.5, y: 0.66, size: SlideTextSize.small, color: SlideTextColor.gold, barColor: SlideTextColor.gold),
          ],
          transition: TransitionEffect.fade,
          durationSeconds: 5,
        );
      case SlideTemplate.memory:
        return Slide(
          id: id,
          textLayers: [
            TextLayer(id: '${id}_s', text: 'A cherished moment', isSubtitle: true, x: 0.5, y: 0.86, size: SlideTextSize.small, color: SlideTextColor.cream, barColor: SlideTextColor.cream),
          ],
          transition: TransitionEffect.kenBurns,
          durationSeconds: 5,
        );
      case SlideTemplate.loveNote:
        return Slide(
          id: id,
          textLayers: [
            TextLayer(id: '${id}_t', text: '"You are my greatest adventure"', x: 0.5, y: 0.50, size: SlideTextSize.medium, fontStyle: SlideFontStyle.serif, color: SlideTextColor.gold),
          ],
          transition: TransitionEffect.fade,
          durationSeconds: 6,
        );
      case SlideTemplate.closing:
        return Slide(
          id: id,
          textLayers: [
            TextLayer(id: '${id}_t', text: 'Forever & Always', x: 0.5, y: 0.46, size: SlideTextSize.large, fontStyle: SlideFontStyle.serif, color: SlideTextColor.gold),
            TextLayer(id: '${id}_s', text: '${DateTime.now().year}', isSubtitle: true, x: 0.5, y: 0.62, size: SlideTextSize.small, color: SlideTextColor.gold, barColor: SlideTextColor.gold),
          ],
          transition: TransitionEffect.fade,
          durationSeconds: 5,
        );
    }
  }
}

class Slide {
  const Slide({
    required this.id,
    this.imagePath,
    this.textLayers = const [],
    this.transition = TransitionEffect.fade,
    this.durationSeconds = 4,
    this.photoFilter = PhotoFilter.none,
    this.photoScale = 1.0,
    this.photoOffsetX = 0.0,
    this.photoOffsetY = 0.0,
    this.backgroundColor = 0xFF000000,
    this.overlay = SlideOverlay.none,
  });

  final String id;
  final String? imagePath;
  final List<TextLayer> textLayers;
  final TransitionEffect transition;
  final int durationSeconds;
  final PhotoFilter photoFilter;
  final double photoScale;      // 1.0 = photo fits canvas (contain), < 1 zooms out, > 1 zooms in
  final double photoOffsetX;    // fraction of canvas width, 0 = center
  final double photoOffsetY;    // fraction of canvas height, 0 = center
  final int backgroundColor;    // ARGB int shown behind the photo (default black)
  final SlideOverlay overlay;

  Slide copyWith({
    String? imagePath,
    List<TextLayer>? textLayers,
    TransitionEffect? transition,
    int? durationSeconds,
    PhotoFilter? photoFilter,
    double? photoScale,
    double? photoOffsetX,
    double? photoOffsetY,
    int? backgroundColor,
    SlideOverlay? overlay,
  }) {
    return Slide(
      id: id,
      imagePath: imagePath ?? this.imagePath,
      textLayers: textLayers ?? this.textLayers,
      transition: transition ?? this.transition,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      photoFilter: photoFilter ?? this.photoFilter,
      photoScale: photoScale ?? this.photoScale,
      photoOffsetX: photoOffsetX ?? this.photoOffsetX,
      photoOffsetY: photoOffsetY ?? this.photoOffsetY,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      overlay: overlay ?? this.overlay,
    );
  }
}
