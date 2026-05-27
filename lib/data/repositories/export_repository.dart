import 'package:film_maker/data/services/mock_export_service.dart';

class ExportRepository {
  ExportRepository({required MockExportService exportService})
      : _exportService = exportService;

  final MockExportService _exportService;

  Stream<double> exportProject({
    required String projectId,
    required String resolution,
  }) {
    return _exportService.exportProject(
      projectId: projectId,
      resolution: resolution,
    );
  }
}
