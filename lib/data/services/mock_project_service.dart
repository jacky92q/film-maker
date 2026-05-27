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
          textLayers: [
            TextLayer(id: 's1_t', text: 'The Day We Met', x: 0.5, y: 0.48, fontSize: 38.0, fontStyle: SlideFontStyle.serif, color: SlideTextColor.cream),
            TextLayer(id: 's1_s', text: 'Seoul, Spring 2024', isSubtitle: true, x: 0.5, y: 0.64, fontSize: 18.0, color: SlideTextColor.gold, barColor: SlideTextColor.gold),
          ],
          transition: TransitionEffect.fade,
          durationSeconds: 5,
        ),
        Slide(
          id: 's2',
          textLayers: [
            TextLayer(id: 's2_t', text: 'First Date', x: 0.5, y: 0.50, fontSize: 38.0, fontStyle: SlideFontStyle.script, color: SlideTextColor.rose),
            TextLayer(id: 's2_s', text: 'Hangang Park', isSubtitle: true, x: 0.5, y: 0.65, fontSize: 18.0, color: SlideTextColor.cream, barColor: SlideTextColor.rose),
          ],
          transition: TransitionEffect.slideLeft,
          durationSeconds: 4,
        ),
        Slide(
          id: 's3',
          textLayers: [
            TextLayer(id: 's3_t', text: 'Our Journey', x: 0.5, y: 0.46, fontSize: 38.0, fontStyle: SlideFontStyle.elegant, color: SlideTextColor.gold),
            TextLayer(id: 's3_s', text: '365 days together', isSubtitle: true, x: 0.5, y: 0.62, fontSize: 18.0, color: SlideTextColor.cream, barColor: SlideTextColor.gold),
          ],
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
          textLayers: [
            TextLayer(id: 's4_t', text: 'Under the Rain', x: 0.5, y: 0.50, fontSize: 52.0, fontStyle: SlideFontStyle.display, color: SlideTextColor.white),
            TextLayer(id: 's4_s', text: 'Just us two', isSubtitle: true, x: 0.5, y: 0.68, fontSize: 18.0, color: SlideTextColor.cream, barColor: SlideTextColor.white),
          ],
          transition: TransitionEffect.fade,
          durationSeconds: 4,
        ),
        Slide(
          id: 's5',
          textLayers: [
            TextLayer(id: 's5_t', text: 'Neon Lights', x: 0.5, y: 0.48, fontSize: 52.0, fontStyle: SlideFontStyle.modern, color: SlideTextColor.rose),
            TextLayer(id: 's5_s', text: 'Hongdae Street', isSubtitle: true, x: 0.5, y: 0.66, fontSize: 18.0, color: SlideTextColor.rose, barColor: SlideTextColor.rose),
          ],
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
