import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:taleb/app/locale_cubit.dart';
import 'package:taleb/core/storage/locale_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('language choice persists and restores on the next launch', () async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    final firstLaunch = LocaleCubit(LocaleRepository());
    await firstLaunch.load();
    expect(firstLaunch.state, isNull);
    await firstLaunch.setLanguage('en');
    await firstLaunch.close();

    final secondLaunch = LocaleCubit(LocaleRepository());
    await secondLaunch.load();
    expect(secondLaunch.state?.languageCode, 'en');
    await secondLaunch.close();
  });
}
