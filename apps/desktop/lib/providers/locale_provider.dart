import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../i18n/strings.g.dart';
import 'settings_provider.dart';

/// Side-effect provider: watches `Settings.locale` and pushes it into
/// slang's `LocaleSettings`. Watch it in the widget tree to apply.
///
/// `Settings.locale` is one of: 'system' | 'zh-CN' | 'en-US'.
final localeApplyProvider = Provider<void>((ref) {
  final asyncSettings = ref.watch(settingsProvider);
  asyncSettings.whenData((s) async {
    if (s.locale == 'system') {
      await LocaleSettings.useDeviceLocale();
      return;
    }
    final match = AppLocaleUtils.parse(s.locale);
    await LocaleSettings.setLocale(match);
  });
});
