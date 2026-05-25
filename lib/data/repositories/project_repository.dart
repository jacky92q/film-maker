import 'package:film_maker/data/services/mock_project_service.dart';
import 'package:film_maker/domain/models/project.dart';

class ProjectRepository {
  ProjectRepository({required MockProjectService projectService})
      : _projectService = projectService;

  final MockProjectService _projectService;

  Future<List<Project>> getProjects() => _projectService.fetchProjects();

  Future<Project> createProject({required String title}) =>
      _projectService.createProject(title: title);

  Future<Project> updateProject(Project project) =>
      _projectService.updateProject(project);

  Future<void> deleteProject(String projectId) =>
      _projectService.deleteProject(projectId);
}
