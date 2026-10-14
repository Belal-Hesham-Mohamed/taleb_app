import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';
import '../storage/locale_repository.dart';
import '../../app/locale_cubit.dart';
import '../../features/auth/data/repositories/supabase_auth_repository.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';

final getIt = GetIt.instance;

Future<void> configureDependencies(AppConfig config) async {
  if (!config.isConfigured) {
    throw ArgumentError('Supabase URL and publishable key are required.');
  }
  getIt
    ..registerSingleton<SupabaseClient>(Supabase.instance.client)
    ..registerLazySingleton<AuthRepository>(
      () => SupabaseAuthRepository(getIt<SupabaseClient>()),
    )
    ..registerFactory(() => AuthCubit(getIt<AuthRepository>()))
    ..registerLazySingleton(LocaleRepository.new)
    ..registerFactory(() => LocaleCubit(getIt<LocaleRepository>()));
}
