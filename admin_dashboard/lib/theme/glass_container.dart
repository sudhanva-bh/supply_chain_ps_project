import 'dart:ui';
import 'package:flutter/material.dart';
import 'app_theme.dart';

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final Color? color;
  final BorderRadius? borderRadius;
  final Border? border;

  const GlassContainer({
    super.key,
    required this.child,
    this.blur = 10.0,
    this.opacity = 0.6,
    this.color,
    this.borderRadius,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          decoration: BoxDecoration(
            color: (color ?? AppTheme.surface).withOpacity(opacity),
            borderRadius: borderRadius,
            border: border ?? Border.all(color: AppTheme.dividerColor.withOpacity(0.5)),
          ),
          child: child,
        ),
      ),
    );
  }
}
