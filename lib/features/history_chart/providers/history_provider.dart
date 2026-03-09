import 'package:flutter/material.dart';
import 'package:currency_converter/features/currency_converter/services/currency_api_service.dart';
import 'package:currency_converter/features/currency_converter/models/currency_model.dart';
import 'package:currency_converter/core/error/exceptions.dart';
import 'package:fl_chart/fl_chart.dart';

class HistoryProvider extends ChangeNotifier {
  final CurrencyApiService _apiService = CurrencyApiService();

  bool isLoading = false;
  String? errorMessage;
  Map<String, double> historicalData = {};
  List<FlSpot> chartSpots = [];
  int selectedDays = 30;
  
  // Cache storage structured by "baseCode_targetCode_days"
  final Map<String, Map<String, double>> _cache = {};
  
  double minY = 0;
  double maxY = 0;

  Future<String?> fetchHistoricalData(CurrencyModel? base, CurrencyModel? target, {int days = 30}) async {
    // Clear any previous error states immediately when switching pairs
    errorMessage = null;

    if (base == null || target == null || base.code == target.code) {
      historicalData = {};
      chartSpots = [];
      notifyListeners();
      return null;
    }

    final cacheKey = '${base.code}_${target.code}_$days';

    // To prevent reloading every time we switch between dashboard and convert tab,
    // we check if it is already loaded and cached, and if so, show instantly.
    if (_cache.containsKey(cacheKey)) {
      historicalData = _cache[cacheKey]!;
      selectedDays = days;
      _prepareChartData();
      notifyListeners();
      
      // If we want to skip fetch when cached, return here:
      return null;
    }

    _setLoading(true);
    chartSpots.clear();
    try {
      historicalData = await _apiService.getHistoricalRates(base.code, target.code, days: days);
      _cache[cacheKey] = historicalData;
      selectedDays = days;
      _prepareChartData();
      errorMessage = null;
      return null;
    } on UnsupportedCurrencyException {
      errorMessage = 'Historical data is not available for this currency pair.';
      return null;
    } catch (e) {
      if (_cache.containsKey(cacheKey)) {
        // Fallback to cache if network fails but cache exists
        historicalData = _cache[cacheKey]!;
        selectedDays = days;
        _prepareChartData();
        errorMessage = null;
        return 'network_error_fallback';
      } else {
        errorMessage = 'Failed to load historical data. Please check your connection.';
        return null;
      }
    } finally {
      _setLoading(false);
    }
  }

  void _prepareChartData() {
    chartSpots.clear();
    
    if (historicalData.isEmpty) return;
    
    // Sort dates chronologically
    final sortedKeys = historicalData.keys.toList()..sort();
    
    if (sortedKeys.isEmpty) return;

    double tempMinY = historicalData[sortedKeys.first]!;
    double tempMaxY = historicalData[sortedKeys.first]!;

    for (int i = 0; i < sortedKeys.length; i++) {
      final value = historicalData[sortedKeys[i]]!;
      
      if (i > 0) {
        final double prevValue = historicalData[sortedKeys[i - 1]]!;
        // Insert intermediate points so tooltip tracker is perfectly smooth between days
        final int steps = selectedDays <= 10 ? 20 : (selectedDays <= 35 ? 10 : 2);
        for (int s = 1; s < steps; s++) {
          chartSpots.add(FlSpot((i - 1) + (s / steps), prevValue));
        }
      }
      
      chartSpots.add(FlSpot(i.toDouble(), value));
      
      if (value < tempMinY) tempMinY = value;
      if (value > tempMaxY) tempMaxY = value;
    }
    
    // Add some padding to Y axis
    final padding = (tempMaxY - tempMinY) * 0.1;
    minY = tempMinY - padding;
    maxY = tempMaxY + padding;
    
    // Safety check if min/max are exactly the same (straight line)
    if (minY == maxY) {
       minY -= 1;
       maxY += 1;
    }
  }

  void _setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }
}
