import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';

class SecurityService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LocalAuthentication _localAuth = LocalAuthentication();
  final String _securityCollection = 'user_security';

  // Check if device supports biometric authentication
  Future<bool> isBiometricAvailable() async {
    try {
      return await _localAuth.canCheckBiometrics;
    } catch (e) {
      return false;
    }
  }

  // Get available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      return [];
    }
  }

  // Authenticate with biometrics
  Future<bool> authenticateWithBiometrics() async {
    try {
      return await _localAuth.authenticate(
        localizedReason: 'Please authenticate to complete the transaction',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } catch (e) {
      return false;
    }
  }

  // Set PIN for user
  Future<bool> setPIN(String userId, String pin) async {
    if (pin.length != 4 || !RegExp(r'^\d{4}$').hasMatch(pin)) {
      return false;
    }

    try {
      await _firestore.collection(_securityCollection).doc(userId).set({
        'pin': _hashPIN(pin),
        'hasPIN': true,
        'hasBiometric': false,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return true;
    } catch (e) {
      return false;
    }
  }

  // Verify PIN
  Future<bool> verifyPIN(String userId, String pin) async {
    try {
      final doc = await _firestore.collection(_securityCollection).doc(userId).get();
      if (!doc.exists) return false;

      final storedHash = doc.data()?['pin'] as String?;
      return storedHash == _hashPIN(pin);
    } catch (e) {
      return false;
    }
  }

  // Enable biometric authentication
  Future<bool> enableBiometric(String userId) async {
    try {
      final hasBiometric = await isBiometricAvailable();
      if (!hasBiometric) return false;

      await _firestore.collection(_securityCollection).doc(userId).update({
        'hasBiometric': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  // Check if user has PIN set
  Future<bool> hasPIN(String userId) async {
    try {
      final doc = await _firestore.collection(_securityCollection).doc(userId).get();
      return doc.exists && (doc.data()?['hasPIN'] ?? false);
    } catch (e) {
      return false;
    }
  }

  // Check if user has biometric enabled
  Future<bool> hasBiometricEnabled(String userId) async {
    try {
      final doc = await _firestore.collection(_securityCollection).doc(userId).get();
      return doc.exists && (doc.data()?['hasBiometric'] ?? false);
    } catch (e) {
      return false;
    }
  }

  // Authenticate user (PIN or Biometric)
  Future<AuthResult> authenticateUser(String userId) async {
    final hasBiometric = await hasBiometricEnabled(userId);
    final hasPin = await hasPIN(userId);

    if (!hasPin && !hasBiometric) {
      return AuthResult(success: false, reason: AuthFailureReason.notConfigured);
    }

    // Try biometric first if available
    if (hasBiometric) {
      final biometricSuccess = await authenticateWithBiometrics();
      if (biometricSuccess) {
        return AuthResult(success: true);
      }
    }

    // Fall back to PIN if biometric failed or not available
    if (hasPin) {
      return AuthResult(success: false, reason: AuthFailureReason.pinRequired);
    }

    return AuthResult(success: false, reason: AuthFailureReason.failed);
  }

  // Simple PIN hashing (in production, use proper hashing)
  String _hashPIN(String pin) {
    // For demo purposes - in production use proper hashing like bcrypt
    return pin.split('').reversed.join() + 'salt';
  }

  // Reset security settings
  Future<void> resetSecurity(String userId) async {
    try {
      await _firestore.collection(_securityCollection).doc(userId).delete();
    } catch (e) {
      // Handle error
    }
  }
}

class AuthResult {
  final bool success;
  final AuthFailureReason reason;

  const AuthResult({
    required this.success,
    this.reason = AuthFailureReason.none,
  });
}

enum AuthFailureReason {
  none,
  notConfigured,
  pinRequired,
  failed,
  cancelled,
}