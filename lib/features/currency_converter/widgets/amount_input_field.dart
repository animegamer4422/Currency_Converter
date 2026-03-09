import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:currency_converter/core/widgets/neu_container.dart';
import 'package:currency_converter/core/providers/theme_provider.dart';

class AmountInputField extends StatelessWidget {
  final ValueChanged<String> onChanged;
  final TextEditingController controller;
  final VoidCallback? onHistoryTap;

  const AmountInputField({
    super.key,
    required this.onChanged,
    required this.controller,
    this.onHistoryTap,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return NeuContainer(
      isPressed: true,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      borderRadius: 16,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.text,
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
