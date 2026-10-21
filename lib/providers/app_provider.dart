import 'dart:async';
import 'dart:convert';

import 'package:cargo_line_tj/l10n/app_strings.dart';
import 'package:cargo_line_tj/models/user_profile.dart';
import 'package:cargo_line_tj/services/auth_service.dart';
import 'package:cargo_line_tj/services/local_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum AuthMethod { sms, telegram, email, google }

typedef AuthSessionListener = void Function();

class AppProvider extends ChangeNotifier {
  AppProvider(this._store, {AuthService? authService})
      : _auth = authService ?? AuthService();

  final LocalStore _store;
  final AuthService _auth;
  final List<AuthSessionListener> _sessionListeners = [];

  AppLocale _locale = AppLocale.ru;
  bool _isAuthenticated = false;
  UserProfile? _user;
  AuthMethod? _authMethod;
  PickupPoint _pickupPoint = PickupPoint.didor;
  String? _accessToken;
  bool _loaded = false;
  ThemeMode _themeMode = ThemeMode.system;

  AppLocale get locale => _locale;
  bool get isAuthenticated => _isAuthenticated;
  UserProfile? get user => _user;
  AuthMethod? get authMethod => _authMethod;
  PickupPoint get pickupPoint => _pickupPoint;
  String? get accessToken => _accessToken;
  bool get isReady => _loaded;
  ThemeMode get themeMode => _themeMode;
  bool get needsProfileSetup =>
      _isAuthenticated && (_user == null || !_user!.profileComplete);
  bool get isDark {
    if (_themeMode == ThemeMode.system) {
      return WidgetsBinding.instance.platformDispatcher.platformBrightness ==
          Brightness.dark;
    }
    return _themeMode == ThemeMode.dark;
  }

  AppStrings get strings => AppStrings(_locale);

  void addSessionListener(AuthSessionListener listener) {
    _sessionListeners.add(listener);
  }

  void removeSessionListener(AuthSessionListener listener) {
    _sessionListeners.remove(listener);
  }

  void _notifySession() {
    for (final l in List<AuthSessionListener>.from(_sessionListeners)) {
      l();
    }
  }

  Future<void> load() async {
    final localeCode = _store.localeCode;
    if (localeCode == 'tj') {
      _locale = AppLocale.tj;
    }

    switch (_store.themeMode) {
      case 'light':
        _themeMode = ThemeMode.light;
      case 'system':
        _themeMode = ThemeMode.system;
      default:
        _themeMode = ThemeMode.dark;
    }

    final pickup = _store.pickupPoint;
    if (pickup != null) {
      _pickupPoint = PickupPoint.values.firstWhere(
        (e) => e.name == pickup,
        orElse: () => PickupPoint.didor,
      );
    } else {
      _pickupPoint = PickupPoint.didor;
    }

    final authRaw = _store.authJson;
    if (authRaw != null && authRaw.isNotEmpty) {
      try {
        final map = jsonDecode(authRaw) as Map<String, dynamic>;
        _user = UserProfile.fromJson(map['user'] as Map<String, dynamic>);
        _authMethod = AuthMethod.values.firstWhere(
          (e) => e.name == map['method'],
          orElse: () => AuthMethod.sms,
        );
        _accessToken = map['access_token'] as String?;
        _isAuthenticated = true;
        if (_accessToken == null && _user != null) {
          // Non-blocking — avoid 6s hang on cold start.
          // ignore: unawaited_futures
          _refreshTokenFromBackend();
        }
      } catch (_) {
        await _store.setAuthJson(null);
      }
    }

    _loaded = true;
    notifyListeners();
    _notifySession();
  }

  Future<void> _refreshTokenFromBackend() async {
    if (_user == null) return;
    try {
      final result = await _auth.ensureSession(
        phone: _user!.phone,
        clientCode: _user!.clientCode,
      );
      _accessToken = result['access_token'] as String?;
      _applyUserPayload(result);
      await _persistAuth();
    } catch (_) {}
  }

  void _applyUserPayload(Map<String, dynamic> result) {
    final userMap = result['user'];
    if (userMap is Map<String, dynamic>) {
      _user = UserProfile.fromJson(userMap);
      return;
    }
    final code = result['client_code'] as String?;
    final complete = result['profile_complete'] as bool?;
    if (_user != null) {
      _user = _user!.copyWith(
        clientCode: code ?? _user!.clientCode,
        profileComplete: complete ?? _user!.profileComplete,
      );
    }
  }

  Future<void> setLocale(AppLocale locale) async {
    if (_locale == locale) return;
    _locale = locale;
    await _store.setLocaleCode(locale == AppLocale.ru ? 'ru' : 'tj');
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    final raw = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.system => 'system',
      ThemeMode.dark => 'dark',
    };
    await _store.setThemeMode(raw);
    notifyListeners();
  }

  Future<void> toggleTheme() =>
      setThemeMode(isDark ? ThemeMode.light : ThemeMode.dark);

  Future<void> setPickupPoint(PickupPoint point) async {
    _pickupPoint = point;
    await _store.setPickupPoint(point.name);
    notifyListeners();
    _notifySession();
  }

  Future<void> sendSmsCode(String phone) async {
    await _auth.sendCode(phone);
  }

  Future<bool> verifySms(String code, String phone) async {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 9) return false;
    final phoneNorm = digits.startsWith('992') ? digits : '992$digits';
    if (phoneNorm.length != 12) return false;

    try {
      final result = await _auth.verifyCode(phone, code);
      final token = result['access_token'] as String?;
      UserProfile profile;
      final userMap = result['user'];
      if (userMap is Map<String, dynamic>) {
        profile = UserProfile.fromJson(userMap);
      } else {
        final clientCode = result['client_code'] as String? ??
            'TJ${DateTime.now().year}${digits.substring(digits.length - 4)}';
        profile = UserProfile(
          clientCode: clientCode,
          phone: phoneNorm,
          profileComplete: result['profile_complete'] as bool? ?? false,
        );
      }
      await _login(profile, AuthMethod.sms, accessToken: token);
      return true;
    } on AuthException {
      return false;
    }
  }

  Future<void> sendEmailCode(String email) => _auth.sendEmailCode(email);

  Future<bool> verifyEmail(String email, String code) async {
    try {
      final result = await _auth.verifyEmailCode(email, code);
      final token = result['access_token'] as String?;
      final userMap = result['user'];
      if (userMap is! Map<String, dynamic>) return false;
      await _login(
        UserProfile.fromJson(userMap),
        AuthMethod.email,
        accessToken: token,
      );
      return true;
    } on AuthException {
      return false;
    }
  }

  Future<void> loginWithGoogleAccount({
    required String idToken,
    String? email,
    String? name,
  }) async {
    final result = await _auth.loginWithGoogleToken(
      idToken: idToken,
      email: email,
      name: name,
    );
    final token = result['access_token'] as String?;
    final userMap = result['user'];
    if (userMap is! Map<String, dynamic>) {
      throw AuthException('Пустой ответ Google');
    }
    await _login(
      UserProfile.fromJson(userMap),
      AuthMethod.google,
      accessToken: token,
    );
  }

  /// Opens Telegram externally; local session after phone+code via SMS/Telegram flow.
  Future<void> loginWithTelegramPhone({
    required String phone,
    required String code,
  }) async {
    final ok = await verifySms(code, phone);
    if (!ok) {
      throw AuthException('Неверный код');
    }
    _authMethod = AuthMethod.telegram;
    await _persistAuth();
    notifyListeners();
  }

  Future<void> completeProfile({
    String? firstName,
    String? lastName,
    String? birthDate,
    String? workPhone,
    String? address,
    String? avatarPath,
  }) async {
    if (_user == null) return;

    // Save locally first so «Продолжить» leaves the screen immediately.
    _user = _user!.copyWith(
      firstName: firstName,
      lastName: lastName,
      birthDate: birthDate,
      workPhone: workPhone,
      address: address,
      avatarPath: avatarPath,
      profileComplete: true,
    );
    await _persistAuth();
    notifyListeners();
    _notifySession();

    if (_accessToken == null) return;
    try {
      final result = await _auth.updateProfile(
        token: _accessToken!,
        firstName: firstName,
        lastName: lastName,
        birthDate: birthDate,
        workPhone: workPhone,
        address: address,
        avatarUrl: avatarPath,
      );
      _user = UserProfile.fromJson(result).copyWith(
        firstName: firstName ?? _user!.firstName,
        lastName: lastName ?? _user!.lastName,
        profileComplete: true,
      );
      await _persistAuth();
      notifyListeners();
    } catch (_) {
      // Offline / API error — local completed profile already applied.
    }
  }

  Future<void> _login(
    UserProfile user,
    AuthMethod method, {
    String? accessToken,
  }) async {
    _user = user;
    _authMethod = method;
    _accessToken = accessToken;
    _isAuthenticated = true;
    await _persistAuth();
    notifyListeners();
    _notifySession();
  }

  Future<void> _persistAuth() async {
    if (_user == null || _authMethod == null) {
      await _store.setAuthJson(null);
      await _store.setLoggedInFlag(false);
      return;
    }
    await _store.setAuthJson(
      jsonEncode({
        'user': _user!.toJson(),
        'method': _authMethod!.name,
        if (_accessToken != null) 'access_token': _accessToken,
      }),
    );
    await _store.setLoggedInFlag(true);
  }

  Future<void> deleteAccount() async {
    final token = _accessToken;
    if (token == null || token.isEmpty) {
      throw AuthException('Войдите снова');
    }
    await _auth.deleteAccount(token);
    await logout();
  }

  Future<void> logout() async {
    _isAuthenticated = false;
    _user = null;
    _authMethod = null;
    _accessToken = null;
    await _store.setAuthJson(null);
    await _store.setLoggedInFlag(false);
    notifyListeners();
    _notifySession();
  }

  void setUnreadNotifications(int count) {
    if (_user == null) return;
    _user = _user!.copyWith(unreadNotifications: count);
    unawaited(_persistAuth());
    notifyListeners();
  }

  Future<void> refreshUnreadFromServer() async {
    final token = _accessToken;
    if (token == null || token.isEmpty || _user == null) return;
    try {
      final me = await _auth.fetchMe(token);
      final n = me['unread_notifications'] as int? ??
          me['unreadNotifications'] as int? ??
          _user!.unreadNotifications;
      final prev = _user!.unreadNotifications;
      _user = _user!.copyWith(unreadNotifications: n);
      await _persistAuth();
      notifyListeners();
      // Sound when a new news/notification arrives.
      if (n > prev) {
        try {
          await SystemSound.play(SystemSoundType.alert);
        } catch (_) {}
      }
    } catch (_) {}
  }
}
