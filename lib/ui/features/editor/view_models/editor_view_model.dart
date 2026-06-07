import 'dart:io';
import 'dart:ui' as ui;

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
  String? _selectedPhotoLayerId;
  bool _isSaving = false;
  bool _hasUnsavedChanges = false;
  bool _cropMode = false;

  Project get project => _project;
  int get selectedSlideIndex => _selectedSlideIndex;
  String? get selectedLayerId => _selectedLayerId;
  String? get selectedPhotoLayerId => _selectedPhotoLayerId;
  bool get isSaving => _isSaving;
  bool get hasUnsavedChanges => _hasUnsavedChanges;
  bool get cropMode => _cropMode;

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

  PhotoLayer? get selectedPhotoLayer {
    final slide = selectedSlide;
    if (slide == null || _selectedPhotoLayerId == null) return null;
    try {
      return slide.photoLayers.firstWhere((l) => l.id == _selectedPhotoLayerId);
    } catch (_) {
      return null;
    }
  }

  void selectSlide(int index) {
    if (index >= 0 && index < _project.slides.length) {
      _selectedSlideIndex = index;
      _selectedLayerId = null;
      _selectedPhotoLayerId = null;
      _cropMode = false;
      notifyListeners();
    }
  }

  void selectLayer(String? id) {
    _selectedLayerId = id;
    if (id != null) {
      _selectedPhotoLayerId = null;
      _cropMode = false;
    }
    notifyListeners();
  }

  void selectPhotoLayer(String? id) {
    _selectedPhotoLayerId = id;
    if (id != null) _selectedLayerId = null;
    if (id == null) _cropMode = false;
    notifyListeners();
  }

  int _nextZOrder() {
    final slide = selectedSlide;
    if (slide == null) return 1;
    int max = 0;
    for (final l in slide.textLayers) { if (l.zOrder > max) max = l.zOrder; }
    for (final l in slide.photoLayers) { if (l.zOrder > max) max = l.zOrder; }
    return max + 1;
  }

  void bringToFront(String layerId, {required bool isPhoto}) {
    final slide = selectedSlide;
    if (slide == null) return;
    final newOrder = _nextZOrder();
    if (isPhoto) {
      _updateSlide(slide.copyWith(photoLayers: [
        for (final l in slide.photoLayers) if (l.id == layerId) l.copyWith(zOrder: newOrder) else l,
      ]));
    } else {
      _updateSlide(slide.copyWith(textLayers: [
        for (final l in slide.textLayers) if (l.id == layerId) l.copyWith(zOrder: newOrder) else l,
      ]));
    }
  }

  void sendToBack(String layerId, {required bool isPhoto}) {
    final slide = selectedSlide;
    if (slide == null) return;
    int minOrder = 0;
    for (final l in slide.textLayers) { if (l.zOrder < minOrder) minOrder = l.zOrder; }
    for (final l in slide.photoLayers) { if (l.zOrder < minOrder) minOrder = l.zOrder; }
    final newOrder = minOrder - 1;
    if (isPhoto) {
      _updateSlide(slide.copyWith(photoLayers: [
        for (final l in slide.photoLayers) if (l.id == layerId) l.copyWith(zOrder: newOrder) else l,
      ]));
    } else {
      _updateSlide(slide.copyWith(textLayers: [
        for (final l in slide.textLayers) if (l.id == layerId) l.copyWith(zOrder: newOrder) else l,
      ]));
    }
  }

  void toggleCropMode() {
    _cropMode = !_cropMode;
    notifyListeners();
  }

  void addTextLayer({bool isSubtitle = false}) {
    final slide = selectedSlide;
    if (slide == null) return;
    final layer = TextLayer(
      id: _uuid.v4(),
      text: isSubtitle ? 'Subtitle text' : 'Main title',
      isSubtitle: isSubtitle,
      fontSize: isSubtitle ? 56.0 : 96.0,
      x: 0.5,
      y: isSubtitle ? 0.70 : 0.50,
      zOrder: _nextZOrder(),
    );
    // Set selection state BEFORE _updateSlide() so notifyListeners sees them
    _selectedLayerId = layer.id;
    _selectedPhotoLayerId = null;
    _cropMode = false;
    _updateSlide(slide.copyWith(textLayers: [...slide.textLayers, layer]));
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

  void movePhotoLayer(String layerId, double x, double y) {
    final slide = selectedSlide;
    if (slide == null) return;
    final layers = [
      for (final l in slide.photoLayers)
        if (l.id == layerId) l.copyWith(x: x, y: y) else l,
    ];
    _updateSlide(slide.copyWith(photoLayers: layers));
  }

  void updatePhotoLayer(PhotoLayer layer) {
    final slide = selectedSlide;
    if (slide == null) return;
    final layers = [
      for (final l in slide.photoLayers)
        if (l.id == layer.id) layer else l,
    ];
    _updateSlide(slide.copyWith(photoLayers: layers));
  }

  void deletePhotoLayer(String layerId) {
    final slide = selectedSlide;
    if (slide == null) return;
    final layers = slide.photoLayers.where((l) => l.id != layerId).toList();
    _updateSlide(slide.copyWith(photoLayers: layers));
    if (_selectedPhotoLayerId == layerId) _selectedPhotoLayerId = null;
  }

  Future<void> addPhotoLayer() async {
    final slide = selectedSlide;
    if (slide == null) return;
    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        requestFullMetadata: false,
      );
      if (picked != null) {
        // Compute initial size so the full photo is visible (contain within canvas)
        final double canvasW = _project.orientation.canvasWidth;
        final double canvasH = _project.orientation.canvasHeight;
        double wf = 0.45, hf = 0.55; // fallback
        try {
          final bytes = await File(picked.path).readAsBytes();
          final codec = await ui.instantiateImageCodec(bytes);
          final frame = await codec.getNextFrame();
          final imgW = frame.image.width.toDouble();
          final imgH = frame.image.height.toDouble();
          frame.image.dispose();
          final photoAR = imgW / imgH;
          final canvasAR = canvasW / canvasH;
          if (photoAR >= canvasAR) {
            wf = 1.0;
            hf = ((canvasW / imgW) * imgH) / canvasH;
          } else {
            hf = 1.0;
            wf = ((canvasH / imgH) * imgW) / canvasW;
          }
        } catch (_) {}

        final layer = PhotoLayer(
          id: _uuid.v4(),
          imagePath: picked.path,
          zOrder: _nextZOrder(),
          widthFraction: wf,
          heightFraction: hf,
        );
        _updateSlide(slide.copyWith(
          photoLayers: [...slide.photoLayers, layer],
        ));
        _selectedPhotoLayerId = layer.id;
        _selectedLayerId = null;
      }
    } catch (_) {}
  }

  Future<void> pickImageForPhotoLayer(String layerId) async {
    final slide = selectedSlide;
    if (slide == null) return;
    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        requestFullMetadata: false,
      );
      if (picked != null) {
        final layers = [
          for (final l in slide.photoLayers)
            if (l.id == layerId) l.copyWith(imagePath: picked.path) else l,
        ];
        _updateSlide(slide.copyWith(photoLayers: layers));
      }
    } catch (_) {}
  }

  void addSlide({SlideTemplate template = SlideTemplate.blank}) {
    final newSlide = SlideDefaults.fromTemplate(_uuid.v4(), template);
    final slides = [..._project.slides, newSlide];
    _project = _project.copyWith(slides: slides);
    _selectedSlideIndex = slides.length - 1;
    _selectedLayerId = null;
    _selectedPhotoLayerId = null;
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
    _selectedPhotoLayerId = null;
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

  Future<void> pickImageForSlot(int slot) async {
    final slide = selectedSlide;
    if (slide == null) return;
    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        requestFullMetadata: false,
      );
      if (picked != null) {
        switch (slot) {
          case 2:
            _updateSlide(slide.copyWith(imagePath2: picked.path));
            break;
          case 3:
            _updateSlide(slide.copyWith(imagePath3: picked.path));
            break;
          default:
            _updateSlide(slide.copyWith(imagePath: picked.path));
        }
      }
    } catch (_) {
      // Image picker unavailable
    }
  }

  Future<void> pickImageForCurrentSlide() async {
    final slide = selectedSlide;
    if (slide == null) return;
    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        requestFullMetadata: false, // uses system Photo Picker on Android 13+ (no permission needed)
      );
      if (picked != null) {
        _updateSlide(slide.copyWith(imagePath: picked.path));
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
      _project = await projectRepository.upsertProject(_project);
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
