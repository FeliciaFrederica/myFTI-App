import 'dart:ui';

import 'package:flutter/material.dart';

import '../../features/authentication/pages/profile_page.dart';
import '../../features/merchant/pages/merchant_home_page.dart';
import '../../features/merchant/pages/merchant_profile_page.dart';
import '../../features/merchant/pages/merchant_transaction_history_page.dart';
import '../../features/transaction/pages/transaction_history_page.dart';
import '../../features/wallet/pages/my_wallet_page.dart';
import '../../features/wallet/pages/home_page.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key, this.isMerchant = false});

  final bool isMerchant;

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  static const Color _primaryPurple = Color(0xFF673AB7);
  static const Color _backgroundColor = Color(0xFFF8F6FC);

  final GlobalKey<MyWalletPageState> _walletKey =
      GlobalKey<MyWalletPageState>();

  int _currentIndex = 0;
  double _pageOpacity = 1;

  late final List<Widget> _pages = widget.isMerchant
      ? [
          MerchantHomePage(
            onProfileTap: () => _switchTab(3),
            onHistoryTap: (_) => _switchTab(2),
          ),
          MyWalletPage(
            key: _walletKey,
            readOnly: true,
            onHistoryTap: () => _switchTab(2),
          ),
          const MerchantTransactionHistoryPage(),
          const MerchantProfilePage(),
        ]
      : [
          HomePage(onProfileTap: () => _switchTab(3)),
          MyWalletPage(key: _walletKey, onHistoryTap: () => _switchTab(2)),
          TransactionHistoryPage(),
          ProfilePage(),
        ];

  static const List<IconData> _icons = [
    Icons.home_outlined,
    Icons.account_balance_wallet_outlined,
    Icons.receipt_long_outlined,
    Icons.person_outline,
  ];

  static const List<String> _labels = [
    'Beranda',
    'Dompet',
    'Riwayat',
    'Profil',
  ];

  void _switchTab(int index) {
    if (index < 0 || index >= _pages.length || index == _currentIndex) {
      return;
    }

    if (index == 1) {
      _walletKey.currentState?.hideBalance();
    }

    setState(() => _pageOpacity = 0);

    Future.delayed(const Duration(milliseconds: 100), () {
      if (!mounted) return;

      setState(() {
        _currentIndex = index;
        _pageOpacity = 1;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      extendBody: true,
      body: AnimatedOpacity(
        opacity: _pageOpacity,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        child: IndexedStack(index: _currentIndex, children: _pages),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.only(top: 30),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth = constraints.maxWidth / _icons.length;

              return SizedBox(
                height: 85,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(24),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _primaryPurple.withValues(alpha: 0.10),
                              blurRadius: 20,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(24),
                          ),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFEDE7F6)
                                    .withValues(alpha: 0.45),
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(24),
                                ),
                                border: Border.all(
                                  color: const Color(0xFFD1C4E9)
                                      .withValues(alpha: 0.65),
                                ),
                              ),
                              child: Row(
                                children: List.generate(_icons.length, (index) {
                                  final isSelected = _currentIndex == index;

                                  return Expanded(
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(26),
                                      onTap: () => _switchTab(index),
                                      child: Padding(
                                        padding: const EdgeInsets.only(top: 2),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            SizedBox(
                                              height: 23,
                                              child: Center(
                                                child: AnimatedOpacity(
                                                  duration: const Duration(
                                                    milliseconds: 300,
                                                  ),
                                                  curve: Curves.easeInOut,
                                                  opacity: isSelected ? 0 : 1,
                                                  child: Icon(
                                                    _icons[index],
                                                    color: Colors.grey,
                                                    size: 22,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              _labels[index],
                                              style: TextStyle(
                                                fontSize: 11,
                                                height: 1.2,
                                                fontWeight: isSelected
                                                    ? FontWeight.bold
                                                    : FontWeight.w500,
                                                color: isSelected
                                                    ? _primaryPurple
                                                    : Colors.grey.shade600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 350),
                      curve: Curves.easeInOutCubic,
                      left: (itemWidth * _currentIndex) + (itemWidth / 2) - 29,
                      top: -25,
                      width: 58,
                      height: 58,
                      child: Container(
                        decoration: BoxDecoration(
                          color: _primaryPurple,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                          boxShadow: [
                            BoxShadow(
                              color: _primaryPurple.withValues(alpha: 0.25),
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
