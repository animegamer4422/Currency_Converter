import 'dart:io';
import 'package:image/image.dart';

void main() {
  final bytes = File('assets/icon/app_icon.png').readAsBytesSync();
  final image = decodeImage(bytes);
  if (image != null) {
    final pixel = image.getPixel(0, 0);
    print('#${pixel.r.toInt().toRadixString(16).padLeft(2, '0')}${pixel.g.toInt().toRadixString(16).padLeft(2, '0')}${pixel.b.toInt().toRadixString(16).padLeft(2, '0')}');
  } else {
    print('Failed to decode image.');
  }
}
