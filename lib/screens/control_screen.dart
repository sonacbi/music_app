import 'package:flutter/material.dart';
import 'dart:math';

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
  bool gamepadActive = false;

  bool get isConnected =>
      bluetoothService.currentStatus == BluetoothStatus.connected;

  @override
  void initState() {
    super.initState();

    beamController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2), // 충분히 길게
    );
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

  @override
  void dispose() {
    beamController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                              connected: gamepadActive,
                              onTap: () {
                                setState(() {
                                  gamepadActive = !gamepadActive;
                                });

                                triggerBeam(gamepadButtonKey);
                              },
                            ),
                          ],
                        );
                      },
                    ),
                    const Spacer(),

                    MusicVisualizer(
                      state: isConnected ? transportState : TransportState.stop,
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
                          children: const [
                            DebugPanel(
                              title: "Arduino TX",
                              logs: ["NOTE:C4", "NOTE:E4", "NOTE:G4"],
                            ),
                            SizedBox(width: 20),
                            DebugPanel(
                              title: "Gamepad RX",
                              logs: ["BTN_A", "BTN_B", "BTN_X"],
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
    );
  }
}
