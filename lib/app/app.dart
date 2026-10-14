import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../core/config/app_config.dart';
import '../core/di/injection.dart';
import '../features/auth/presentation/cubit/auth_cubit.dart';
import '../l10n/app_localizations.dart';
import 'router/auth_redirect_policy.dart';
import 'locale_cubit.dart';
import 'pages/auth_pages.dart';

class TalebApp extends StatefulWidget {
  const TalebApp({required this.config, super.key});
  final AppConfig config;

  @override
  State<TalebApp> createState() => _TalebAppState();
}

class _TalebAppState extends State<TalebApp> {
  late final AuthCubit _auth = getIt<AuthCubit>()..restore();
  late final LocaleCubit _locale = getIt<LocaleCubit>()..load();
  late final _AuthRouterRefresh _routerRefresh = _AuthRouterRefresh(_auth);
  late final GoRouter _router = GoRouter(
    initialLocation: '/',
    refreshListenable: _routerRefresh,
    errorBuilder: (_, _) => const InvalidLinkPage(),
    redirect: (context, state) {
      final recoveryError =
          state.uri.queryParameters.containsKey('error') ||
          state.uri.queryParameters.containsKey('error_code');
      if (recoveryError) return '/invalid-link';
      return resolveAuthRedirect(_auth.state, state.matchedLocation);
    },
    routes: [
      GoRoute(path: '/', builder: (_, _) => const WelcomePage()),
      GoRoute(path: '/roles', builder: (_, _) => const RoleSelectionPage()),
      GoRoute(path: '/loading', builder: (_, _) => const LoadingPage()),
      GoRoute(
        path: '/profile-unavailable',
        builder: (_, _) => const ProfileUnavailablePage(),
      ),
      GoRoute(path: '/sign-in', builder: (_, _) => const SignInPage()),
      GoRoute(
        path: '/register',
        builder: (_, state) => RegistrationPage(
          role: state.uri.queryParameters['role'] ?? 'student',
        ),
      ),
      GoRoute(path: '/reset', builder: (_, _) => const ResetPasswordPage()),
      GoRoute(
        path: '/invalid-link',
        builder: (_, _) => const InvalidLinkPage(),
      ),
      GoRoute(
        path: '/password-update',
        builder: (_, _) => const UpdatePasswordPage(),
      ),
      GoRoute(
        path: '/reset-password',
        builder: (_, _) => const UpdatePasswordPage(),
      ),
      GoRoute(
        path: '/confirm-email',
        builder: (_, _) => const ConfirmEmailPage(),
      ),
      GoRoute(path: '/pending', builder: (_, _) => const PendingTeacherPage()),
      GoRoute(path: '/home', builder: (_, _) => const HomePage()),
    ],
  );

  @override
  void dispose() {
    _router.dispose();
    _routerRefresh.dispose();
    _auth.close();
    _locale.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MultiBlocProvider(
    providers: [
      BlocProvider.value(value: _auth),
      BlocProvider.value(value: _locale),
    ],
    child: BlocBuilder<LocaleCubit, Locale?>(
      builder: (context, locale) => MaterialApp.router(
        title: 'Taleb',
        routerConfig: _router,
        locale: locale,
        supportedLocales: const [Locale('ar'), Locale('en')],
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        localeResolutionCallback: (deviceLocale, supported) =>
            locale ??
            supported.firstWhere(
              (item) => item.languageCode == deviceLocale?.languageCode,
              orElse: () => const Locale('ar'),
            ),
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF126B62),
            surface: const Color(0xFFF8FAF9),
          ),
          useMaterial3: true,
          inputDecorationTheme: const InputDecorationTheme(
            border: OutlineInputBorder(),
            filled: true,
          ),
        ),
      ),
    ),
  );
}

class _AuthRouterRefresh extends ChangeNotifier {
  _AuthRouterRefresh(AuthCubit cubit) {
    _subscription = cubit.stream.listen((_) => notifyListeners());
  }
  late final StreamSubscription<AuthState> _subscription;
  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

class ConfigMissingApp extends StatelessWidget {
  const ConfigMissingApp({super.key});
  @override
  Widget build(BuildContext context) => const MaterialApp(
    home: Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Supabase is not configured. Run with --dart-define-from-file=.env.json. See README.md.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    ),
  );
}
