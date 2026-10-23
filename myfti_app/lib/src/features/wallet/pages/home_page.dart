import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static const Color primaryPurple = Color(0xFF673AB7);
  static const Color backgroundColor = Color(0xFFF8F6FC);
  static const Color textColor = Color(0xFF2D1B46);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: Color(0xFFEDE7F6),
                    child: Icon(
                      Icons.person,
                      color: primaryPurple,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome back,',
                          style: TextStyle(color: Colors.grey),
                        ),
                        Text(
                          'Mahasiswa FTI!',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(
                      Icons.notifications_none,
                      color: primaryPurple,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // Balance Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: primaryPurple,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Balance',
                      style: TextStyle(color: Colors.white70),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Rp 1.500.000',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 20),
                    Row(
                      children: [
                        Icon(
                          Icons.account_balance_wallet_outlined,
                          color: Colors.white,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'myFTI Wallet',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Quick Actions
              const Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildAction(
                    icon: Icons.add_circle_outline,
                    label: 'Top Up',
                    onTap: () {},
                  ),
                  _buildAction(
                    icon: Icons.send_outlined,
                    label: 'Transfer',
                    onTap: () {},
                  ),
                  _buildAction(
                    icon: Icons.payment_outlined,
                    label: 'Payment',
                    onTap: () {},
                  ),
                  _buildAction(
                    icon: Icons.account_balance_outlined,
                    label: 'Withdraw',
                    onTap: () {},
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // Recent Transactions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recent Transactions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text(
                      'See All',
                      style: TextStyle(color: primaryPurple),
                    ),
                  ),
                ],
              ),

              _buildTransaction(
                icon: Icons.add_circle_outline,
                title: 'Top Up',
                date: 'Today, 10:30',
                amount: '+ Rp 200.000',
                isIncome: true,
              ),
              _buildTransaction(
                icon: Icons.payment_outlined,
                title: 'Payment',
                date: 'Yesterday, 14:20',
                amount: '- Rp 50.000',
                isIncome: false,
              ),
              _buildTransaction(
                icon: Icons.send_outlined,
                title: 'Transfer',
                date: '20 Oct 2026, 09:15',
                amount: '- Rp 100.000',
                isIncome: false,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Quick Action Widget
  Widget _buildAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        width: 72,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: const Color(0xFFEDE7F6),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                color: primaryPurple,
                size: 26,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Transaction Item Widget
  Widget _buildTransaction({
    required IconData icon,
    required String title,
    required String date,
    required String amount,
    required bool isIncome,
  }) {
    return Card(
      color: Colors.white,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFEDE7F6),
          child: Icon(
            icon,
            color: primaryPurple,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        subtitle: Text(date),
        trailing: Text(
          amount,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isIncome ? Colors.green : Colors.redAccent,
          ),
        ),
      ),
    );
  }
}