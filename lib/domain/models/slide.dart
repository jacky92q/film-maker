enum TransitionEffect { fade, slideLeft, slideRight, zoomIn, kenBurns }

enum TextPosition {
  topCenter,
  centerLeft,
  center,
  centerRight,
  bottomLeft,
  bottomCenter,
  bottomRight,
}

enum SlideTextColor { white, gold, cream, black, rose }

enum SlideTextSize { small, medium, large }

enum SlideFontStyle { serif, sans }

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
    }
  }

  double get titleFontSize {
    switch (this) {
      case SlideTextSize.small:
        return 16;
      case SlideTextSize.medium:
        return 22;
      case SlideTextSize.large:
        return 30;
    }
  }

  double get subtitleFontSize {
    switch (this) {
      case SlideTextSize.small:
        return 11;
      case SlideTextSize.medium:
        return 13;
      case SlideTextSize.large:
        return 16;
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

// ignore: avoid_classes_with_only_static_members
class SlideDefaults {
  static Slide fromTemplate(String id, SlideTemplate template) {
    switch (template) {
      case SlideTemplate.blank:
        return Slide(id: id);
      case SlideTemplate.opening:
        return Slide(
          id: id,
          title: 'Our Story',
          subtitle: 'A Wedding Film',
          textPosition: TextPosition.center,
          textSize: SlideTextSize.large,
          fontStyle: SlideFontStyle.serif,
          transition: TransitionEffect.fade,
          durationSeconds: 5,
        );
      case SlideTemplate.memory:
        return Slide(
          id: id,
          title: '',
          subtitle: 'A cherished moment',
          textPosition: TextPosition.bottomCenter,
          textSize: SlideTextSize.small,
          textColor: SlideTextColor.cream,
          transition: TransitionEffect.kenBurns,
          durationSeconds: 5,
        );
      case SlideTemplate.loveNote:
        return Slide(
          id: id,
          title: '"You are my greatest adventure"',
          subtitle: '',
          textPosition: TextPosition.center,
          textSize: SlideTextSize.medium,
          fontStyle: SlideFontStyle.serif,
          textColor: SlideTextColor.gold,
          transition: TransitionEffect.fade,
          durationSeconds: 6,
        );
      case SlideTemplate.closing:
        return Slide(
          id: id,
          title: 'Forever & Always',
          subtitle: '${DateTime.now().year}',
          textPosition: TextPosition.center,
          textSize: SlideTextSize.large,
          fontStyle: SlideFontStyle.serif,
          textColor: SlideTextColor.gold,
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
    this.title = '',
    this.subtitle = '',
    this.transition = TransitionEffect.fade,
    this.textPosition = TextPosition.bottomCenter,
    this.durationSeconds = 4,
    this.textColor = SlideTextColor.white,
    this.textSize = SlideTextSize.medium,
    this.fontStyle = SlideFontStyle.serif,
    this.photoFilter = PhotoFilter.none,
  });

  final String id;
  final String? imagePath;
  final String title;
  final String subtitle;
  final TransitionEffect transition;
  final TextPosition textPosition;
  final int durationSeconds;
  final SlideTextColor textColor;
  final SlideTextSize textSize;
  final SlideFontStyle fontStyle;
  final PhotoFilter photoFilter;

  Slide copyWith({
    String? imagePath,
    String? title,
    String? subtitle,
    TransitionEffect? transition,
    TextPosition? textPosition,
    int? durationSeconds,
    SlideTextColor? textColor,
    SlideTextSize? textSize,
    SlideFontStyle? fontStyle,
    PhotoFilter? photoFilter,
  }) {
    return Slide(
      id: id,
      imagePath: imagePath ?? this.imagePath,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      transition: transition ?? this.transition,
      textPosition: textPosition ?? this.textPosition,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      textColor: textColor ?? this.textColor,
      textSize: textSize ?? this.textSize,
      fontStyle: fontStyle ?? this.fontStyle,
      photoFilter: photoFilter ?? this.photoFilter,
    );
  }
}
