import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:local_auth/local_auth.dart';

class BiometricService {
  static final LocalAuthentication _auth = LocalAuthentication();

  static Future<bool> isBiometricsAvailable() async {
    try {
      final canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final canAuthenticate = canAuthenticateWithBiometrics || await _auth.isDeviceSupported();
      return canAuthenticate;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> authenticateBiometric() async {
    try {
      return await _auth.authenticate(
        localizedReason: 'Unlock Nutmate to view private logs',
      );
    } catch (_) {
      return false;
    }
  }

  static String hashPin(String pin) {
    final bytes = utf8.encode('nutmate_salt_$pin');
    return sha256.convert(bytes).toString();
  }

  static bool verifyPin(String enteredPin, String storedHash) {
    return hashPin(enteredPin) == storedHash;
  }
}
