import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:shared_preferences_platform_interface/types.dart';

InMemorySharedPreferencesAsync? _asyncPreferences;

void installTestPreferences() {
  TestWidgetsFlutterBinding.ensureInitialized();
  _asyncPreferences = InMemorySharedPreferencesAsync.empty();
  SharedPreferencesAsyncPlatform.instance = _asyncPreferences;
  SharedPreferences.setMockInitialValues(<String, Object>{});
}

Future<void> resetTestPreferences() async {
  final InMemorySharedPreferencesAsync? preferences = _asyncPreferences;
  if (preferences == null) {
    installTestPreferences();
    return;
  }

  await preferences.clear(
    const ClearPreferencesParameters(
      filter: PreferencesFilters(),
    ),
    const SharedPreferencesOptions(),
  );
  SharedPreferences.setMockInitialValues(<String, Object>{});
}

void uninstallTestPreferences() {
  SharedPreferencesAsyncPlatform.instance = null;
  _asyncPreferences = null;
}
