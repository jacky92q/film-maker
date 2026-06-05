import 'package:film_maker/l10n/app_strings.dart';
import 'package:film_maker/l10n/locale_controller.dart';
import 'package:film_maker/ui/core/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<LocaleController>();

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: Text(L10n.s.settingsTitle),
        backgroundColor: AppTheme.bg,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppTheme.textDark,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        children: [
          _SectionLabel(L10n.s.language),
          const SizedBox(height: 4),
          Text(
            L10n.s.languageSubtitle,
            style: const TextStyle(
              fontFamily: AppTheme.fontTheme,
              color: AppTheme.textMid,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.line),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (int i = 0; i < AppLanguage.values.length; i++) ...[
                  if (i > 0) const Divider(height: 1, color: AppTheme.line),
                  _LanguageTile(
                    language: AppLanguage.values[i],
                    selected: controller.language == AppLanguage.values[i],
                    onTap: () =>
                        controller.setLanguage(AppLanguage.values[i]),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: AppTheme.fontTheme,
        color: AppTheme.textDark,
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({
    required this.language,
    required this.selected,
    required this.onTap,
  });

  final AppLanguage language;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Expanded(
              child: Text(
                language.nativeName,
                style: TextStyle(
                  fontFamily: AppTheme.fontTheme,
                  color: AppTheme.textDark,
                  fontSize: 15,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle, color: AppTheme.primary, size: 22)
            else
              Icon(Icons.circle_outlined,
                  color: AppTheme.textMid.withValues(alpha: 0.4), size: 22),
          ],
        ),
      ),
    );
  }
}
