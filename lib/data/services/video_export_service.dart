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
  (int, int) _dimensions(String resolution) => switch (resolution) {
        '4k' => (3840, 2160),
        '1080p' => (1920, 1080),
        _ => (1280, 720),
      };

  Future<String> exportProject({
    required Project project,
    required String resolution,
    required void Function(double) onProgress,
  }) async {
    final (w, h) = _dimensions(resolution);
    final size = Size(w.toDouble(), h.toDouble());

    final tmpDir = await getTemporaryDirectory();
    final docDir = await getApplicationDocumentsDirectory();
    final exportsDir = Directory('${docDir.path}/exports');
    if (!exportsDir.existsSync()) {
      await exportsDir.create(recursive: true);
    }

    final ts = DateTime.now().millisecondsSinceEpoch;
    final safe = project.title
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    final outputPath = '${exportsDir.path}/${safe}_$ts.mp4';

    // Render each slide as a PNG at target resolution
    final dir = Directory('${tmpDir.path}/export_${project.id}_$ts');
    if (dir.existsSync()) await dir.delete(recursive: true);
    await dir.create(recursive: true);

    final slides = project.slides;
    final concatLines = <String>[];

    for (int i = 0; i < slides.length; i++) {
      final bytes = await _renderSlide(slides[i], i, size);
      final framePath = '${dir.path}/f$i.png';
      await File(framePath).writeAsBytes(bytes);
      concatLines.add("file '${framePath.replaceAll("'", r"'\''")}'");
      concatLines.add('duration ${slides[i].durationSeconds}');
      onProgress((i + 1) / slides.length * 0.65);
    }
    // Trailing entry required by the concat demuxer
    concatLines.add("file '${dir.path}/f${slides.length - 1}.png'"
        .replaceAll("'${dir.path}", "'${dir.path}"));

    final concatFile = File('${dir.path}/concat.txt');
    await concatFile.writeAsString(concatLines.join('\n'));

    onProgress(0.70);

    final totalSecs = slides.fold(0, (s, sl) => s + sl.durationSeconds);
    // Frames are already at the target resolution — only pixel format needed.
    const vf = 'format=yuv420p';

    // Try hardware H.264 first (low memory, fast); fall back to software.
    final hwOk = await _runEncoder(
      concatPath: concatFile.path,
      musicPath: project.musicPath,
      outputPath: outputPath,
      vf: vf,
      encoder: 'h264_mediacodec',
      encoderFlags: '-b:v 4000k',
      totalSecs: totalSecs,
      onProgress: (p) => onProgress(0.70 + p * 0.28),
    );

    if (!hwOk) {
      onProgress(0.70);
      final swOk = await _runEncoder(
        concatPath: concatFile.path,
        musicPath: project.musicPath,
        outputPath: outputPath,
        vf: vf,
        encoder: 'libx264',
        encoderFlags: '-preset ultrafast -crf 28 -threads 2',
        totalSecs: totalSecs,
        onProgress: (p) => onProgress(0.70 + p * 0.28),
      );
      if (!swOk) {
        throw Exception(
          'Video encoding failed with both h264_mediacodec and libx264.',
        );
      }
    }

    // Clean up temp frame dir
    try {
      await dir.delete(recursive: true);
    } catch (_) {}

    onProgress(1.0);
    return outputPath;
  }

  Future<bool> _runEncoder({
    required String concatPath,
    required String? musicPath,
    required String outputPath,
    required String vf,
    required String encoder,
    required String encoderFlags,
    required int totalSecs,
    required void Function(double) onProgress,
  }) async {
    const fps = 30;
    final totalFrames = totalSecs * fps;

    final cmd = StringBuffer();
    cmd.write('-y -f concat -safe 0 -i "$concatPath" ');
    if (musicPath != null) cmd.write('-i "$musicPath" ');
    cmd.write('-vf "$vf" -r $fps ');
    cmd.write('-c:v $encoder $encoderFlags ');
    if (musicPath != null) cmd.write('-c:a aac -b:a 192k -shortest ');
    cmd.write('"$outputPath"');

    final completer = Completer<bool>();

    await FFmpegKit.executeAsync(
      cmd.toString(),
      (session) async {
        final rc = await session.getReturnCode();
        completer.complete(ReturnCode.isSuccess(rc));
      },
      null,
      (stats) {
        if (totalFrames > 0) {
          final frame = stats.getVideoFrameNumber();
          onProgress((frame / totalFrames).clamp(0.0, 0.99));
        }
      },
    );

    return completer.future;
  }

  Future<Uint8List> _renderSlide(Slide slide, int index, Size size) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromLTWH(0, 0, size.width, size.height),
    );

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

    // Gradient overlay (matches preview appearance)
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
    final image =
        await picture.toImage(size.width.toInt(), size.height.toInt());
    final byteData =
        await image.toByteData(format: ui.ImageByteFormat.png);
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
    if (!file.existsSync()) return;

    final bytes = await file.readAsBytes();
    // Decode at canvas resolution — avoids loading full 12MP images into memory.
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
        Shadow(color: Colors.black.withValues(alpha: 0.85), blurRadius: 12),
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
        Rect.fromLTWH(offset.dx - 12.5, offset.dy - 4, 2.5, tp.height + 8),
        Paint()..color = layer.barColor.color,
      );
    }
    tp.paint(canvas, offset);
  }
}
