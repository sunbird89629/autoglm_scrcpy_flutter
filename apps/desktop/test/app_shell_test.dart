import 'package:autoglm_desktop/i18n/strings.g.dart';
import 'package:autoglm_desktop/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(LocaleSettings.useDeviceLocale);

  Future<void> pumpAppShell(WidgetTester tester) async {
    final router = createRouter();
    await tester.pumpWidget(
      TranslationProvider(
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders 5 NavigationRail destinations', (tester) async {
    await pumpAppShell(tester);
    final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
    expect(rail.destinations, hasLength(5));
  });

  testWidgets('NavigationRail labels match i18n', (tester) async {
    await pumpAppShell(tester);
    expect(find.text(t.nav.devices), findsWidgets);
    expect(find.text(t.nav.chat), findsWidgets);
    expect(find.text(t.nav.workflows), findsWidgets);
    expect(find.text(t.nav.history), findsWidgets);
    expect(find.text(t.nav.settings), findsWidgets);
  });

  testWidgets('tapping NavigationRail destination changes route',
      (tester) async {
    final router = createRouter();
    await tester.pumpWidget(
      TranslationProvider(
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    expect(router.routerDelegate.currentConfiguration.uri.path, '/devices');

    // Tap the "Settings" label (index 4).
    await tester.tap(find.text(t.nav.settings).first);
    await tester.pumpAndSettle();
    expect(router.routerDelegate.currentConfiguration.uri.path, '/settings');
  });
}
