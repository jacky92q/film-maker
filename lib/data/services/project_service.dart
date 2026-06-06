import 'package:film_maker/domain/models/project.dart';

abstract class ProjectService {
  Future<List<Project>> fetchProjects();
  Future<Project> createProject({required String title});
  Future<Project> updateProject(Project project);
  Future<Project> upsertProject(Project project);
  Future<void> deleteProject(String projectId);
}
