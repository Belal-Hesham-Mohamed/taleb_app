import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'core/config/app_config.dart';
import 'core/di/injection.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final config = AppConfig.fromEnvironment();
  if (!config.isConfigured) {
    runApp(const ConfigMissingApp());
    return;
  }

  // The fake registration flag lets the registration flow be driven without
  // a reachable backend, but Supabase Auth still needs a client for sign-in
  // and session restore, so initialize it whenever a URL is present.
  if (!config.fakeRegistration || config.supabaseUrl.startsWith('https://')) {
    await Supabase.initialize(
      url: config.supabaseUrl,
      publishableKey: config.supabasePublishableKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );
  }
  await configureDependencies(config);
  runApp(TalebApp(config: config));
}
