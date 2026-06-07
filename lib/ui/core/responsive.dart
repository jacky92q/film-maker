import 'package:flutter/widgets.dart';

/// Shared responsive breakpoints and helpers so every screen adapts
/// consistently across phone (portrait/landscape), tablet, and web/desktop.
///
/// Width-based breakpoints (logical pixels), following Material 3 window
/// size classes:
///   • compact   < 600   → phones
///   • medium    600–1023 → small tablets / large phones landscape
///   • expanded  ≥ 1024   → tablets / web / desktop
class Breakpoints {
  const Breakpoints._();

  static const double medium = 600;
  static const double expanded = 1024;
}

extension ResponsiveContext on BuildContext {
  double get screenWidth => MediaQuery.sizeOf(this).width;

  /// Phone-sized viewport (the existing portrait layout target).
  bool get isCompact => screenWidth < Breakpoints.medium;

  /// Tablet-sized viewport.
  bool get isMedium =>
      screenWidth >= Breakpoints.medium && screenWidth < Breakpoints.expanded;

  /// Web / desktop / large tablet.
  bool get isExpanded => screenWidth >= Breakpoints.expanded;

  /// True for anything wider than a phone.
  bool get isWide => screenWidth >= Breakpoints.medium;
}

/// Constrains [child] to [maxWidth] and centers it horizontally. On phones the
/// content fills the width as before; on wider screens it stops growing so text
/// columns and forms stay comfortably readable instead of stretching edge-to-edge.
class ResponsiveCenter extends StatelessWidget {
  const ResponsiveCenter({
    super.key,
    required this.child,
    this.maxWidth = 600,
    this.padding,
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    Widget content = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: child,
    );
    if (padding != null) {
      content = Padding(padding: padding!, child: content);
    }
    return Align(alignment: Alignment.topCenter, child: content);
  }
}
