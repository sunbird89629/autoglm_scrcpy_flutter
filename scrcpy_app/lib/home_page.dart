import 'package:flutter/material.dart';
import 'package:scrcpy_app/app_controller.dart';
import 'package:scrcpy_app/device_list_widget.dart';
import 'package:scrcpy_app/views/control_view.dart';
import 'package:scrcpy_view/scrcpy_view.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: _buildBody());
  }

  Widget _buildBody() {
    final appController = AppController();
    return ListenableBuilder(
      listenable: appController,
      builder: (context, child) {
        final mainContent = appController.running
            ? ScrcpyView(controller: appController.scrcpyViewController)
            : FutureBuilder(
                future: appController.scrcpyViewController.getDevices(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final devices = snapshot.data!;
                  if (devices.isEmpty) {
                    return const Center(child: Text('No device found'));
                  }
                  return DeviceListWidget(
                    devices: devices,
                    onItemTap: (index) {
                      appController.connectDevice(devices[index]);
                    },
                  );
                },
              );
        return Row(
          children: [
            Expanded(child: mainContent),
            ControlView(),
          ],
        );
      },
    );
  }
}
