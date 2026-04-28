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
  final Color? color;

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
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final backgroundColor = color ??
        (isDark ? const Color(0xFF252525) : const Color(0xFFE0E5EC));

    final pressedBackgroundColor = color != null
        ? Color.lerp(color!, isDark ? Colors.black : Colors.grey.shade400, 0.25)!
        : (isDark ? const Color(0xFF1C1C1C) : const Color(0xFFCDD4E0));

    final darkShadow =
        isDark ? const Color(0xFF0D0D0D) : const Color(0xFFA3B1C6);
    final lightShadow =
        isDark ? const Color(0xFF333333) : const Color(0xFFFFFFFF);

    final List<BoxShadow> raisedShadows = [
      BoxShadow(
        color: darkShadow,
        offset: const Offset(5, 5),
        blurRadius: 10,
        spreadRadius: 0,
      ),
      BoxShadow(
        color: lightShadow,
        offset: const Offset(-5, -5),
        blurRadius: 10,
        spreadRadius: 0,
      ),
    ];

    // Simulate inset by flipping shadow directions + using darker bg
    final List<BoxShadow> pressedShadows = [
      BoxShadow(
        color: darkShadow.withValues(alpha: 0.9),
        offset: const Offset(2, 2),
        blurRadius: 5,
        spreadRadius: 0,
      ),
      BoxShadow(
        color: lightShadow.withValues(alpha: 0.5),
        offset: const Offset(-1, -1),
        blurRadius: 3,
        spreadRadius: 0,
      ),
    ];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 60),
      curve: Curves.easeOut,
      padding: padding,
      margin: margin,
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: isPressed ? pressedBackgroundColor : backgroundColor,
        borderRadius: shape == BoxShape.circle
            ? null
            : BorderRadius.circular(borderRadius),
        shape: shape,
        boxShadow: isPressed ? pressedShadows : raisedShadows,
      ),
      child: isPressed
          ? Transform.translate(offset: const Offset(1.5, 1.5), child: child)
          : child,
    );
  }
}
