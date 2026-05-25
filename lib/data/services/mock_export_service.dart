class MockExportService {
  Stream<double> exportProject({
    required String projectId,
    required String resolution,
  }) async* {
    for (int i = 1; i <= 100; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 60));
      yield i / 100.0;
    }
  }
}
