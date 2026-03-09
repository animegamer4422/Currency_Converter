import 'package:flutter/material.dart';

class NeuContainer extends StatelessWidget {
  final Widget child;
  final bool isPressed;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final BoxShape shape;

  const NeuContainer({
    super.key,
    required this.child,
    this.isPressed = false,
    this.borderRadius = 16.0,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.shape = BoxShape.rectangle,
  });

  @override
  Widget build(BuildContext context) {

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF212121) : const Color(0xFFF0F0F3);
    final pressedBackgroundColor = isDark ? const Color(0xFF1A1A1A) : const Color(0xFFE6E6E9);
    
    final darkShadowColor = isDark ? const Color(0xFF101010) : const Color(0xFFCDCDD0);
    final lightShadowColor = isDark ? const Color(0xFF2E2E2E) : const Color(0xFFFFFFFF);

    return Container(
      padding: padding,
      margin: margin,
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: isPressed ? pressedBackgroundColor : backgroundColor,
        borderRadius: shape == BoxShape.circle ? null : BorderRadius.circular(borderRadius),
        shape: shape,
        boxShadow: isPressed
            ? [
                // Inset shadow effect (simulated via decoration tricks or just no outset for simplicity)
                // True inset shadows require inner container, but removing outset gives a pressed flat look.
                // We could use an inner shadow package, but let\'s keep it dependency free and visually pressed.
              ]
            : [
                BoxShadow(
                  color: darkShadowColor,
                  offset: const Offset(12, 12),
                  blurRadius: 24,
                  spreadRadius: 1,
                ),
                BoxShadow(
                  color: lightShadowColor,
                  offset: const Offset(-12, -12),
                  blurRadius: 24,
                  spreadRadius: 1,
                ),
              ],
      ),
      // If pressed, slightly shift the content down
      child: isPressed
          ? Transform.translate(
              offset: const Offset(2, 2),
              child: child,
            )
          : child,
    );
  }
}
