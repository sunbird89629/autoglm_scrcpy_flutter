import 'package:autoglm_core/autoglm_core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Settings', () {
    test('default values match spec', () {
      const s = Settings();
      expect(s.themeMode, 'system');
      expect(s.locale, 'system');
      expect(s.llmProvider, 'gemini');
      expect(s.llmApiKey, '');
    });

    test('toJson/fromJson roundtrip preserves all fields', () {
      const s = Settings(
        themeMode: 'light',
        locale: 'en-US',
        llmProvider: 'openai',
        llmApiKey: 'sk-123',
      );

      final json = s.toJson();
      final fromJson = Settings.fromJson(json);

      expect(fromJson.themeMode, s.themeMode);
      expect(fromJson.locale, s.locale);
      expect(fromJson.llmProvider, s.llmProvider);
      expect(fromJson.llmApiKey, s.llmApiKey);
    });
  });
}
