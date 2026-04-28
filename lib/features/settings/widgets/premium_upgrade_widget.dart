import 'package:flutter/material.dart';
import 'package:currency_converter/core/widgets/neu_container.dart';

class PremiumUpgradeWidget extends StatelessWidget {
  const PremiumUpgradeWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtitleColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    return NeuContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.workspace_premium,
                color: Colors.amber.shade600,
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Currency Converter Pro',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Unlock all premium features',
                      style: TextStyle(color: subtitleColor, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildFeatureItem(
            Icons.currency_bitcoin,
            'Crypto Conversions',
            subtitleColor,
          ),
          _buildFeatureItem(
            Icons.edit_note,
            'Create Custom Named Currencies',
            subtitleColor,
          ),
          _buildFeatureItem(
            Icons.auto_graph,
            'Unlimited Historical Charts',
            subtitleColor,
          ),
          _buildFeatureItem(
            Icons.notifications_active,
            'Price Alerts & Offline Mode',
            subtitleColor,
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Premium upgrade coming soon!')),
              );
            },
            child: NeuContainer(
              padding: const EdgeInsets.symmetric(vertical: 16),
              isPressed: false,
              child: Center(
                child: Text(
                  'Upgrade to Premium',
                  style: TextStyle(
                    color: isDark
                        ? Colors.amber.shade400
                        : Colors.amber.shade700,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String text, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.amber.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
