import 'package:flutter/material.dart';
import 'package:currency_converter/features/currency_converter/pages/converter_page.dart';
import 'package:currency_converter/features/currency_converter/pages/dashboard_page.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final PageController _pageController = PageController(initialPage: 0);

  final List<Widget> _pages = const [
    ConverterPage(),
    DashboardPage(),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const BouncingScrollPhysics(),
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        children: _pages,
      ),
      bottomNavigationBar: _buildCustomNavBar(isDark),
    );
  }

  Widget _buildCustomNavBar(bool isDark) {
    const double barHeight = 70.0;

    return Container(
      width: double.infinity,
      height: barHeight + MediaQuery.of(context).padding.bottom,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.white10 : Colors.black12,
            width: 1.0,
          ),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNavItem(0, Icons.sync_alt, 'Convert', isDark),
            _buildNavItem(1, Icons.dashboard_outlined, 'Dashboard', isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label, bool isDark) {
    final isSelected = _currentIndex == index;
    final color = isSelected 
        ? (isDark ? Colors.white : Colors.black)
        : Colors.grey;
        
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (!isSelected) {
            _pageController.animateToPage(
              index,
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutCubic,
            );
          }
        },
        behavior: HitTestBehavior.opaque,
        child: Container(
          color: Colors.transparent, // expand gesture area 
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedTheme(
                data: Theme.of(context).copyWith(
                  iconTheme: IconThemeData(color: color, size: 26)
                ),
                child: Icon(icon),
              ),
              const SizedBox(height: 4),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 300),
                style: TextStyle(
                  color: color, 
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  fontFamily: Theme.of(context).textTheme.bodyMedium?.fontFamily,
                ),
                child: Text(label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
