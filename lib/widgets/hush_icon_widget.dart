import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Reusable SVG icon widget with color and size overrides.
/// Wraps flutter_svg's SvgPicture.asset for a consistent API.
class HushIcon extends StatelessWidget {
  final String assetPath;
  final double size;
  final Color? color;

  const HushIcon(
    this.assetPath, {
    super.key,
    this.size = 24,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      assetPath,
      width: size,
      height: size,
      colorFilter: color != null
          ? ColorFilter.mode(color!, BlendMode.srcIn)
          : null,
    );
  }
}
