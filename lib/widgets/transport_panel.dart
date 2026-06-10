import 'package:flutter/material.dart';
import 'double_border_button.dart';

class TransportPanel extends StatelessWidget {
  const TransportPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        DoubleBorderButton(
          onTap: () {},
          child: const Icon(
            Icons.play_arrow,
            color: Colors.white,
            size: 40,
          ),
        ),
        const SizedBox(width: 30),
        DoubleBorderButton(
          onTap: () {},
          child: const Icon(
            Icons.pause,
            color: Colors.white,
            size: 40,
          ),
        ),
        const SizedBox(width: 30),
        DoubleBorderButton(
          onTap: () {},
          child: const Icon(
            Icons.stop,
            color: Colors.white,
            size: 40,
          ),
        ),
      ],
    );
  }
}