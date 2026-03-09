import 'package:flutter/material.dart';

class ChartRevealWidget extends StatelessWidget {
  final Widget child;
  
  const ChartRevealWidget({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 1200),
          curve: Curves.easeOutCubic,
          tween: Tween(begin: 0.0, end: 1.0),
          builder: (context, value, chartChild) {
            return ClipRect(
              child: Align(
                alignment: Alignment.centerLeft,
                widthFactor: value,
                child: SizedBox(
                  width: constraints.maxWidth,
                  height: constraints.maxHeight,
                  child: chartChild,
                ),
              ),
            );
          },
          child: child,
        );
      }
    );
  }
}
