import 'package:film_maker/data/repositories/export_repository.dart';
import 'package:film_maker/domain/models/project.dart';
import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';

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

  ExportStatus get status => _status;
  ExportResolution get resolution => _resolution;
  double get progress => _progress;
  String? get error => _error;
  String? get outputPath => exportRepository.lastOutputPath;
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
        project: project,
        resolution: _resolution.value,
      )) {
        _progress = p;
        notifyListeners();
      }
      _status = ExportStatus.done;
    } catch (e) {
      _status = ExportStatus.error;
      _error = 'Export failed: ${e.toString()}';
    }
    notifyListeners();
  }

  Future<void> shareVideo() async {
    final path = outputPath;
    if (path == null) return;
    await Share.shareXFiles(
      [XFile(path, mimeType: 'video/mp4')],
      subject: '${project.title} — Wedding Film',
    );
  }

  void reset() {
    _status = ExportStatus.idle;
    _progress = 0;
    _error = null;
    notifyListeners();
  }
}
