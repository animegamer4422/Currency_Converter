import 'package:shared_preferences/shared_preferences.dart';

class FavoritesService {
  static const String _favoritesKey = 'favorite_currencies';
  static const String _dashboardFavoritesKey = 'dashboard_favorite_currencies';
  static const String _amountHistoryKey = 'amount_history';
  static const String _dashboardAmountHistoryKey = 'dashboard_amount_history';
  static const int _maxHistoryItems = 20;

  Future<List<String>> getFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_favoritesKey) ?? [];
  }

  Future<void> toggleFavorite(String currencyCode) async {
    final prefs = await SharedPreferences.getInstance();
    final favorites = prefs.getStringList(_favoritesKey) ?? [];

    if (favorites.contains(currencyCode)) {
      favorites.remove(currencyCode);
    } else {
      favorites.add(currencyCode);
    }

    await prefs.setStringList(_favoritesKey, favorites);
  }

  Future<List<String>> getDashboardFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_dashboardFavoritesKey) ?? [];
  }

  Future<void> toggleDashboardFavorite(String currencyCode) async {
    final prefs = await SharedPreferences.getInstance();
    final favorites = prefs.getStringList(_dashboardFavoritesKey) ?? [];

    if (favorites.contains(currencyCode)) {
      favorites.remove(currencyCode);
    } else {
      favorites.add(currencyCode);
    }

    await prefs.setStringList(_dashboardFavoritesKey, favorites);
  }

  Future<List<String>> getAmountHistory({bool isDashboard = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final key = isDashboard ? _dashboardAmountHistoryKey : _amountHistoryKey;
    return prefs.getStringList(key) ?? [];
  }

  Future<void> saveAmountToHistory(
    String amount,
    String baseCode,
    String targetCode, {
    bool isDashboard = false,
  }) async {
    if (amount.trim().isEmpty) return;
    final prefs = await SharedPreferences.getInstance();

    final key = isDashboard ? _dashboardAmountHistoryKey : _amountHistoryKey;
    final history = prefs.getStringList(key) ?? [];

    // Attempt to store structured info as JSON in the list
    final String entry =
        '{"amount":"$amount", "base":"$baseCode", "target":"$targetCode"}';

    // Remove duplicate if exists, then add at front
    history.remove(entry);
    history.insert(0, entry);
    // Cap at max items
    if (history.length > _maxHistoryItems) {
      history.removeRange(_maxHistoryItems, history.length);
    }
    await prefs.setStringList(key, history);
  }

  Future<void> reorderDashboardFavorites(int oldIndex, int newIndex) async {
    final prefs = await SharedPreferences.getInstance();
    final favorites = prefs.getStringList(_dashboardFavoritesKey) ?? [];

    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = favorites.removeAt(oldIndex);
    favorites.insert(newIndex, item);

    await prefs.setStringList(_dashboardFavoritesKey, favorites);
  }

  Future<void> saveDashboardFavorites(List<String> codes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_dashboardFavoritesKey, codes);
  }

  Future<void> clearAmountHistory({bool isDashboard = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final key = isDashboard ? _dashboardAmountHistoryKey : _amountHistoryKey;
    await prefs.remove(key);
  }
}
