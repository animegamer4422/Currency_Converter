class ExchangeRateModel {
  final String baseCurrency;
  final String date;
  final Map<String, double> rates;

  ExchangeRateModel({
    required this.baseCurrency,
    required this.date,
    required this.rates,
  });

  factory ExchangeRateModel.fromJson(Map<String, dynamic> json) {
    return ExchangeRateModel(
      baseCurrency: json['base'],
      date: json['date'],
      rates: (json['rates'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, (value as num).toDouble()),
      ),
    );
  }
}
