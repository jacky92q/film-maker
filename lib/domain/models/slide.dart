import 'package:flutter/material.dart';

enum TransitionEffect { fade, slideLeft, slideRight, zoomIn, kenBurns, blurDissolve, wipeLeft, wipeRight }

enum SlideTextColor { white, gold, cream, black, rose, silver, champagne, blush, dustyBlue, sage, lavender, warmGray, coral }

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
      case SlideTextColor.silver:
        return 'Silver';
      case SlideTextColor.champagne:
        return 'Champagne';
      case SlideTextColor.blush:
        return 'Blush';
      case SlideTextColor.dustyBlue:
        return 'Blue';
      case SlideTextColor.sage:
        return 'Sage';
      case SlideTextColor.lavender:
        return 'Lavender';
      case SlideTextColor.warmGray:
        return 'Gray';
      case SlideTextColor.coral:
        return 'Coral';
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
      case SlideTextColor.silver:
        return const Color(0xFFC0C0C0);
      case SlideTextColor.champagne:
        return const Color(0xFFF7E7CE);
      case SlideTextColor.blush:
        return const Color(0xFFE8A0B0);
      case SlideTextColor.dustyBlue:
        return const Color(0xFF88A8C0);
      case SlideTextColor.sage:
        return const Color(0xFF8FAF8F);
      case SlideTextColor.lavender:
        return const Color(0xFFB090C8);
      case SlideTextColor.warmGray:
        return const Color(0xFF999080);
      case SlideTextColor.coral:
        return const Color(0xFFE88070);
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

enum PhotoShape { none, rounded, circle, heart, arch }

extension PhotoShapeX on PhotoShape {
  String get label {
    switch (this) {
      case PhotoShape.none:    return 'None';
      case PhotoShape.rounded: return 'Rounded';
      case PhotoShape.circle:  return 'Circle';
      case PhotoShape.heart:   return 'Heart';
      case PhotoShape.arch:    return 'Arch';
    }
  }
}

enum PhotoFrame { none, white, gold, polaroid }

extension PhotoFrameX on PhotoFrame {
  String get label {
    switch (this) {
      case PhotoFrame.none:     return 'None';
      case PhotoFrame.white:    return 'White';
      case PhotoFrame.gold:     return 'Gold';
      case PhotoFrame.polaroid: return 'Polaroid';
    }
  }
}

enum SlideLayout { single, strip2, strip3 }

extension SlideLayoutX on SlideLayout {
  String get label {
    switch (this) {
      case SlideLayout.single: return 'Single';
      case SlideLayout.strip2: return '2 Photos';
      case SlideLayout.strip3: return '3 Photos';
    }
  }
}

enum SlideContentAnimation {
  none,
  typewriter,
  slideUp,
  slideIn,
  fadeStagger,
  float,
  zoomPulse,
  wipeReveal,
}

extension SlideContentAnimationX on SlideContentAnimation {
  String get label => switch (this) {
    SlideContentAnimation.none        => 'None',
    SlideContentAnimation.typewriter  => 'Typewriter',
    SlideContentAnimation.slideUp     => 'Slide Up',
    SlideContentAnimation.slideIn     => 'Slide In',
    SlideContentAnimation.fadeStagger => 'Fade In',
    SlideContentAnimation.float       => 'Float',
    SlideContentAnimation.zoomPulse   => 'Zoom Pulse',
    SlideContentAnimation.wipeReveal  => 'Wipe Reveal',
  };

  String get emoji => switch (this) {
    SlideContentAnimation.none        => '✦',
    SlideContentAnimation.typewriter  => '⌨',
    SlideContentAnimation.slideUp     => '↑',
    SlideContentAnimation.slideIn     => '→',
    SlideContentAnimation.fadeStagger => '✨',
    SlideContentAnimation.float       => '〜',
    SlideContentAnimation.zoomPulse   => '⊙',
    SlideContentAnimation.wipeReveal  => '▶',
  };

  // Animations that make sense on text layers
  static const textAnimations = [
    SlideContentAnimation.none,
    SlideContentAnimation.typewriter,
    SlideContentAnimation.slideUp,
    SlideContentAnimation.slideIn,
    SlideContentAnimation.fadeStagger,
    SlideContentAnimation.float,
    SlideContentAnimation.wipeReveal,
  ];

  // Animations that make sense on photo layers
  static const photoAnimations = [
    SlideContentAnimation.none,
    SlideContentAnimation.slideUp,
    SlideContentAnimation.slideIn,
    SlideContentAnimation.fadeStagger,
    SlideContentAnimation.float,
    SlideContentAnimation.zoomPulse,
  ];
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

enum DimDirection { none, bottom, top, left, right, radial }

extension DimDirectionX on DimDirection {
  String get label {
    switch (this) {
      case DimDirection.none:   return 'None';
      case DimDirection.bottom: return 'Bottom';
      case DimDirection.top:    return 'Top';
      case DimDirection.left:   return 'Left';
      case DimDirection.right:  return 'Right';
      case DimDirection.radial: return 'Radial';
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
    this.fontSize = 96.0,
    this.rotation = 0.0,
    this.fontStyle = SlideFontStyle.serif,
    this.textBg = SlideTextBg.none,
    this.strokeWidth = 0.0,
    this.letterSpacing = 0.0,
    this.zOrder = 0,
    this.contentAnimation = SlideContentAnimation.none,
  });

  final String id;
  final String text;
  final bool isSubtitle;
  final double x;
  final double y;
  final SlideTextColor color;
  final SlideTextColor barColor;
  final double fontSize;
  final double rotation;
  final SlideFontStyle fontStyle;
  final SlideTextBg textBg;
  final double strokeWidth;
  final double letterSpacing;
  final int zOrder;
  final SlideContentAnimation contentAnimation;

  TextLayer copyWith({
    String? text,
    bool? isSubtitle,
    double? x,
    double? y,
    SlideTextColor? color,
    SlideTextColor? barColor,
    double? fontSize,
    double? rotation,
    SlideFontStyle? fontStyle,
    SlideTextBg? textBg,
    double? strokeWidth,
    double? letterSpacing,
    int? zOrder,
    SlideContentAnimation? contentAnimation,
  }) {
    return TextLayer(
      id: id,
      text: text ?? this.text,
      isSubtitle: isSubtitle ?? this.isSubtitle,
      x: x ?? this.x,
      y: y ?? this.y,
      color: color ?? this.color,
      barColor: barColor ?? this.barColor,
      fontSize: fontSize ?? this.fontSize,
      rotation: rotation ?? this.rotation,
      fontStyle: fontStyle ?? this.fontStyle,
      textBg: textBg ?? this.textBg,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      letterSpacing: letterSpacing ?? this.letterSpacing,
      zOrder: zOrder ?? this.zOrder,
      contentAnimation: contentAnimation ?? this.contentAnimation,
    );
  }
}

class PhotoLayer {
  PhotoLayer({
    required this.id,
    this.imagePath,
    this.x = 0.5,
    this.y = 0.5,
    this.widthFraction = 0.45,
    this.heightFraction = 0.55,
    this.rotation = 0.0,
    this.shape = PhotoShape.none,
    this.frame = PhotoFrame.none,
    this.filter = PhotoFilter.none,
    this.frameWidth = 16.0,
    this.cropScale = 1.0,
    this.cropOffsetX = 0.0,
    this.cropOffsetY = 0.0,
    this.zOrder = 0,
    this.contentAnimation = SlideContentAnimation.none,
  });

  final String id;
  final String? imagePath;
  final double x;              // center-x as fraction of canvas width  (0–1)
  final double y;              // center-y as fraction of canvas height (0–1)
  final double widthFraction;  // width  as fraction of canvas width  (0–1)
  final double heightFraction; // height as fraction of canvas height (0–1)
  final double rotation;       // degrees
  final PhotoShape shape;
  final PhotoFrame frame;
  final PhotoFilter filter;
  final double frameWidth;     // border thickness in logical pixels
  final double cropScale;      // zoom factor within frame (1.0 = no zoom)
  final double cropOffsetX;    // horizontal pan as fraction of frame width  (-0.5..0.5)
  final double cropOffsetY;    // vertical   pan as fraction of frame height (-0.5..0.5)
  final int zOrder;
  final SlideContentAnimation contentAnimation;

  PhotoLayer copyWith({
    String? imagePath,
    double? x,
    double? y,
    double? widthFraction,
    double? heightFraction,
    double? rotation,
    PhotoShape? shape,
    PhotoFrame? frame,
    PhotoFilter? filter,
    double? frameWidth,
    double? cropScale,
    double? cropOffsetX,
    double? cropOffsetY,
    int? zOrder,
    SlideContentAnimation? contentAnimation,
  }) {
    return PhotoLayer(
      id: id,
      imagePath: imagePath ?? this.imagePath,
      x: x ?? this.x,
      y: y ?? this.y,
      widthFraction: widthFraction ?? this.widthFraction,
      heightFraction: heightFraction ?? this.heightFraction,
      rotation: rotation ?? this.rotation,
      shape: shape ?? this.shape,
      frame: frame ?? this.frame,
      filter: filter ?? this.filter,
      frameWidth: frameWidth ?? this.frameWidth,
      cropScale: cropScale ?? this.cropScale,
      cropOffsetX: cropOffsetX ?? this.cropOffsetX,
      cropOffsetY: cropOffsetY ?? this.cropOffsetY,
      zOrder: zOrder ?? this.zOrder,
      contentAnimation: contentAnimation ?? this.contentAnimation,
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
            TextLayer(id: '${id}_t', text: 'Our Story', x: 0.5, y: 0.50, fontSize: 96.0, fontStyle: SlideFontStyle.serif, color: SlideTextColor.cream),
            TextLayer(id: '${id}_s', text: 'A Wedding Film', isSubtitle: true, x: 0.5, y: 0.66, fontSize: 56.0, color: SlideTextColor.gold, barColor: SlideTextColor.gold),
          ],
          transition: TransitionEffect.fade,
          durationSeconds: 5,
        );
      case SlideTemplate.memory:
        return Slide(
          id: id,
          textLayers: [
            TextLayer(id: '${id}_s', text: 'A cherished moment', isSubtitle: true, x: 0.5, y: 0.86, fontSize: 56.0, color: SlideTextColor.cream, barColor: SlideTextColor.cream),
          ],
          transition: TransitionEffect.kenBurns,
          durationSeconds: 5,
        );
      case SlideTemplate.loveNote:
        return Slide(
          id: id,
          textLayers: [
            TextLayer(id: '${id}_t', text: '"You are my greatest adventure"', x: 0.5, y: 0.50, fontSize: 96.0, fontStyle: SlideFontStyle.serif, color: SlideTextColor.gold),
          ],
          transition: TransitionEffect.fade,
          durationSeconds: 6,
        );
      case SlideTemplate.closing:
        return Slide(
          id: id,
          textLayers: [
            TextLayer(id: '${id}_t', text: 'Forever & Always', x: 0.5, y: 0.46, fontSize: 96.0, fontStyle: SlideFontStyle.serif, color: SlideTextColor.gold),
            TextLayer(id: '${id}_s', text: '${DateTime.now().year}', isSubtitle: true, x: 0.5, y: 0.62, fontSize: 56.0, color: SlideTextColor.gold, barColor: SlideTextColor.gold),
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
    this.photoLayers = const [],
    this.transition = TransitionEffect.fade,
    this.durationSeconds = 4,
    this.photoFilter = PhotoFilter.none,
    this.photoScale = 1.0,
    this.photoOffsetX = 0.0,
    this.photoOffsetY = 0.0,
    this.backgroundColor = 0xFF000000,
    this.overlay = SlideOverlay.none,
    this.photoShape = PhotoShape.none,
    this.photoFrame = PhotoFrame.none,
    this.layout = SlideLayout.single,
    this.imagePath2,
    this.imagePath3,
    this.contentAnimation = SlideContentAnimation.none,
    this.dimDirection = DimDirection.none,
    this.dimOpacity = 0.5,
  });

  final String id;
  final String? imagePath;
  final List<TextLayer> textLayers;
  final List<PhotoLayer> photoLayers;
  final TransitionEffect transition;
  final int durationSeconds;
  final PhotoFilter photoFilter;
  final double photoScale;
  final double photoOffsetX;
  final double photoOffsetY;
  final int backgroundColor;
  final SlideOverlay overlay;
  final PhotoShape photoShape;
  final PhotoFrame photoFrame;
  final SlideLayout layout;
  final String? imagePath2;
  final String? imagePath3;
  final SlideContentAnimation contentAnimation;
  final DimDirection dimDirection;
  final double dimOpacity;

  Slide copyWith({
    String? imagePath,
    List<TextLayer>? textLayers,
    List<PhotoLayer>? photoLayers,
    TransitionEffect? transition,
    int? durationSeconds,
    PhotoFilter? photoFilter,
    double? photoScale,
    double? photoOffsetX,
    double? photoOffsetY,
    int? backgroundColor,
    SlideOverlay? overlay,
    PhotoShape? photoShape,
    PhotoFrame? photoFrame,
    SlideLayout? layout,
    String? imagePath2,
    String? imagePath3,
    SlideContentAnimation? contentAnimation,
    DimDirection? dimDirection,
    double? dimOpacity,
  }) {
    return Slide(
      id: id,
      imagePath: imagePath ?? this.imagePath,
      textLayers: textLayers ?? this.textLayers,
      photoLayers: photoLayers ?? this.photoLayers,
      transition: transition ?? this.transition,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      photoFilter: photoFilter ?? this.photoFilter,
      photoScale: photoScale ?? this.photoScale,
      photoOffsetX: photoOffsetX ?? this.photoOffsetX,
      photoOffsetY: photoOffsetY ?? this.photoOffsetY,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      overlay: overlay ?? this.overlay,
      photoShape: photoShape ?? this.photoShape,
      photoFrame: photoFrame ?? this.photoFrame,
      layout: layout ?? this.layout,
      imagePath2: imagePath2 ?? this.imagePath2,
      imagePath3: imagePath3 ?? this.imagePath3,
      contentAnimation: contentAnimation ?? this.contentAnimation,
      dimDirection: dimDirection ?? this.dimDirection,
      dimOpacity: dimOpacity ?? this.dimOpacity,
    );
  }
}
