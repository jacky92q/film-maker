import 'package:film_maker/domain/models/slide.dart';
import 'package:film_maker/ui/core/photo_frame_widget.dart';
import 'package:flutter/material.dart';

// ─── EDITORIAL DESIGN ────────────────────────────────────────────────────────

/// Renders a magazine-editorial style slide: white background, thin border,
/// decorative text labels around edges, oval stamp badge, photo strip.
Widget buildEditorialDesign({
  required Slide slide,
  required AnimationController stripController,
}) {
  return LayoutBuilder(builder: (context, constraints) {
    final date = slide.weddingDate.isEmpty ? '2024.10.05' : slide.weddingDate;

    final photos = [slide.imagePath, slide.imagePath2, slide.imagePath3]
        .where((p) => p != null && p.isNotEmpty)
        .toList();

    return Container(
      color: Colors.white,
      child: Stack(
        children: [
          // Thin border frame
          Positioned.fill(
            child: Container(
              margin: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFAAAAAA), width: 0.6),
              ),
            ),
          ),

          // Top labels
          Positioned(
            top: 14, left: 20, right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('WEDDING',              style: _editorialLabel),
                Text('WE\'RE GETTING MARRIED', style: _editorialLabel),
                Text('ALWAYS HAPPINESS',    style: _editorialLabel),
              ],
            ),
          ),

          // Left "OUR" rotated
          Positioned(
            left: 14, top: 0, bottom: 0,
            child: Center(
              child: RotatedBox(
                quarterTurns: -1,
                child: Text('OUR', style: _editorialLabel),
              ),
            ),
          ),

          // Right date rotated
          Positioned(
            right: 14, top: 0, bottom: 0,
            child: Center(
              child: RotatedBox(
                quarterTurns: 1,
                child: Text(date, style: _editorialLabel),
              ),
            ),
          ),

          // Scrolling photo strip — occupies left 80% of inner area
          Positioned(
            top: 32, bottom: 32, left: 28, right: 72,
            child: ClipRect(
              child: _EditorialPhotoStrip(
                photos: photos,
                shape: slide.photoShape,
                frame: slide.photoFrame,
                colorFilter: slide.photoFilter.colorFilter,
                controller: stripController,
              ),
            ),
          ),

          // Oval PRECIOUS MOMENT badge
          Positioned(
            right: 20, bottom: 60,
            child: _OvalBadge(
              line1: 'PRECIOUS',
              line2: 'MOMENT',
            ),
          ),

          // Bottom labels
          Positioned(
            bottom: 14, left: 20, right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('A PRECIOUS MOMENT', style: _editorialLabel),
                Text('HAPPY WEDDING',     style: _editorialLabel),
                Text('EVERLASTING LOVE',  style: _editorialLabel),
              ],
            ),
          ),
        ],
      ),
    );
  });
}

const TextStyle _editorialLabel = TextStyle(
  fontSize: 7,
  letterSpacing: 1.5,
  color: Color(0xFF555555),
  fontFamily: 'Cinzel',
  fontWeight: FontWeight.w500,
);

class _EditorialPhotoStrip extends StatelessWidget {
  const _EditorialPhotoStrip({
    required this.photos,
    required this.shape,
    required this.frame,
    required this.colorFilter,
    required this.controller,
  });

  final List<String?> photos;
  final PhotoShape shape;
  final PhotoFrame frame;
  final ColorFilter? colorFilter;
  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    if (photos.isEmpty) {
      return Container(color: const Color(0xFFEEEEEE));
    }
    final n = photos.length;
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return LayoutBuilder(builder: (ctx, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;
          final offset = controller.value * (n - 1) * w;
          return Transform.translate(
            offset: Offset(-offset, 0),
            child: Row(
              children: photos.map((path) {
                return SizedBox(
                  width: w,
                  height: h,
                  child: buildShapedPhoto(
                    imagePath: path,
                    shape: shape,
                    frame: frame,
                    fit: BoxFit.cover,
                    colorFilter: colorFilter,
                  ),
                );
              }).toList(),
            ),
          );
        });
      },
    );
  }
}

class _OvalBadge extends StatelessWidget {
  const _OvalBadge({required this.line1, required this.line2});
  final String line1;
  final String line2;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 68,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFF444444), width: 1),
      ),
      child: Center(
        child: RotatedBox(
          quarterTurns: 1,
          child: Text(
            '$line1\n$line2',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 6.5,
              letterSpacing: 2,
              fontFamily: 'Cinzel',
              color: Color(0xFF333333),
              fontWeight: FontWeight.w600,
              height: 1.6,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── INVITATION DESIGN ───────────────────────────────────────────────────────

/// Renders an invitation-card split slide:
/// [invitation card | person photo] pair, optionally scrolling to show a second person.
Widget buildInvitationDesign({
  required Slide slide,
  required AnimationController stripController,
}) {
  return LayoutBuilder(builder: (context, constraints) {
    final w = constraints.maxWidth;
    final h = constraints.maxHeight;
    final halfW = w / 2;

    final photos = <_PersonPhoto>[
      _PersonPhoto(path: slide.imagePath,  name: slide.groomName.isEmpty ? 'GROOM' : slide.groomName.toUpperCase()),
      if (slide.imagePath2 != null && slide.imagePath2!.isNotEmpty)
        _PersonPhoto(path: slide.imagePath2, name: slide.brideName.isEmpty ? 'BRIDE' : slide.brideName.toUpperCase()),
    ];

    final n = photos.length; // 1 or 2
    // Strip: [invitation | photo1 | (photo2)] — scroll half-width at a time
    // total scrollable = (n) * halfW so we show invitation+photo1, then photo1+photo2
    // Simpler: make the strip [invitation | photo1 | photo2] always width = n+1 panels
    // and scroll from 0 to n*halfW
    final totalScrollW = n * halfW;

    return Container(
      color: Colors.white,
      child: AnimatedBuilder(
        animation: stripController,
        builder: (context, _) {
          final offset = stripController.value * totalScrollW;
          return ClipRect(
            child: Transform.translate(
              offset: Offset(-offset, 0),
              child: SizedBox(
                width: (n + 1) * halfW,
                height: h,
                child: Row(
                  children: [
                    // Panel 0: Invitation card (always first)
                    SizedBox(
                      width: halfW,
                      height: h,
                      child: _InvitationCard(slide: slide),
                    ),
                    // Person photo panels
                    ...photos.map((p) => SizedBox(
                      width: halfW,
                      height: h,
                      child: _PersonPhotoPanel(
                        imagePath: p.path,
                        name: p.name,
                        colorFilter: slide.photoFilter.colorFilter,
                        shape: slide.photoShape,
                        frame: slide.photoFrame,
                      ),
                    )),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  });
}

class _PersonPhoto {
  const _PersonPhoto({required this.path, required this.name});
  final String? path;
  final String name;
}

class _InvitationCard extends StatelessWidget {
  const _InvitationCard({required this.slide});
  final Slide slide;

  @override
  Widget build(BuildContext context) {
    final date = slide.weddingDate.isEmpty ? 'OCT 00, 2024' : slide.weddingDate;
    final groom = slide.groomName.isEmpty ? 'Groom' : slide.groomName;
    final bride = slide.brideName.isEmpty ? 'Bride' : slide.brideName;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date small
          Text(
            date,
            style: const TextStyle(
              fontSize: 9,
              letterSpacing: 2,
              color: Color(0xFF888888),
              fontFamily: 'Cinzel',
            ),
          ),
          const SizedBox(height: 12),
          // Main title
          const Text(
            "WE'RE\nGETTING\nMARRIED",
            style: TextStyle(
              fontSize: 22,
              fontFamily: 'Cinzel',
              fontWeight: FontWeight.w700,
              color: Color(0xFF222222),
              height: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          // Couple names in script
          Text(
            '$groom & $bride',
            style: const TextStyle(
              fontSize: 14,
              fontFamily: 'DancingScript',
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 16),
          // Ribbon bow decoration
          Center(child: _RibbonBow()),
          const Spacer(),
          // Thank you text
          const Text(
            'Thank you for being here\nwith us on our special day.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 9,
              color: Color(0xFF666666),
              height: 1.6,
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _RibbonBow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(80, 48),
      painter: _RibbonPainter(),
    );
  }
}

class _RibbonPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h / 2;

    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFFDDDDDD);

    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = const Color(0xFFBBBBBB)
      ..strokeWidth = 0.5;

    // Horizontal ribbon line
    canvas.drawRect(Rect.fromLTWH(0, cy - 2, w, 4), paint);
    canvas.drawRect(Rect.fromLTWH(0, cy - 2, w, 4), strokePaint);

    // Left bow loop
    final leftPath = Path()
      ..moveTo(cx - 2, cy)
      ..cubicTo(cx - 20, cy - 18, cx - 42, cy - 16, cx - 36, cy)
      ..cubicTo(cx - 42, cy + 16, cx - 20, cy + 18, cx - 2, cy)
      ..close();
    canvas.drawPath(leftPath, paint);
    canvas.drawPath(leftPath, strokePaint);

    // Right bow loop
    final rightPath = Path()
      ..moveTo(cx + 2, cy)
      ..cubicTo(cx + 20, cy - 18, cx + 42, cy - 16, cx + 36, cy)
      ..cubicTo(cx + 42, cy + 16, cx + 20, cy + 18, cx + 2, cy)
      ..close();
    canvas.drawPath(rightPath, paint);
    canvas.drawPath(rightPath, strokePaint);

    // Center knot
    final knotPaint = Paint()
      ..color = const Color(0xFFCCCCCC)
      ..style = PaintingStyle.fill;
    canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy), width: 12, height: 14), knotPaint);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy), width: 12, height: 14), strokePaint);

    // Ribbon tails
    final tailLeft = Path()
      ..moveTo(cx - 4, cy + 2)
      ..lineTo(cx - 18, h)
      ..lineTo(cx - 8, h)
      ..lineTo(cx, cy + 2)
      ..close();
    canvas.drawPath(tailLeft, paint);
    canvas.drawPath(tailLeft, strokePaint);

    final tailRight = Path()
      ..moveTo(cx + 4, cy + 2)
      ..lineTo(cx + 18, h)
      ..lineTo(cx + 8, h)
      ..lineTo(cx, cy + 2)
      ..close();
    canvas.drawPath(tailRight, paint);
    canvas.drawPath(tailRight, strokePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _PersonPhotoPanel extends StatelessWidget {
  const _PersonPhotoPanel({
    required this.imagePath,
    required this.name,
    required this.colorFilter,
    required this.shape,
    required this.frame,
  });

  final String? imagePath;
  final String name;
  final ColorFilter? colorFilter;
  final PhotoShape shape;
  final PhotoFrame frame;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        buildShapedPhoto(
          imagePath: imagePath,
          shape: shape,
          frame: frame,
          fit: BoxFit.cover,
          colorFilter: colorFilter,
        ),
        // Role label at bottom
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Color(0xCC000000)],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 10,
                    letterSpacing: 3,
                    color: Colors.white70,
                    fontFamily: 'Cinzel',
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
