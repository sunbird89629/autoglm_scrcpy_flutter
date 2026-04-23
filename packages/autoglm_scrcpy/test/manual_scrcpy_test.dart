import 'dart:async';
import 'dart:io';

import 'package:autoglm_adb/autoglm_adb.dart';
import 'package:autoglm_core/autoglm_core.dart';
import 'package:autoglm_scrcpy/autoglm_scrcpy.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // This "test" is designed to be run as a standalone app to allow
  // real interaction with ADB and a physical device.
  runApp(const MaterialApp(
    home: Scaffold(
      body: Center(child: Text('Check console for Scrcpy logs')),
    ),
  ));

  testMain();
}

Future<void> testMain() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  appLogger.i('--- Starting Manual Scrcpy Test ---');

  final adbClient = AdbClient();
  
  try {
    // 1. Find a device
    final devices = await adbClient.listDevices();
    if (devices.isEmpty) {
      appLogger.e('No devices found! Please connect an Android phone via USB/ADB.');
      return;
    }

    final deviceId = devices.first.serial;
    appLogger.i('Using device: $deviceId');

    // 2. Initialize ScrcpyServer
    final server = ScrcpyServer(
      adbClient: adbClient,
      deviceId: deviceId,
    );

    // 3. Listen to metadata and packets
    server.metadata.listen((meta) {
      appLogger.i('[TEST] Received Metadata: ${meta.deviceName} (${meta.width}x${meta.height})');
    });

    var packetCount = 0;
    server.packets.listen((packet) {
      packetCount++;
      if (packetCount % 60 == 0) {
        appLogger.d('[TEST] Received $packetCount packets... (latest size: ${packet.data.length})');
      }
    });

    // 4. Start the server
    appLogger.i('[TEST] Starting server...');
    await server.start();
    
    appLogger.i('[TEST] Server started successfully!');
    appLogger.i('[TEST] Proxy Media URL: ${server.proxyUrl}');
    appLogger.i('[TEST] Waiting for proxy to be ready (SPS/PPS buffered)...');
    
    await server.proxyReady.timeout(const Duration(seconds: 10));
    appLogger.i('[TEST] Proxy is READY. You can now open ${server.proxyUrl} in VLC.');

    // 5. Run for 30 seconds then stop
    appLogger.i('[TEST] Running for 30 seconds before cleanup...');
    await Future<void>.delayed(const Duration(seconds: 30));

    appLogger.i('[TEST] Stopping server...');
    await server.stop();
    appLogger.i('[TEST] Test completed successfully.');
    
    exit(0);
  } catch (e, st) {
    appLogger.e('[TEST] Fatal error during test', e, st);
    exit(1);
  }
}