import 'package:http/http.dart' as http;
import 'package:currency_converter/core/error/exceptions.dart';

class ApiClient {
  final http.Client _client;

  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  Future<http.Response> get(String url) async {
    try {
      final response = await _client.get(Uri.parse(url));

      if (response.statusCode == 200) {
        return response;
      } else if (response.statusCode == 404) {
        throw UnsupportedCurrencyException(
          'Historical data is not available for this currency pair.',
        );
      } else {
        throw ServerException(
          'Failed to load data. Status Code: ${response.statusCode}',
        );
      }
    } on UnsupportedCurrencyException {
      rethrow;
    } on ServerException {
      rethrow;
    } catch (e) {
      // Catch socket errors (like no internet connection)
      throw ServerException('Network Error. Please check your connection.');
    }
  }
}
