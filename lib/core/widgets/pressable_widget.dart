import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A reusable pressable wrapper that gives any child a tactile feel:
/// - Haptic feedback on tap-down
/// - Scale + NeuContainer depth animation
/// - Guaranteed minimum press duration so the effect is always visible
class PressableWidget extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Duration minPressDuration;
  final double scaleEnd;

  const PressableWidget({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.minPressDuration = const Duration(milliseconds: 120),
    this.scaleEnd = 0.94,
  });

  @override
  State<PressableWidget> createState() => _PressableWidgetState();
}

class _PressableWidgetState extends State<PressableWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _pendingRelease = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 60),
      reverseDuration: const Duration(milliseconds: 140),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: widget.scaleEnd).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _release() {
    if (!mounted) return;
    setState(() => _pendingRelease = false);
    _controller.reverse();
  }

  void _handleTapDown(TapDownDetails _) {
    _pendingRelease = false;
    _controller.forward();
    HapticFeedback.lightImpact();
  }

  void _handleTapUp(TapUpDetails _) {
    widget.onTap?.call();
    _pendingRelease = true;
    Future.delayed(widget.minPressDuration, () {
      if (_pendingRelease) _release();
    });
  }

  void _handleTapCancel() {
    _release();
  }

  void _handleLongPress() {
    widget.onLongPress?.call();
    HapticFeedback.mediumImpact();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: widget.onTap != null ? _handleTapDown : null,
      onTapUp: widget.onTap != null ? _handleTapUp : null,
      onTapCancel: widget.onTap != null ? _handleTapCancel : null,
      onLongPress: widget.onLongPress != null ? _handleLongPress : null,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.child,
      ),
    );
  }
}
