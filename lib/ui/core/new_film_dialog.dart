import 'package:film_maker/domain/models/project.dart';
import 'package:film_maker/l10n/app_strings.dart';
import 'package:film_maker/ui/core/app_theme.dart';
import 'package:flutter/material.dart';

/// Result of [showNewFilmDialog].
typedef NewFilmRequest = ({String title, VideoOrientation orientation});

/// Prompts for a film title and frame orientation. Returns `null` if cancelled
/// or if no title was entered.
Future<NewFilmRequest?> showNewFilmDialog(BuildContext context) {
  return showDialog<NewFilmRequest>(
    context: context,
    builder: (ctx) => const _NewFilmDialog(),
  );
}

class _NewFilmDialog extends StatefulWidget {
  const _NewFilmDialog();

  @override
  State<_NewFilmDialog> createState() => _NewFilmDialogState();
}

class _NewFilmDialogState extends State<_NewFilmDialog> {
  final _controller = TextEditingController();
  VideoOrientation _orientation = VideoOrientation.landscape;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final title = _controller.text.trim();
    if (title.isEmpty) return;
    Navigator.of(context).pop((title: title, orientation: _orientation));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(L10n.s.newWeddingFilm),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(L10n.s.filmTitlePrompt),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              autofocus: true,
              style: const TextStyle(color: AppTheme.textDark),
              decoration: InputDecoration(
                hintText: L10n.s.filmTitleHint,
                prefixIcon: const Icon(Icons.movie_creation_outlined),
              ),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 20),
            Text(
              L10n.s.videoFormat,
              style: const TextStyle(
                fontFamily: AppTheme.fontTheme,
                color: AppTheme.textMid,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _OrientationOption(
                    icon: Icons.crop_landscape,
                    label: L10n.s.formatLandscape,
                    desc: L10n.s.formatLandscapeDesc,
                    selected: _orientation == VideoOrientation.landscape,
                    onTap: () => setState(
                        () => _orientation = VideoOrientation.landscape),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _OrientationOption(
                    icon: Icons.crop_portrait,
                    label: L10n.s.formatPortrait,
                    desc: L10n.s.formatPortraitDesc,
                    selected: _orientation == VideoOrientation.portrait,
                    onTap: () => setState(
                        () => _orientation = VideoOrientation.portrait),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(L10n.s.cancel),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(L10n.s.create),
        ),
      ],
    );
  }
}

class _OrientationOption extends StatelessWidget {
  const _OrientationOption({
    required this.icon,
    required this.label,
    required this.desc,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String desc;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.primary.withValues(alpha: 0.08)
              : AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppTheme.primary : AppTheme.line,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 30,
              color: selected ? AppTheme.primary : AppTheme.textMid,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontFamily: AppTheme.fontTheme,
                color: AppTheme.textDark,
                fontSize: 14,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              desc,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: AppTheme.fontTheme,
                color: AppTheme.textMid,
                fontSize: 10.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
