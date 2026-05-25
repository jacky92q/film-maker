import 'package:film_maker/data/repositories/project_repository.dart';
import 'package:film_maker/domain/models/user.dart';
import 'package:flutter/foundation.dart';

class HomeViewModel extends ChangeNotifier {
  HomeViewModel({required this.user, required ProjectRepository projectRepository})
      : _projectRepository = projectRepository;

  final User user;
  final ProjectRepository _projectRepository;

  int _projectCount = 0;
  int _totalSlides = 0;
  bool _isLoadingStats = false;

  int get projectCount => _projectCount;
  int get totalSlides => _totalSlides;
  bool get isLoadingStats => _isLoadingStats;

  Future<void> loadStats() async {
    _isLoadingStats = true;
    notifyListeners();
    try {
      final projects = await _projectRepository.getProjects();
      _projectCount = projects.length;
      _totalSlides = projects.fold(0, (sum, p) => sum + p.slideCount);
    } catch (_) {
      // Stats are non-critical; silently ignore
    } finally {
      _isLoadingStats = false;
      notifyListeners();
    }
  }
}
