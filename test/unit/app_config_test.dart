import 'package:flutter_test/flutter_test.dart';
import 'package:taleb/core/config/app_config.dart';

void main() {
  test('configuration requires both an HTTPS URL and a public key', () {
    expect(
      const AppConfig(
        supabaseUrl: 'https://example.supabase.co',
        supabasePublishableKey: 'public-key',
      ).isConfigured,
      isTrue,
    );
    expect(
      const AppConfig(supabaseUrl: '', supabasePublishableKey: '').isConfigured,
      isFalse,
    );
    expect(
      const AppConfig(
        supabaseUrl: 'http://example.supabase.co',
        supabasePublishableKey: 'public-key',
      ).isConfigured,
      isFalse,
    );
  });
}
