import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:currency_converter/core/providers/theme_provider.dart';
import 'package:currency_converter/core/widgets/neu_container.dart';
import 'package:currency_converter/core/widgets/pressable_widget.dart';
import 'package:currency_converter/features/settings/widgets/premium_upgrade_widget.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final mutedColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Settings',
          style: Theme.of(context).appBarTheme.titleTextStyle,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              NeuContainer(
                padding: const EdgeInsets.all(18),
                borderRadius: 28,
                child: Column(
                  children: [
                    NeuContainer(
                      isPressed: true,
                      borderRadius: 18,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Center(
                        child: Text(
                          'Theme',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _ThemeModePicker(
                      selectedMode: themeProvider.themeMode,
                      onChanged: themeProvider.setThemeMode,
                      textColor: textColor,
                      mutedColor: mutedColor,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              const PremiumUpgradeWidget(),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemeModePicker extends StatelessWidget {
  final ThemeMode selectedMode;
  final ValueChanged<ThemeMode> onChanged;
  final Color textColor;
  final Color mutedColor;

  const _ThemeModePicker({
    required this.selectedMode,
    required this.onChanged,
    required this.textColor,
    required this.mutedColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ThemeModeButton(
            mode: ThemeMode.light,
            icon: Icons.light_mode_outlined,
            label: 'Light',
            selectedMode: selectedMode,
            onChanged: onChanged,
            textColor: textColor,
            mutedColor: mutedColor,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ThemeModeButton(
            mode: ThemeMode.system,
            icon: Icons.brightness_auto_outlined,
            label: 'System',
            selectedMode: selectedMode,
            onChanged: onChanged,
            textColor: textColor,
            mutedColor: mutedColor,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ThemeModeButton(
            mode: ThemeMode.dark,
            icon: Icons.dark_mode_outlined,
            label: 'Dark',
            selectedMode: selectedMode,
            onChanged: onChanged,
            textColor: textColor,
            mutedColor: mutedColor,
          ),
        ),
      ],
    );
  }
}

class _ThemeModeButton extends StatelessWidget {
  final ThemeMode mode;
  final IconData icon;
  final String label;
  final ThemeMode selectedMode;
  final ValueChanged<ThemeMode> onChanged;
  final Color textColor;
  final Color mutedColor;

  const _ThemeModeButton({
    required this.mode,
    required this.icon,
    required this.label,
    required this.selectedMode,
    required this.onChanged,
    required this.textColor,
    required this.mutedColor,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = mode == selectedMode;

    return PressableWidget(
      onTap: () => onChanged(mode),
      child: NeuContainer(
        height: 88,
        borderRadius: 20,
        isPressed: isSelected,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? textColor : mutedColor, size: 24),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                maxLines: 1,
                style: TextStyle(
                  color: isSelected ? textColor : mutedColor,
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
