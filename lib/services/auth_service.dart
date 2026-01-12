import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Check if Firebase is initialized
  bool get isFirebaseInitialized {
    try {
      Firebase.app();
      return true;
    } catch (e) {
      print('Firebase not initialized: $e');
      return false;
    }
  }

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Register with email and password
  Future<UserCredential> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String fullName,
    required String role,
  }) async {
    if (!isFirebaseInitialized) {
      throw Exception('Firebase not initialized. Please restart app.');
    }
    
    try {
      print('Attempting to register user: $email');
      // Create user with Firebase Auth with timeout
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Registration timed out. Please check your internet connection and try again.');
        },
      );
      print('User created in Auth: [32m${userCredential.user!.uid}[0m');

      // Store user data in Firestore with timeout
      try {
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'fullName': fullName,
          'email': email,
          'role': role,
          'createdAt': Timestamp.now(),
        }).timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            throw Exception('Data storage timed out. Please check your internet connection.');
          },
        );
        print('User document written in Firestore for UID: [32m${userCredential.user!.uid}[0m');
      } catch (e) {
        print('Firestore write error: [31m$e[0m');
        rethrow;
      }

      return userCredential;
    } catch (e) {
      debugPrint('🔥 AUTH ERROR TYPE: ${e.runtimeType}');
      debugPrint('🔥 AUTH ERROR: $e');
      rethrow;
    }
  }

  // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    if (!isFirebaseInitialized) {
      throw Exception('Firebase not initialized. Please restart app.');
    }
    
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      debugPrint('🔥 AUTH ERROR TYPE: ${e.runtimeType}');
      debugPrint('🔥 AUTH ERROR: $e');
      rethrow;
    }
  }

  // Get user data from Firestore
  Future<UserModel?> getUserData(String uid) async {
    if (!isFirebaseInitialized) {
      throw Exception('Firebase not initialized. Please restart app.');
    }
    
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      print('Firestore raw user doc: ${doc.data()}');
      if (doc.exists) {
        final data = doc.data();
        if (data is Map<String, dynamic>) {
          return UserModel.fromMap(uid, data);
        } else {
          print('Firestore user data is not a Map<String, dynamic>: ${data.runtimeType}');
          throw Exception('Invalid user data format');
        }
      }
      return null;
    } catch (e) {
      print('Exception when fetching user data from Firestore: $e');
      throw Exception('Failed to get user data: $e');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw Exception('Failed to sign out: $e');
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw Exception(_handleAuthError(e));
    }
  }

  // Handle authentication errors
Exception _handleAuthError(dynamic error) {
  if (error is FirebaseAuthException) {
    switch (error.code) {
      case 'weak-password':
        return Exception('The password provided is too weak.');
      case 'email-already-in-use':
        return Exception('An account already exists for this email.');
      case 'user-not-found':
        return Exception('No user found for this email.');
      case 'wrong-password':
        return Exception('Wrong password provided.');
      case 'invalid-email':
        return Exception('The email address is not valid.');
      case 'user-disabled':
        return Exception('This user account has been disabled.');
      case 'too-many-requests':
        return Exception('Too many requests. Try again later.');
      case 'operation-not-allowed':
        return Exception('Email & Password sign-in is not enabled.');
      default:
        return Exception(error.message ?? 'Authentication error occurred.');
    }
  }
  return Exception('An unknown error occurred.');
}

}
