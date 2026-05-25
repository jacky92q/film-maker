import 'package:film_maker/data/services/mock_project_service.dart';
import 'package:film_maker/domain/models/project.dart';

class ProjectRepository {
  ProjectRepository({required MockProjectService projectService}) : _projectService = projectService;

  final MockProjectService _projectService;

  Future<List<Project>> getProjects() async {
    final raw = await _projectService.fetchProjects();
    return raw
        .map(
          (p) => Project(
            id: p['id']! as String,
            title: p['title']! as String,
            sceneCount: p['sceneCount']! as int,
          ),
        )
        .toList(growable: false);
  }
}
