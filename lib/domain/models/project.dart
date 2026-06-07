import 'package:film_maker/domain/models/slide.dart';

/// Video frame orientation. The logical canvas keeps a long edge of 1280 so
/// that normalized layer coordinates render identically in either orientation.
enum VideoOrientation {
  landscape,
  portrait;

  bool get isPortrait => this == VideoOrientation.portrait;

  /// Logical canvas width (px) used across editor, preview and export.
  double get canvasWidth => isPortrait ? 720.0 : 1280.0;

  /// Logical canvas height (px).
  double get canvasHeight => isPortrait ? 1280.0 : 720.0;

  /// width / height — feed directly into [AspectRatio].
  double get aspectRatio => canvasWidth / canvasHeight;

  static VideoOrientation fromName(String? name) =>
      VideoOrientation.values.firstWhere(
        (o) => o.name == name,
        orElse: () => VideoOrientation.landscape,
      );
}

class Project {
  const Project({
    required this.id,
    required this.title,
    required this.slides,
    required this.createdAt,
    required this.updatedAt,
    this.orientation = VideoOrientation.landscape,
    this.musicPath,
    this.musicName,
  });

  final String id;
  final String title;
  final List<Slide> slides;
  final VideoOrientation orientation;
  final String? musicPath;
  final String? musicName;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory Project.fromJson(Map<String, dynamic> j) => Project(
        id: j['id'] as String,
        title: j['title'] as String,
        slides: (j['slides'] as List)
            .map((e) => Slide.fromJson(e as Map<String, dynamic>))
            .toList(),
        orientation: VideoOrientation.fromName(j['orientation'] as String?),
        musicPath: j['musicPath'] as String?,
        musicName: j['musicName'] as String?,
        createdAt: DateTime.parse(j['createdAt'] as String),
        updatedAt: DateTime.parse(j['updatedAt'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'slides': slides.map((s) => s.toJson()).toList(),
        'orientation': orientation.name,
        'musicPath': musicPath,
        'musicName': musicName,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  int get slideCount => slides.length;
  String? get thumbnailPath => slides.isNotEmpty ? slides.first.imagePath : null;
  int get totalDurationSeconds =>
      slides.fold(0, (sum, s) => sum + s.durationSeconds);

  // Note: passing null for musicPath/musicName keeps the existing value.
  // To clear music, create a new Project directly.
  Project copyWith({
    String? title,
    List<Slide>? slides,
    VideoOrientation? orientation,
    String? musicPath,
    String? musicName,
    DateTime? updatedAt,
  }) {
    return Project(
      id: id,
      title: title ?? this.title,
      slides: slides ?? this.slides,
      orientation: orientation ?? this.orientation,
      musicPath: musicPath ?? this.musicPath,
      musicName: musicName ?? this.musicName,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
