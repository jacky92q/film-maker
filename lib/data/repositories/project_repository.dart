import 'package:film_maker/data/services/project_service.dart';
import 'package:film_maker/domain/models/project.dart';

class ProjectRepository {
  ProjectRepository({required ProjectService projectService})
      : _projectService = projectService;

  final ProjectService _projectService;

  Future<List<Project>> getProjects() => _projectService.fetchProjects();

  Future<Project> createProject({required String title}) =>
      _projectService.createProject(title: title);

  Future<Project> updateProject(Project project) =>
      _projectService.updateProject(project);

  Future<Project> upsertProject(Project project) =>
      _projectService.upsertProject(project);

  Future<void> deleteProject(String projectId) =>
      _projectService.deleteProject(projectId);
}
