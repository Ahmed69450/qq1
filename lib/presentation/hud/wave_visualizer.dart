import 'package:flutter/material.dart';

class WaveVisualizer extends StatelessWidget {
  final bool isListening;

  const WaveVisualizer({super.key, required this.isListening});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final height = isListening ? (12.0 + (index % 3) * 8.0) : 6.0;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          width: 4,
          height: height,
          decoration: BoxDecoration(
            color: Colors.cyanAccent,
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }),
    );
  }
}
