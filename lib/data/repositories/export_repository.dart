import 'package:film_maker/data/services/video_export_service.dart';
import 'package:film_maker/domain/models/project.dart';

class ExportRepository {
  ExportRepository({required VideoExportService exportService})
      : _exportService = exportService;

  final VideoExportService _exportService;

  Future<String> exportProject({
    required Project project,
    required String resolution,
    required void Function(double) onProgress,
  }) {
    return _exportService.exportProject(
      project: project,
      resolution: resolution,
      onProgress: onProgress,
    );
  }
}
