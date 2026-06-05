import 'package:film_maker/l10n/app_strings.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Holds the app's active language and persists the user's choice.
///
/// Updates [L10n.current] so non-widget code (enum labels, view-models) can
/// read the active translations without a [BuildContext].
class LocaleController extends ChangeNotifier {
  LocaleController();

  static const _prefsKey = 'app_language';

  AppLanguage _language = AppLanguage.en;
  AppLanguage get language => _language;

  /// Loads the saved language from disk. Safe to call once at startup.
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefsKey);
      if (saved != null) {
        _language = AppLanguage.fromCode(saved);
      } else {
        // First launch: use device locale.
        final deviceLang = PlatformDispatcher.instance.locale.languageCode;
        _language = deviceLang == 'ko' ? AppLanguage.ko : AppLanguage.en;
      }
    } catch (_) {
      _language = AppLanguage.en;
    }
    L10n.current = _language;
    notifyListeners();
  }

  Future<void> setLanguage(AppLanguage language) async {
    if (_language == language) return;
    _language = language;
    L10n.current = language;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, language.code);
    } catch (_) {
      // Persisting is best-effort; the in-memory choice still applies.
    }
  }
}
