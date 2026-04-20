import 'package:autoglm_core/autoglm_core.dart';
import 'package:autoglm_desktop/i18n/strings.g.dart';
import 'package:autoglm_desktop/providers/settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Page for application settings.
class SettingsPage extends ConsumerWidget {
  /// Creates a [SettingsPage].
  const SettingsPage({super.key});

  /// Key for the theme dropdown.
  static const themeDropdownKey = Key('theme-dropdown');

  /// Key for the locale dropdown.
  static const localeDropdownKey = Key('locale-dropdown');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(t.nav.settings),
      ),
      body: settingsAsync.when(
        data: (settings) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildThemeSection(context, ref, settings),
            const Divider(),
            _buildLocaleSection(context, ref, settings),
            const Divider(),
            _buildLlmSection(context, ref, settings),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildThemeSection(
    BuildContext context,
    WidgetRef ref,
    Settings settings,
  ) {
    return ListTile(
      title: Text(t.settings.theme.label),
      trailing: DropdownButton<String>(
        key: themeDropdownKey,
        value: settings.themeMode,
        onChanged: (value) {
          if (value != null) {
            ref.read(settingsProvider.notifier).updateSettings(
                  settings.copyWith(themeMode: value),
                );
          }
        },
        items: [
          DropdownMenuItem(
            value: 'system',
            child: Text(t.settings.theme.system),
          ),
          DropdownMenuItem(
            value: 'light',
            child: Text(t.settings.theme.light),
          ),
          DropdownMenuItem(
            value: 'dark',
            child: Text(t.settings.theme.dark),
          ),
        ],
      ),
    );
  }

  Widget _buildLocaleSection(
    BuildContext context,
    WidgetRef ref,
    Settings settings,
  ) {
    return ListTile(
      title: Text(t.settings.locale.label),
      trailing: DropdownButton<String>(
        key: localeDropdownKey,
        value: settings.locale,
        onChanged: (value) {
          if (value != null) {
            ref.read(settingsProvider.notifier).updateSettings(
                  settings.copyWith(locale: value),
                );
          }
        },
        items: [
          DropdownMenuItem(
            value: 'system',
            child: Text(t.settings.locale.system),
          ),
          const DropdownMenuItem(
            value: 'zh-CN',
            child: Text('简体中文'),
          ),
          const DropdownMenuItem(
            value: 'en-US',
            child: Text('English'),
          ),
        ],
      ),
    );
  }

  Widget _buildLlmSection(
    BuildContext context,
    WidgetRef ref,
    Settings settings,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Text('LLM Configuration', style: TextStyle(fontSize: 16)),
        ),
        TextField(
          decoration: const InputDecoration(labelText: 'API Key'),
          obscureText: true,
          controller: TextEditingController(text: settings.llmApiKey),
          onSubmitted: (value) {
            ref.read(settingsProvider.notifier).updateSettings(
                  settings.copyWith(llmApiKey: value),
                );
          },
        ),
      ],
    );
  }
}
