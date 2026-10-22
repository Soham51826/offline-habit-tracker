import 'dart:ui';
import 'package:flutter/material.dart';

/// A reusable frosted glassmorphic container with backdrop blur, subtle borders,
/// and optional ambient neon glow.
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double blur;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderWidth;
  final Color? glowColor;
  final double glowRadius;
  final VoidCallback? onTap;

  const GlassContainer({
    super.key,
    required this.child,
    this.blur = 12.0,
    this.borderRadius = 20.0,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth = 1.0,
    this.glowColor,
    this.glowRadius = 0.0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final defaultBg = isDark
        ? const Color(0xFF141C2E).withValues(alpha: 0.72)
        : Colors.white.withValues(alpha: 0.85);

    final defaultBorder = isDark
        ? const Color(0xFF26334D).withValues(alpha: 0.65)
        : const Color(0xFFE2E8F0).withValues(alpha: 0.9);

    final containerDecoration = BoxDecoration(
      color: backgroundColor ?? defaultBg,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: borderColor ?? defaultBorder,
        width: borderWidth,
      ),
      boxShadow: glowRadius > 0 && glowColor != null
          ? [
              BoxShadow(
                color: glowColor!.withValues(alpha: 0.25),
                blurRadius: glowRadius,
                spreadRadius: 1,
              ),
            ]
          : null,
    );

    Widget content = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding ?? const EdgeInsets.all(16),
          decoration: containerDecoration,
          child: child,
        ),
      ),
    );

    if (margin != null) {
      content = Padding(padding: margin!, child: content);
    }

    if (onTap != null) {
      content = Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(borderRadius),
        child: InkWell(
          borderRadius: BorderRadius.circular(borderRadius),
          onTap: onTap,
          child: content,
        ),
      );
    }

    return content;
  }
}
