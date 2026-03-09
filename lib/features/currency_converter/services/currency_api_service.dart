import 'dart:convert';
import 'package:currency_converter/core/network/api_client.dart';
import 'package:currency_converter/features/currency_converter/models/currency_model.dart';
import 'package:currency_converter/features/currency_converter/models/exchange_rate_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:currency_converter/core/error/exceptions.dart';

class CurrencyApiService {
  final ApiClient _apiClient;
  static const String _frankFurterBaseUrl = 'https://api.frankfurter.dev/v1';
  // open.er-api.com: free, no key, 170+ world currencies
  static const String _erApiBaseUrl = 'https://open.er-api.com/v6';

  CurrencyApiService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  Future<List<CurrencyModel>> getAvailableCurrencies() async {
    const cacheKey = 'cached_currencies_v2';
    final prefs = await SharedPreferences.getInstance();

    try {
      // Fetch all available currencies from open.er-api which gives ~170 codes
      final response = await _apiClient.get('$_erApiBaseUrl/latest/USD');
      final Map<String, dynamic> data = json.decode(response.body);

      final Map<String, dynamic> rates = data['rates'];
      // er-api doesn't provide currency names, so we merge with our local names map
      final Map<String, String> names = _currencyNames;

      final currencies = rates.keys
          .map((code) => CurrencyModel(
                code: code,
                name: names[code] ?? code,
              ))
          .toList();

      // Cache the list of codes
      final cacheData = json.encode({for (var c in currencies) c.code: c.name});
      await prefs.setString(cacheKey, cacheData);

      return currencies;
    } catch (e) {
      // Try cache first
      final cachedString = prefs.getString(cacheKey);
      if (cachedString != null) {
        final Map<String, dynamic> data = json.decode(cachedString);
        return data.entries
            .map((e) => CurrencyModel(code: e.key, name: e.value.toString()))
            .toList();
      }
      // Last resort: use Frankfurter (fewer currencies but stable)
      try {
        final response = await _apiClient.get('$_frankFurterBaseUrl/currencies');
        final Map<String, dynamic> data = json.decode(response.body);
        return data.entries
            .map((e) => CurrencyModel(code: e.key, name: e.value))
            .toList();
      } catch (_) {
        throw Exception('Failed to load currencies. Please check your internet connection.');
      }
    }
  }

  Future<ExchangeRateModel> getExchangeRates(String baseCurrency) async {
    final cacheKey = 'cached_rates_v2_$baseCurrency';
    final prefs = await SharedPreferences.getInstance();

    try {
      final response = await _apiClient.get('$_erApiBaseUrl/latest/$baseCurrency');
      final Map<String, dynamic> data = json.decode(response.body);

      final rates = (data['rates'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, (value as num).toDouble()),
      );

      final model = ExchangeRateModel(
        baseCurrency: baseCurrency,
        date: data['time_last_update_utc']?.toString() ?? '',
        rates: rates,
      );

      final cacheData = json.encode({'base': baseCurrency, 'date': model.date, 'rates': rates});
      await prefs.setString(cacheKey, cacheData);

      return model;
    } catch (e) {
      final cachedString = prefs.getString(cacheKey);
      if (cachedString != null) {
        final Map<String, dynamic> data = json.decode(cachedString);
        return ExchangeRateModel.fromJson(data);
      }
      // Fallback to Frankfurter for supported currencies
      try {
        final response = await _apiClient.get('$_frankFurterBaseUrl/latest?base=$baseCurrency');
        final Map<String, dynamic> data = json.decode(response.body);
        final rates = ExchangeRateModel.fromJson(data);
        final cacheData = json.encode(data);
        await prefs.setString(cacheKey, cacheData);
        return rates;
      } catch (_) {
        throw Exception('Failed to load exchange rates. Please check your internet connection.');
      }
    }
  }

  Future<Map<String, double>> getHistoricalRates(String baseCurrency, String targetCurrency, {int days = 30}) async {
    final endDate = DateTime.now();
    final startDate = endDate.subtract(Duration(days: days));
    
    // Format: YYYY-MM-DD
    final startStr = '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}';
    final endStr = '${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}';

    final cacheKey = 'cached_history_${baseCurrency}_${targetCurrency}_$startStr';
    final prefs = await SharedPreferences.getInstance();

    try {
      final response = await _apiClient.get('$_frankFurterBaseUrl/$startStr..$endStr?base=$baseCurrency&to=$targetCurrency');
      final Map<String, dynamic> data = json.decode(response.body);

      final Map<String, dynamic> ratesData = data['rates'];
      final Map<String, double> historicalData = {};

      // Frankfurter returns dates as keys, and then a map of currencies: "2023-01-01": {"EUR": 0.9}
      ratesData.forEach((dateString, currencyMap) {
        if (currencyMap[targetCurrency] != null) {
           historicalData[dateString] = (currencyMap[targetCurrency] as num).toDouble();
        }
      });
      
      final cacheData = json.encode(historicalData);
      await prefs.setString(cacheKey, cacheData);

      return historicalData;
    } on UnsupportedCurrencyException {
      rethrow;
    } catch (e) {
      final cachedString = prefs.getString(cacheKey);
      if (cachedString != null) {
         final Map<String, dynamic> cachedData = json.decode(cachedString);
         return cachedData.map((key, value) => MapEntry(key, (value as num).toDouble()));
      }
      throw Exception('Failed to load historical data.');
    }
  }

  Future<(Map<String, double>, int)> getPercentageChanges(String baseCurrency) async {
    final endDate = DateTime.now();
    final startDate = endDate.subtract(const Duration(days: 7));
    
    final startStr = '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}';
    final endStr = '${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}';

    final cacheKey = 'cached_pct_changes_${baseCurrency}_$startStr';
    final prefs = await SharedPreferences.getInstance();

    try {
      final response = await _apiClient.get('$_frankFurterBaseUrl/$startStr..$endStr?base=$baseCurrency');
      final Map<String, dynamic> data = json.decode(response.body);

      final Map<String, dynamic> ratesData = data['rates'];
      
      final sortedDates = ratesData.keys.toList()..sort();
      if (sortedDates.length >= 2) {
        final String latestDate = sortedDates.last;
        final String previousDate = sortedDates[sortedDates.length - 2];
        
        final Map<String, dynamic> latestRates = ratesData[latestDate];
        final Map<String, dynamic> previousRates = ratesData[previousDate];
        
        final Map<String, double> changes = {};
        
        latestRates.forEach((currency, rate) {
            final double currentRate = (rate as num).toDouble();
            final num? prevRateNum = previousRates[currency];
            if (prevRateNum != null) {
                final double previousRate = prevRateNum.toDouble();
                if (previousRate != 0) {
                    changes[currency] = ((currentRate - previousRate) / previousRate) * 100;
                }
            }
        });
        int daysDiff = DateTime.parse(latestDate).difference(DateTime.parse(previousDate)).inDays;
        if (daysDiff == 0) daysDiff = 1;
        
        final cacheData = json.encode({'changes': changes, 'days': daysDiff});
        await prefs.setString(cacheKey, cacheData);
        return (changes, daysDiff);
      }
      return (<String, double>{}, 0);
    } catch (e) {
      final cachedString = prefs.getString(cacheKey);
      if (cachedString != null) {
         final Map<String, dynamic> cachedData = json.decode(cachedString);
         if (cachedData.containsKey('changes')) {
            final Map<String, dynamic> rawChanges = cachedData['changes'];
            final int days = cachedData['days'] ?? 1;
            return (rawChanges.map((key, value) => MapEntry(key, (value as num).toDouble())), days);
         } else {
            // Fallback for old cache format
            return (cachedData.map((key, value) => MapEntry(key, (value as num).toDouble())), 1);
         }
      }
      return (<String, double>{}, 0);
    }
  }

  static const Map<String, String> _currencyNames = {
    'AED': 'UAE Dirham', 'AFN': 'Afghan Afghani', 'ALL': 'Albanian Lek',
    'AMD': 'Armenian Dram', 'ANG': 'Netherlands Antillian Guilder',
    'AOA': 'Angolan Kwanza', 'ARS': 'Argentine Peso', 'AUD': 'Australian Dollar',
    'AWG': 'Aruban Florin', 'AZN': 'Azerbaijani Manat', 'BAM': 'Bosnia-Herzegovina Mark',
    'BBD': 'Barbadian Dollar', 'BDT': 'Bangladeshi Taka', 'BGN': 'Bulgarian Lev',
    'BHD': 'Bahraini Dinar', 'BIF': 'Burundian Franc', 'BMD': 'Bermudian Dollar',
    'BND': 'Brunei Dollar', 'BOB': 'Bolivian Boliviano', 'BRL': 'Brazilian Real',
    'BSD': 'Bahamian Dollar', 'BTN': 'Bhutanese Ngultrum', 'BWP': 'Botswana Pula',
    'BYN': 'Belarusian Ruble', 'BZD': 'Belize Dollar', 'CAD': 'Canadian Dollar',
    'CDF': 'Congolese Franc', 'CHF': 'Swiss Franc', 'CLP': 'Chilean Peso',
    'CNY': 'Chinese Yuan', 'COP': 'Colombian Peso', 'CRC': 'Costa Rican Colon',
    'CUP': 'Cuban Peso', 'CVE': 'Cape Verdean Escudo', 'CZK': 'Czech Koruna',
    'DJF': 'Djiboutian Franc', 'DKK': 'Danish Krone', 'DOP': 'Dominican Peso',
    'DZD': 'Algerian Dinar', 'EGP': 'Egyptian Pound', 'ERN': 'Eritrean Nakfa',
    'ETB': 'Ethiopian Birr', 'EUR': 'Euro', 'FJD': 'Fijian Dollar',
    'FKP': 'Falkland Islands Pound', 'FOK': 'Faroese Króna', 'GBP': 'British Pound',
    'GEL': 'Georgian Lari', 'GGP': 'Guernsey Pound', 'GHS': 'Ghanaian Cedi',
    'GIP': 'Gibraltar Pound', 'GMD': 'Gambian Dalasi', 'GNF': 'Guinean Franc',
    'GTQ': 'Guatemalan Quetzal', 'GYD': 'Guyanese Dollar', 'HKD': 'Hong Kong Dollar',
    'HNL': 'Honduran Lempira', 'HRK': 'Croatian Kuna', 'HTG': 'Haitian Gourde',
    'HUF': 'Hungarian Forint', 'IDR': 'Indonesian Rupiah', 'ILS': 'Israeli Shekel',
    'IMP': 'Isle of Man Pound', 'INR': 'Indian Rupee', 'IQD': 'Iraqi Dinar',
    'IRR': 'Iranian Rial', 'ISK': 'Icelandic Króna', 'JEP': 'Jersey Pound',
    'JMD': 'Jamaican Dollar', 'JOD': 'Jordanian Dinar', 'JPY': 'Japanese Yen',
    'KES': 'Kenyan Shilling', 'KGS': 'Kyrgyzstani Som', 'KHR': 'Cambodian Riel',
    'KID': 'Kiribati Dollar', 'KMF': 'Comorian Franc', 'KRW': 'South Korean Won',
    'KWD': 'Kuwaiti Dinar', 'KYD': 'Cayman Islands Dollar', 'KZT': 'Kazakhstani Tenge',
    'LAK': 'Lao Kip', 'LBP': 'Lebanese Pound', 'LKR': 'Sri Lankan Rupee',
    'LRD': 'Liberian Dollar', 'LSL': 'Lesotho Loti', 'LYD': 'Libyan Dinar',
    'MAD': 'Moroccan Dirham', 'MDL': 'Moldovan Leu', 'MGA': 'Malagasy Ariary',
    'MKD': 'Macedonian Denar', 'MMK': 'Myanmar Kyat', 'MNT': 'Mongolian Tögrög',
    'MOP': 'Macanese Pataca', 'MRU': 'Mauritanian Ouguiya', 'MUR': 'Mauritian Rupee',
    'MVR': 'Maldivian Rufiyaa', 'MWK': 'Malawian Kwacha', 'MXN': 'Mexican Peso',
    'MYR': 'Malaysian Ringgit', 'MZN': 'Mozambican Metical', 'NAD': 'Namibian Dollar',
    'NGN': 'Nigerian Naira', 'NIO': 'Nicaraguan Córdoba', 'NOK': 'Norwegian Krone',
    'NPR': 'Nepalese Rupee', 'NZD': 'New Zealand Dollar', 'OMR': 'Omani Rial',
    'PAB': 'Panamanian Balboa', 'PEN': 'Peruvian Sol', 'PGK': 'Papua New Guinean Kina',
    'PHP': 'Philippine Peso', 'PKR': 'Pakistani Rupee', 'PLN': 'Polish Złoty',
    'PYG': 'Paraguayan Guaraní', 'QAR': 'Qatari Riyal', 'RON': 'Romanian Leu',
    'RSD': 'Serbian Dinar', 'RUB': 'Russian Ruble', 'RWF': 'Rwandan Franc',
    'SAR': 'Saudi Riyal', 'SBD': 'Solomon Islands Dollar', 'SCR': 'Seychellois Rupee',
    'SDG': 'Sudanese Pound', 'SEK': 'Swedish Krona', 'SGD': 'Singapore Dollar',
    'SHP': 'Saint Helena Pound', 'SLE': 'Sierra Leonean Leone', 'SLL': 'Sierra Leonean Leone (old)',
    'SOS': 'Somali Shilling', 'SRD': 'Surinamese Dollar', 'SSP': 'South Sudanese Pound',
    'STN': 'São Tomé & Príncipe Dobra', 'SYP': 'Syrian Pound', 'SZL': 'Swazi Lilangeni',
    'THB': 'Thai Baht', 'TJS': 'Tajikistani Somoni', 'TMT': 'Turkmenistani Manat',
    'TND': 'Tunisian Dinar', 'TOP': 'Tongan Paʻanga', 'TRY': 'Turkish Lira',
    'TTD': 'Trinidad & Tobago Dollar', 'TVD': 'Tuvaluan Dollar', 'TWD': 'New Taiwan Dollar',
    'TZS': 'Tanzanian Shilling', 'UAH': 'Ukrainian Hryvnia', 'UGX': 'Ugandan Shilling',
    'USD': 'US Dollar', 'UYU': 'Uruguayan Peso', 'UZS': 'Uzbekistani Som',
    'VES': 'Venezuelan Bolívar', 'VND': 'Vietnamese Đồng', 'VUV': 'Vanuatu Vatu',
    'WST': 'Samoan Tālā', 'XAF': 'Central African CFA Franc', 'XCD': 'East Caribbean Dollar',
    'XDR': 'IMF Special Drawing Rights', 'XOF': 'West African CFA Franc',
    'XPF': 'CFP Franc', 'YER': 'Yemeni Rial', 'ZAR': 'South African Rand',
    'ZMW': 'Zambian Kwacha', 'ZWL': 'Zimbabwean Dollar',
  };
}
