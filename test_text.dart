import 'package:flutter/material.dart';

void main() {
  runApp(const MaterialApp(home: Scaffold(body: Center(child: TestWidget()))));
}

class TestWidget extends StatelessWidget {
  const TestWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      color: Colors.blue[100],
      child: Text(
        '\u202E82,491,111,111,111.11\u202C',
        style: TextStyle(fontSize: 20),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textDirection: TextDirection.rtl,
      ),
    );
  }
}
