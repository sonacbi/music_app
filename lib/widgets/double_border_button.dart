import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class DoubleBorderButton extends StatelessWidget {
  final Widget child;
  final double width;
  final double height;

  const DoubleBorderButton({
    super.key,
    required this.child,
    this.width = 90,
    this.height = 90,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border, width: 2),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border, width: 1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(child: child),
      ),
    );
  }
}