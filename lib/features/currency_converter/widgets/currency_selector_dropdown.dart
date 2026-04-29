import 'package:flutter/material.dart';
import 'package:currency_converter/features/currency_converter/models/currency_model.dart';
import 'package:currency_converter/core/widgets/neu_container.dart';
import 'package:currency_converter/core/widgets/pressable_widget.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mutedColor = isDark ? Colors.white60 : Colors.black54;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (label.isNotEmpty) ...[
          Center(
            child: Transform.translate(
              offset: const Offset(-3, 0),
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
        PressableWidget(
          onTap: () => _showCurrencyPicker(context),
          child: NeuContainer(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            borderRadius: 12,
            child: Row(
              children: [
                Expanded(
                  child: Center(
                    child: Text(
                      selectedCurrency?.code ?? '...',
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                    ),
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: mutedColor,
                  size: 24,
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
    super.key,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final textColor = isDark ? Colors.white : Colors.black;
    final mutedColor = isDark ? Colors.white60 : Colors.black54;
    final selectedColor = isDark ? Colors.white : Colors.black;

    final query = _searchQuery.toLowerCase().trim();
    final filteredCurrencies =
        widget.currencies.where((currency) {
          return currency.code.toLowerCase().contains(query) ||
              currency.name.toLowerCase().contains(query);
        }).toList()..sort((a, b) {
          final aIsFav = widget.isFavorite(a.code);
          final bIsFav = widget.isFavorite(b.code);
          if (aIsFav && !bIsFav) return -1;
          if (!aIsFav && bIsFav) return 1;

          final aIsSelected = a.code == widget.selectedCurrency?.code;
          final bIsSelected = b.code == widget.selectedCurrency?.code;
          if (aIsSelected && !bIsSelected) return -1;
          if (!aIsSelected && bIsSelected) return 1;

          return a.code.compareTo(b.code);
        });

    return SafeArea(
      top: false,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.84,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 10),
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: (isDark ? Colors.white : Colors.black).withValues(
                    alpha: 0.18,
                  ),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: _CurrencyPickerHeader(
                selectedCurrency: widget.selectedCurrency,
                textColor: textColor,
                mutedColor: mutedColor,
                selectedColor: selectedColor,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: NeuContainer(
                isPressed: true,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                borderRadius: 16,
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search currencies',
                    hintStyle: TextStyle(color: mutedColor),
                    border: InputBorder.none,
                    icon: Icon(Icons.search_rounded, color: mutedColor),
                  ),
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                  ),
                  onChanged: (value) {
                    setState(() => _searchQuery = value);
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text(
                    query.isEmpty ? 'All currencies' : 'Search results',
                    style: TextStyle(
                      color: mutedColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${filteredCurrencies.length}',
                    style: TextStyle(
                      color: mutedColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: filteredCurrencies.isEmpty
                  ? Center(
                      child: Text(
                        'No currencies found',
                        style: TextStyle(
                          color: mutedColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                      itemCount: filteredCurrencies.length,
                      itemBuilder: (context, index) {
                        final currency = filteredCurrencies[index];
                        final isFav = widget.isFavorite(currency.code);
                        final isSelected =
                            currency.code == widget.selectedCurrency?.code;

                        return _CurrencyListItem(
                          currency: currency,
                          isFavorite: isFav,
                          isSelected: isSelected,
                          textColor: textColor,
                          mutedColor: mutedColor,
                          selectedColor: selectedColor,
                          onTap: () => _selectCurrency(currency),
                          onFavoriteToggled: () async {
                            await widget.onFavoriteToggled(currency.code);
                            if (mounted) setState(() {});
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectCurrency(CurrencyModel currency) async {
    await Future.delayed(const Duration(milliseconds: 140));
    if (!mounted) return;

    widget.onChanged(currency);
    Navigator.of(context).pop();
  }
}

class _CurrencyPickerHeader extends StatelessWidget {
  final CurrencyModel? selectedCurrency;
  final Color textColor;
  final Color mutedColor;
  final Color selectedColor;

  const _CurrencyPickerHeader({
    required this.selectedCurrency,
    required this.textColor,
    required this.mutedColor,
    required this.selectedColor,
  });

  @override
  Widget build(BuildContext context) {
    return NeuContainer(
      padding: const EdgeInsets.all(16),
      borderRadius: 24,
      child: Row(
        children: [
          Container(
            width: 60,
            height: 54,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selectedColor.withValues(alpha: 0.08),
              shape: BoxShape.circle,
              border: Border.all(color: selectedColor.withValues(alpha: 0.18)),
            ),
            child: Text(
              _currencyInitials(selectedCurrency?.code),
              style: TextStyle(
                color: selectedColor,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selected currency',
                  style: TextStyle(
                    color: mutedColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  selectedCurrency?.code ?? 'Choose currency',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (selectedCurrency != null)
                  Text(
                    selectedCurrency!.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: mutedColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CurrencyListItem extends StatelessWidget {
  final CurrencyModel currency;
  final bool isFavorite;
  final bool isSelected;
  final Color textColor;
  final Color mutedColor;
  final Color selectedColor;
  final VoidCallback onTap;
  final Future<void> Function() onFavoriteToggled;

  const _CurrencyListItem({
    required this.currency,
    required this.isFavorite,
    required this.isSelected,
    required this.textColor,
    required this.mutedColor,
    required this.selectedColor,
    required this.onTap,
    required this.onFavoriteToggled,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: PressableWidget(
        onTap: onTap,
        child: NeuContainer(
          isPressed: false,
          padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
          borderRadius: 18,
          child: Row(
            children: [
              Container(
                width: 50,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: mutedColor.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                  border: Border.all(color: mutedColor.withValues(alpha: 0.12)),
                ),
                child: Text(
                  _currencyInitials(currency.code),
                  style: TextStyle(
                    color: textColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          currency.code,
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.w900,
                            fontSize: 17,
                          ),
                        ),
                        if (isSelected) ...[
                          const SizedBox(width: 8),
                          Icon(
                            Icons.check_circle_rounded,
                            color: selectedColor.withValues(alpha: 0.72),
                            size: 16,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      currency.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: mutedColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: isFavorite ? 'Remove favorite' : 'Add favorite',
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 160),
                  child: Icon(
                    isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
                    key: ValueKey(isFavorite),
                    color: isFavorite ? selectedColor : mutedColor,
                    size: 26,
                  ),
                ),
                onPressed: onFavoriteToggled,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _currencyInitials(String? code) {
  if (code == null || code.isEmpty) return '..';
  return code.length <= 3 ? code : code.substring(0, 3);
}
