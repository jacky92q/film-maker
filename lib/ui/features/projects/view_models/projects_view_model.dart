import 'package:film_maker/data/repositories/project_repository.dart';
import 'package:film_maker/domain/models/project.dart';
import 'package:flutter/foundation.dart';

class ProjectsViewModel extends ChangeNotifier {
  ProjectsViewModel({required ProjectRepository projectRepository})
      : _projectRepository = projectRepository;

  final ProjectRepository _projectRepository;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<Project> _projects = const [];
  List<Project> get projects => List.unmodifiable(_projects);

  Future<void> loadProjects() async {
    _isLoading = true;
    notifyListeners();

    _projects = await _projectRepository.getProjects();

    _isLoading = false;
    notifyListeners();
  }
}
