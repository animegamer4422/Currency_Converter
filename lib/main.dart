import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:currency_converter/features/home/pages/main_screen.dart';
import 'package:currency_converter/features/currency_converter/providers/converter_provider.dart';
import 'package:currency_converter/core/providers/theme_provider.dart';
import 'package:currency_converter/core/theme/app_themes.dart';
import 'package:currency_converter/features/history_chart/providers/history_provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ConverterProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => HistoryProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Currency Converter',
          debugShowCheckedModeBanner: false,
          themeMode: themeProvider.themeMode,
          theme: AppThemes.lightTheme,
          darkTheme: AppThemes.darkTheme,
          home: const MainScreen(),
        );
      },
    );
  }
}
