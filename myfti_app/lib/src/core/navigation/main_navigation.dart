import 'dart:ui';

import 'package:flutter/material.dart';

import '../../features/wallet/pages/home_page.dart';
import '../../features/wallet/pages/my_wallet_page.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  static const Color primaryPurple = Color(0xFF673AB7);
  static const Color backgroundColor = Color(0xFFF8F6FC);

  final List<Widget> _pages = const [
    HomePage(),
    MyWalletPage(),
  ];

  final List<IconData> _icons = [
    Icons.home_outlined,
    Icons.account_balance_wallet_outlined,
    Icons.receipt_long_outlined,
    Icons.person_outline,
  ];

  final List<String> _labels = [
    'Home',
    'Wallet',
    'History',
    'Profile',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,

      // Allow page content to extend behind the navbar
      extendBody: true,

      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),

      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 35, 16, 12),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth = constraints.maxWidth / _icons.length;

              return SizedBox(
                height: 72,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Glass Navigation Container
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(26),
                          boxShadow: [
                            BoxShadow(
                              color: primaryPurple.withValues(alpha: 0.10),
                              blurRadius: 20,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(26),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(
                              sigmaX: 18,
                              sigmaY: 18,
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.45),
                                borderRadius: BorderRadius.circular(26),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: List.generate(
                                  _icons.length,
                                  (index) {
                                    final isSelected =
                                        _currentIndex == index;

                                    return Expanded(
                                      child: InkWell(
                                        borderRadius:
                                            BorderRadius.circular(26),
                                        onTap: () {
                                          if (index < _pages.length) {
                                            setState(() {
                                              _currentIndex = index;
                                            });
                                          }
                                        },
                                        child: Padding(
                                          padding:
                                              const EdgeInsets.only(top: 23),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              // Icon for every tab
                                              SizedBox(
                                                height: 23,
                                                child: Center(
                                                  child: AnimatedOpacity(
                                                    duration: const Duration(milliseconds: 300),
                                                    curve: Curves.easeInOut,
                                                    opacity: isSelected ? 0.0 : 1.0,
                                                    child: Icon(
                                                      _icons[index],
                                                      color: Colors.grey,
                                                      size: 22,
                                                    ),
                                                  ),
                                                ),
                                              ),

                                              const SizedBox(height: 2),

                                              // Tab label
                                              Text(
                                                _labels[index],
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  height: 1.2,
                                                  fontWeight: isSelected
                                                      ? FontWeight.bold
                                                      : FontWeight.w500,
                                                  color: isSelected
                                                      ? primaryPurple
                                                      : Colors.grey.shade600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Floating Active Circle
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 350),
                      curve: Curves.easeInOutCubic,
                      left: (itemWidth * _currentIndex) +
                          (itemWidth / 2) -
                          29,
                      top: -25,
                      width: 58,
                      height: 58,
                      child: Container(
                        decoration: BoxDecoration(
                          color: primaryPurple,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 4,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: primaryPurple.withValues(alpha: 0.25),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          _icons[_currentIndex],
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
