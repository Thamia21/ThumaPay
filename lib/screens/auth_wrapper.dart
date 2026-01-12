import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import 'login_screen.dart';
import 'home_screen.dart';

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
          _isLoading = false; // Set loading to false immediately when auth state changes
        });
      }
      
      if (user != null) {
        try {
          final userData = await _authService.getUserData(user.uid);
          if (mounted) {
            setState(() {
              _userData = userData;
            });
          }
        } catch (e) {
          print('Error fetching user data: $e');
          // Don't set _userData to null, just log the error
          // User can still proceed to home screen without Firestore data
        }
      } else {
        if (mounted) {
          setState(() {
            _userData = null;
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
      // User is logged in, navigate to home screen
      // Use user data if available, otherwise use email display name
      String userName = _userData?.fullName ?? _currentUser?.displayName ?? _currentUser?.email?.split('@')[0] ?? 'User';
      print('🔄 Redirecting to home screen with userName: $userName');
      print('🔄 Current user: ${_currentUser?.email}');
      print('🔄 User data: ${_userData?.fullName}');
      return HomeScreen(userName: userName);
    }
    
    // User is not logged in or user data not available
    return const LoginScreen();
  }
}
