import 'package:film_maker/data/repositories/project_repository.dart';
import 'package:film_maker/domain/models/project.dart';
import 'package:film_maker/domain/models/slide.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

class EditorViewModel extends ChangeNotifier {
  EditorViewModel({
    required Project project,
    required this.projectRepository,
  })  : _project = project,
        _selectedSlideIndex = 0;

  final ProjectRepository projectRepository;
  final _uuid = const Uuid();
  final _imagePicker = ImagePicker();

  Project _project;
  int _selectedSlideIndex;
  bool _isSaving = false;
  bool _hasUnsavedChanges = false;

  Project get project => _project;
  int get selectedSlideIndex => _selectedSlideIndex;
  bool get isSaving => _isSaving;
  bool get hasUnsavedChanges => _hasUnsavedChanges;

  Slide? get selectedSlide =>
      _project.slides.isNotEmpty ? _project.slides[_selectedSlideIndex] : null;

  void selectSlide(int index) {
    if (index >= 0 && index < _project.slides.length) {
      _selectedSlideIndex = index;
      notifyListeners();
    }
  }

  void addSlide() {
    final newSlide = Slide(
      id: _uuid.v4(),
      title: '',
      subtitle: '',
      transition: TransitionEffect.fade,
    );
    final slides = [..._project.slides, newSlide];
    _project = _project.copyWith(slides: slides);
    _selectedSlideIndex = slides.length - 1;
    _hasUnsavedChanges = true;
    notifyListeners();
  }

  void deleteSelectedSlide() {
    if (_project.slides.length <= 1) return;
    final slides = [..._project.slides]..removeAt(_selectedSlideIndex);
    _project = _project.copyWith(slides: slides);
    if (_selectedSlideIndex >= slides.length) {
      _selectedSlideIndex = slides.length - 1;
    }
    _hasUnsavedChanges = true;
    notifyListeners();
  }

  void reorderSlides(int oldIndex, int newIndex) {
    final slides = [..._project.slides];
    if (newIndex > oldIndex) newIndex--;
    final slide = slides.removeAt(oldIndex);
    slides.insert(newIndex, slide);
    _project = _project.copyWith(slides: slides);
    _selectedSlideIndex = newIndex;
    _hasUnsavedChanges = true;
    notifyListeners();
  }

  void updateSelectedSlide(Slide updatedSlide) {
    final slides = [
      for (final s in _project.slides)
        if (s.id == updatedSlide.id) updatedSlide else s,
    ];
    _project = _project.copyWith(slides: slides);
    _hasUnsavedChanges = true;
    notifyListeners();
  }

  void updateProjectTitle(String title) {
    _project = _project.copyWith(title: title);
    _hasUnsavedChanges = true;
    notifyListeners();
  }

  Future<void> pickImageForCurrentSlide() async {
    final slide = selectedSlide;
    if (slide == null) return;
    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (picked != null) {
        updateSelectedSlide(slide.copyWith(imagePath: picked.path));
      }
    } catch (_) {
      // Image picker unavailable in this environment
    }
  }

  void setMusic(String? path, String? name) {
    _project = Project(
      id: _project.id,
      title: _project.title,
      slides: _project.slides,
      musicPath: path,
      musicName: name,
      createdAt: _project.createdAt,
      updatedAt: DateTime.now(),
    );
    _hasUnsavedChanges = true;
    notifyListeners();
  }

  Future<bool> saveProject() async {
    _isSaving = true;
    notifyListeners();
    try {
      _project = await projectRepository.updateProject(_project);
      _hasUnsavedChanges = false;
      return true;
    } catch (_) {
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }
}
