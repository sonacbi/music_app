import 'package:flutter/material.dart';
import 'screens/control_screen.dart';

void main() {
  runApp(const ArduinoMusicApp());
}

class ArduinoMusicApp extends StatelessWidget {
  const ArduinoMusicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Arduino Music Controller',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const ControlScreen(),
    );
  }
}