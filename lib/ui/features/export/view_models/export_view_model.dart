import 'package:film_maker/data/repositories/export_repository.dart';
import 'package:film_maker/domain/models/project.dart';
import 'package:flutter/foundation.dart';

enum ExportStatus { idle, exporting, done, error }

enum ExportResolution { hd, fullHd, fourK }

extension ExportResolutionX on ExportResolution {
  String get label {
    switch (this) {
      case ExportResolution.hd:
        return '720p HD';
      case ExportResolution.fullHd:
        return '1080p Full HD';
      case ExportResolution.fourK:
        return '4K Ultra HD';
    }
  }

  String get value {
    switch (this) {
      case ExportResolution.hd:
        return '720p';
      case ExportResolution.fullHd:
        return '1080p';
      case ExportResolution.fourK:
        return '4k';
    }
  }
}

class ExportViewModel extends ChangeNotifier {
  ExportViewModel({
    required this.project,
    required this.exportRepository,
  });

  final Project project;
  final ExportRepository exportRepository;

  ExportStatus _status = ExportStatus.idle;
  ExportResolution _resolution = ExportResolution.fullHd;
  double _progress = 0;
  String? _error;
  String? _outputPath;

  ExportStatus get status => _status;
  ExportResolution get resolution => _resolution;
  double get progress => _progress;
  String? get error => _error;
  String? get outputPath => _outputPath;
  bool get isExporting => _status == ExportStatus.exporting;
  bool get isDone => _status == ExportStatus.done;

  void setResolution(ExportResolution res) {
    _resolution = res;
    notifyListeners();
  }

  Future<void> startExport() async {
    _status = ExportStatus.exporting;
    _progress = 0;
    _error = null;
    notifyListeners();

    try {
      await for (final p in exportRepository.exportProject(
        projectId: project.id,
        resolution: _resolution.value,
      )) {
        _progress = p;
        notifyListeners();
      }
      _status = ExportStatus.done;
      final fileName = project.title
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9]+'), '_');
      _outputPath = '/Movies/${fileName}_wedding_film.mp4';
    } catch (_) {
      _status = ExportStatus.error;
      _error = 'Export failed. Please try again.';
    }
    notifyListeners();
  }

  void reset() {
    _status = ExportStatus.idle;
    _progress = 0;
    _error = null;
    _outputPath = null;
    notifyListeners();
  }
}
