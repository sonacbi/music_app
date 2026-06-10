import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class DebugPanel extends StatelessWidget {
  final String title;
  final List<String> logs;

  const DebugPanel({
    super.key,
    required this.title,
    required this.logs,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.panel,
          border: Border.all(
            color: AppColors.border,
          ),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(color: Colors.white30),
            Expanded(
              child: ListView(
                children: logs
                    .map(
                      (e) => Padding(
                        padding:
                            const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          e,
                          style: const TextStyle(
                            color: Colors.white70,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}