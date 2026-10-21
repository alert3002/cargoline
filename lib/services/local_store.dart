import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Thin wrapper around SharedPreferences keys for CargoLine.Tj.
class LocalStore {
  LocalStore(this._prefs);

  final SharedPreferences _prefs;

  static Future<LocalStore> open() async {
    final prefs = await SharedPreferences.getInstance();
    return LocalStore(prefs);
  }

  // Auth
  static const _kAuth = 'auth_json';
  static const _kLocale = 'locale';
  static const _kPickup = 'pickup_point';
  static const _kTheme = 'theme_mode'; // light | dark
  static const _kIsDark = 'is_dark_mode';
  static const _kLoggedIn = 'is_logged_in';

  // Parcels
  static const _kParcels = 'parcels_json';
  static const _kNotifications = 'notifications_json';
  static const _kAdminTracks = 'admin_tracks_json';
  static const _kSeeded = 'sample_seeded';

  String? get localeCode => _prefs.getString(_kLocale);
  Future<void> setLocaleCode(String code) => _prefs.setString(_kLocale, code);

  String? get pickupPoint => _prefs.getString(_kPickup);
  Future<void> setPickupPoint(String value) => _prefs.setString(_kPickup, value);

  /// `light` or `dark` (default dark to match brand reference).
  String get themeMode {
    if (_prefs.containsKey(_kTheme)) {
      return _prefs.getString(_kTheme) ?? 'dark';
    }
    // Compat with CargoApp `is_dark_mode` bool.
    if (_prefs.containsKey(_kIsDark)) {
      return (_prefs.getBool(_kIsDark) ?? true) ? 'dark' : 'light';
    }
    return 'dark';
  }

  Future<void> setThemeMode(String value) async {
    await _prefs.setString(_kTheme, value);
    await _prefs.setBool(_kIsDark, value != 'light');
  }

  bool get isLoggedInFlag => _prefs.getBool(_kLoggedIn) ?? false;
  Future<void> setLoggedInFlag(bool value) =>
      _prefs.setBool(_kLoggedIn, value);

  String? get authJson => _prefs.getString(_kAuth);
  Future<void> setAuthJson(String? json) async {
    if (json == null) {
      await _prefs.remove(_kAuth);
    } else {
      await _prefs.setString(_kAuth, json);
    }
  }

  String? get parcelsJson => _prefs.getString(_kParcels);
  Future<void> setParcelsJson(String json) => _prefs.setString(_kParcels, json);

  String? get notificationsJson => _prefs.getString(_kNotifications);
  Future<void> setNotificationsJson(String json) =>
      _prefs.setString(_kNotifications, json);

  List<String> get adminTracks {
    final raw = _prefs.getString(_kAdminTracks);
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list.cast<String>();
  }

  Future<void> setAdminTracks(List<String> tracks) =>
      _prefs.setString(_kAdminTracks, jsonEncode(tracks));

  bool get sampleSeeded => _prefs.getBool(_kSeeded) ?? false;
  Future<void> setSampleSeeded(bool v) => _prefs.setBool(_kSeeded, v);
}
