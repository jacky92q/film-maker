import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:film_maker/domain/models/project.dart';
import 'package:film_maker/domain/models/slide.dart';
import 'package:film_maker/ui/core/slide_styles.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class VideoExportService {
  String? _lastOutputPath;
  String? get lastOutputPath => _lastOutputPath;

  Stream<double> exportProject({
    required Project project,
    required String resolution,
  }) async* {
    _lastOutputPath = null;
    final (w, h) = _dimensions(resolution);
    final size = Size(w.toDouble(), h.toDouble());

    final tmpDir = await getTemporaryDirectory();
    final dir = Directory('${tmpDir.path}/export_${project.id}');
    if (await dir.exists()) await dir.delete(recursive: true);
    await dir.create(recursive: true);

    final slides = project.slides;
    final concatLines = <String>[];

    for (int i = 0; i < slides.length; i++) {
      final bytes = await _renderSlide(slides[i], i, size);
      final framePath = '${dir.path}/f$i.png';
      await File(framePath).writeAsBytes(bytes);
      concatLines.add("file '$framePath'");
      concatLines.add("duration ${slides[i].durationSeconds}");
      yield (i + 1) / slides.length * 0.70;
    }
    // Trailing entry required by concat demuxer to display last frame
    concatLines.add("file '${dir.path}/f${slides.length - 1}.png'");

    final concatFile = File('${dir.path}/concat.txt');
    await concatFile.writeAsString(concatLines.join('\n'));

    yield 0.75;

    final outputPath = '${dir.path}/wedding_film.mp4';
    final vf = 'scale=$w:$h:force_original_aspect_ratio=decrease,'
        'pad=$w:$h:-1:-1:color=black,format=yuv420p';

    final cmd = StringBuffer();
    cmd.write('-y -f concat -safe 0 -i "${concatFile.path}" ');
    if (project.musicPath != null) {
      cmd.write('-i "${project.musicPath}" -c:a aac -shortest ');
    }
    cmd.write('-vf "$vf" -c:v libx264 -preset fast -crf 23 "$outputPath"');

    final completer = Completer<bool>();
    FFmpegKit.executeAsync(cmd.toString(), (session) async {
      final rc = await session.getReturnCode();
      completer.complete(ReturnCode.isSuccess(rc));
    });

    // Yield incremental progress while FFmpeg works
    for (double p = 0.76; p < 0.99; p += 0.01) {
      if (completer.isCompleted) break;
      await Future<void>.delayed(const Duration(milliseconds: 400));
      yield p;
    }

    final success = await completer.future;
    if (!success) throw Exception('Video encoding failed');

    _lastOutputPath = outputPath;
    yield 1.0;
  }

  (int, int) _dimensions(String resolution) => switch (resolution) {
        '4k' => (3840, 2160),
        '1080p' => (1920, 1080),
        _ => (1280, 720),
      };

  Future<Uint8List> _renderSlide(Slide slide, int index, Size size) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
        recorder, Rect.fromLTWH(0, 0, size.width, size.height));

    // Background
    if (slide.imagePath != null) {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = Color(slide.backgroundColor),
      );
      await _drawImage(canvas, slide, size);
    } else {
      _drawGradientBg(canvas, size, index);
    }

    // Gradient overlay (matches preview_view)
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Color(0x80000000)],
          stops: [0.3, 1.0],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    for (final layer in slide.textLayers) {
      _drawTextLayer(canvas, layer, size);
    }

    final picture = recorder.endRecording();
    final image = await picture.toImage(size.width.toInt(), size.height.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    picture.dispose();
    if (byteData == null) throw Exception('Frame $index render failed');
    return byteData.buffer.asUint8List();
  }

  void _drawGradientBg(Canvas canvas, Size size, int index) {
    final gradients = [
      [const Color(0xFF1A1208), const Color(0xFF0D0D0D)],
      [const Color(0xFF0D1A18), const Color(0xFF0A1414)],
      [const Color(0xFF1A0D1A), const Color(0xFF0D0D0D)],
    ];
    final colors = gradients[index % gradients.length];
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );
  }

  Future<void> _drawImage(Canvas canvas, Slide slide, Size size) async {
    final file = File(slide.imagePath!);
    if (!await file.exists()) return;

    final bytes = await file.readAsBytes();
    // Decode at canvas resolution — prevents loading full 12MP camera images
    // into GPU memory (which would OOM on most phones).
    final codec = await ui.instantiateImageCodec(
      bytes,
      targetWidth: size.width.toInt(),
      targetHeight: size.height.toInt(),
    );
    final frame = await codec.getNextFrame();
    final img = frame.image;
    codec.dispose();

    final imgW = img.width.toDouble();
    final imgH = img.height.toDouble();
    final containScale = min(size.width / imgW, size.height / imgH);
    final finalScale = containScale * slide.photoScale;
    final cx = size.width / 2 + slide.photoOffsetX * size.width;
    final cy = size.height / 2 + slide.photoOffsetY * size.height;

    final paint = Paint();
    final colorFilter = slide.photoFilter.colorFilter;
    if (colorFilter != null) paint.colorFilter = colorFilter;

    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawImageRect(
      img,
      Rect.fromLTWH(0, 0, imgW, imgH),
      Rect.fromCenter(
        center: Offset(cx, cy),
        width: imgW * finalScale,
        height: imgH * finalScale,
      ),
      paint,
    );
    canvas.restore();
    img.dispose();
  }

  void _drawTextLayer(Canvas canvas, TextLayer layer, Size size) {
    final fontSize =
        layer.isSubtitle ? layer.size.subFontSize : layer.size.mainFontSize;
    final style = slideLayerTextStyle(
      layer.fontStyle,
      fontSize: fontSize,
      color: layer.color.color,
      shadows: [
        Shadow(color: Colors.black.withValues(alpha: 0.85), blurRadius: 12)
      ],
    );

    final tp = TextPainter(
      text: TextSpan(text: layer.text, style: style),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout(maxWidth: size.width * 0.85);

    final alignX = (layer.x * 2 - 1).clamp(-0.92, 0.92);
    final alignY = (layer.y * 2 - 1).clamp(-0.92, 0.92);
    final cx = size.width / 2 + alignX * size.width / 2;
    final cy = size.height / 2 + alignY * size.height / 2;
    final offset = Offset(cx - tp.width / 2, cy - tp.height / 2);

    if (layer.isSubtitle) {
      canvas.drawRect(
        Rect.fromLTWH(
          offset.dx - 12.5,
          offset.dy - 4,
          2.5,
          tp.height + 8,
        ),
        Paint()..color = layer.barColor.color,
      );
    }
    tp.paint(canvas, offset);
  }
}
