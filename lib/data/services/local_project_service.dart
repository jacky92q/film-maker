import 'dart:convert';

import 'package:film_maker/data/services/project_service.dart';
import 'package:film_maker/domain/models/project.dart';
import 'package:film_maker/domain/models/slide.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class LocalProjectService implements ProjectService {
  static const _key = 'fm_projects';
  final _uuid = const Uuid();

  @override
  Future<List<Project>> fetchProjects() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      final projects = list
          .map((e) => Project.fromJson(e as Map<String, dynamic>))
          .toList();
      projects.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return projects;
    } catch (_) {
      return [];
    }
  }

  @override
  Future<Project> createProject({required String title}) async {
    final prefs = await SharedPreferences.getInstance();
    final projects = await fetchProjects();
    final project = Project(
      id: _uuid.v4(),
      title: title,
      slides: [Slide(id: _uuid.v4())],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    projects.insert(0, project);
    await _save(prefs, projects);
    return project;
  }

  @override
  Future<Project> updateProject(Project project) async {
    final prefs = await SharedPreferences.getInstance();
    final projects = await fetchProjects();
    final index = projects.indexWhere((p) => p.id == project.id);
    if (index == -1) throw Exception('Project not found');
    final updated = project.copyWith(updatedAt: DateTime.now());
    projects[index] = updated;
    await _save(prefs, projects);
    return updated;
  }

  @override
  Future<Project> upsertProject(Project project) async {
    final prefs = await SharedPreferences.getInstance();
    final projects = await fetchProjects();
    final index = projects.indexWhere((p) => p.id == project.id);
    final updated = project.copyWith(updatedAt: DateTime.now());
    if (index == -1) {
      projects.insert(0, updated);
    } else {
      projects[index] = updated;
    }
    await _save(prefs, projects);
    return updated;
  }

  @override
  Future<void> deleteProject(String projectId) async {
    final prefs = await SharedPreferences.getInstance();
    final projects = await fetchProjects();
    projects.removeWhere((p) => p.id == projectId);
    await _save(prefs, projects);
  }

  Future<void> _save(SharedPreferences prefs, List<Project> projects) =>
      prefs.setString(_key, jsonEncode(projects.map((p) => p.toJson()).toList()));
}
