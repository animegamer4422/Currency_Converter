class CurrencyModel {
  final String code;
  final String name;

  CurrencyModel({required this.code, required this.name});

  factory CurrencyModel.fromJson(Map<String, dynamic> json) {
    return CurrencyModel(
      code: json.keys.first,
      name:
          json[json.keys.first], // Assuming the value is the name of the currency
    );
  }

  Map<String, dynamic> toJson() {
    return {code: name};
  }
}
