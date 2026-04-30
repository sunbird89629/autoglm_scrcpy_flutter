import 'package:flutter/material.dart';
import 'package:scrcpy_app/app_controller.dart';
import 'package:scrcpy_view/scrcpy_view.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    final appController = AppController();
    return ListenableBuilder(
      listenable: appController,
      builder: (context, child) {
        if (appController.running) {
          return ScrcpyView(
            controller: appController.scrcpyViewController,
          );
        } else {
          return FutureBuilder(
            future: appController.scrcpyViewController.getDevices(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return CircularProgressIndicator();
              } else if (snapshot.data == null || snapshot.data!.length == 0) {
                return Text("No device found");
              } else {
                final devices = snapshot.data!;
                return ListView.builder(
                  itemCount: devices.length,
                  itemBuilder: (context, index) {
                    final deviceId = devices[index];
                    return ListTile(
                      title: Text(deviceId),
                      onTap: () {
                        // appController.connectDevice(deviceId);
                        appController.connectDevice("11081FDD4004DY");
                      },
                    );
                  },
                );
              }
            },
          );
        }
      },
    );
  }
}
