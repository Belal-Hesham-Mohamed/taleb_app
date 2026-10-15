class AppConfig {
  const AppConfig({
    required this.supabaseUrl,
    required this.supabasePublishableKey,
    this.fakeRegistration = false,
  });

  final String supabaseUrl;
  final String supabasePublishableKey;

  /// When true, the student registration repository is replaced with an
  /// in-memory fake so the flow can be driven on an emulator without a
  /// reachable backend. Never enable in release builds: it accepts any
  /// password and pretends account creation succeeded.
  final bool fakeRegistration;

  bool get isConfigured =>
      fakeRegistration ||
      (supabaseUrl.startsWith('https://') && supabasePublishableKey.isNotEmpty);

  static AppConfig fromEnvironment() => AppConfig(
    supabaseUrl: const String.fromEnvironment('SUPABASE_URL'),
    supabasePublishableKey: const String.fromEnvironment(
      'SUPABASE_PUBLISHABLE_KEY',
    ),
    fakeRegistration: const bool.fromEnvironment('FAKE_REGISTRATION'),
  );
}
