import 'package:flutter/material.dart';
import 'double_border_button.dart';
import 'pressable_wrapper.dart';

class TransportPanel extends StatelessWidget {
  final VoidCallback? onPlay;
  final VoidCallback? onPause;
  final VoidCallback? onStop;

  const TransportPanel({
    super.key,
    this.onPlay,
    this.onPause,
    this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        PressableWrapper(
          onTap: onPlay,
          child: const DoubleBorderButton(
            child: Icon(
              Icons.play_arrow,
              color: Colors.white,
              size: 40,
            ),
          ),
        ),

        const Spacer(),

        PressableWrapper(
          onTap: onPause,
          child: const DoubleBorderButton(
            child: Icon(
              Icons.pause,
              color: Colors.white,
              size: 40,
            ),
          ),
        ),

        const Spacer(),

        PressableWrapper(
          onTap: onStop,
          child: const DoubleBorderButton(
            child: Icon(
              Icons.stop,
              color: Colors.white,
              size: 40,
            ),
          ),
        ),
      ],
    );
  }
}