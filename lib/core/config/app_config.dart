abstract final class AppConfig {
  static const appName = 'VEYORA';
  static const tagline = 'Your Potential. Our Intelligence.';
  static const version = '1.0.0';

  static const aiProxyUrl = String.fromEnvironment('AI_PROXY_URL');
  static const aiProxyToken = String.fromEnvironment('AI_PROXY_TOKEN');
  static const jobsEndpoint = 'https://remotive.com/api/remote-jobs';

  static bool get hasSecureAiBackend => aiProxyUrl.isNotEmpty;
}
