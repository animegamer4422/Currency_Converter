import 'package:flutter/material.dart';
import 'package:currency_converter/features/currency_converter/models/currency_model.dart';
import 'package:currency_converter/features/currency_converter/models/exchange_rate_model.dart';
import 'package:currency_converter/features/currency_converter/services/currency_api_service.dart';
import 'package:currency_converter/core/services/favorites_service.dart';

class ConverterProvider extends ChangeNotifier {
  final CurrencyApiService _apiService = CurrencyApiService();
  final FavoritesService _favoritesService = FavoritesService();

  List<CurrencyModel> currencies = [];
  List<String> favoriteCurrencyCodes = [];
  List<String> favoriteDashboardCurrencyCodes = [];
  ExchangeRateModel? currentRates;
  Map<String, double> percentageChanges = {};
  int percentageChangeDays = 0;

  CurrencyModel? baseCurrency;
  CurrencyModel? targetCurrency;
  CurrencyModel? dashboardBaseCurrency;

  double amount = 0.0;
  double convertedAmount = 0.0;

  double dashboardAmount = 0.0;
  String inputText = '';
  String dashboardInputText = '';
  ExchangeRateModel? dashboardCurrentRates;
  Map<String, double> dashboardPercentageChanges = {};
  int dashboardPercentageChangeDays = 0;

  bool isLoading = false;
  String? errorMessage;

  ConverterProvider() {
    _init();
  }

  Future<void> _init() async {
    await fetchCurrencies();
    favoriteCurrencyCodes = await _favoritesService.getFavorites();
    favoriteDashboardCurrencyCodes = await _favoritesService
        .getDashboardFavorites();
    _sortCurrencies();

    if (currencies.isNotEmpty) {
      baseCurrency = currencies.firstWhere(
        (c) => c.code == 'USD',
        orElse: () => currencies.first,
      );
      targetCurrency = currencies.firstWhere(
        (c) => c.code == 'EUR',
        orElse: () => currencies.length > 1 ? currencies[1] : currencies.first,
      );
      dashboardBaseCurrency = baseCurrency;
      await Future.wait([
        _fetchRatesForBaseCurrency(),
        _fetchRatesForDashboardBaseCurrency(),
      ]);
    }
  }

  Future<void> fetchCurrencies() async {
    _setLoading(true);
    try {
      currencies = await _apiService.getAvailableCurrencies();
      _sortCurrencies();
      errorMessage = null;
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  void _sortCurrencies() {
    currencies.sort((a, b) => a.code.compareTo(b.code));
  }

  Future<void> toggleFavorite(String code) async {
    await _favoritesService.toggleFavorite(code);
    favoriteCurrencyCodes = await _favoritesService.getFavorites();
    notifyListeners();
  }

  bool isFavorite(String code) {
    return favoriteCurrencyCodes.contains(code);
  }

  Future<void> toggleDashboardFavorite(String code) async {
    await _favoritesService.toggleDashboardFavorite(code);
    favoriteDashboardCurrencyCodes = await _favoritesService
        .getDashboardFavorites();
    notifyListeners();
  }

  Future<void> reorderDashboardFavorites(int oldIndex, int newIndex) async {
    // 1. Apply the standard ReorderableListView correction
    if (oldIndex < newIndex) newIndex -= 1;

    // 2. Update in-memory immediately so the UI never snaps back (no blink)
    final list = List<String>.from(favoriteDashboardCurrencyCodes);
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    favoriteDashboardCurrencyCodes = list;
    notifyListeners();

    // 3. Persist to disk in the background
    _favoritesService.saveDashboardFavorites(favoriteDashboardCurrencyCodes);
  }

  bool isDashboardFavorite(String code) {
    return favoriteDashboardCurrencyCodes.contains(code);
  }

  Future<void> _fetchRatesForBaseCurrency() async {
    if (baseCurrency == null) return;
    _setLoading(true);
    try {
      currentRates = await _apiService.getExchangeRates(baseCurrency!.code);
      _calculateConversion();

      // Fetch percentage changes concurrently or right after
      _apiService
          .getPercentageChanges(baseCurrency!.code)
          .then((result) {
            percentageChanges = result.$1;
            percentageChangeDays = result.$2;
            if (percentageChanges.isNotEmpty) notifyListeners();
          })
          .catchError((_) {});

      errorMessage = null;
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  void setBaseCurrency(CurrencyModel currency) {
    if (baseCurrency?.code == currency.code) return;
    baseCurrency = currency;
    _fetchRatesForBaseCurrency(); // Need new rates when base changes
  }

  void setTargetCurrency(CurrencyModel currency) {
    if (targetCurrency?.code == currency.code) return;
    targetCurrency = currency;
    _calculateConversion(); // Only need to recalculate local math
    notifyListeners();
  }

  void setAmount(double newAmount) {
    amount = newAmount;
    _calculateConversion();
    notifyListeners();
  }

  void setDashboardBaseCurrency(CurrencyModel currency) {
    if (dashboardBaseCurrency?.code == currency.code) return;
    dashboardBaseCurrency = currency;
    _fetchRatesForDashboardBaseCurrency();
  }

  void setInputText(String text) {
    inputText = text;
  }

  void setDashboardInputText(String text) {
    dashboardInputText = text;
  }

  void setDashboardAmount(double newAmount) {
    dashboardAmount = newAmount;
    notifyListeners();
  }

  Future<void> _fetchRatesForDashboardBaseCurrency() async {
    if (dashboardBaseCurrency == null) return;
    try {
      dashboardCurrentRates = await _apiService.getExchangeRates(
        dashboardBaseCurrency!.code,
      );

      _apiService
          .getPercentageChanges(dashboardBaseCurrency!.code)
          .then((result) {
            dashboardPercentageChanges = result.$1;
            dashboardPercentageChangeDays = result.$2;
            if (dashboardPercentageChanges.isNotEmpty) notifyListeners();
          })
          .catchError((_) {});
    } catch (e) {
      // Ignored explicit error message for dashboard to prevent blocking UI
    } finally {
      notifyListeners();
    }
  }

  void swapCurrencies() {
    if (baseCurrency == null || targetCurrency == null) return;
    final temp = baseCurrency;
    baseCurrency = targetCurrency;
    targetCurrency = temp;
    _fetchRatesForBaseCurrency(); // Important: Must fetch rates for the NEW base currency!
  }

  void _calculateConversion() {
    if (currentRates == null || targetCurrency == null) {
      convertedAmount = 0.0;
      return;
    }

    // If target is same as base, rate is 1.0 (some APIs don't return the base currency in the rates list)
    if (baseCurrency?.code == targetCurrency?.code) {
      convertedAmount = amount;
      return;
    }

    final rate = currentRates!.rates[targetCurrency!.code] ?? 0.0;
    convertedAmount = amount * rate;
  }

  void _setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }
}
