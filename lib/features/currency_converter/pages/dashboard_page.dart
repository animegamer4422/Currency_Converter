import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:currency_converter/features/currency_converter/providers/converter_provider.dart';
import 'package:currency_converter/core/widgets/neu_container.dart';
import 'package:currency_converter/features/settings/pages/settings_page.dart';
import 'package:currency_converter/features/currency_converter/widgets/currency_selector_dropdown.dart';
import 'package:currency_converter/features/currency_converter/widgets/amount_input_field.dart';
import 'package:currency_converter/features/history_chart/pages/deep_history_page.dart';
import 'package:currency_converter/core/widgets/skeleton_loader.dart';
import 'package:currency_converter/features/currency_converter/widgets/amount_history_sheet.dart';
import 'package:math_expressions/math_expressions.dart' hide Stack;
import 'package:currency_converter/core/services/favorites_service.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late TextEditingController _amountController;
  final FavoritesService _favoritesService = FavoritesService();
  List<String> _amountHistory = [];
  Timer? _saveDebounce;

  @override
  void initState() {
    super.initState();
    // Start empty so no default value clutters the field
    _amountController = TextEditingController();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final history = await _favoritesService.getAmountHistory(isDashboard: true);
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
        isDashboard: true
      );
      _loadHistory();
    });
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
            await _favoritesService.clearAmountHistory(isDashboard: true);
            await _loadHistory();
            if (ctx.mounted) Navigator.pop(ctx);
          },
          onSelect: (displayAmount, baseCode, targetCode) {
            _amountController.text = displayAmount;
            if (displayAmount.isNotEmpty) {
              try {
                GrammarParser p = GrammarParser();
                Expression exp = p.parse(displayAmount.replaceAll(',', ''));
                ContextModel cm = ContextModel();
                double ev = exp.evaluate(EvaluationType.REAL, cm);
                provider.setAmount(ev);
              } catch (_) {}
            }
            if (baseCode.isNotEmpty && targetCode.isNotEmpty) {
              final base = provider.currencies.where((c) => c.code == baseCode).firstOrNull;
              final target = provider.currencies.where((c) => c.code == targetCode).firstOrNull;
              if (base != null) provider.setBaseCurrency(base);
              if (target != null) provider.setTargetCurrency(target);
            }
            Navigator.pop(ctx);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Multi-Currency',
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
                MaterialPageRoute(builder: (context) => const SettingsPage())
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Consumer<ConverterProvider>(
          builder: (context, provider, child) {
            if (provider.currencies.isEmpty || provider.currentRates == null) {
              return const Center(child: SkeletonLoader(width: 200, height: 200, borderRadius: 32));
            }

            final favorites = provider.currencies
                .where((c) => provider.isDashboardFavorite(c.code) && c.code != provider.baseCurrency?.code)
                .toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: NeuContainer(
                    padding: const EdgeInsets.all(24),
                    borderRadius: 32,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Base Currency',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        CurrencySelectorDropdown(
                          label: '', // Label hidden intentionally
                          selectedCurrency: provider.baseCurrency,
                          currencies: provider.currencies,
                          onChanged: (currency) => provider.setBaseCurrency(currency!),
                          onFavoriteToggled: provider.toggleDashboardFavorite,
                          isFavorite: provider.isDashboardFavorite,
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Amount to Convert',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        AmountInputField(
                          controller: _amountController,
                          onChanged: (value) {
                            if (value.isEmpty) {
                              provider.setAmount(0.0);
                              return;
                            }
                            try {
                              GrammarParser p = GrammarParser();
                              Expression exp = p.parse(value);
                              ContextModel cm = ContextModel();
                              double evaluatedAmount = exp.evaluate(EvaluationType.REAL, cm);
                              provider.setAmount(evaluatedAmount);
                            } catch (e) {
                              final fallback = double.tryParse(value);
                              if (fallback != null) {
                                provider.setAmount(fallback);
                              }
                            }
                            _scheduleSave(value, provider);
                          },
                          onHistoryTap: () => _showAmountHistory(provider),
                        ),
                      ],
                    ),
                  ),
                ),
                
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Favorites Dashboard',
                        style: TextStyle(
                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (provider.isLoading)
                        const SizedBox(
                          width: 16, height: 16,
                          child: SkeletonLoader(width: 16, height: 16, borderRadius: 8),
                        )
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                Expanded(
                  child: favorites.isEmpty
                    ? Center(
                        child: Text(
                          'Star your favorite currencies \nin the Convert tab to see them here!',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                      )
                    : ReorderableListView.builder(
                        padding: const EdgeInsets.only(left: 24.0, right: 24.0, top: 8.0, bottom: 100.0), // Extra bottom padding for floating bar
                        itemCount: favorites.length,
                        proxyDecorator: (child, index, animation) {
                          return Material(
                            color: Colors.transparent,
                            child: child,
                          );
                        },
                        onReorder: (oldIndex, newIndex) {
                          provider.reorderDashboardFavorites(oldIndex, newIndex);
                        },
                        itemBuilder: (context, index) {
                          final target = favorites[index];
                          final rate = provider.currentRates!.rates[target.code] ?? 0.0;
                          final converted = provider.amount * rate;
                          
                          final double? pctChange = provider.percentageChanges[target.code];
                          // A positive rate change means target weakened vs base (you get MORE for 1 base unit)
                          // We invert: negative pctChange = target strengthened = good = green ↑
                          final bool targetStrengthened = (pctChange ?? 0) < 0;
                          final Color changeColor = targetStrengthened ? Colors.green : Colors.red;
                          final double absPct = (pctChange ?? 0).abs();
                          final int daysDiff = provider.percentageChangeDays;
                          final String changeSign = targetStrengthened ? '+' : '-';
                          final String changeText = pctChange != null
                              ? '$changeSign${absPct.toStringAsFixed(2)}%  ${daysDiff}d'
                              : '';
                          
                          return Padding(
                            key: ValueKey(target.code),
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Dismissible(
                              key: ValueKey('dismiss_${target.code}'),
                              direction: DismissDirection.endToStart,
                              background: NeuContainer(
                                padding: const EdgeInsets.only(right: 20),
                                borderRadius: 24,
                                child: Container(
                                  alignment: Alignment.centerRight,
                                  child: const Icon(Icons.delete_outline, color: Colors.red, size: 32),
                                ),
                              ),
                              onDismissed: (_) {
                                provider.toggleDashboardFavorite(target.code);
                              },
                              child: InkWell(
                                borderRadius: BorderRadius.circular(24),
                                onLongPress: () {
                                  final text = '${converted.toStringAsFixed(2)} ${target.code}';
                                  Clipboard.setData(ClipboardData(text: text));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Copied "$text"'),
                                      duration: const Duration(seconds: 1),
                                    ),
                                  );
                                },
                                onTap: () {
                                  provider.setTargetCurrency(target);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const DeepHistoryPage()),
                                  );
                                },
                                child: NeuContainer(
                                  padding: const EdgeInsets.all(20),
                                  borderRadius: 24,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            target.code,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18,
                                              color: isDark ? Colors.white : Colors.black,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            target.name.length > 12 ? '${target.name.substring(0, 10)}...' : target.name,
                                            style: const TextStyle(color: Colors.grey),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            converted.toStringAsFixed(2),
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18,
                                              color: isDark ? Colors.white : Colors.black,
                                            ),
                                          ),
                                           if (pctChange != null)
                                             Padding(
                                               padding: const EdgeInsets.only(top: 4.0),
                                               child: Row(
                                                 mainAxisSize: MainAxisSize.min,
                                                 children: [
                                                   Icon(
                                                     targetStrengthened
                                                         ? Icons.arrow_upward_rounded
                                                         : Icons.arrow_downward_rounded,
                                                     size: 12, color: changeColor,
                                                   ),
                                                   const SizedBox(width: 2),
                                                   Text(
                                                     changeText,
                                                     style: TextStyle(
                                                       color: changeColor,
                                                       fontSize: 13,
                                                       fontWeight: FontWeight.w600,
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
                              ),
                            ),
                          );
                        },
                      ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
