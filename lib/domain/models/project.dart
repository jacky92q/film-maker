import 'package:film_maker/domain/models/slide.dart';

class Project {
  const Project({
    required this.id,
    required this.title,
    required this.slides,
    required this.createdAt,
    required this.updatedAt,
    this.musicPath,
    this.musicName,
  });

  final String id;
  final String title;
  final List<Slide> slides;
  final String? musicPath;
  final String? musicName;
  final DateTime createdAt;
  final DateTime updatedAt;

  int get slideCount => slides.length;
  String? get thumbnailPath => slides.isNotEmpty ? slides.first.imagePath : null;
  int get totalDurationSeconds =>
      slides.fold(0, (sum, s) => sum + s.durationSeconds);

  // Note: passing null for musicPath/musicName keeps the existing value.
  // To clear music, create a new Project directly.
  Project copyWith({
    String? title,
    List<Slide>? slides,
    String? musicPath,
    String? musicName,
    DateTime? updatedAt,
  }) {
    return Project(
      id: id,
      title: title ?? this.title,
      slides: slides ?? this.slides,
      musicPath: musicPath ?? this.musicPath,
      musicName: musicName ?? this.musicName,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
