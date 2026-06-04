import 'package:film_maker/domain/models/project.dart';
import 'package:film_maker/domain/models/slide.dart';
import 'package:uuid/uuid.dart';

class MockProjectService {
  final _uuid = const Uuid();

  final List<Project> _projects = [];

  Future<List<Project>> fetchProjects() async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    return List.from(_projects);
  }

  Future<Project> createProject({required String title}) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    final project = Project(
      id: _uuid.v4(),
      title: title,
      slides: [Slide(id: _uuid.v4())],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _projects.add(project);
    return project;
  }

  Future<Project> updateProject(Project project) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    final index = _projects.indexWhere((p) => p.id == project.id);
    if (index == -1) throw Exception('Project not found');
    final updated = project.copyWith(updatedAt: DateTime.now());
    _projects[index] = updated;
    return updated;
  }

  Future<void> deleteProject(String projectId) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    _projects.removeWhere((p) => p.id == projectId);
  }
}
