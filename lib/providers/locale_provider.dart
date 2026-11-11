import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages language state with instant UI updates and persistent storage.
class LocaleProvider extends ChangeNotifier {
  static const String _prefKey = 'selected_language';
  Locale _locale = const Locale('id', 'ID');

  Locale get locale => _locale;
  bool get isIndonesian => _locale.languageCode == 'id';

  LocaleProvider() {
    _loadSavedLocale();
  }

  Future<void> _loadSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final langCode = prefs.getString(_prefKey);
    if (langCode != null) {
      _locale = langCode == 'en'
          ? const Locale('en', 'US')
          : const Locale('id', 'ID');
      notifyListeners();
    }
  }

  /// Toggle instantly between Indonesian and English without restarting
  Future<void> toggleLocale() async {
    if (_locale.languageCode == 'id') {
      _locale = const Locale('en', 'US');
    } else {
      _locale = const Locale('id', 'ID');
    }
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, _locale.languageCode);
  }

  Future<void> setLocale(Locale newLocale) async {
    if (_locale == newLocale) return;
    _locale = newLocale;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, _locale.languageCode);
  }
}
