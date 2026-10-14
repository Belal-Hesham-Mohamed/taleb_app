class AppConfig {
  const AppConfig({
    required this.supabaseUrl,
    required this.supabasePublishableKey,
  });

  final String supabaseUrl;
  final String supabasePublishableKey;

  bool get isConfigured =>
      supabaseUrl.startsWith('https://') && supabasePublishableKey.isNotEmpty;

  static AppConfig fromEnvironment() => AppConfig(
    supabaseUrl: const String.fromEnvironment('SUPABASE_URL'),
    supabasePublishableKey: const String.fromEnvironment(
      'SUPABASE_PUBLISHABLE_KEY',
    ),
  );
}
