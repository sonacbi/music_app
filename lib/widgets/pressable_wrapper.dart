import 'package:flutter/material.dart';

class PressableWrapper extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const PressableWrapper({
    super.key,
    required this.child,
    this.onTap,
  });

  @override
  State<PressableWrapper> createState() => _PressableWrapperState();
}

class _PressableWrapperState extends State<PressableWrapper> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) {
        setState(() => _pressed = true);
      },
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap?.call();
      },
      onTapCancel: () {
        setState(() => _pressed = false);
      },

      child: AnimatedScale(
        duration: const Duration(milliseconds: 80),
        curve: Curves.easeOut,
        scale: _pressed ? 0.95 : 1.0,

        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 80),
          opacity: _pressed ? 0.7 : 1.0,

          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: Colors.white.withOpacity(_pressed ? 0.06 : 0.0),
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}