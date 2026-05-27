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
  String? _selectedLayerId;
  bool _isSaving = false;
  bool _hasUnsavedChanges = false;
  String? _pickError;

  Project get project => _project;
  int get selectedSlideIndex => _selectedSlideIndex;
  String? get selectedLayerId => _selectedLayerId;
  bool get isSaving => _isSaving;
  bool get hasUnsavedChanges => _hasUnsavedChanges;
  String? get pickError => _pickError;

  void clearPickError() {
    _pickError = null;
    notifyListeners();
  }

  Slide? get selectedSlide =>
      _project.slides.isNotEmpty ? _project.slides[_selectedSlideIndex] : null;

  TextLayer? get selectedLayer {
    final slide = selectedSlide;
    if (slide == null || _selectedLayerId == null) return null;
    try {
      return slide.textLayers.firstWhere((l) => l.id == _selectedLayerId);
    } catch (_) {
      return null;
    }
  }

  void selectSlide(int index) {
    if (index >= 0 && index < _project.slides.length) {
      _selectedSlideIndex = index;
      _selectedLayerId = null;
      notifyListeners();
    }
  }

  void selectLayer(String? id) {
    _selectedLayerId = id;
    notifyListeners();
  }

  void addTextLayer({bool isSubtitle = false}) {
    final slide = selectedSlide;
    if (slide == null) return;
    final layer = TextLayer(
      id: _uuid.v4(),
      text: isSubtitle ? 'Subtitle text' : 'Main title',
      isSubtitle: isSubtitle,
      x: 0.5,
      y: isSubtitle ? 0.70 : 0.50,
    );
    _updateSlide(slide.copyWith(textLayers: [...slide.textLayers, layer]));
    _selectedLayerId = layer.id;
  }

  void updateTextLayer(TextLayer layer) {
    final slide = selectedSlide;
    if (slide == null) return;
    final layers = [
      for (final l in slide.textLayers)
        if (l.id == layer.id) layer else l,
    ];
    _updateSlide(slide.copyWith(textLayers: layers));
  }

  void deleteTextLayer(String layerId) {
    final slide = selectedSlide;
    if (slide == null) return;
    final layers = slide.textLayers.where((l) => l.id != layerId).toList();
    _updateSlide(slide.copyWith(textLayers: layers));
    if (_selectedLayerId == layerId) _selectedLayerId = null;
  }

  void updatePhotoTransform({required double scale, required double offsetX, required double offsetY}) {
    final slide = selectedSlide;
    if (slide == null || slide.imagePath == null) return;
    _updateSlide(slide.copyWith(photoScale: scale, photoOffsetX: offsetX, photoOffsetY: offsetY));
  }

  void moveTextLayer(String layerId, double x, double y) {
    final slide = selectedSlide;
    if (slide == null) return;
    final layers = [
      for (final l in slide.textLayers)
        if (l.id == layerId) l.copyWith(x: x, y: y) else l,
    ];
    _updateSlide(slide.copyWith(textLayers: layers));
  }

  void addSlide({SlideTemplate template = SlideTemplate.blank}) {
    final newSlide = SlideDefaults.fromTemplate(_uuid.v4(), template);
    final slides = [..._project.slides, newSlide];
    _project = _project.copyWith(slides: slides);
    _selectedSlideIndex = slides.length - 1;
    _selectedLayerId = null;
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
    _selectedLayerId = null;
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
    _updateSlide(updatedSlide);
  }

  void _updateSlide(Slide slide) {
    final slides = [
      for (final s in _project.slides)
        if (s.id == slide.id) slide else s,
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
    _pickError = null;
    try {
      final picked = await _imagePicker.pickImage(source: ImageSource.gallery);
      if (picked != null) {
        _updateSlide(slide.copyWith(imagePath: picked.path));
      }
    } catch (e) {
      _pickError = e.toString();
      notifyListeners();
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
