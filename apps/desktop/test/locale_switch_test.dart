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
  testWidgets('locale=en-US shows English nav labels', (tester) async {
    LocaleSettings.setLocaleRaw('en-US');
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsRepositoryProvider.overrideWithValue(
            _MemoryRepo(const Settings(locale: 'en-US')),
          ),
        ],
        child: TranslationProvider(
          child: Consumer(
            builder: (context, ref, _) {
              ref.watch(localeApplyProvider);
              return MaterialApp.router(routerConfig: createRouter());
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Devices'), findsWidgets);
    expect(find.text('设备'), findsNothing);
  });

  testWidgets('locale=zh-CN shows Chinese nav labels', (tester) async {
    LocaleSettings.setLocaleRaw('zh-CN');
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsRepositoryProvider.overrideWithValue(
            _MemoryRepo(const Settings(locale: 'zh-CN')),
          ),
        ],
        child: TranslationProvider(
          child: Consumer(
            builder: (context, ref, _) {
              ref.watch(localeApplyProvider);
              return MaterialApp.router(routerConfig: createRouter());
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('设备'), findsWidgets);
    expect(find.text('Devices'), findsNothing);
  });
}
