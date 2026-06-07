import 'package:film_maker/domain/models/slide.dart';
import 'package:film_maker/l10n/app_strings.dart';

/// A curated set of elegant, wedding-grade decorative stickers. Each is drawn
/// as crisp vector art (see `sticker_painter.dart`) so it stays sharp at any
/// export resolution. These are intentionally *static* / tasteful — not the
/// animated ambient effects.
enum StickerKind {
  heart,
  doubleHeart,
  rings,
  ribbonBow,
  ribbonBanner,
  oliveBranch,
  leafSprig,
  wreath,
  floralRose,
  sparkle,
  starOutline,
  flourish,
  cornerFlourish,
  ovalFrame,
  crown,
  champagne,
  dove,
  arch,
}

extension StickerKindX on StickerKind {
  String get label => switch (this) {
        StickerKind.heart          => L10n.s.stickerHeart,
        StickerKind.doubleHeart    => L10n.s.stickerDoubleHeart,
        StickerKind.rings          => L10n.s.stickerRings,
        StickerKind.ribbonBow      => L10n.s.stickerRibbonBow,
        StickerKind.ribbonBanner   => L10n.s.stickerBanner,
        StickerKind.oliveBranch    => L10n.s.stickerOliveBranch,
        StickerKind.leafSprig      => L10n.s.stickerLeafSprig,
        StickerKind.wreath         => L10n.s.stickerWreath,
        StickerKind.floralRose     => L10n.s.stickerRose,
        StickerKind.sparkle        => L10n.s.stickerSparkle,
        StickerKind.starOutline    => L10n.s.stickerStar,
        StickerKind.flourish       => L10n.s.stickerFlourish,
        StickerKind.cornerFlourish => L10n.s.stickerCorner,
        StickerKind.ovalFrame      => L10n.s.stickerOval,
        StickerKind.crown          => L10n.s.stickerCrown,
        StickerKind.champagne      => L10n.s.stickerChampagne,
        StickerKind.dove           => L10n.s.stickerDove,
        StickerKind.arch           => L10n.s.stickerArch,
      };

  String get emoji => switch (this) {
        StickerKind.heart          => '♡',
        StickerKind.doubleHeart    => '❥',
        StickerKind.rings          => '💍',
        StickerKind.ribbonBow      => '🎀',
        StickerKind.ribbonBanner   => '🏷',
        StickerKind.oliveBranch    => '🌿',
        StickerKind.leafSprig      => '🍃',
        StickerKind.wreath         => '🌾',
        StickerKind.floralRose     => '🌹',
        StickerKind.sparkle        => '✦',
        StickerKind.starOutline    => '☆',
        StickerKind.flourish       => '❧',
        StickerKind.cornerFlourish => '⤣',
        StickerKind.ovalFrame      => '⬭',
        StickerKind.crown          => '♛',
        StickerKind.champagne      => '🥂',
        StickerKind.dove           => '🕊',
        StickerKind.arch           => '⌒',
      };

  /// Natural width / height of the sticker's artwork box. Used to derive the
  /// layer's height from its [StickerLayer.widthFraction].
  double get aspectRatio => switch (this) {
        StickerKind.heart          => 1.1,
        StickerKind.doubleHeart    => 1.5,
        StickerKind.rings          => 1.6,
        StickerKind.ribbonBow      => 1.4,
        StickerKind.ribbonBanner   => 2.8,
        StickerKind.oliveBranch    => 2.4,
        StickerKind.leafSprig      => 1.0,
        StickerKind.wreath         => 1.0,
        StickerKind.floralRose     => 1.0,
        StickerKind.sparkle        => 1.0,
        StickerKind.starOutline    => 1.0,
        StickerKind.flourish       => 3.6,
        StickerKind.cornerFlourish => 1.0,
        StickerKind.ovalFrame      => 0.74,
        StickerKind.crown          => 1.5,
        StickerKind.champagne      => 1.05,
        StickerKind.dove           => 1.4,
        StickerKind.arch           => 0.78,
      };

  /// Whether this sticker reads better filled vs. as line art. Used as the
  /// default when a layer is first created.
  bool get defaultFilled => switch (this) {
        StickerKind.heart       => false,
        StickerKind.starOutline => false,
        StickerKind.ovalFrame   => false,
        StickerKind.arch        => false,
        StickerKind.rings       => false,
        StickerKind.flourish    => false,
        _                       => true,
      };

  static StickerKind fromName(String? name) => StickerKind.values.firstWhere(
        (k) => k.name == name,
        orElse: () => StickerKind.heart,
      );
}

/// A free-floating decorative sticker placed on a slide. Position and size are
/// normalized to the canvas so they render identically at any resolution or
/// orientation.
class StickerLayer {
  const StickerLayer({
    required this.id,
    required this.kind,
    this.x = 0.5,
    this.y = 0.5,
    this.widthFraction = 0.22,
    this.rotation = 0.0,
    this.color = SlideTextColor.gold,
    this.filled = true,
    this.opacity = 1.0,
    this.zOrder = 0,
  });

  final String id;
  final StickerKind kind;
  final double x;             // center-x as fraction of canvas width  (0–1)
  final double y;             // center-y as fraction of canvas height (0–1)
  final double widthFraction; // width as fraction of canvas width
  final double rotation;      // degrees
  final SlideTextColor color;
  final bool filled;          // filled artwork vs. line art
  final double opacity;       // 0–1
  final int zOrder;

  factory StickerLayer.fromJson(Map<String, dynamic> j) => StickerLayer(
        id: j['id'] as String,
        kind: StickerKindX.fromName(j['kind'] as String?),
        x: (j['x'] as num).toDouble(),
        y: (j['y'] as num).toDouble(),
        widthFraction: (j['widthFraction'] as num? ?? 0.22).toDouble(),
        rotation: (j['rotation'] as num? ?? 0).toDouble(),
        color: SlideTextColor.values.firstWhere(
            (e) => e.name == j['color'],
            orElse: () => SlideTextColor.gold),
        filled: j['filled'] as bool? ?? true,
        opacity: (j['opacity'] as num? ?? 1.0).toDouble(),
        zOrder: j['zOrder'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': kind.name,
        'x': x,
        'y': y,
        'widthFraction': widthFraction,
        'rotation': rotation,
        'color': color.name,
        'filled': filled,
        'opacity': opacity,
        'zOrder': zOrder,
      };

  StickerLayer copyWith({
    StickerKind? kind,
    double? x,
    double? y,
    double? widthFraction,
    double? rotation,
    SlideTextColor? color,
    bool? filled,
    double? opacity,
    int? zOrder,
  }) {
    return StickerLayer(
      id: id,
      kind: kind ?? this.kind,
      x: x ?? this.x,
      y: y ?? this.y,
      widthFraction: widthFraction ?? this.widthFraction,
      rotation: rotation ?? this.rotation,
      color: color ?? this.color,
      filled: filled ?? this.filled,
      opacity: opacity ?? this.opacity,
      zOrder: zOrder ?? this.zOrder,
    );
  }
}
