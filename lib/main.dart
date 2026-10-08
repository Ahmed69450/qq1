import 'package:flutter/material.dart';
import 'presentation/settings/settings_screen.dart';

void main() {
  runApp(
    MaterialApp(
      title: 'BYD Assistant',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const SettingsScreen(),
    ),
  );
}
