import 'package:film_maker/data/repositories/project_repository.dart';
import 'package:film_maker/domain/models/project.dart';
import 'package:film_maker/domain/models/slide.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

class ProjectsViewModel extends ChangeNotifier {
  ProjectsViewModel({required ProjectRepository projectRepository})
      : _projectRepository = projectRepository;

  final ProjectRepository _projectRepository;
  final _uuid = const Uuid();

  bool _isLoading = false;
  List<Project> _projects = const [];
  String? _error;

  bool get isLoading => _isLoading;
  List<Project> get projects => List.unmodifiable(_projects);
  String? get error => _error;

  Future<void> loadProjects() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _projects = await _projectRepository.getProjects();
    } catch (_) {
      _error = 'Failed to load films. Please try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Returns an in-memory project only — it gets persisted when the user saves
  // from the editor. If they discard, nothing is written to storage.
  Future<Project?> createProject(String title) async {
    return Project(
      id: _uuid.v4(),
      title: title,
      slides: [Slide(id: _uuid.v4())],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  Future<void> deleteProject(String projectId) async {
    _projects = _projects.where((p) => p.id != projectId).toList();
    notifyListeners();
    try {
      await _projectRepository.deleteProject(projectId);
    } catch (_) {
      await loadProjects();
    }
  }

  void upsertProjectInList(Project project) {
    final index = _projects.indexWhere((p) => p.id == project.id);
    if (index == -1) {
      _projects = [project, ..._projects];
    } else {
      _projects = [
        for (final p in _projects)
          if (p.id == project.id) project else p,
      ];
    }
    notifyListeners();
  }
}
