import 'package:flutter/material.dart';

class MyWalletPage extends StatelessWidget {
  const MyWalletPage({super.key});

  static const Color primaryPurple = Color(0xFF673AB7);
  static const Color backgroundColor = Color(0xFFF8F6FC);
  static const Color textColor = Color(0xFF2D1B46);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          'My Wallet',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: backgroundColor,
        elevation: 0,
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Wallet Balance
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF673AB7),
                    Color(0xFF9575CD),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.account_balance_wallet_outlined,
                    color: Colors.white,
                    size: 32,
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Available Balance',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Rp 1.500.000',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'myFTI Digital Wallet',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Wallet Information
            const Text(
              'Wallet Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),

            const SizedBox(height: 12),

            Card(
              color: Colors.white,
              elevation: 0,
              child: Column(
                children: [
                  _buildInfoTile(
                    icon: Icons.credit_card,
                    title: 'Wallet ID',
                    subtitle: 'FTI2026001',
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  _buildInfoTile(
                    icon: Icons.verified_user_outlined,
                    title: 'Wallet Status',
                    subtitle: 'Active',
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  _buildInfoTile(
                    icon: Icons.account_balance_outlined,
                    title: 'Account Type',
                    subtitle: 'Student Wallet',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Quick Actions
            const Text(
              'Wallet Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.add_circle_outline,
                    label: 'Top Up',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Halaman Top Up akan segera tersedia.',
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.receipt_long_outlined,
                    label: 'History',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Halaman Transaction History akan segera tersedia.',
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFEDE7F6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: primaryPurple),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
      subtitle: Text(subtitle),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryPurple,
        side: const BorderSide(color: primaryPurple),
        padding: const EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, size: 28),
          const SizedBox(height: 8),
          Text(label),
        ],
      ),
    );
  }
}