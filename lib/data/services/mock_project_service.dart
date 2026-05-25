import 'package:film_maker/domain/models/project.dart';
import 'package:film_maker/domain/models/slide.dart';
import 'package:uuid/uuid.dart';

class MockProjectService {
  final _uuid = const Uuid();

  final List<Project> _projects = [
    Project(
      id: 'p1',
      title: 'Our Beginning',
      slides: [
        Slide(
          id: 's1',
          title: 'The Day We Met',
          subtitle: 'Seoul, Spring 2024',
          transition: TransitionEffect.fade,
          durationSeconds: 5,
        ),
        Slide(
          id: 's2',
          title: 'First Date',
          subtitle: 'Hangang Park',
          transition: TransitionEffect.slideLeft,
          durationSeconds: 4,
        ),
        Slide(
          id: 's3',
          title: 'Our Journey',
          subtitle: '365 days together',
          transition: TransitionEffect.kenBurns,
          durationSeconds: 6,
        ),
      ],
      createdAt: DateTime(2024, 6, 1),
      updatedAt: DateTime(2024, 6, 15),
    ),
    Project(
      id: 'p2',
      title: 'City Rain',
      slides: [
        Slide(
          id: 's4',
          title: 'Under the Rain',
          subtitle: 'Just us two',
          transition: TransitionEffect.fade,
          durationSeconds: 4,
        ),
        Slide(
          id: 's5',
          title: 'Neon Lights',
          subtitle: 'Hongdae Street',
          transition: TransitionEffect.zoomIn,
          durationSeconds: 5,
        ),
      ],
      createdAt: DateTime(2024, 9, 1),
      updatedAt: DateTime(2024, 9, 10),
    ),
  ];

  Future<List<Project>> fetchProjects() async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    return List.from(_projects);
  }

  Future<Project> createProject({required String title}) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    final project = Project(
      id: _uuid.v4(),
      title: title,
      slides: [
        Slide(
          id: _uuid.v4(),
          title: '',
          subtitle: '',
          transition: TransitionEffect.fade,
        ),
      ],
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
