/// Вставьте Web Client ID из Google Cloud Console (OAuth 2.0 → Web application).
/// Тот же ID укажите в backend/.env как GOOGLE_CLIENT_ID.
class OAuthConfig {
  static const googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue: '',
  );
}
