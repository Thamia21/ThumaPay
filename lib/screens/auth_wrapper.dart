import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:thuma_pay/screens/vendor/vendor_dashboard.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import 'login_screen.dart';
import 'parent/parent_dashboard.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final AuthService _authService = AuthService();
  User? _currentUser;
  UserModel? _userData;
  bool _isLoading = true;
  bool _isEmailVerified = false;
  bool _hasCheckedVerification = false;

  @override
  void initState() {
    super.initState();
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    // Check if Firebase is initialized
    try {
      Firebase.app();
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      return;
    }
    
    // Listen to auth state changes
    _authService.authStateChanges.listen((user) async {
      if (mounted) {
        setState(() {
          _currentUser = user;
        });
      }
      
      if (user != null && !_hasCheckedVerification) {
        debugPrint('🔄 Starting verification check for user: ${user.email}');
        try {
          // Check email verification status
          final isVerified = await _authService.checkEmailVerification();
          debugPrint('🔄 Email verification result: $isVerified');
          
          final userData = await _authService.getUserData(user.uid);
          debugPrint('🔄 User data fetched: ${userData?.fullName}');
          
          if (mounted) {
            setState(() {
              _isEmailVerified = isVerified;
              _userData = userData;
              _hasCheckedVerification = true; // Mark as completed
              _isLoading = false; // Set loading to false after all data is loaded
            });
            debugPrint('🔄 State updated - isVerified: $isVerified, hasChecked: true');
          }
        } catch (e) {
          debugPrint('Error fetching user data: $e');
          if (mounted) {
            setState(() {
              _hasCheckedVerification = true; // Mark as completed even on error
              _isLoading = false; // Set loading to false even on error
            });
          }
        }
      } else if (user == null) {
        if (mounted) {
          setState(() {
            _userData = null;
            _isEmailVerified = false;
            _hasCheckedVerification = false; // Reset for new login attempts
            _isLoading = false;
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Check if Firebase is initialized
    try {
      Firebase.app();
    } catch (e) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 20),
              const Text('Initializing Firebase...', style: TextStyle(fontSize: 16)),
              const SizedBox(height: 10),
              Text('Error: $e', style: const TextStyle(color: Colors.red)),
            ],
          ),
        ),
      );
    }
    
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    if (_currentUser != null) {
      debugPrint('🔄 Build method - Current user: ${_currentUser?.email}');
      debugPrint('🔄 Build method - Has checked verification: $_hasCheckedVerification');
      debugPrint('🔄 Build method - Is verified: $_isEmailVerified');
      
      // Only proceed if verification check has completed
      if (!_hasCheckedVerification) {
        debugPrint('🔄 Build method - Showing verification loading screen');
        return const Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 20),
                Text('Verifying your account...'),
              ],
            ),
          ),
        );
      }
      
      // Check if email is verified
      if (!_isEmailVerified) {
        // Sign out unverified user
        debugPrint('🔄 Build method - User not verified, signing out');
        _authService.signOut();
        debugPrint('🔄 User not verified, signed out');
        return const LoginScreen();
      }

      // User is logged in and verified, navigate to appropriate screen based on role
      // Use user data if available, otherwise use email display name
      String userName = _userData?.fullName ?? _currentUser?.displayName ?? _currentUser?.email?.split('@')[0] ?? 'User';
      String userRole = _userData?.role ?? 'vendor'; // Default to vendor if no role
      
      debugPrint('🔄 User role: $userRole');
      debugPrint('🔄 Redirecting to appropriate screen with userName: $userName');
      debugPrint('🔄 Current user: ${_currentUser?.email}');
      debugPrint('🔄 User data: ${_userData?.fullName}');
      
      // Route based on user role
      switch (userRole) {
        case 'parent':
          return ParentDashboard(userModel: null);  // Simplified: pass null for now
        case 'vendor':
          return const VendorDashboard();
        case 'admin':
        default:
          return ParentDashboard(userModel: null);  // Simplified: pass null for now
      }
    }
    
    // User is not logged in or user data not available
    return const LoginScreen();
  }
}
