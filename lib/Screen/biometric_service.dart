import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:rainbow_edge_lighting/rainbow_edge_lighting.dart';
import 'dataModle.dart';

class BiometricService {
  BiometricService._();

  static final LocalAuthentication _auth = LocalAuthentication();

  static Future<bool> isAvailable() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isDeviceSupported = await _auth.isDeviceSupported();
      return canCheck && isDeviceSupported;
    } on PlatformException {
      return false;
    }
  }

  static Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } on PlatformException {
      return [];
    }
  }

  static Future<bool> isFingerprintAvailable() async {
    try {
      if (!await isAvailable()) return false;
      final biometrics = await getAvailableBiometrics();
      return biometrics.contains(BiometricType.fingerprint) ||
          biometrics.contains(BiometricType.strong) ||
          biometrics.contains(BiometricType.weak);
    } catch (_) {
      return false;
    }
  }

  static Future<BiometricResult> authenticate({
    String reason = "Verify your identity to access VibeNote",
  }) async {
    try {
      final available = await isAvailable();
      debugPrint("🔐 Biometric available: $available");

      if (!available) return BiometricResult.notAvailable;

      final authenticated = await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );

      debugPrint("🔐 Auth result: $authenticated");
      return authenticated ? BiometricResult.success : BiometricResult.failed;
    } on PlatformException catch (e) {
      debugPrint("🔐 PlatformException: ${e.code} — ${e.message}");
      if (e.code == "NotEnrolled") return BiometricResult.notEnrolled;
      if (e.code == "LockedOut" || e.code == "PermanentlyLockedOut") {
        return BiometricResult.lockedOut;
      }
      return BiometricResult.error;
    } catch (e) {
      debugPrint("🔐 Unknown biometric error: $e");
      return BiometricResult.error;
    }
  }

  static Future<void> stopAuthentication() async {
    try {
      await _auth.stopAuthentication();
    } catch (_) {}
  }

  static Future<bool> unlockNote(
      BuildContext context,
      NoteModel note, {
        String reason = "Unlock note",
      }) async {
    if (!note.isLocked) return true;

    final bioAvailable = await isFingerprintAvailable();
    if (bioAvailable) {
      final result = await authenticate(reason: reason);
      if (result == BiometricResult.success) return true;
    }

    if (!context.mounted) return false;

    final entered = await showPinEntry(
      context,
      title: "Enter PIN",
      actionText: "Unlock",
    );

    if (entered == null) return false;
    if (entered == "__biometric__") return true;

    final correct = entered == note.pin;
    if (!correct && context.mounted) {
      _showSnack(context, "Wrong PIN. Please try again.", danger: true);
    }
    return correct;
  }

  static Future<String?> showPinEntry(
      BuildContext context, {
        required String title,
        required String actionText,
        String hintText = "Enter 4 digit PIN",
        bool allowBiometric = true,
      }) {
    return Navigator.of(context).push<String>(
      PageRouteBuilder<String>(
        opaque: false,
        barrierColor: Colors.black.withOpacity(0.45),
        transitionDuration: const Duration(milliseconds: 220),
        reverseTransitionDuration: const Duration(milliseconds: 180),
        pageBuilder: (_, animation, __) => PinEntryPage(
          title: title,
          actionText: actionText,
          hintText: hintText,
          allowBiometric: allowBiometric,
        ),
        transitionsBuilder: (_, animation, __, child) => FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.96, end: 1).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  static void _showSnack(
      BuildContext context,
      String message, {
        bool danger = false,
      }) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              danger ? Icons.error_outline : Icons.info_outline,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: danger ? Colors.redAccent : const Color(0xff7F5AF0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(milliseconds: 2500),
        elevation: 4,
      ),
    );
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

class PinEntryPage extends StatefulWidget {
  final String title;
  final String actionText;
  final String hintText;
  final bool allowBiometric;

  const PinEntryPage({
    super.key,
    required this.title,
    required this.actionText,
    this.hintText = "Enter 4 digit PIN",
    this.allowBiometric = true,
  });

  @override
  State<PinEntryPage> createState() => _PinEntryPageState();
}

class _PinEntryPageState extends State<PinEntryPage> {
  final TextEditingController controller = TextEditingController();
  final FocusNode pinFocusNode = FocusNode();
  bool isPinFocused = false;
  bool isVerifyingBiometric = false;
  String? errorText;
  bool obscurePin = true;
  int _wrongAttempts = 0;
  int _lockoutTimer = 0;
  Timer? _lockoutTimerTick;
  static const int _maxAttempts = 5;
  static const int _lockoutDurationSeconds = 30;

  @override
  void initState() {
    super.initState();
    pinFocusNode.addListener(() {
      if (!mounted) return;
      setState(() => isPinFocused = pinFocusNode.hasFocus);
    });
    Future.delayed(const Duration(milliseconds: 250), () {
      if (mounted) pinFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    controller.dispose();
    pinFocusNode.dispose();
    _lockoutTimerTick?.cancel();
    super.dispose();
  }

  bool get _isLockedOut => _lockoutTimer > 0;

  Future<void> _tryBiometric() async {
    if (isVerifyingBiometric || _isLockedOut) return;
    setState(() => isVerifyingBiometric = true);

    final result = await BiometricService.authenticate(
      reason: "Use fingerprint to unlock this note",
    );

    if (!mounted) return;
    setState(() => isVerifyingBiometric = false);

    if (result == BiometricResult.success) {
      Navigator.of(context).pop("__biometric__");
    } else if (result == BiometricResult.lockedOut) {
      _showError("🔒 Too many biometric attempts. Use PIN.");
    } else if (result == BiometricResult.notAvailable ||
        result == BiometricResult.notEnrolled) {
      _showError("🔐 Fingerprint not available. Use PIN.", isError: false);
    } else {
      _showError("❌ Biometric failed. Try again or use PIN.");
    }
  }

  void _showError(String message, {bool isError = true}) {
    if (!mounted) return;
    setState(() {
      errorText = message;
    });
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted && errorText == message) {
        setState(() => errorText = null);
      }
    });
  }

  void _handlePinError() {
    HapticFeedback.heavyImpact();
    _wrongAttempts++;
    final remaining = _maxAttempts - _wrongAttempts;

    if (remaining <= 0) {
      _startLockout();
      return;
    }

    final message = remaining == 1
        ? "⚠️ Wrong PIN! Last attempt before lockout."
        : "❌ Wrong PIN. $remaining attempts remaining.";

    _showError(message);
    controller.clear();
  }

  void _startLockout() {
    _lockoutTimer = _lockoutDurationSeconds;
    _showError(
      "🔒 Too many attempts! Locked for $_lockoutDurationSeconds seconds.",
    );

    _lockoutTimerTick = Timer.periodic(
      const Duration(seconds: 1),
          (timer) {
        setState(() {
          _lockoutTimer--;
        });

        if (_lockoutTimer <= 0) {
          timer.cancel();
          setState(() {
            _wrongAttempts = 0;
            _lockoutTimer = 0;
            errorText = null;
          });
        }
      },
    );

    controller.clear();
  }

  void submitPin() {
    if (_isLockedOut) {
      _showError("🔒 Wait $_lockoutTimer seconds before retrying.");
      return;
    }

    final pin = controller.text.trim();
    if (pin.isEmpty) {
      _showError("Please enter your PIN");
      return;
    }
    if (pin.length != 4) {
      _showError("PIN must be exactly 4 digits");
      return;
    }
    if (!RegExp(r'^[0-9]{4}$').hasMatch(pin)) {
      _showError("Only numbers allowed");
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();
    Future.delayed(const Duration(milliseconds: 120), () {
      if (!mounted) return;
      Navigator.of(context).pop(pin);
    });
  }

  void cancelPin() {
    FocusManager.instance.primaryFocus?.unfocus();
    Future.delayed(const Duration(milliseconds: 120), () {
      if (!mounted) return;
      Navigator.of(context).pop(null);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              left: 22,
              right: 22,
              top: 22,
              bottom: MediaQuery.of(context).viewInsets.bottom + 22,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xff171928).withOpacity(0.96)
                        : Colors.white.withOpacity(0.96),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: Colors.white.withOpacity(0.24)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.45 : 0.16),
                        blurRadius: 26,
                        offset: const Offset(0, 14),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        height: 70,
                        width: 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xff7F5AF0), Color(0xffFF6B9A)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xff7F5AF0).withOpacity(0.30),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Icon(
                          _isLockedOut ? Icons.lock_rounded : Icons.lock_open_rounded,
                          color: Colors.white,
                          size: 34,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _isLockedOut
                            ? "🔒 Locked"
                            : widget.title,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isDark ? Colors.white : const Color(0xff151225),
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _isLockedOut
                            ? "Wait $_lockoutTimer seconds"
                            : "Enter exactly 4 digits",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _isLockedOut
                              ? Colors.redAccent
                              : (isDark ? Colors.white60 : Colors.black54),
                          fontSize: 13,
                          fontWeight: _isLockedOut ? FontWeight.w700 : FontWeight.w600,
                        ),
                      ),
                      if (_wrongAttempts > 0 && !_isLockedOut) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.redAccent.withOpacity(0.30),
                            ),
                          ),
                          child: Text(
                            "$_wrongAttempts/${_maxAttempts} attempts used",
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 18),
                      RainbowEdgeLighting(
                        enabled: isPinFocused && !_isLockedOut,
                        radius: 18,
                        child: TextField(
                          controller: controller,
                          focusNode: pinFocusNode,
                          keyboardType: TextInputType.number,
                          obscureText: obscurePin,
                          maxLength: 4,
                          enabled: !_isLockedOut,
                          textAlign: TextAlign.center,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(4),
                          ],
                          style: TextStyle(
                            color: _isLockedOut
                                ? Colors.grey
                                : (isDark ? Colors.white : const Color(0xff151225)),
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 8,
                          ),
                          decoration: InputDecoration(
                            hintText: "••••",
                            hintStyle: TextStyle(
                              color: isDark ? Colors.white30 : Colors.black26,
                              letterSpacing: 8,
                            ),
                            errorText: errorText,
                            errorMaxLines: 2,
                            counterText: "",
                            filled: true,
                            fillColor: _isLockedOut
                                ? Colors.grey.withOpacity(0.1)
                                : (isDark
                                ? Colors.white.withOpacity(0.08)
                                : const Color(0xffF4F1FF)),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: const BorderSide(
                                color: Color(0xff7F5AF0),
                                width: 1.5,
                              ),
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                obscurePin
                                    ? Icons.visibility_rounded
                                    : Icons.visibility_off_rounded,
                                color: _isLockedOut
                                    ? Colors.grey
                                    : (isDark ? Colors.white54 : Colors.black38),
                                size: 18,
                              ),
                              onPressed: _isLockedOut
                                  ? null
                                  : () => setState(() => obscurePin = !obscurePin),
                            ),
                          ),
                          onChanged: (_) {
                            if (errorText != null && !errorText!.contains("Wrong")) {
                              setState(() => errorText = null);
                            }
                          },
                          onSubmitted: (_) => submitPin(),
                        ),
                      ),
                      const SizedBox(height: 18),
                      if (widget.allowBiometric && !_isLockedOut) ...[
                        FutureBuilder<bool>(
                          future: BiometricService.isFingerprintAvailable(),
                          builder: (context, snapshot) {
                            if (snapshot.data != true) {
                              return const SizedBox.shrink();
                            }
                            return Column(
                              children: [
                                Center(
                                  child: TextButton.icon(
                                    onPressed: isVerifyingBiometric
                                        ? null
                                        : _tryBiometric,
                                    icon: isVerifyingBiometric
                                        ? const SizedBox(
                                      height: 16,
                                      width: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Color(0xff7F5AF0),
                                      ),
                                    )
                                        : const Icon(
                                      Icons.fingerprint_rounded,
                                      color: Color(0xff7F5AF0),
                                    ),
                                    label: const Text(
                                      "Unlock with Fingerprint",
                                      style: TextStyle(
                                        color: Color(0xff7F5AF0),
                                        fontWeight: FontWeight.w800,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                              ],
                            );
                          },
                        ),
                      ],
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _isLockedOut ? null : cancelPin,
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                side: BorderSide(
                                  color: _isLockedOut
                                      ? Colors.grey.withOpacity(0.3)
                                      : (isDark
                                      ? Colors.white.withOpacity(0.18)
                                      : Colors.black.withOpacity(0.12)),
                                ),
                              ),
                              child: Text(
                                _isLockedOut ? "Locked" : "Cancel",
                                style: TextStyle(
                                  color: _isLockedOut
                                      ? Colors.grey
                                      : (isDark ? Colors.white70 : Colors.black54),
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton(
                              onPressed: _isLockedOut ? null : submitPin,
                              style: FilledButton.styleFrom(
                                backgroundColor: _isLockedOut
                                    ? Colors.grey
                                    : const Color(0xff7F5AF0),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Text(
                                _isLockedOut ? "⏳ Wait" : widget.actionText,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_isLockedOut) ...[
                        const SizedBox(height: 14),
                        Text(
                          "Restart the app to try again",
                          style: TextStyle(
                            color: isDark ? Colors.white38 : Colors.black38,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}