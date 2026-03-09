String numberToWords(double number) {
  if (number == 0) return 'zero';

  final int integerPart = number.truncate();
  final int fractionalPart = ((number - integerPart) * 100).round();

  String words = _convertWholeNumber(integerPart);

  if (fractionalPart > 0) {
    words += ' point ${_convertWholeNumber(fractionalPart)}';
  }

  if (words.isEmpty) return words;
  return '${words[0].toUpperCase()}${words.substring(1)}';
}

String _convertWholeNumber(int number) {
  if (number == 0) return '';

  const List<String> units = [
    '',
    'one',
    'two',
    'three',
    'four',
    'five',
    'six',
    'seven',
    'eight',
    'nine',
    'ten',
    'eleven',
    'twelve',
    'thirteen',
    'fourteen',
    'fifteen',
    'sixteen',
    'seventeen',
    'eighteen',
    'nineteen',
  ];

  const List<String> tens = [
    '',
    '',
    'twenty',
    'thirty',
    'forty',
    'fifty',
    'sixty',
    'seventy',
    'eighty',
    'ninety',
  ];

  const List<String> scales = [
    '',
    'thousand',
    'million',
    'billion',
    'trillion',
    'quadrillion',
    'quintillion',
    'sextillion',
  ];

  if (number < 20) {
    return units[number];
  }

  if (number < 100) {
    return tens[number ~/ 10] +
        (number % 10 != 0 ? ' ${units[number % 10]}' : '');
  }

  if (number < 1000) {
    return '${units[number ~/ 100]} hundred${number % 100 != 0 ? ' and ${_convertWholeNumber(number % 100)}' : ''}';
  }

  String result = '';
  int scaleIndex = 0;

  while (number > 0) {
    int chunk = number % 1000;
    if (chunk > 0) {
      String chunkWords = _convertWholeNumber(chunk);
      String scaleName = scaleIndex < scales.length ? scales[scaleIndex] : '';
      result = '$chunkWords $scaleName $result';
    }
    number ~/= 1000;
    scaleIndex++;
  }

  return result.trim();
}
