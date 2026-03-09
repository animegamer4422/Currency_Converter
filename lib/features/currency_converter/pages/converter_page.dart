import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:currency_converter/features/currency_converter/providers/converter_provider.dart';
import 'package:currency_converter/core/providers/theme_provider.dart';
import 'package:currency_converter/core/widgets/neu_container.dart';
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
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
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
                  Expanded(
                    child: NeuContainer(
                      padding: const EdgeInsets.all(16),
                      borderRadius: 32,
                      child: SingleChildScrollView(
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
                                    onChanged: (c) =>
                                        provider.setBaseCurrency(c!),
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
                                        color: isDark
                                            ? Colors.white
                                            : Colors.black,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                (isDark
                                                        ? Colors.white
                                                        : Colors.black)
                                                    .withOpacity(0.3),
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Icon(
                                        Icons.swap_horiz,
                                        color: isDark
                                            ? Colors.black
                                            : Colors.white,
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Amount',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
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
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    const Text(
                                      'Converted',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    provider.isLoading
                                        ? const SizedBox(
                                            height: 48,
                                            child: Center(
                                              child: SkeletonLoader(
                                                width: 120,
                                                height: 32,
                                              ),
                                            ),
                                          )
                                        : InkWell(
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                            onTap: () {
                                              final text =
                                                  NumberFormat(
                                                    '#,##0.00',
                                                  ).format(
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
                                            child: SizedBox(
                                              width: double.infinity,
                                              height:
                                                  48, // Fixed height to prevent shifting
                                              child: FittedBox(
                                                fit: BoxFit.scaleDown,
                                                alignment:
                                                    Alignment.centerRight,
                                                child: Text(
                                                  NumberFormat(
                                                    '#,##0.00',
                                                  ).format(
                                                    provider.convertedAmount,
                                                  ),
                                                  style: TextStyle(
                                                    fontSize: 32,
                                                    fontWeight: FontWeight.bold,
                                                    color: isDark
                                                        ? Colors.white
                                                        : Colors.black,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                    if (provider.convertedAmount > 0 &&
                                        provider.targetCurrency != null &&
                                        !provider.isLoading)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          top: 4.0,
                                        ),
                                        child: Text(
                                          numberToWords(
                                            provider.convertedAmount,
                                          ),
                                          style: TextStyle(
                                            color: isDark
                                                ? Colors.white70
                                                : Colors.black54,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            fontStyle: FontStyle.italic,
                                          ),
                                          textAlign: TextAlign.right,
                                        ),
                                      ),
                                    if (provider.currentRates != null &&
                                        provider.targetCurrency != null &&
                                        !provider.isLoading)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          top: 4.0,
                                        ),
                                        child: Text(
                                          '1 ${provider.baseCurrency?.code} = ${provider.currentRates!.rates[provider.targetCurrency!.code]?.toStringAsFixed(4) ?? "N/A"}',
                                          style: const TextStyle(
                                            color: Colors.grey,
                                            fontSize: 10,
                                          ),
                                          textAlign: TextAlign.right,
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Rate Calculator Numpad
                  Expanded(child: _buildNumpad(provider, isDark)),
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
    String current = _amountController.text.replaceAll(',', '');
    if (text == 'AC') {
      _amountController.text = '';
      _evaluateAmount(provider, '');
    } else if (text == '⌫') {
      if (current.isNotEmpty) {
        String newText = current.substring(0, current.length - 1);
        _amountController.text = _formatInputExpression(newText);
        provider.setInputText(_amountController.text);
        _evaluateAmount(provider, _amountController.text);
      }
    } else if (text == '=') {
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
      bool isOp = ['%', '+', '-', '*', '/'].contains(text);
      if (current == '0' && text != '.' && !isOp) {
        current = text;
      } else {
        if (isOp && current.isNotEmpty) {
          String lastChar = current[current.length - 1];
          if (['%', '+', '-', '*', '/'].contains(lastChar)) {
            current = current.substring(0, current.length - 1) + text;
          } else {
            current = current + text;
          }
        } else {
          current = current + text;
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
      ['7', '8', '9', '%', '⌫'],
      ['4', '5', '6', '+', '-'],
      ['1', '2', '3', '*', '/'],
      ['00', '0', '.', '=', 'AC'],
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Rate Calculator',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: NeuContainer(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            borderRadius: 32,
            child: Column(
              children: keys.map((row) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: row.map((key) {
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: _NumpadButton(
                              text: key,
                              isDark: isDark,
                              onTap: () => _onCalcBtn(key, provider),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
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
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.9,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _controller.reverse();
    widget.onTap();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    bool isOp = ['%', '⌫', '+', '-', '*', '/', '=', 'AC'].contains(widget.text);
    bool isTextSized = [
      '%',
      '⌫',
      '+',
      '-',
      '*',
      '/',
      '=',
      'AC',
      '00',
      '.',
    ].contains(widget.text);

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: NeuContainer(
          borderRadius: 24,
          isPressed: _isPressed,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: widget.text == '⌫'
                  ? Icon(
                      Icons.backspace_rounded,
                      size: 28,
                      color: widget.isDark ? Colors.white : Colors.black,
                    )
                  : Text(
                      widget.text,
                      style: TextStyle(
                        fontSize: isTextSized && widget.text == '00' ? 24 : 32,
                        fontWeight: isOp ? FontWeight.bold : FontWeight.w500,
                        color: widget.isDark ? Colors.white : Colors.black,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
