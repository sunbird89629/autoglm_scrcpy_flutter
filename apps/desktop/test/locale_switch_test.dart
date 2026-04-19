import 'package:autoglm_core/autoglm_core.dart';
import 'package:autoglm_desktop/i18n/strings.g.dart';
import 'package:autoglm_desktop/providers/locale_provider.dart';
import 'package:autoglm_desktop/providers/settings_provider.dart';
import 'package:autoglm_desktop/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _MemoryRepo implements SettingsRepository {
  _MemoryRepo(this.initial);
  Settings initial;
  @override
  Future<Settings> load() async => initial;
  @override
  Future<void> save(Settings s) async => initial = s;
}

void main() {
  setUpAll(LocaleSettings.useDeviceLocale);

  testWidgets('localeApplyProvider wires into widget tree', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsRepositoryProvider.overrideWithValue(
            _MemoryRepo(const Settings()),
          ),
        ],
        child: TranslationProvider(
          child: Consumer(
            builder: (context, ref, _) {
              ref.watch(localeApplyProvider);
              return MaterialApp.router(
                routerConfig: createRouter(),
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    // Verify the router is rendered (smoke test that wiring works)
    expect(find.byType(NavigationRail), findsOneWidget);
  });
}
