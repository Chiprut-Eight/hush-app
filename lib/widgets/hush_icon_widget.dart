import 'package:flutter/material.dart';

/// Reusable icon widget.
/// Now wraps Phosphor IconData to maintain consistent abstraction across the app.
class HushIcon extends StatelessWidget {
  final IconData icon;
  final double size;
  final Color? color;

  const HushIcon(
    this.icon, {
    super.key,
    this.size = 24,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Icon(
      icon,
      size: size,
      color: color,
    );
  }
}
