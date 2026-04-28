import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:currency_converter/core/widgets/neu_container.dart';
import 'package:currency_converter/core/widgets/skeleton_loader.dart';
import 'package:currency_converter/core/widgets/chart_reveal_widget.dart';
import 'package:currency_converter/features/history_chart/providers/history_provider.dart';
import 'package:currency_converter/features/currency_converter/providers/converter_provider.dart';

class DeepHistoryPage extends StatefulWidget {
  final String? baseCurrencyCode;
  final String? targetCurrencyCode;

  const DeepHistoryPage({
    super.key,
    this.baseCurrencyCode,
    this.targetCurrencyCode,
  });

  @override
  State<DeepHistoryPage> createState() => _DeepHistoryPageState();
}

class _DeepHistoryPageState extends State<DeepHistoryPage> {
  int _selectedDays = 30;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    final converterProvider = Provider.of<ConverterProvider>(
      context,
      listen: false,
    );
    final historyProvider = Provider.of<HistoryProvider>(
      context,
      listen: false,
    );

    final baseCurrencyCode =
        widget.baseCurrencyCode ?? converterProvider.baseCurrency?.code;
    final targetCurrencyCode =
        widget.targetCurrencyCode ?? converterProvider.targetCurrency?.code;

    if (baseCurrencyCode != null && targetCurrencyCode != null) {
      // Build minimal CurrencyModel-like objects: history provider just needs the code string
      final base = converterProvider.currencies.firstWhere(
        (c) => c.code == baseCurrencyCode,
        orElse: () => converterProvider.baseCurrency!,
      );
      final target = converterProvider.currencies.firstWhere(
        (c) => c.code == targetCurrencyCode,
        orElse: () => converterProvider.targetCurrency!,
      );
      historyProvider.fetchHistoricalData(base, target, days: _selectedDays);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Deep History',
          style: Theme.of(context).appBarTheme.titleTextStyle,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Consumer2<ConverterProvider, HistoryProvider>(
        builder: (context, converterProvider, historyProvider, child) {
          final baseCurrencyCode =
              widget.baseCurrencyCode ?? converterProvider.baseCurrency?.code;
          final targetCurrencyCode = widget.targetCurrencyCode ??
              converterProvider.targetCurrency?.code;
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '${baseCurrencyCode ?? '?'} to ${targetCurrencyCode ?? '?'}',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Historical Exchange Rates',
                    style: TextStyle(
                      color: isDark
                          ? Colors.grey.shade400
                          : Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // Time Selector
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final containerWidth = constraints.maxWidth;
                      final optionWidth = containerWidth / 4;

                      final int selectedIndex = _getSelectedIndex(
                        _selectedDays,
                      );

                      return NeuContainer(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        borderRadius: 16,
                        child: Stack(
                          children: [
                            AnimatedPositioned(
                              duration: const Duration(milliseconds: 350),
                              curve: Curves.easeOutCubic,
                              left: selectedIndex * optionWidth,
                              top: 0,
                              bottom: 0,
                              width: optionWidth,
                              child: Center(
                                child: Container(
                                  width: optionWidth - 12, // margin
                                  decoration: BoxDecoration(
                                    color: isDark ? Colors.white : Colors.black,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                            Row(
                              children: [
                                _buildTimeOption(7, '1W', optionWidth, isDark),
                                _buildTimeOption(30, '1M', optionWidth, isDark),
                                _buildTimeOption(90, '3M', optionWidth, isDark),
                                _buildTimeOption(
                                  365,
                                  '1Y',
                                  optionWidth,
                                  isDark,
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 48),

                  // Chart Area
                  Expanded(child: _buildChartArea(historyProvider, isDark)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  int _getSelectedIndex(int days) {
    if (days == 7) return 0;
    if (days == 30) return 1;
    if (days == 90) return 2;
    if (days == 365) return 3;
    return 1;
  }

  Widget _buildTimeOption(int days, String label, double width, bool isDark) {
    final isSelected = _selectedDays == days;
    return GestureDetector(
      onTap: () {
        if (!isSelected) {
          setState(() {
            _selectedDays = days;
          });
          _loadData();
        }
      },
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: width,
        height: 40,
        child: Center(
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 300),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              fontFamily: Theme.of(context).textTheme.bodyMedium?.fontFamily,
              color: isSelected
                  ? (isDark ? Colors.black : Colors.white)
                  : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
            ),
            child: Text(label),
          ),
        ),
      ),
    );
  }

  Widget _buildChartArea(HistoryProvider historyProvider, bool isDark) {
    if (historyProvider.isLoading && historyProvider.chartSpots.isEmpty) {
      return const SkeletonLoader(
        width: double.infinity,
        height: double.infinity,
        borderRadius: 32,
      );
    }

    if (historyProvider.errorMessage != null) {
      final isUnsupported = historyProvider.errorMessage!.contains(
        'not available',
      );
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isUnsupported ? Icons.info_outline : Icons.error_outline,
              size: 48,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Text(
                historyProvider.errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark ? Colors.white54 : Colors.black54,
                ),
              ),
            ),
            if (!isUnsupported)
              TextButton(onPressed: _loadData, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (historyProvider.chartSpots.isEmpty) {
      return Center(
        child: Text(
          'No data available for this range.',
          style: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
        ),
      );
    }

    if (historyProvider.isLoading) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(16, 32, 24, 16),
        child: SkeletonLoader(
          width: double.infinity,
          height: double.infinity,
          borderRadius: 32,
        ),
      );
    }

    return NeuContainer(
      padding: const EdgeInsets.fromLTRB(16, 32, 24, 16),
      borderRadius: 32,
      child: ChartRevealWidget(
        child: LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval:
                  ((historyProvider.maxY - historyProvider.minY) / 5).clamp(
                    0.0001,
                    double.infinity,
                  ),
              getDrawingHorizontalLine: (value) {
                return FlLine(
                  color: isDark ? Colors.white12 : Colors.black12,
                  strokeWidth: 1,
                  dashArray: [5, 5],
                );
              },
            ),
            titlesData: FlTitlesData(
              show: true,
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              bottomTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 50,
                  getTitlesWidget: (value, meta) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Text(
                        value.toStringAsFixed(3),
                        style: TextStyle(
                          color: isDark ? Colors.white54 : Colors.black54,
                          fontSize: 10,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    );
                  },
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            minX: 0,
            maxX: (historyProvider.historicalData.length - 1).toDouble(),
            minY: historyProvider.minY,
            maxY: historyProvider.maxY,
            lineBarsData: [
              LineChartBarData(
                spots: historyProvider.chartSpots,
                isCurved: false,
                color: isDark ? Colors.white : Colors.black,
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  color: (isDark ? Colors.white : Colors.black).withValues(
                    alpha: 0.1,
                  ),
                ),
              ),
            ],
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                fitInsideHorizontally: true,
                getTooltipColor: (_) =>
                    isDark ? Colors.grey.shade900 : Colors.white,
                getTooltipItems: (touchedSpots) {
                  return touchedSpots.map((LineBarSpot touchedSpot) {
                    final dateStr = historyProvider.historicalData.keys
                        .elementAt(touchedSpot.x.toInt());
                    return LineTooltipItem(
                      '$dateStr\n',
                      TextStyle(
                        color: isDark ? Colors.white70 : Colors.black87,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      children: [
                        TextSpan(
                          text: touchedSpot.y.toStringAsFixed(4),
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    );
                  }).toList();
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
