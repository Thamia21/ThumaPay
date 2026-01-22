import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import 'pos_screen.dart';
import 'digital_services_screen.dart';
import 'customer_services_screen.dart';
import 'product_management_screen.dart';
import 'sales_reports_screen.dart';
import 'wallet_settlements_screen.dart';
import 'business_profile_screen.dart';
import 'security_screen.dart';

class VendorDashboard extends StatefulWidget {
  const VendorDashboard({super.key, this.userName});

  final String? userName;

  @override
  State<VendorDashboard> createState() => _VendorDashboardState();
}

class _DashboardOverview extends StatelessWidget {
  const _DashboardOverview();

  @override
  Widget build(BuildContext context) {
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
                    const Text(
                      'Welcome to ThumaPay Vendor!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Manage your business and receive payments securely',
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
                  title: 'POS - Receive Payment',
                  icon: Icons.payment,
                  color: Colors.green,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const PosScreen()),
                  ),
                ),
                _buildActionCard(
                  title: 'Sales Reports',
                  icon: Icons.analytics,
                  color: Colors.blue,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const SalesReportsScreen()),
                  ),
                ),
                _buildActionCard(
                  title: 'Product Management',
                  icon: Icons.inventory,
                  color: Colors.orange,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const ProductManagementScreen()),
                  ),
                ),
                _buildActionCard(
                  title: 'Business Profile',
                  icon: Icons.store,
                  color: Colors.purple,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const BusinessProfileScreen()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Recent Activity
            const Text(
              'Quick Stats',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Icon(Icons.bar_chart, size: 48, color: Colors.blue),
                    const SizedBox(height: 8),
                    const Text(
                      'Business Analytics',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'View detailed reports and analytics in the Sales & Reports section',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
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
}

class _VendorDashboardState extends State<VendorDashboard> {
  final AuthService _authService = AuthService();
  Widget _currentScreen = const _DashboardOverview();
  int _selectedIndex = 0;

  Future<void> _signOut() async {
    await _authService.signOut();
  }

  void _navigateToScreen(Widget screen) {
    setState(() {
      _currentScreen = screen;
    });
    Navigator.of(context).pop(); // Close drawer
  }

  void _onBottomNavTap(int index) {
    setState(() {
      _selectedIndex = index;
    });
    switch (index) {
      case 0:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const CustomerServicesScreen()),
        );
        break;
      case 1:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const PosScreen()),
        );
        break;
      case 2:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ProductManagementScreen()),
        );
        break;
      case 3:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const WalletSettlementsScreen()),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
      drawer: _buildDrawer(),
      body: _currentScreen,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onBottomNavTap,
        backgroundColor: Colors.blue,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.qr_code_scanner),
            label: 'Scan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.payment),
            label: 'POS',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory),
            label: 'Products',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet),
            label: 'Wallet',
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.business, size: 30, color: Colors.blue),
                ),
                const SizedBox(height: 10),
                Text(
                  'Welcome, ${widget.userName ?? 'Vendor'}!',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'Manage your business',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          _buildDrawerItem(
            icon: Icons.dashboard,
            title: 'Dashboard',
            onTap: () =>
                setState(() => _currentScreen = const _DashboardOverview()),
          ),
          _buildDrawerItem(
            icon: Icons.payment,
            title: 'POS - Receive Payment',
            onTap: () => _navigateToScreen(const PosScreen()),
          ),
          _buildDrawerItem(
            icon: Icons.phone_android,
            title: 'Digital Services',
            onTap: () => _navigateToScreen(const DigitalServicesScreen()),
          ),
          _buildDrawerItem(
            icon: Icons.people,
            title: 'Customer Services',
            onTap: () => _navigateToScreen(const CustomerServicesScreen()),
          ),
          _buildDrawerItem(
            icon: Icons.inventory,
            title: 'Product Management',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) => const ProductManagementScreen()),
            ),
          ),
          _buildDrawerItem(
            icon: Icons.analytics,
            title: 'Sales & Reports',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SalesReportsScreen()),
            ),
          ),
          _buildDrawerItem(
            icon: Icons.account_balance_wallet,
            title: 'Wallet & Settlements',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) => const WalletSettlementsScreen()),
            ),
          ),
          _buildDrawerItem(
            icon: Icons.store,
            title: 'Business Profile',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const BusinessProfileScreen()),
            ),
          ),
          _buildDrawerItem(
            icon: Icons.security,
            title: 'Security & Child Protection',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SecurityScreen()),
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Sign Out'),
            onTap: _signOut,
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: onTap,
    );
  }
}
