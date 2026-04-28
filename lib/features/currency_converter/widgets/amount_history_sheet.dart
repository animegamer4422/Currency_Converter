import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:currency_converter/core/widgets/neu_container.dart';
import 'package:currency_converter/core/widgets/pressable_widget.dart';
import 'package:currency_converter/features/currency_converter/providers/converter_provider.dart';
import 'package:math_expressions/math_expressions.dart' hide Stack;

class AmountHistorySheet extends StatefulWidget {
  final List<String> history;
  final VoidCallback onClear;
  final Function(String amount, String base, String target) onSelect;
  final ConverterProvider provider;

  const AmountHistorySheet({
    super.key,
    required this.history,
    required this.onClear,
    required this.onSelect,
    required this.provider,
  });

  @override
  State<AmountHistorySheet> createState() => _AmountHistorySheetState();
}

class _AmountHistorySheetState extends State<AmountHistorySheet> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF212121) : const Color(0xFFF0F0F3);
    final textColor = isDark ? Colors.white : Colors.black;

    // Filter history based on search query
    final filteredHistory = widget.history.where((entry) {
      if (_searchQuery.trim().isEmpty) return true;

      String displayAmount = entry;
      String baseCode = '';
      String targetCode = '';

      try {
        final map = jsonDecode(entry) as Map<String, dynamic>;
        displayAmount = map['amount']?.toString() ?? '';
        baseCode = map['base']?.toString() ?? '';
        targetCode = map['target']?.toString() ?? '';
      } catch (_) {}

      final query = _searchQuery.toLowerCase().replaceAll(',', '').trim();
      final qAmount = displayAmount.toLowerCase().replaceAll(',', '').trim();

      bool isMatch = false;

      // check if query matches base or target
      if (baseCode.toLowerCase().contains(query)) isMatch = true;
      if (targetCode.toLowerCase().contains(query)) isMatch = true;

      // check if exact query string matches the math expression
      if (qAmount.contains(query)) isMatch = true;

      // evaluate math amount to get actual double value
      double actualAmount = 0.0;
      try {
        final exp = GrammarParser().parse(qAmount);
        actualAmount = exp.evaluate(EvaluationType.REAL, ContextModel());
      } catch (_) {
        actualAmount = double.tryParse(qAmount) ?? 0.0;
      }

      // try parsing the query as a number for fuzzy matching
      final queryNum = double.tryParse(query);
      if (queryNum != null && actualAmount != 0.0) {
        // fuzzy checking on the evaluated double result!
        double diff = (queryNum - actualAmount).abs();

        // Match if within 15% distance
        if (diff <= (actualAmount.abs() * 0.15)) {
          isMatch = true;
        }
        // Match if within absolute 5.0 flat (for small numbers like 10 matching 12)
        if (diff <= 5.0) {
          isMatch = true;
        }
      }

      return isMatch;
    }).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Icon(
                  Icons.history_rounded,
                  size: 24,
                  color: textColor.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 8),
                Text(
                  'Amount History',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: textColor,
                  ),
                ),
                const Spacer(),
                if (widget.history.isNotEmpty)
                  TextButton(
                    onPressed: widget.onClear,
                    child: const Text(
                      'Clear',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
              ],
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: NeuContainer(
              isPressed: true,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              borderRadius: 12,
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search history (e.g., 50, USD)...',
                  hintStyle: TextStyle(color: Colors.grey.shade500),
                  border: InputBorder.none,
                  icon: Icon(Icons.search, color: textColor.withValues(alpha: 0.5)),
                ),
                style: TextStyle(color: textColor),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),
          ),
          const Divider(),
          // List View
          Expanded(
            child: filteredHistory.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Text(
                        widget.history.isEmpty
                            ? 'No history yet.\nEnter an amount and press = to save.'
                            : 'No history found for "$_searchQuery".',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                    itemCount: filteredHistory.length,
                    itemBuilder: (ctx, i) {
                      final entry = filteredHistory[i];
                      String displayAmount = entry;
                      String baseCode = '';
                      String targetCode = '';

                      try {
                        final map = jsonDecode(entry) as Map<String, dynamic>;
                        displayAmount = map['amount']?.toString() ?? '';
                        baseCode = map['base']?.toString() ?? '';
                        targetCode = map['target']?.toString() ?? '';
                      } catch (_) {}

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: PressableWidget(
                          onTap: () {
                            widget.onSelect(
                              displayAmount,
                              baseCode,
                              targetCode,
                            );
                          },
                          child: NeuContainer(
                            padding: const EdgeInsets.all(16),
                            borderRadius: 20,
                            child: Row(
                              children: [
                                Icon(
                                  Icons.history_rounded,
                                  size: 24,
                                  color: textColor.withValues(alpha: 0.5),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        displayAmount,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                          color: textColor,
                                        ),
                                      ),
                                      if (baseCode.isNotEmpty &&
                                          targetCode.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: 4.0,
                                          ),
                                          child: Text(
                                            '$baseCode ➔ $targetCode',
                                            style: const TextStyle(
                                              color: Colors.grey,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 16,
                                  color: textColor.withValues(alpha: 0.3),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
