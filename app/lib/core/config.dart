/// Runtime config injected at build time via --dart-define.
///
///   flutter run --dart-define=API_BASE=http://localhost:8000 \
///               --dart-define=API_TOKEN=dev-local-token-change-me
///
/// On a phone, set API_BASE to your Mac's LAN IP (e.g. http://192.168.1.20:8000).
class AppConfig {
  static const String apiBase =
      String.fromEnvironment('API_BASE', defaultValue: 'http://localhost:8000');
  static const String apiToken =
      String.fromEnvironment('API_TOKEN', defaultValue: 'dev-local-token-change-me');
}
