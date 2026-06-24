import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';

class BiometricService {
  static final LocalAuthentication _auth = LocalAuthentication();

  // ✅ Check if biometric is available on device
  static Future<bool> isAvailable() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isDeviceSupported = await _auth.isDeviceSupported();
      return canCheck && isDeviceSupported;
    } on PlatformException {
      return false;
    }
  }

  // ✅ Check what biometrics are enrolled
  static Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } on PlatformException {
      return [];
    }
  }

  // ✅ Check if fingerprint specifically is available
  static Future<bool> isFingerprintAvailable() async {
    try {
      final biometrics = await getAvailableBiometrics();
      return biometrics.contains(BiometricType.fingerprint) ||
          biometrics.contains(BiometricType.strong) ||
          biometrics.contains(BiometricType.weak);
    } catch (_) {
      return false;
    }
  }

  // ✅ Authenticate with biometric
  static Future<BiometricResult> authenticate({
    String reason = "Verify your identity to access VibeNote",
  }) async {
    try {
      final available = await isAvailable();
      print("🔐 Biometric available: $available"); // debug

      final biometrics = await getAvailableBiometrics();
      print("🔐 Available biometrics: $biometrics"); // debug

      if (!available) {
        return BiometricResult.notAvailable;
      }

      final authenticated = await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );

      print("🔐 Auth result: $authenticated"); // debug
      return authenticated
          ? BiometricResult.success
          : BiometricResult.failed;

    } on PlatformException catch (e) {
      print("🔐 PlatformException: ${e.code} — ${e.message}"); // debug
      if (e.code == "NotEnrolled") return BiometricResult.notEnrolled;
      if (e.code == "LockedOut" || e.code == "PermanentlyLockedOut") {
        return BiometricResult.lockedOut;
      }
      return BiometricResult.error;
    } catch (e) {
      print("🔐 Unknown error: $e"); // debug
      return BiometricResult.error;
    }
  }

  // ✅ Stop ongoing authentication
  static Future<void> stopAuthentication() async {
    try {
      await _auth.stopAuthentication();
    } catch (_) {}
  }
}

enum BiometricResult {
  success,
  failed,
  notAvailable,
  notEnrolled,
  lockedOut,
  error,

}