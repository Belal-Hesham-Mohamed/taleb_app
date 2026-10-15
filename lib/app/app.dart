import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../core/config/app_config.dart';
import '../core/di/injection.dart';
import '../features/auth/domain/repositories/registration_repository.dart';
import '../features/auth/presentation/cubit/auth_cubit.dart';
import '../l10n/app_localizations.dart';
import 'router/auth_redirect_policy.dart';
import 'locale_cubit.dart';
import 'pages/auth_pages.dart';
import 'pages/student_registration_page.dart';

class TalebApp extends StatefulWidget {
  const TalebApp({required this.config, super.key});
  final AppConfig config;

  @override
  State<TalebApp> createState() => _TalebAppState();
}

class _TalebAppState extends State<TalebApp> {
  AuthCubit? _auth;

  @override
  void initState() {
    super.initState();
    // In emulator mode (FAKE_REGISTRATION) no AuthCubit is registered, so
    // the router runs without auth state and the registration flow is
    // exercised directly.
    if (getIt.isRegistered<AuthCubit>()) {
      final auth = getIt<AuthCubit>()..restore();
      _auth = auth;
      _routerRefresh = _AuthRouterRefresh(auth);
    }
  }

  late final LocaleCubit _locale = getIt<LocaleCubit>()..load();
  _AuthRouterRefresh? _routerRefresh;
  late final GoRouter _router = GoRouter(
    initialLocation: '/',
    refreshListenable: _routerRefresh,
    errorBuilder: (_, _) => const InvalidLinkPage(),
    redirect: (context, state) {
      final recoveryError =
          state.uri.queryParameters.containsKey('error') ||
          state.uri.queryParameters.containsKey('error_code');
      if (recoveryError) return '/invalid-link';
      final auth = _auth;
      if (auth == null) return null;
      return resolveAuthRedirect(auth.state, state.matchedLocation);
    },
    routes: [
      GoRoute(path: '/', builder: (_, _) => const RoleSelectionPage()),
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
      GoRoute(
        path: '/register/student',
        builder: (_, _) => StudentRegistrationPage(
          repository: getIt<RegistrationRepository>(),
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
    _routerRefresh?.dispose();
    _auth?.close();
    _locale.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MultiBlocProvider(
    providers: [
      if (_auth != null) BlocProvider<AuthCubit>.value(value: _auth!),
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
          colorScheme:
              ColorScheme.fromSeed(
                seedColor: const Color(0xFF5147EE),
                surface: const Color(0xFFFBFAFF),
              ).copyWith(
                primary: const Color(0xFF5147EE),
                onPrimary: Colors.white,
                primaryContainer: const Color(0xFFE8E6FF),
                onPrimaryContainer: const Color(0xFF221B78),
              ),
          useMaterial3: true,
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF5147EE),
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
            ),
          ),
          inputDecorationTheme: const InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(14)),
              borderSide: BorderSide(color: Color(0xFFE4E2ED)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(14)),
              borderSide: BorderSide(color: Color(0xFFE4E2ED)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(14)),
              borderSide: BorderSide(color: Color(0xFF5147EE), width: 1.5),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: EdgeInsetsDirectional.fromSTEB(18, 16, 18, 16),
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
