import 'package:flutter/material.dart';
import 'package:scrcpy_app/home_page.dart';

class ScrcpyApp extends StatelessWidget {
  const ScrcpyApp({super.key});

  static const _accent = Color(0xFF3B82F6);

  static final _darkTheme = ThemeData(
    colorSchemeSeed: _accent,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF0D0D0D),
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ScrcpyApp',
      debugShowCheckedModeBanner: false,
      theme: _darkTheme,
      darkTheme: _darkTheme,
      themeMode: ThemeMode.dark,
      home: const HomePage(),
    );
  }
}
