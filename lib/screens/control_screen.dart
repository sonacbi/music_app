import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../widgets/debug_panel.dart';
import '../widgets/device_card.dart';
import '../widgets/transport_panel.dart';

class ControlScreen extends StatefulWidget {
  const ControlScreen({super.key});

  @override
  State<ControlScreen> createState() => _ControlScreenState();
}

class _ControlScreenState extends State<ControlScreen> {
  bool debugMode = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.backgroundTop,
              AppColors.backgroundBottom,
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
                  mainAxisAlignment:
                      MainAxisAlignment.spaceEvenly,
                  children: [
                    DeviceCard(
                      icon: Icons.memory,
                      title: "Arduino",
                      connected: true,
                      onTap: () {},
                    ),
                    DeviceCard(
                      icon: Icons.sports_esports,
                      title: "Gamepad",
                      connected: false,
                      onTap: () {},
                    ),
                  ],
                ),

                const Spacer(),

                const TransportPanel(),

                const Spacer(),

                SwitchListTile(
                  title: const Text(
                    "Debug Mode",
                    style: TextStyle(color: Colors.white),
                  ),
                  value: debugMode,
                  onChanged: (value) {
                    setState(() {
                      debugMode = value;
                    });
                  },
                ),

                if (debugMode)
                  Expanded(
                    flex: 2,
                    child: Row(
                      children: [
                        DebugPanel(
                          title: "Arduino TX",
                          logs: const [
                            "NOTE:C4",
                            "NOTE:E4",
                            "NOTE:G4",
                          ],
                        ),
                        const SizedBox(width: 20),
                        DebugPanel(
                          title: "Gamepad RX",
                          logs: const [
                            "BTN_A",
                            "BTN_B",
                            "BTN_X",
                          ],
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}