import 'package:flutter/material.dart';
import 'dart:math';

import '../theme/app_colors.dart';
import '../widgets/debug_panel.dart';
import '../widgets/device_card.dart';
import '../widgets/transport_panel.dart';
import '../widgets/beam_overlay.dart';
import '../widgets/music_visualizer.dart';

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

  final renderBox =
      targetKey.currentContext!.findRenderObject() as RenderBox;

  final overlayBox =
      Overlay.of(context).context.findRenderObject() as RenderBox;

  final local = overlayBox.globalToLocal(
    renderBox.localToGlobal(Offset.zero),
  );

  final size = renderBox.size;

  // 0.5px~1.5px 미세 보정 (Flutter subpixel rounding 대응)
  const double yFix = -2; // 세부 조정

  beamTopRight = Offset(
    local.dx + size.width,
    local.dy + yFix,
  );

  beamBottomLeft = Offset(
    local.dx,
    local.dy + size.height + yFix,
  );

  setState(() {});

  beamController
    ..reset()
    ..forward();
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
                colors: [
                  AppColors.backgroundTop,
                  AppColors.backgroundBottom
                ],
              ),
            ),

            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  children: [
                    const SizedBox(height: 20),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        DeviceCard(
                          buttonKey: arduinoButtonKey,
                          icon: Icons.memory,
                          title: "Arduino",
                          connected: true,
                          onTap: () => triggerBeam(arduinoButtonKey),
                        ),
                        DeviceCard(
                          buttonKey: gamepadButtonKey,
                          icon: Icons.sports_esports,
                          title: "Gamepad",
                          connected: false,
                          onTap: () => triggerBeam(gamepadButtonKey),
                        ),
                      ],
                    ),
                    const Spacer(),

                    MusicVisualizer(state: transportState),

                    const Spacer(),
                    TransportPanel(
                        onPlay: () {
                            setState(() => transportState = TransportState.play);
                        },
                        onPause: () {
                            setState(() => transportState = TransportState.pause);
                        },
                        onStop: () {
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