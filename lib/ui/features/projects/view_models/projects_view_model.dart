import 'package:film_maker/data/repositories/project_repository.dart';
import 'package:film_maker/domain/models/project.dart';
import 'package:flutter/foundation.dart';

class ProjectsViewModel extends ChangeNotifier {
  ProjectsViewModel({required ProjectRepository projectRepository})
      : _projectRepository = projectRepository;

  final ProjectRepository _projectRepository;

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

  Future<Project?> createProject(String title) async {
    try {
      final project = await _projectRepository.createProject(title: title);
      _projects = [project, ..._projects];
      notifyListeners();
      return project;
    } catch (_) {
      return null;
    }
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

  void updateProjectInList(Project updatedProject) {
    _projects = [
      for (final p in _projects)
        if (p.id == updatedProject.id) updatedProject else p,
    ];
    notifyListeners();
  }
}
