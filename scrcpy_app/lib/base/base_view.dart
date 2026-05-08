import 'package:flutter/material.dart';
import 'package:scrcpy_app/app_controller.dart';

abstract class BaseView extends StatelessWidget {
  const BaseView({super.key});

  @override
  Widget build(BuildContext context) {
    final appController = AppController();
    return ListenableBuilder(
      listenable: appController,
      builder: (BuildContext context, Widget? child) => buildContent(
        context,
        appController,
      ),
    );
  }

  Widget buildContent(BuildContext context, AppController controller);
}
