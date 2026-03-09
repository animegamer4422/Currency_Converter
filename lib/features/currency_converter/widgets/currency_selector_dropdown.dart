import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:currency_converter/features/currency_converter/models/currency_model.dart';
import 'package:currency_converter/core/widgets/neu_container.dart';
import 'package:currency_converter/core/providers/theme_provider.dart';

class CurrencySelectorDropdown extends StatelessWidget {
  final CurrencyModel? selectedCurrency;
  final List<CurrencyModel> currencies;
  final ValueChanged<CurrencyModel?> onChanged;
  final String label;
  final Future<void> Function(String) onFavoriteToggled;
  final bool Function(String) isFavorite;

  const CurrencySelectorDropdown({
    super.key,
    required this.selectedCurrency,
    required this.currencies,
    required this.onChanged,
    required this.label,
    required this.onFavoriteToggled,
    required this.isFavorite,
  });

  void _showCurrencyPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return CurrencySearchSheet(
          currencies: currencies,
          selectedCurrency: selectedCurrency,
          onChanged: onChanged,
          onFavoriteToggled: onFavoriteToggled,
          isFavorite: isFavorite,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty) ...[
          Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
        ],
        GestureDetector(
          onTap: () => _showCurrencyPicker(context),
          child: NeuContainer(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            borderRadius: 12,
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        selectedCurrency?.code ?? '...',
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // We hide the full name if we don't have enough horizontal space
                      // So we use a Flexible to let it optionally drop out
                      Flexible(
                        child: Text(
                          selectedCurrency?.name ?? 'Select Currency',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class CurrencySearchSheet extends StatefulWidget {
  final List<CurrencyModel> currencies;
  final CurrencyModel? selectedCurrency;
  final ValueChanged<CurrencyModel?> onChanged;
  final Future<void> Function(String) onFavoriteToggled;
  final bool Function(String) isFavorite;

  const CurrencySearchSheet({
    required this.currencies,
    required this.selectedCurrency,
    required this.onChanged,
    required this.onFavoriteToggled,
    required this.isFavorite,
  });

  @override
  State<CurrencySearchSheet> createState() => _CurrencySearchSheetState();
}

class _CurrencySearchSheetState extends State<CurrencySearchSheet> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF212121) : const Color(0xFFF0F0F3);
    final textColor = isDark ? Colors.white : Colors.black;

    final filteredCurrencies =
        widget.currencies.where((c) {
          final query = _searchQuery.toLowerCase();
          return c.code.toLowerCase().contains(query) ||
              c.name.toLowerCase().contains(query);
        }).toList()..sort((a, b) {
          final aIsFav = widget.isFavorite(a.code);
          final bIsFav = widget.isFavorite(b.code);
          if (aIsFav && !bIsFav) return -1;
          if (!aIsFav && bIsFav) return 1;
          return a.code.compareTo(b.code);
        });

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: NeuContainer(
              isPressed: true,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              borderRadius: 12,
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search currencies...',
                  hintStyle: TextStyle(color: Colors.grey.shade500),
                  border: InputBorder.none,
                  icon: Icon(Icons.search, color: textColor.withOpacity(0.5)),
                ),
                style: TextStyle(color: textColor),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),
          ),
          const Divider(),
          // List View
          Expanded(
            child: ListView.builder(
              itemCount: filteredCurrencies.length,
              itemBuilder: (context, index) {
                final currency = filteredCurrencies[index];
                final isFav = widget.isFavorite(currency.code);

                return ListTile(
                  title: Row(
                    children: [
                      Text(
                        currency.code,
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          currency.name,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: Icon(
                      isFav ? Icons.star : Icons.star_border,
                      color: isFav
                          ? (isDark ? Colors.white : Colors.black)
                          : Colors.grey,
                      size: 24,
                    ),
                    onPressed: () async {
                      await widget.onFavoriteToggled(currency.code);
                      if (mounted) setState(() {});
                    },
                  ),
                  onTap: () {
                    widget.onChanged(currency);
                    Navigator.of(context).pop();
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
