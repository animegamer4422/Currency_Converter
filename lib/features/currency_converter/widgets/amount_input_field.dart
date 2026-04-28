import 'package:flutter/material.dart';
import 'package:currency_converter/core/widgets/neu_container.dart';
import 'package:flutter/services.dart';

class AmountInputField extends StatelessWidget {
  final ValueChanged<String> onChanged;
  final TextEditingController controller;
  final VoidCallback? onHistoryTap;
  /// If provided, the field becomes read-only and this callback fires on tap.
  final VoidCallback? onTap;

  const AmountInputField({
    super.key,
    required this.onChanged,
    required this.controller,
    this.onHistoryTap,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return NeuContainer(
      isPressed: true,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      borderRadius: 16,
      child: Row(
        children: [
          Expanded(
            child: onTap != null
              ? GestureDetector(
                  onTap: onTap,
                  child: AbsorbPointer(
                    child: TextField(
                      controller: controller,
                      readOnly: true,
                      showCursor: false,
                      keyboardType: TextInputType.none,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Tap to enter amount...',
                        hintStyle: TextStyle(
                          color: isDark ? Colors.white24 : Colors.black26,
                        ),
                        contentPadding: EdgeInsets.zero,
                      ),
                      onChanged: onChanged,
                    ),
                  ),
                )
              : TextField(
                  controller: controller,
                  readOnly: false,
                  showCursor: true,
                  autofocus: true,
                  keyboardType: TextInputType.none,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9%\+\-\*\/\.]')),
                  ],
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Enter amount...',
                    hintStyle: TextStyle(
                      color: isDark ? Colors.white24 : Colors.black26,
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: onChanged,
                ),
          ),
          if (onHistoryTap != null)
            GestureDetector(
              onTap: onHistoryTap,
              child: Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Icon(
                  Icons.history_rounded,
                  size: 22,
                  color: isDark ? Colors.white54 : Colors.black38,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
