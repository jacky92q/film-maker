import 'package:film_maker/domain/models/project.dart';
import 'package:film_maker/domain/models/slide.dart';
import 'package:flutter/foundation.dart';

class PreviewViewModel extends ChangeNotifier {
  PreviewViewModel({required this.project})
      : _currentIndex = 0,
        _isPlaying = false;

  final Project project;
  int _currentIndex;
  bool _isPlaying;

  int get currentIndex => _currentIndex;
  bool get isPlaying => _isPlaying;
  bool get hasSlides => project.slides.isNotEmpty;

  Slide? get currentSlide =>
      hasSlides ? project.slides[_currentIndex] : null;

  bool get isLastSlide => _currentIndex >= project.slides.length - 1;
  bool get isFirstSlide => _currentIndex == 0;

  double get progress =>
      hasSlides ? (_currentIndex + 1) / project.slides.length : 0;

  void play() {
    _isPlaying = true;
    notifyListeners();
  }

  void pause() {
    _isPlaying = false;
    notifyListeners();
  }

  void togglePlayPause() {
    _isPlaying = !_isPlaying;
    notifyListeners();
  }

  void nextSlide() {
    if (!isLastSlide) {
      _currentIndex++;
      notifyListeners();
    } else {
      _isPlaying = false;
      notifyListeners();
    }
  }

  void previousSlide() {
    if (!isFirstSlide) {
      _currentIndex--;
      notifyListeners();
    }
  }

  void goToSlide(int index) {
    if (index >= 0 && index < project.slides.length) {
      _currentIndex = index;
      notifyListeners();
    }
  }

  void restart() {
    _currentIndex = 0;
    _isPlaying = true;
    notifyListeners();
  }
}
