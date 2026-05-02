import 'package:autoglm_adb/autoglm_adb.dart';
import 'package:autoglm_app/i18n/strings.g.dart';
import 'package:autoglm_app/pages/devices_page.dart';
import 'package:autoglm_app/providers/adb_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(List<DeviceInfo> devices) {
  return ProviderScope(
    overrides: [
      adbDevicesWithInfoProvider.overrideWith((_) async => devices),
    ],
    child: TranslationProvider(
      child: const MaterialApp(home: DevicesPage()),
    ),
  );
}

void main() {
  setUpAll(LocaleSettings.useDeviceLocale);

  testWidgets('shows model name and online badge for online device',
      (tester) async {
    await tester.pumpWidget(
      _wrap([
        const DeviceInfo(
          serial: 'R3CN12345',
          status: DeviceStatus.online,
          model: 'Pixel 8 Pro',
          manufacturer: 'Google',
          androidVersion: '14',
          sdkVersion: 34,
        ),
      ]),
    );
    await tester.pumpAndSettle();

    expect(find.text('Pixel 8 Pro'), findsOneWidget);
    expect(find.text('online'), findsOneWidget);
    expect(find.text('offline'), findsNothing);
  });

  testWidgets('shows serial as title when model is null (offline device)',
      (tester) async {
    await tester.pumpWidget(
      _wrap([
        const DeviceInfo(
          serial: 'emulator-5554',
          status: DeviceStatus.offline,
        ),
      ]),
    );
    await tester.pumpAndSettle();

    expect(find.text('emulator-5554'), findsWidgets); // title + serial row
    expect(find.text('offline'), findsOneWidget);
  });

  testWidgets('shows unauthorized badge for unauthorized device',
      (tester) async {
    await tester.pumpWidget(
      _wrap([
        const DeviceInfo(
          serial: '192.168.1.8:5555',
          status: DeviceStatus.unauthorized,
        ),
      ]),
    );
    await tester.pumpAndSettle();

    expect(find.text('unauthorized'), findsOneWidget);
  });

  testWidgets('shows no-device message when list is empty', (tester) async {
    await tester.pumpWidget(_wrap([]));
    await tester.pumpAndSettle();

    expect(find.text(t.devices_page.no_devices), findsOneWidget);
  });

  testWidgets('shows Wi-Fi icon for wireless serial', (tester) async {
    await tester.pumpWidget(
      _wrap([
        const DeviceInfo(
          serial: '192.168.1.5:5555',
          status: DeviceStatus.online,
          model: 'Xiaomi 14',
        ),
      ]),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.wifi), findsOneWidget);
    expect(find.byIcon(Icons.usb), findsNothing);
  });

  testWidgets('shows USB icon for wired serial', (tester) async {
    await tester.pumpWidget(
      _wrap([
        const DeviceInfo(
          serial: 'R3CN12345',
          status: DeviceStatus.online,
          model: 'Pixel 8',
        ),
      ]),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.usb), findsOneWidget);
    expect(find.byIcon(Icons.wifi), findsNothing);
  });
}
