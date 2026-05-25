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

class Slide {
  const Slide({
    required this.id,
    this.imagePath,
    this.title = '',
    this.subtitle = '',
    this.transition = TransitionEffect.fade,
    this.textPosition = TextPosition.bottomCenter,
    this.durationSeconds = 4,
  });

  final String id;
  final String? imagePath;
  final String title;
  final String subtitle;
  final TransitionEffect transition;
  final TextPosition textPosition;
  final int durationSeconds;

  Slide copyWith({
    String? imagePath,
    String? title,
    String? subtitle,
    TransitionEffect? transition,
    TextPosition? textPosition,
    int? durationSeconds,
  }) {
    return Slide(
      id: id,
      imagePath: imagePath ?? this.imagePath,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      transition: transition ?? this.transition,
      textPosition: textPosition ?? this.textPosition,
      durationSeconds: durationSeconds ?? this.durationSeconds,
    );
  }
}
