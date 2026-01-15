import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';
import 'wallet_screen.dart';
import 'qr_scan_screen.dart';
import 'transaction_screen.dart';
import 'profile_screen.dart';
class ParentDashboard extends StatefulWidget {

  const ParentDashboard({super.key, this.userModel});

  final UserModel? userModel;

  @override
  State<ParentDashboard> createState() => _ParentDashboardState();
}

class _ParentDashboardState extends State<ParentDashboard> {
  final AuthService _authService = AuthService();
  int _currentIndex = 0;

  Future<void> _signOut() async {
    try {
      await _authService.signOut();
      // Navigation will be handled by AuthWrapper listening to auth state changes
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to sign out: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: IndexedStack(
          index: _currentIndex,
          children: [
            _buildDashboardTab(),
            const WalletScreen(),
            const QrScanScreen(),
            const TransactionScreen(),
            const ProfileScreen(),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        elevation: 8,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet),
            label: 'Wallet',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.qr_code_scanner),
            label: 'Scan QR',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'Transactions',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardTab() {
    return RefreshIndicator(
      onRefresh: () async {},
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with sign out button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(), // Empty space for balance
                IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: _signOut,
                  tooltip: 'Sign Out',
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Welcome Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome, ${widget.userModel?.fullName ?? 'Parent'}!',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Manage your children\'s payments and allowances',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Quick Actions Grid
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.2,
              children: [
                _buildActionCard(
                  title: 'Send Money',
                  icon: Icons.send,
                  color: Colors.green,
                  onTap: () {
                    _showFeatureDialog('Send Money');
                  },
                ),
                _buildActionCard(
                  title: 'View Transactions',
                  icon: Icons.history,
                  color: Colors.blue,
                  onTap: () {
                    _showFeatureDialog('View Transactions');
                  },
                ),
                _buildActionCard(
                  title: 'Manage Children',
                  icon: Icons.people,
                  color: Colors.orange,
                  onTap: () {
                    _showFeatureDialog('Manage Children');
                  },
                ),
                _buildActionCard(
                  title: 'Set Allowances',
                  icon: Icons.account_balance_wallet,
                  color: Colors.purple,
                  onTap: () {
                    _showFeatureDialog('Set Allowances');
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Recent Activity
            const Text(
              'Recent Activity',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const Icon(Icons.receipt, color: Colors.blue),
                title: const Text('No recent transactions'),
                subtitle: const Text('Your transaction history will appear here'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  _showFeatureDialog('Transaction History');
                },
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildActionCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 40,
                color: color,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFeatureDialog(String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$feature Feature'),
        content: Text('The $feature feature will be implemented in the next phase of development.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
