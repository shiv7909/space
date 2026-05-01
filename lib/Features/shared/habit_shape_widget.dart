import 'package:flutter/material.dart';

/// Shared widget to render a habit emoji inside a soft tinted container.
class HabitShapeWidget extends StatelessWidget {
  final String emoji;
  final double size;

  const HabitShapeWidget({super.key, required this.emoji, this.size = 18});

  @override
  Widget build(BuildContext context) {
    final containerSize = size * 1.6;
    return SizedBox(
      width: containerSize,
      height: containerSize,
      child: Center(child: Text(emoji, style: TextStyle(fontSize: size))),
    );
  }
}
