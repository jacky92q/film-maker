class MockProjectService {
  Future<List<Map<String, Object>>> fetchProjects() async {
    await Future<void>.delayed(const Duration(milliseconds: 150));

    return const [
      {'id': 'p1', 'title': 'Our Beginning', 'sceneCount': 12},
      {'id': 'p2', 'title': 'City Rain', 'sceneCount': 8},
      {'id': 'p3', 'title': 'Night Drive', 'sceneCount': 15},
    ];
  }
}
