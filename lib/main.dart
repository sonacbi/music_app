import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'screens/control_screen.dart';

void main() {
  runApp(const ArduinoMusicApp());
}

class ArduinoMusicApp extends StatefulWidget {
  const ArduinoMusicApp({super.key});

  @override
  State<ArduinoMusicApp> createState() => _ArduinoMusicAppState();
}

class _ArduinoMusicAppState extends State<ArduinoMusicApp> {

  @override
  void initState() {
    super.initState();
    requestPermissions();
  }

  Future<void> requestPermissions() async {
    await [
      Permission.bluetooth,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.location,
    ].request();
  }

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