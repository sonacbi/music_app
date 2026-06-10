import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'double_border_button.dart';
import 'pressable_wrapper.dart';

class DeviceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool connected;
  final GlobalKey buttonKey;
  final VoidCallback? onTap;

  const DeviceCard({
    super.key,
    required this.icon,
    required this.title,
    required this.connected,
    required this.buttonKey,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        PressableWrapper(
          onTap: onTap,
          child: DoubleBorderButton(
            key: buttonKey,
            width: 120,
            height: 120,
            child: Icon(
              icon,
              color: Colors.white,
              size: 42,
            ),
          ),
        ),

        const SizedBox(height: 10),

        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
          ),
        ),

        const SizedBox(height: 4),

        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.circle,
              size: 10,
              color: connected
                  ? AppColors.connected
                  : AppColors.disconnected,
            ),
            const SizedBox(width: 6),
            Text(
              connected ? "Connected" : "Disconnected",
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ],
    );
  }
}