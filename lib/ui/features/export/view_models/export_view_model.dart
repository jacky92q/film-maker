import 'package:film_maker/domain/models/project.dart';
import 'package:flutter/foundation.dart';

enum ExportStatus { idle, exporting, done, error }

enum ExportResolution { hd, fullHd, fourK }

extension ExportResolutionX on ExportResolution {
  String get label => switch (this) {
        ExportResolution.hd => '720p HD',
        ExportResolution.fullHd => '1080p Full HD',
        ExportResolution.fourK => '4K Ultra HD',
      };

  int get width => switch (this) {
        ExportResolution.hd => 1280,
        ExportResolution.fullHd => 1920,
        ExportResolution.fourK => 3840,
      };

  int get height => switch (this) {
        ExportResolution.hd => 720,
        ExportResolution.fullHd => 1080,
        ExportResolution.fourK => 2160,
      };

  /// Canvas pixel ratio relative to the 1280×720 logical canvas.
  double get pixelRatio => switch (this) {
        ExportResolution.hd => 1.0,
        ExportResolution.fullHd => 1.5,
        ExportResolution.fourK => 3.0,
      };

  int get bitrateBps => switch (this) {
        ExportResolution.hd => 4_000_000,
        ExportResolution.fullHd => 8_000_000,
        ExportResolution.fourK => 20_000_000,
      };
}

class ExportViewModel extends ChangeNotifier {
  ExportViewModel({required this.project});

  final Project project;

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

  /// Transitions to [ExportStatus.exporting]; the view drives the actual work.
  void startExport() {
    _status = ExportStatus.exporting;
    _progress = 0;
    _error = null;
    _outputPath = null;
    notifyListeners();
  }

  void updateProgress(double p) {
    _progress = p;
    notifyListeners();
  }

  void completeExport(String outputPath) {
    _status = ExportStatus.done;
    _outputPath = outputPath;
    notifyListeners();
  }

  void failExport(String message) {
    _status = ExportStatus.error;
    _error = message;
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
