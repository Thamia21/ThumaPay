import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  UserModel? _userData;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = _authService.currentUser;
    if (user != null) {
      try {
        final userData = await _authService.getUserData(user.uid);
        if (mounted) {
          setState(() {
            _userData = userData;
          });
        }
      } catch (e) {
        debugPrint('Error loading user data: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _editProfile,
            icon: const Icon(Icons.edit),
            tooltip: 'Edit Profile',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileHeader(user),
            const SizedBox(height: 24),
            _buildSection('Account Settings', _buildAccountSettings()),
            const SizedBox(height: 24),
            _buildSection('Security', _buildSecuritySettings()),
            const SizedBox(height: 24),
            _buildSection('Preferences', _buildPreferences()),
            const SizedBox(height: 24),
            _buildSection('Support', _buildSupportOptions()),
            const SizedBox(height: 24),
            _buildDangerZone(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(user) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.blue.shade100,
                  child: Icon(
                    Icons.person,
                    size: 40,
                    color: Colors.blue.shade700,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _userData?.fullName ?? user?.displayName ?? 'User Name',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _userData?.email ?? user?.email ?? 'user@example.com',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Verified',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard('Total Transactions', '156'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard('Member Since', 'Jan 2024'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildAccountSettings() {
    return [
      _buildListTile(
        icon: Icons.person_outline,
        title: 'Personal Information',
        subtitle: 'Update your personal details',
        onTap: _showPersonalInfo,
      ),
      const Divider(height: 1),
      _buildListTile(
        icon: Icons.payment,
        title: 'Payment Methods',
        subtitle: 'Manage your payment options',
        onTap: _showPaymentMethods,
      ),
      const Divider(height: 1),
      _buildListTile(
        icon: Icons.account_balance_wallet_outlined,
        title: 'Wallet Settings',
        subtitle: 'Configure wallet preferences',
        onTap: _showWalletSettings,
      ),
      const Divider(height: 1),
      _buildListTile(
        icon: Icons.notifications_outlined,
        title: 'Notifications',
        subtitle: 'Manage notification preferences',
        onTap: _showNotificationSettings,
      ),
    ];
  }

  List<Widget> _buildSecuritySettings() {
    return [
      _buildListTile(
        icon: Icons.lock_outline,
        title: 'Change Password',
        subtitle: 'Update your password',
        onTap: _changePassword,
      ),
      const Divider(height: 1),
      _buildListTile(
        icon: Icons.fingerprint,
        title: 'Biometric Authentication',
        subtitle: 'Enable fingerprint/Face ID',
        onTap: _setupBiometric,
      ),
      const Divider(height: 1),
      _buildListTile(
        icon: Icons.phonelink_lock,
        title: 'Two-Factor Authentication',
        subtitle: 'Add an extra layer of security',
        onTap: _setup2FA,
      ),
    ];
  }

  List<Widget> _buildPreferences() {
    return [
      _buildListTile(
        icon: Icons.language,
        title: 'Language',
        subtitle: 'English',
        onTap: _changeLanguage,
      ),
      const Divider(height: 1),
      _buildListTile(
        icon: Icons.dark_mode_outlined,
        title: 'Dark Mode',
        subtitle: 'Off',
        onTap: _toggleDarkMode,
      ),
      const Divider(height: 1),
      _buildListTile(
        icon: Icons.currency_exchange,
        title: 'Currency',
        subtitle: 'South African Rand (ZAR)',
        onTap: _changeCurrency,
      ),
    ];
  }

  List<Widget> _buildSupportOptions() {
    return [
      _buildListTile(
        icon: Icons.help_outline,
        title: 'Help Center',
        subtitle: 'Get help and support',
        onTap: _openHelpCenter,
      ),
      const Divider(height: 1),
      _buildListTile(
        icon: Icons.contact_support_outlined,
        title: 'Contact Support',
        subtitle: 'Reach out to our team',
        onTap: _contactSupport,
      ),
      const Divider(height: 1),
      _buildListTile(
        icon: Icons.privacy_tip_outlined,
        title: 'Privacy Policy',
        subtitle: 'Read our privacy policy',
        onTap: _showPrivacyPolicy,
      ),
      const Divider(height: 1),
      _buildListTile(
        icon: Icons.description_outlined,
        title: 'Terms of Service',
        subtitle: 'Read our terms and conditions',
        onTap: _showTermsOfService,
      ),
    ];
  }

  Widget _buildDangerZone() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Danger Zone',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          color: Colors.red.shade50,
          child: Column(
            children: [
              _buildListTile(
                icon: Icons.logout,
                title: 'Sign Out',
                subtitle: 'Sign out of your account',
                onTap: _signOut,
                iconColor: Colors.red,
              ),
              const Divider(height: 1),
              _buildListTile(
                icon: Icons.delete_forever,
                title: 'Delete Account',
                subtitle: 'Permanently delete your account',
                onTap: _deleteAccount,
                iconColor: Colors.red,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: iconColor ?? Colors.blue,
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  void _editProfile() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit profile feature coming soon!')),
    );
  }

  void _showPersonalInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Personal Information'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Name: User Name'),
            SizedBox(height: 8),
            Text('Email: user@example.com'),
            SizedBox(height: 8),
            Text('Phone: +27 12 345 6789'),
            SizedBox(height: 8),
            Text('Date of Birth: 01 Jan 1990'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showPaymentMethods() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Payment methods feature coming soon!')),
    );
  }

  void _showWalletSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Wallet settings feature coming soon!')),
    );
  }

  void _showNotificationSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Notification settings feature coming soon!')),
    );
  }

  void _changePassword() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Current Password',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'New Password',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Confirm New Password',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Update Password'),
          ),
        ],
      ),
    );
  }

  void _setupBiometric() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Biometric authentication feature coming soon!')),
    );
  }

  void _setup2FA() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('2FA setup feature coming soon!')),
    );
  }

  void _changeLanguage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Language settings feature coming soon!')),
    );
  }

  void _toggleDarkMode() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Dark mode feature coming soon!')),
    );
  }

  void _changeCurrency() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Currency settings feature coming soon!')),
    );
  }

  void _openHelpCenter() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Help center feature coming soon!')),
    );
  }

  void _contactSupport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Contact support feature coming soon!')),
    );
  }

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: const SingleChildScrollView(
          child: Text(
            'Your privacy is important to us. This policy explains how we collect, use, and protect your information...\n\n'
            '1. Information Collection\n'
            '2. Information Usage\n'
            '3. Information Protection\n'
            '4. User Rights\n'
            '5. Policy Updates',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showTermsOfService() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terms of Service'),
        content: const SingleChildScrollView(
          child: Text(
            'By using Thuma Pay, you agree to these terms...\n\n'
            '1. Acceptance of Terms\n'
            '2. User Responsibilities\n'
            '3. Service Terms\n'
            '4. Limitation of Liability\n'
            '5. Dispute Resolution',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _signOut() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              setState(() {
                _isLoading = true;
              });
              
              await _authService.signOut();
              
              if (mounted) {
                setState(() {
                  _isLoading = false;
                });
              }
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  void _deleteAccount() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Account deletion feature coming soon!'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
