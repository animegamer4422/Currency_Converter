import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:currency_converter/core/widgets/neu_container.dart';
import 'package:currency_converter/features/history_chart/providers/history_provider.dart';
import 'package:currency_converter/features/currency_converter/providers/converter_provider.dart';
import 'package:currency_converter/core/widgets/skeleton_loader.dart';
import 'package:currency_converter/core/widgets/chart_reveal_widget.dart';
import 'package:currency_converter/features/history_chart/pages/deep_history_page.dart';

class HistoricalChartWidget extends StatefulWidget {
  const HistoricalChartWidget({super.key});

  @override
  State<HistoricalChartWidget> createState() => _HistoricalChartWidgetState();
}

class _HistoricalChartWidgetState extends State<HistoricalChartWidget> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Re-fetch data whenever dependencies (ConverterProvider) change
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchData();
    });
  }

  void _fetchData() async {
    final converterProvider = Provider.of<ConverterProvider>(
      context,
      listen: false,
    );
    final historyProvider = Provider.of<HistoryProvider>(
      context,
      listen: false,
    );

    if (converterProvider.baseCurrency != null &&
        converterProvider.targetCurrency != null) {
      final errorResult = await historyProvider.fetchHistoricalData(
        converterProvider.baseCurrency,
        converterProvider.targetCurrency,
        days: historyProvider
            .selectedDays, // Persist whatever was picked in Deep Search
      );

      if (errorResult == 'network_error_fallback' && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Network error. Showing previously cached data.'),
            duration: Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to changes in ConverterProvider to refetch chart data if currencies change
    return Consumer2<ConverterProvider, HistoryProvider>(
      builder: (context, converterProvider, historyProvider, child) {
        // This is a bit of a hack to trigger a refetch when currencies change,
        // but it works for this simple use case without complex listeners.
        // A better approach in a larger app would be to use a ProxyProvider or
        // a dedicated orchestration layer.

        if (historyProvider.isLoading && historyProvider.chartSpots.isEmpty) {
          return const Padding(
            padding: EdgeInsets.only(top: 8.0),
            child: SkeletonLoader(
              width: double.infinity,
              height: 250,
              borderRadius: 32,
            ),
          );
        }

        if (historyProvider.errorMessage != null) {
          final isUnsupported = historyProvider.errorMessage!.contains(
            'not available',
          );
          return SizedBox(
            height: 200,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isUnsupported ? Icons.info_outline : Icons.error_outline,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Text(
                      historyProvider.errorMessage!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isUnsupported
                            ? Colors.grey
                            : Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                  if (!isUnsupported)
                    TextButton(
                      onPressed: _fetchData,
                      child: const Text('Retry'),
                    ),
                ],
              ),
            ),
          );
        }

        if (historyProvider.chartSpots.isEmpty) {
          return const SizedBox(
            height: 200,
            child: Center(
              child: Text(
                'No historical data available for this pair.',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          );
        }

        if (historyProvider.isLoading) {
          return const SizedBox(
            height: 200,
            child: SkeletonLoader(
              width: double.infinity,
              height: double.infinity,
              borderRadius: 32,
            ),
          );
        }

        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 8.0, bottom: 24.0),
              child: Text(
                'Past ${historyProvider.selectedDays} Days (${converterProvider.baseCurrency?.code} to ${converterProvider.targetCurrency?.code})',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DeepHistoryPage(),
                  ),
                );
              },
              child: NeuContainer(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                borderRadius: 32,
                child: SizedBox(
                  height: 220,
                  width: double.infinity,
                  child: ChartRevealWidget(
                    child: LineChart(
                      LineChartData(
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval:
                              ((historyProvider.maxY - historyProvider.minY) /
                                      4)
                                  .clamp(0.0001, double.infinity),
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
                          ), // Hide x-axis labels to save space
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 46,
                              getTitlesWidget: (value, meta) {
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: Text(
                                    value.toStringAsFixed(3),
                                    style: TextStyle(
                                      color: isDark
                                          ? Colors.white54
                                          : Colors.black54,
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
                        maxX: (historyProvider.historicalData.length - 1)
                            .toDouble(),
                        minY: historyProvider.minY,
                        maxY: historyProvider.maxY,
                        lineBarsData: [
                          LineChartBarData(
                            spots: historyProvider.chartSpots,
                            isCurved: false,
                            color: Theme.of(context).colorScheme.primary,
                            barWidth: 3,
                            isStrokeCapRound: true,
                            dotData: const FlDotData(show: false),
                            belowBarData: BarAreaData(
                              show: true,
                              color: Theme.of(
                                context,
                              ).colorScheme.primary.withValues(alpha: 0.15),
                            ),
                          ),
                        ],
                        lineTouchData: LineTouchData(
                          touchTooltipData: LineTouchTooltipData(
                            getTooltipColor: (touchedSpot) =>
                                isDark ? Colors.grey.shade800 : Colors.white,
                            getTooltipItems: (touchedSpots) {
                              return touchedSpots.map((
                                LineBarSpot touchedSpot,
                              ) {
                                final dateStr = historyProvider
                                    .historicalData
                                    .keys
                                    .elementAt(touchedSpot.x.toInt());
                                return LineTooltipItem(
                                  '$dateStr\n',
                                  TextStyle(
                                    color: isDark
                                        ? Colors.white70
                                        : Colors.black87,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: touchedSpot.y.toStringAsFixed(4),
                                      style: TextStyle(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
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
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
