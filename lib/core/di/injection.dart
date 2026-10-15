import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';
import '../storage/locale_repository.dart';
import '../../app/locale_cubit.dart';
import '../../features/auth/data/repositories/supabase_auth_repository.dart';
import '../../features/auth/data/repositories/supabase_registration_repository.dart';
import '../../features/auth/data/repositories/fake_registration_repository.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/repositories/registration_repository.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../features/auth/presentation/cubit/registration_cubit.dart';

final getIt = GetIt.instance;

Future<void> configureDependencies(AppConfig config) async {
  if (!config.isConfigured) {
    throw ArgumentError('Supabase URL and publishable key are required.');
  }
  if (config.fakeRegistration) {
    // Emulator mode: no Supabase client is registered, so nothing can reach
    // a backend. Only the registration flow is exercised in this mode.
    getIt
      ..registerLazySingleton<RegistrationRepository>(
        FakeRegistrationRepository.new,
      )
      ..registerFactory(() => RegistrationCubit(getIt<RegistrationRepository>()))
      ..registerLazySingleton(LocaleRepository.new)
      ..registerFactory(() => LocaleCubit(getIt<LocaleRepository>()));
    return;
  }
  getIt
    ..registerSingleton<SupabaseClient>(Supabase.instance.client)
    ..registerLazySingleton<AuthRepository>(
      () => SupabaseAuthRepository(getIt<SupabaseClient>()),
    )
    ..registerLazySingleton<RegistrationRepository>(
      () => SupabaseRegistrationRepository(getIt<SupabaseClient>()),
    )
    ..registerFactory(() => AuthCubit(getIt<AuthRepository>()))
    ..registerFactory(() => RegistrationCubit(getIt<RegistrationRepository>()))
    ..registerLazySingleton(LocaleRepository.new)
    ..registerFactory(() => LocaleCubit(getIt<LocaleRepository>()));
}
