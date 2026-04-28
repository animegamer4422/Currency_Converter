# 💱 Currency Converter

A premium, feature-rich currency conversion application built with Flutter. This app provides real-time exchange rates, interactive historical charts, and a sleek, user-friendly interface designed for both casual users and frequent travelers.

## ✨ Features

- **Real-time Conversion**: Instantly convert between 150+ world currencies with up-to-date exchange rates.
- **Interactive Dashboard**: A clean overview of your favorite currencies and recent market trends.
- **Historical Charts**: Visualize currency fluctuations over time with deep history tracking and interactive fl_charts.
- **Custom Numpad**: Optimized input experience with a custom-designed numeric keypad for faster entries.
- **Premium Tier**: Unlock advanced features including ad-free experience, unlimited history, and exclusive themes.
- **Dark & Light Modes**: Full support for system themes with a beautiful custom design system.
- **Offline Support**: Access previously fetched rates even when you're not connected to the internet.

## 🛠️ Tech Stack

- **Framework**: [Flutter](https://flutter.dev/)
- **State Management**: [Provider](https://pub.dev/packages/provider)
- **Networking**: [HTTP](https://pub.dev/packages/http)
- **Data Visualization**: [fl_chart](https://pub.dev/packages/fl_chart)
- **Local Storage**: [Shared Preferences](https://pub.dev/packages/shared_preferences)
- **Localization**: [Intl](https://pub.dev/packages/intl)

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (>= 3.10.8)
- Android Studio / VS Code
- A valid API key for the exchange rate service (configured in `lib/features/currency_converter/services/currency_api_service.dart`)

### Installation

1. **Clone the repository**:
   ```bash
   git clone https://github.com/animegamer4422/Currency_Converter.git
   ```

2. **Navigate to the project directory**:
   ```bash
   cd Currency_Converter
   ```

3. **Install dependencies**:
   ```bash
   flutter pub get
   ```

4. **Run the application**:
   ```bash
   flutter run
   ```

## 📦 Automated Releases

This project uses **GitHub Actions** to automatically build and release the Android APK. 

- Every push to the `main` branch triggers a build.
- You can find the latest compiled APK under the [Releases](https://github.com/animegamer4422/Currency_Converter/releases) section of this repository.

---
*Built with ❤️ by Hari*
