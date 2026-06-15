import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// import 'dart:math';
import 'dart:async';

import '../theme/app_colors.dart';
import '../widgets/debug_panel.dart';
import '../widgets/device_card.dart';
import '../widgets/transport_panel.dart';
import '../widgets/beam_overlay.dart';
import '../widgets/music_visualizer.dart';
import '../widgets/device_selector_popup.dart';
import '../bluetooth/bluetooth_service.dart';

class ControlScreen extends StatefulWidget {
  const ControlScreen({super.key});

  @override
  State<ControlScreen> createState() => _ControlScreenState();
}

class _ControlScreenState extends State<ControlScreen>
    with SingleTickerProviderStateMixin {
  bool debugMode = false;

  final GlobalKey arduinoButtonKey = GlobalKey();
  final GlobalKey gamepadButtonKey = GlobalKey();

  late AnimationController beamController;

  Offset? beamTopRight;
  Offset? beamBottomLeft;
  TransportState transportState = TransportState.stop;

  final BluetoothService bluetoothService = BluetoothService();
  // bool gamepadActive = false;
  DateTime _lastInputTime = DateTime.now();
  bool gamepadConnected = false;
  bool gamepadDetected = false;
  Timer? _gamepadWatchdog;

  final FocusNode _focusNode = FocusNode();

  String lastGamepadKey = "No Input";

  bool get isConnected =>
      bluetoothService.currentStatus == BluetoothStatus.connected;

  @override
  void initState() {
    super.initState();

    beamController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2), // 충분히 길게
    );

    // gamepadDetected = true; // 테스트용
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });

    _gamepadWatchdog = Timer.periodic(const Duration(seconds: 1), (_) {
      final diff = DateTime.now().difference(_lastInputTime);

      // 2초 이상 입력 없으면 disconnect 처리
      if (diff.inSeconds > 2 && gamepadConnected) {
        setState(() {
          gamepadConnected = false;
          gamepadDetected = false;
          print("GAMEPAD UI → DISCONNECTED");
        });

        print("GAMEPAD DISCONNECTED (timeout)");
      }
    });
  }

  Future<void> triggerBeam(GlobalKey targetKey) async {
    if (beamController.isAnimating) {
      beamController.stop();
    }
    if (targetKey.currentContext == null) return;
    final renderBox = targetKey.currentContext!.findRenderObject() as RenderBox;

    final overlayBox =
        Overlay.of(context).context.findRenderObject() as RenderBox;

    final local = overlayBox.globalToLocal(
      renderBox.localToGlobal(Offset.zero),
    );

    final size = renderBox.size;

    // 0.5px~1.5px 미세 보정 (Flutter subpixel rounding 대응)
    const double yFix = -2; // 세부 조정

    beamTopRight = Offset(local.dx + size.width, local.dy + yFix);

    beamBottomLeft = Offset(local.dx, local.dy + size.height + yFix);

    setState(() {});

    beamController
      ..reset()
      ..forward();
  }

  void showDevicePopup() async {
    final devices = await bluetoothService.getBondedDevices();

    showModalBottomSheet(
      context: context,
      builder: (_) {
        return DeviceSelectorPopup(
          devices: devices,
          onSelect: (device) async {
            final success = await bluetoothService.connect(device);

            if (success) {
              setState(() {
                debugMode = true;
              });
            }

            return success;
          },
        );
      },
    );
  }

  // int _mapKeyToCmd(LogicalKeyboardKey key) {
  //   if (key == LogicalKeyboardKey.keyA) return 4;
  //   if (key == LogicalKeyboardKey.keyB) return 5;
  //   if (key == LogicalKeyboardKey.keyX) return 6;
  //   if (key == LogicalKeyboardKey.keyY) return 7;

  //   if (key == LogicalKeyboardKey.arrowUp) return 8;
  //   if (key == LogicalKeyboardKey.arrowDown) return 9;
  //   if (key == LogicalKeyboardKey.arrowLeft) return 10;
  //   if (key == LogicalKeyboardKey.arrowRight) return 11;

  //   return 0;
  // }
  int _mapKeyToCmd(LogicalKeyboardKey key) {
  final label = key.keyLabel.toLowerCase();

  // ABXY
  if (label.contains('game button a')) return 4;
  if (label.contains('game button b')) return 5;
  if (label.contains('game button x')) return 6;
  if (label.contains('game button y')) return 7;

  // dpad
  if (label.contains('arrow up')) return 8;
  if (label.contains('arrow down')) return 9;
  if (label.contains('arrow left')) return 10;
  if (label.contains('arrow right')) return 11;

  // shoulder
  if (label.contains('right 2')) return 12;
  if (label.contains('left 2')) return 13;

  return 0;
}

  void _handleKey(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    _lastInputTime = DateTime.now();

    if (!gamepadConnected) {
      setState(() {
        gamepadConnected = true;
        gamepadDetected = true;
      });
    }

    final cmd = _mapKeyToCmd(event.logicalKey);

    setState(() {
      lastGamepadKey = event.logicalKey.keyLabel;
    });

    print("GAMEPAD -> $cmd (${event.logicalKey.keyLabel})");

    if (bluetoothService.isConnected && cmd != 0) {
      bluetoothService.send(cmd); // 🔥 동일 채널 사용
    }
  }

  @override
  void dispose() {
    _gamepadWatchdog?.cancel();
    _focusNode.dispose();
    beamController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: false,
      onKeyEvent: _handleKey,
      child: Scaffold(
        body: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppColors.backgroundTop, AppColors.backgroundBottom],
                ),
              ),

              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),

                      StreamBuilder<BluetoothStatus>(
                        stream: bluetoothService.statusStream,
                        initialData: BluetoothStatus.disconnected,
                        builder: (context, snapshot) {
                          final arduinoStatus = snapshot.data!;

                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              // 🔵 Arduino = Bluetooth 상태
                              DeviceCard(
                                buttonKey: arduinoButtonKey,
                                icon: Icons.memory,
                                title: "Arduino",
                                connected:
                                    arduinoStatus == BluetoothStatus.connected,
                                onTap: () async {
                                  triggerBeam(arduinoButtonKey);
                                  showDevicePopup();
                                },
                              ),

                              // 🎮 Gamepad = 로컬 상태 (절대 Bluetooth 아님)
                              DeviceCard(
                                buttonKey: gamepadButtonKey,
                                icon: Icons.sports_esports,
                                title: "Gamepad",
                                connected: gamepadDetected,
                                onTap: () {
                                  triggerBeam(gamepadButtonKey);

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        "게임패드를 Android Bluetooth 설정에서 연결하세요.",
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          );
                        },
                      ),
                      const Spacer(),

                      MusicVisualizer(
                        state: isConnected
                            ? transportState
                            : TransportState.stop,
                        disabled: !isConnected,
                      ),

                      const Spacer(),
                      TransportPanel(
                        onPlay: () {
                          bluetoothService.send(1);
                          setState(() => transportState = TransportState.play);
                        },

                        onPause: () {
                          bluetoothService.send(2);
                          setState(() => transportState = TransportState.pause);
                        },

                        onStop: () {
                          bluetoothService.send(3);
                          setState(() => transportState = TransportState.stop);
                        },
                      ),
                      const Spacer(),

                      SwitchListTile(
                        title: const Text(
                          "Debug Mode",
                          style: TextStyle(color: Colors.white),
                        ),
                        value: debugMode,
                        onChanged: (value) {
                          setState(() => debugMode = value);
                        },
                      ),

                      if (debugMode)
                        Expanded(
                          flex: 2,
                          child: Row(
                            children: [
                              DebugPanel(
                                title: "Arduino TX",
                                logs: ["NOTE:C4", "NOTE:E4", "NOTE:G4"],
                              ),
                              SizedBox(width: 20),
                              DebugPanel(
                                title: "Gamepad RX",
                                logs: [lastGamepadKey],
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // repaint 폭주 방지용 AnimatedBuilder 단독 사용
            AnimatedBuilder(
              animation: beamController,
              builder: (_, __) {
                if (beamTopRight == null || beamBottomLeft == null) {
                  return const SizedBox.shrink();
                }

                final t = beamController.value;

                final progress = Curves.easeOut.transform(
                  (t / 0.15).clamp(0.0, 1.0),
                );

                final fade = t <= 0.15
                    ? 0.0
                    : Curves.easeOutQuart.transform(
                        ((t - 0.15) / 0.85).clamp(0.0, 1.0),
                      );

                return BeamOverlay(
                  topRightTarget: beamTopRight,
                  bottomLeftTarget: beamBottomLeft,
                  progress: progress,
                  fade: fade,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
