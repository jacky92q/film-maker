import 'package:film_maker/data/services/video_export_service.dart';
import 'package:film_maker/domain/models/project.dart';

class ExportRepository {
  ExportRepository({required VideoExportService exportService})
      : _exportService = exportService;

  final VideoExportService _exportService;

  String? get lastOutputPath => _exportService.lastOutputPath;

  Stream<double> exportProject({
    required Project project,
    required String resolution,
  }) {
    return _exportService.exportProject(
      project: project,
      resolution: resolution,
    );
  }
}
