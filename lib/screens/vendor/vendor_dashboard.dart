import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../parent/wallet_screen.dart';
import '../parent/qr_scan_screen.dart';
import '../parent/transaction_screen.dart';
import '../parent/profile_screen.dart';

class VendorDashboard extends StatefulWidget {
  const VendorDashboard({super.key, this.userName});

  final String? userName;

  @override
  State<VendorDashboard> createState() => _VendorDashboardState();
}

class _VendorDashboardState extends State<VendorDashboard> {
  final AuthService _authService = AuthService();
  int _currentIndex = 0;

  Future<void> _signOut() async {
    await _authService.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('Vendor Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildDashboardTab(),
          const WalletScreen(),
          const QrScanScreen(),
          const TransactionScreen(),
          const ProfileScreen(),
        ],
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
            // Welcome Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome, ${widget.userName ?? 'Vendor'}!',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Manage your business and receive payments',
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
              'Business Tools',
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
                  title: 'Receive Payment',
                  icon: Icons.payment,
                  color: Colors.green,
                  onTap: () {
                    _showFeatureDialog('Receive Payment');
                  },
                ),
                _buildActionCard(
                  title: 'Sales Report',
                  icon: Icons.analytics,
                  color: Colors.blue,
                  onTap: () {
                    _showFeatureDialog('Sales Report');
                  },
                ),
                _buildActionCard(
                  title: 'Manage Products',
                  icon: Icons.inventory,
                  color: Colors.orange,
                  onTap: () {
                    _showFeatureDialog('Manage Products');
                  },
                ),
                _buildActionCard(
                  title: 'Business Profile',
                  icon: Icons.store,
                  color: Colors.purple,
                  onTap: () {
                    _showFeatureDialog('Business Profile');
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Recent Activity
            const Text(
              'Recent Transactions',
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
                subtitle: const Text('Your payment history will appear here'),
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

  Widget _buildWalletTab() {
    return const WalletScreen();
  }

  Widget _buildScanQRTab() {
    return const QrScanScreen();
  }

  Widget _buildTransactionsTab() {
    return const TransactionScreen();
  }

  Widget _buildProfileTab() {
    return const ProfileScreen();
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
