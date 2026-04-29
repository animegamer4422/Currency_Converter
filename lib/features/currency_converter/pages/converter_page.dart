import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:currency_converter/features/currency_converter/providers/converter_provider.dart';
import 'package:currency_converter/core/widgets/neu_container.dart';
import 'package:currency_converter/core/widgets/pressable_widget.dart';
import 'package:currency_converter/features/settings/pages/settings_page.dart';
import 'package:currency_converter/features/currency_converter/widgets/amount_input_field.dart';
import 'package:currency_converter/features/currency_converter/widgets/currency_selector_dropdown.dart';
import 'package:currency_converter/features/currency_converter/widgets/amount_history_sheet.dart';
import 'package:flutter/services.dart';
import 'package:math_expressions/math_expressions.dart' hide Stack;
import 'package:currency_converter/core/widgets/skeleton_loader.dart';
import 'package:intl/intl.dart';
import 'package:currency_converter/core/utils/number_to_words.dart';
import 'package:currency_converter/core/services/favorites_service.dart';
import 'package:auto_size_text/auto_size_text.dart';

class ConverterPage extends StatefulWidget {
  const ConverterPage({super.key});

  @override
  State<ConverterPage> createState() => _ConverterPageState();
}

class _ConverterPageState extends State<ConverterPage> {
  final TextEditingController _amountController = TextEditingController();
  final FavoritesService _favoritesService = FavoritesService();
  List<String> _amountHistory = [];
  Timer? _saveDebounce;

  static final _numberFormat = NumberFormat('#,##0.00');

  String _formatConvertedAmount(double amount) {
    String text = _numberFormat.format(amount);
    if (text.length > 21) {
      return '...${text.substring(text.length - 18)}';
    }
    return text;
  }

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<ConverterProvider>(context, listen: false);
    _amountController.text = provider.inputText;
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final history = await _favoritesService.getAmountHistory();
    if (mounted) setState(() => _amountHistory = history);
  }

  @override
  void dispose() {
    _saveDebounce?.cancel();
    _amountController.dispose();
    super.dispose();
  }

  /// Schedules a save to history after 3 seconds of no input.
  void _scheduleSave(String value, ConverterProvider provider) {
    _saveDebounce?.cancel();
    if (value.trim().isEmpty) return;
    _saveDebounce = Timer(const Duration(seconds: 3), () async {
      await _favoritesService.saveAmountToHistory(
        value,
        provider.baseCurrency?.code ?? '',
        provider.targetCurrency?.code ?? '',
      );
      _loadHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Currency Converter',
          style: Theme.of(context).appBarTheme.titleTextStyle,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Consumer<ConverterProvider>(
          builder: (context, provider, child) {
            if (provider.currencies.isEmpty && provider.isLoading) {
              return const Center(
                child: SkeletonLoader(
                  width: 200,
                  height: 200,
                  borderRadius: 32,
                ),
              );
            }

            if (provider.errorMessage != null && provider.currencies.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        provider.errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () => provider.fetchCurrencies(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              );
            }

            return Padding(
              padding: const EdgeInsets.only(
                left: 16.0,
                top: 16.0,
                right: 16.0,
                bottom: 16.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Merged Conversion Card
                  NeuContainer(
                    padding: const EdgeInsets.all(16),
                    borderRadius: 32,
                    child: Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: CurrencySelectorDropdown(
                                label: 'From',
                                selectedCurrency: provider.baseCurrency,
                                currencies: provider.currencies,
                                onChanged: (c) => provider.setBaseCurrency(c!),
                                onFavoriteToggled: provider.toggleFavorite,
                                isFavorite: provider.isFavorite,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              child: GestureDetector(
                                onTap: provider.swapCurrencies,
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isDark ? Colors.white : Colors.black,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                            (isDark
                                                    ? Colors.white
                                                    : Colors.black)
                                                .withValues(alpha: 0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.swap_horiz,
                                    color: isDark ? Colors.black : Colors.white,
                                    size: 24,
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: CurrencySelectorDropdown(
                                label: 'To',
                                selectedCurrency: provider.targetCurrency,
                                currencies: provider.currencies,
                                onChanged: (c) =>
                                    provider.setTargetCurrency(c!),
                                onFavoriteToggled: provider.toggleFavorite,
                                isFavorite: provider.isFavorite,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                AmountInputField(
                                  controller: _amountController,
                                  onChanged: (value) {
                                    provider.setInputText(value);
                                    _evaluateAmount(provider, value);
                                    _scheduleSave(value, provider);
                                  },
                                  onHistoryTap: () =>
                                      _showAmountHistory(provider),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 115,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  provider.isLoading
                                      ? const Center(
                                          child: SkeletonLoader(
                                            width: 120,
                                            height: 32,
                                          ),
                                        )
                                      : PressableWidget(
                                          onTap: () {
                                            final text = _numberFormat.format(
                                              provider.convertedAmount,
                                            );
                                            Clipboard.setData(
                                              ClipboardData(text: text),
                                            );
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'Copied "$text" to clipboard!',
                                                ),
                                                duration: const Duration(
                                                  seconds: 2,
                                                ),
                                                behavior:
                                                    SnackBarBehavior.floating,
                                              ),
                                            );
                                          },
                                          child: Container(
                                            alignment: Alignment.bottomRight,
                                            child: AutoSizeText(
                                              _formatConvertedAmount(
                                                provider.convertedAmount,
                                              ),
                                              style: TextStyle(
                                                fontSize: 32,
                                                fontWeight: FontWeight.bold,
                                                color: isDark
                                                    ? Colors.white
                                                    : Colors.black,
                                              ),
                                              textAlign: TextAlign.right,
                                              minFontSize: 14,
                                              maxLines: 1,
                                            ),
                                          ),
                                        ),
                                  if (provider.convertedAmount >= 0 &&
                                      provider.targetCurrency != null &&
                                      !provider.isLoading)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4.0),
                                      child: AutoSizeText(
                                        numberToWords(provider.convertedAmount),
                                        style: TextStyle(
                                          color: isDark
                                              ? Colors.white70
                                              : Colors.black54,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          fontStyle: FontStyle.italic,
                                        ),
                                        textAlign: TextAlign.right,
                                        minFontSize: 8,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  if (provider.currentRates != null &&
                                      provider.targetCurrency != null &&
                                      !provider.isLoading)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4.0),
                                      child: Text(
                                        '1 ${provider.baseCurrency?.code} = ${provider.currentRates!.rates[provider.targetCurrency!.code]?.toStringAsFixed(4) ?? "N/A"} ${provider.targetCurrency!.code}',
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        textAlign: TextAlign.right,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Rate Calculator Numpad
                  Expanded(flex: 1, child: _buildNumpad(provider, isDark)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _evaluateAmount(ConverterProvider provider, String value) {
    if (value.isEmpty) {
      provider.setAmount(0.0);
      return;
    }
    String sanitizedValue = value.replaceAll(',', '');
    try {
      GrammarParser p = GrammarParser();
      Expression exp = p.parse(sanitizedValue);
      ContextModel cm = ContextModel();
      double evaluatedAmount = exp.evaluate(EvaluationType.REAL, cm);
      provider.setAmount(evaluatedAmount);
    } catch (e) {
      final fallback = double.tryParse(sanitizedValue);
      if (fallback != null) {
        provider.setAmount(fallback);
      }
    }
  }

  String _formatInputExpression(String input) {
    String sanitized = input.replaceAll(',', '');
    String result = '';
    String currentNumber = '';
    for (int i = 0; i < sanitized.length; i++) {
      var char = sanitized[i];
      if (RegExp(r'[0-9.]').hasMatch(char)) {
        currentNumber += char;
      } else {
        if (currentNumber.isNotEmpty) {
          result += _formatSimpleNumber(currentNumber);
          currentNumber = '';
        }
        result += char;
      }
    }
    if (currentNumber.isNotEmpty) {
      result += _formatSimpleNumber(currentNumber);
    }
    return result;
  }

  String _formatSimpleNumber(String numStr) {
    List<String> parts = numStr.split('.');
    String intPart = parts[0];
    if (intPart.isNotEmpty) {
      intPart = intPart.replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'),
        (Match m) => ',',
      );
    }
    if (parts.length > 1) {
      return '$intPart.${parts[1]}';
    }
    return intPart;
  }

  void _onCalcBtn(String text, ConverterProvider provider) {
    String logicalText = text;
    if (text == '÷') logicalText = '/';
    if (text == '×') logicalText = '*';
    if (text == 'C') logicalText = 'AC';

    String current = _amountController.text.replaceAll(',', '');
    if (logicalText == 'AC') {
      _amountController.text = '';
      _evaluateAmount(provider, '');
    } else if (logicalText == '⌫') {
      if (current.isNotEmpty) {
        String newText = current.substring(0, current.length - 1);
        _amountController.text = _formatInputExpression(newText);
        provider.setInputText(_amountController.text);
        _evaluateAmount(provider, _amountController.text);
      }
    } else if (logicalText == '=') {
      try {
        GrammarParser p = GrammarParser();
        Expression exp = p.parse(current);
        ContextModel cm = ContextModel();
        double ev = exp.evaluate(EvaluationType.REAL, cm);
        if (ev == ev.truncateToDouble()) {
          _amountController.text = _formatInputExpression(
            ev.toInt().toString(),
          );
        } else {
          String str = ev.toStringAsFixed(4);
          str = str.replaceAll(RegExp(r'0*$'), '');
          str = str.replaceAll(RegExp(r'\.$'), '');
          _amountController.text = _formatInputExpression(str);
        }
        provider.setInputText(_amountController.text);
        provider.setAmount(ev);
        // Schedule debounce save for the evaluated result too
        _scheduleSave(_amountController.text, provider);
      } catch (e) {
        // syntax error, do nothing
      }
    } else {
      // Append text
      bool isOp = ['%', '+', '-', '*', '/'].contains(logicalText);
      if (current == '0' && logicalText != '.' && !isOp) {
        current = logicalText;
      } else {
        if (isOp && current.isNotEmpty) {
          String lastChar = current[current.length - 1];
          if (['%', '+', '-', '*', '/'].contains(lastChar)) {
            current = current.substring(0, current.length - 1) + logicalText;
          } else {
            current = current + logicalText;
          }
        } else {
          current = current + logicalText;
        }
      }
      _amountController.text = _formatInputExpression(current);
      provider.setInputText(_amountController.text);
      _evaluateAmount(provider, _amountController.text);
      _scheduleSave(_amountController.text, provider);
    }
  }

  void _showAmountHistory(ConverterProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // makes sheet full height
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return AmountHistorySheet(
          history: _amountHistory,
          provider: provider,
          onClear: () async {
            await _favoritesService.clearAmountHistory();
            await _loadHistory();
            if (ctx.mounted) Navigator.pop(ctx);
          },
          onSelect: (displayAmount, baseCode, targetCode) {
            _amountController.text = displayAmount;
            provider.setInputText(displayAmount);
            _evaluateAmount(provider, displayAmount);
            if (baseCode.isNotEmpty && targetCode.isNotEmpty) {
              final base = provider.currencies
                  .where((c) => c.code == baseCode)
                  .firstOrNull;
              final target = provider.currencies
                  .where((c) => c.code == targetCode)
                  .firstOrNull;
              if (base != null) provider.setBaseCurrency(base);
              if (target != null) provider.setTargetCurrency(target);
            }
            Navigator.pop(ctx);
          },
        );
      },
    );
  }

  Widget _buildNumpad(ConverterProvider provider, bool isDark) {
    final List<List<String>> keys = [
      ['C', '⌫', '%', '÷'],
      ['7', '8', '9', '×'],
      ['4', '5', '6', '-'],
      ['1', '2', '3', '+'],
      ['0', '.', '00', '='],
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: NeuContainer(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            borderRadius: 32,
            child: Column(
              children: keys.map((row) {
                return Expanded(
                  child: _NumpadRow(
                    row: row,
                    isDark: isDark,
                    onTap: (key) => _onCalcBtn(key, provider),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}

/// A standalone numpad bottom sheet used by the dashboard page.
/// It mirrors the converter's numpad but lives in a modal sheet.
class DashboardNumpadSheet extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onCalcBtn;

  const DashboardNumpadSheet({
    super.key,
    required this.controller,
    required this.onCalcBtn,
  });

  static const List<List<String>> _keys = [
    ['C', '⌫', '%', '÷'],
    ['7', '8', '9', '×'],
    ['4', '5', '6', '-'],
    ['1', '2', '3', '+'],
    ['0', '.', '00', '='],
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black26,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Live input display
            AnimatedBuilder(
              animation: controller,
              builder: (context, _) {
                final text = controller.text;
                return NeuContainer(
                  isPressed: true,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  borderRadius: 16,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      text.isEmpty ? '0' : text,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: text.isEmpty
                            ? (isDark ? Colors.white24 : Colors.black26)
                            : (isDark ? Colors.white : Colors.black),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            // Numpad grid
            NeuContainer(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              borderRadius: 32,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: _keys.map((row) {
                  return SizedBox(
                    height: 72,
                    child: _NumpadRow(
                      row: row,
                      isDark: isDark,
                      onTap: onCalcBtn,
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NumpadRow extends StatelessWidget {
  final List<String> row;
  final bool isDark;
  final ValueChanged<String> onTap;

  const _NumpadRow({
    required this.row,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: row.map((key) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: _NumpadButton(
                text: key,
                isDark: isDark,
                onTap: () => onTap(key),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _NumpadButton extends StatefulWidget {
  final String text;
  final bool isDark;
  final VoidCallback onTap;

  const _NumpadButton({
    required this.text,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_NumpadButton> createState() => _NumpadButtonState();
}

class _NumpadButtonState extends State<_NumpadButton>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  bool _pendingRelease = false;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  static const _minPressDuration = Duration(milliseconds: 120);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 60),
      reverseDuration: const Duration(milliseconds: 140),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.86,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _release() {
    if (!mounted) return;
    setState(() {
      _isPressed = false;
      _pendingRelease = false;
    });
    _controller.reverse();
  }

  void _handleTapDown(TapDownDetails details) {
    _pendingRelease = false;
    setState(() => _isPressed = true);
    _controller.forward();
    HapticFeedback.lightImpact();
  }

  void _handleTapUp(TapUpDetails details) {
    widget.onTap(); // fire action immediately
    _pendingRelease = true;
    Future.delayed(_minPressDuration, () {
      if (_pendingRelease) _release();
    });
  }

  void _handleTapCancel() {
    _release();
  }

  @override
  Widget build(BuildContext context) {
    bool isEquals = widget.text == '=';
    bool isOperator = ['÷', '×', '-', '+'].contains(widget.text);
    bool isAction = ['C', '⌫', '%'].contains(widget.text);
    bool isDecimal = widget.text == '.';

    Color getTextColor() {
      if (_isPressed && isOperator) return Colors.blue.shade200;
      if (_isPressed && isAction) return Colors.orange.shade300;
      if (isEquals) return Colors.white;
      if (isOperator) return Colors.blueAccent;
      if (isAction) return Colors.grey;
      return widget.isDark ? Colors.white : Colors.black;
    }

    Color? getPressFlashColor() {
      if (!_isPressed) return null;
      if (isEquals) return Colors.blue.shade300;
      if (isOperator) return Colors.blueAccent.withValues(alpha: 0.20);
      if (isAction) return Colors.orange.withValues(alpha: 0.15);
      return widget.isDark
          ? Colors.white.withValues(alpha: 0.10)
          : Colors.black.withValues(alpha: 0.07);
    }

    Color? getBgColor() {
      if (isEquals) return getPressFlashColor() ?? Colors.blueAccent;
      return getPressFlashColor();
    }

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: NeuContainer(
          borderRadius: 24,
          isPressed: _isPressed,
          color: getBgColor(),
          width: double.infinity,
          height: double.infinity,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.center,
                child: widget.text == '⌫'
                    ? Icon(
                        Icons.backspace_outlined,
                        size: 32,
                        color: getTextColor(),
                      )
                    : isDecimal
                    ? Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: getTextColor(),
                          shape: BoxShape.circle,
                        ),
                      )
                    : Text(
                        widget.text,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: widget.text == '00' ? 28 : 32,
                          fontWeight: (isOperator || isEquals)
                              ? FontWeight.bold
                              : FontWeight.w500,
                          color: getTextColor(),
                          height: 1,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
