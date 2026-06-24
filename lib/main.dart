import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'Screen/Smart_Notes.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'Screen/notification_service.dart';
import 'package:rainbow_edge_lighting/rainbow_edge_lighting.dart';
import 'Screen/biometric_service.dart';


final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Lock portrait orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // ✅ Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  await NotificationService.init();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  static _MyAppState? of(BuildContext context) =>
      context.findAncestorStateOfType<_MyAppState>();

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool isDark = false;

  @override
  void initState() {
    super.initState();
    loadTheme();
  }

  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      isDark = prefs.getBool("isDark") ?? false;
    });
  }

  Future<void> toggleTheme() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        isDark = !isDark;
      });
      prefs.setBool("isDark", isDark);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'VibeNote',
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        fontFamily: "Poppins",
        scaffoldBackgroundColor: const Color(0xffF6F3FF),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xff7F5AF0),
          brightness: Brightness.light,
        ),
        // ✅ Consistent snackbar theme
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        fontFamily: "Poppins",
        scaffoldBackgroundColor: const Color(0xff090A12),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xff7F5AF0),
          brightness: Brightness.dark,
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SHARED WIDGETS
// ─────────────────────────────────────────────────────────────

class AppGradientBackground extends StatelessWidget {
  final Widget child;

  const AppGradientBackground({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? const [
            Color(0xff090A12),
            Color(0xff17122B),
            Color(0xff261A3D),
          ]
              : const [
            Color(0xffF8F5FF),
            Color(0xffEFE7FF),
            Color(0xffFFEAF3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -80,
            right: -60,
            child: _GlowCircle(
              color: const Color(0xff7F5AF0).withOpacity(0.35),
              size: 220,
            ),
          ),
          Positioned(
            bottom: -90,
            left: -70,
            child: _GlowCircle(
              color: const Color(0xffFF6B9A).withOpacity(0.30),
              size: 240,
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _GlowCircle extends StatelessWidget {
  final Color color;
  final double size;

  const _GlowCircle({
    required this.color,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(22),
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.08)
                : Colors.white.withOpacity(0.55),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: Colors.white.withOpacity(0.25),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.35 : 0.10),
                blurRadius: 25,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class GradientButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final IconData? icon;


  const GradientButton({
    super.key,
    required this.text,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        height: 52,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xff7F5AF0),
              Color(0xffFF6B9A),
            ],
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: const Color(0xff7F5AF0).withOpacity(0.35),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.white, size: 21),
              const SizedBox(width: 8),
            ],
            Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SPLASH SCREEN
// ─────────────────────────────────────────────────────────────

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  late final Animation<double> logoFade;
  late final Animation<double> logoScale;
  late final Animation<double> logoRotate;
  late final Animation<double> textFade;
  late final Animation<Offset> textSlide;
  late final Animation<double> progressValue;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1350),
    );

    logoFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.00, 0.65, curve: Curves.easeOut),
    );

    logoScale = Tween<double>(begin: 0.72, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.00, 0.75, curve: Curves.easeOutBack),
      ),
    );

    logoRotate = Tween<double>(begin: -0.035, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.00, 0.70, curve: Curves.easeOutCubic),
      ),
    );

    textFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.30, 1.0, curve: Curves.easeOut),
    );

    textSlide = Tween<Offset>(
      begin: const Offset(0, 0.18),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.28, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    progressValue = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.45, 1.0, curve: Curves.easeInOut),
      ),
    );

    // ✅ navigate after animation completes, not hardcoded delay
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _goNext();
      }
    });

    _controller.forward();
  }

  Future<void> _goNext() async {
    // ✅ Small delay after animation for smooth feel
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    final appLockOn = prefs.getBool("appLockOn") ?? false;
    final appPin = prefs.getString("appPin");

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      _premiumRoute(
        appLockOn && appPin != null && appPin.isNotEmpty
            ? PinLockScreen(correctPin: appPin)
            : const MyApp2(),
      ),
    );
  }

  Route _premiumRoute(Widget page) {
    return PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 420),
      pageBuilder: (_, animation, __) => page,
      transitionsBuilder: (_, animation, __, child) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.98, end: 1).animate(
              CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              ),
            ),
            child: child,
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _softGlow({required Color color, required double size}) {
    return IgnorePointer(
      child: Container(
        height: size,
        width: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
    );
  }

  Widget _sparkle({
    required double top,
    required double left,
    required double size,
    required Color color,
  }) {
    return Positioned(
      top: top,
      left: left,
      child: FadeTransition(
        opacity: textFade,
        child: Icon(Icons.auto_awesome_rounded, size: size, color: color),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? const [
              Color(0xff070711),
              Color(0xff130D2D),
              Color(0xff24114A),
            ]
                : const [
              Color(0xffFDF9FF),
              Color(0xffF0E7FF),
              Color(0xffFFE8F4),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -90,
              right: -70,
              child: _softGlow(
                color: const Color(0xff7F5AF0).withOpacity(0.34),
                size: 240,
              ),
            ),
            Positioned(
              bottom: -105,
              left: -75,
              child: _softGlow(
                color: const Color(0xffFF6B9A).withOpacity(0.28),
                size: 260,
              ),
            ),
            Positioned(
              top: 145,
              left: 28,
              child: _softGlow(
                color: const Color(0xff00C2FF).withOpacity(0.12),
                size: 140,
              ),
            ),
            _sparkle(
              top: 145,
              left: 58,
              size: 20,
              color: const Color(0xffFF6B9A).withOpacity(0.85),
            ),
            _sparkle(
              top: 235,
              left: MediaQuery.of(context).size.width - 86,
              size: 17,
              color: const Color(0xffA855F7).withOpacity(0.85),
            ),
            SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FadeTransition(
                        opacity: logoFade,
                        child: ScaleTransition(
                          scale: logoScale,
                          child: RotationTransition(
                            turns: logoRotate,
                            child: Container(
                              height: 190,
                              width: 190,
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(
                                  isDark ? 0.075 : 0.35,
                                ),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.18),
                                  width: 1.2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xff7F5AF0)
                                        .withOpacity(0.35),
                                    blurRadius: 44,
                                    offset: const Offset(0, 18),
                                  ),
                                  BoxShadow(
                                    color: const Color(0xffFF6B9A)
                                        .withOpacity(0.18),
                                    blurRadius: 55,
                                    offset: const Offset(0, -10),
                                  ),
                                ],
                              ),
                              child: Image.asset(
                                "assets/logo/VibeNote_logo_withoutBg.png",
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      FadeTransition(
                        opacity: textFade,
                        child: SlideTransition(
                          position: textSlide,
                          child: Column(
                            children: [
                              ShaderMask(
                                shaderCallback: (bounds) {
                                  return const LinearGradient(
                                    colors: [
                                      Colors.white,
                                      Color(0xffFF6B9A),
                                      Color(0xff7F5AF0),
                                    ],
                                  ).createShader(bounds);
                                },
                                child: Text(
                                  "VibeNote",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 38,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.2,
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xff151225),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Every Thought Has a Vibe.",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.3,
                                  color: isDark
                                      ? Colors.white70
                                      : const Color(0xff6D6680),
                                ),
                              ),
                              const SizedBox(height: 24),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(30),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(
                                    sigmaX: 14,
                                    sigmaY: 14,
                                  ),
                                  child: Container(
                                    width: 178,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(
                                        isDark ? 0.075 : 0.42,
                                      ),
                                      borderRadius: BorderRadius.circular(30),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.20),
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        AnimatedBuilder(
                                          animation: progressValue,
                                          builder: (context, _) {
                                            return ClipRRect(
                                              borderRadius:
                                              BorderRadius.circular(20),
                                              child: LinearProgressIndicator(
                                                value: progressValue.value,
                                                minHeight: 5,
                                                backgroundColor:
                                                Colors.white.withOpacity(
                                                  isDark ? 0.12 : 0.45,
                                                ),
                                                valueColor:
                                                const AlwaysStoppedAnimation<
                                                    Color>(
                                                  Color(0xffFF6B9A),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          "Loading your vibes...",
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                            color: isDark
                                                ? Colors.white60
                                                : const Color(0xff6D6680),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PinLockScreen extends StatefulWidget {
  final String correctPin;

  const PinLockScreen({
    super.key,
    required this.correctPin,
  });

  @override
  State<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends State<PinLockScreen> {
  final TextEditingController pinController = TextEditingController();
  final FocusNode pinFocusNode = FocusNode();

  bool isPinFocused = false;
  bool obscurePin = true;
  bool canUseBiometric = false;

  int wrongAttempts = 0;
  static const int maxAttempts = 5;

  @override
  void initState() {
    super.initState();

    pinFocusNode.addListener(() {
      if (!mounted) return;
      setState(() {
        isPinFocused = pinFocusNode.hasFocus;
      });
    });
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) tryBiometric();
    });

  }

  @override
  void dispose() {
    pinController.dispose();
    pinFocusNode.dispose();
    super.dispose();
  }

  void showPinMessage(String message, {bool danger = true}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: danger ? Colors.redAccent : const Color(0xff2CB67D),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }
  Future<void> tryBiometric() async {
    final result = await BiometricService.authenticate(
      reason: "Use fingerprint to unlock VibeNote",
    );
    if (!mounted) return;

    if (result == BiometricResult.success) {
      // ✅ Fingerprint success — unlock app
      FocusManager.instance.primaryFocus?.unfocus();
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 550),
          pageBuilder: (_, animation, __) => const MyApp2(),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    } else if (result == BiometricResult.notAvailable ||
        result == BiometricResult.notEnrolled) {
      showPinMessage(
        "Fingerprint not available. Use PIN.",
        danger: false,
      );
    } else if (result == BiometricResult.lockedOut) {
      showPinMessage(
        "Too many attempts. Use PIN instead.",
        danger: true,
      );
    }
  }

  Future<void> unlockApp() async {
    final pin = pinController.text.trim();

    if (pin.isEmpty) {
      showPinMessage("Please enter PIN");
      return;
    }

    if (pin.length != 4) {
      showPinMessage("PIN must be exactly 4 digits");
      return;
    }

    if (pin != widget.correctPin) {
      wrongAttempts++;
      HapticFeedback.heavyImpact();

      final remaining = maxAttempts - wrongAttempts;

      if (remaining <= 0) {
        showPinMessage("Too many wrong attempts. Please restart the app.");
        pinController.clear();
        return;
      }

      showPinMessage(
        remaining == 1
            ? "Wrong PIN! Last attempt remaining."
            : "Wrong PIN. $remaining attempts left.",
      );

      pinController.clear();
      return;
    }

    HapticFeedback.lightImpact();
    FocusManager.instance.primaryFocus?.unfocus();

    await Future.delayed(const Duration(milliseconds: 120));
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 550),
        pageBuilder: (_, animation, __) => const MyApp2(),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.08),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                ),
              ),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: AppGradientBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: GlassCard(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      height: 86,
                      width: 86,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xff7F5AF0), Color(0xffFF6B9A)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xff7F5AF0).withOpacity(0.35),
                            blurRadius: 25,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.lock_rounded,
                        size: 42,
                        color: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 22),

                    Text(
                      "Welcome Back",
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : const Color(0xff151225),
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      "Enter your PIN to unlock VibeNote",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),

                    if (wrongAttempts > 0) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.redAccent.withOpacity(0.30),
                          ),
                        ),
                        child: Text(
                          "$wrongAttempts wrong attempt${wrongAttempts > 1 ? 's' : ''}",
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    RainbowEdgeLighting(
                      enabled: isPinFocused,
                      radius: 18,
                      child: TextField(
                        focusNode: pinFocusNode,
                        controller: pinController,
                        keyboardType: TextInputType.number,
                        maxLength: 4,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(4),
                        ],
                        obscureText: obscurePin,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 8,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                        decoration: InputDecoration(
                          hintText: "••••",
                          counterText: "",
                          filled: true,
                          fillColor: isDark
                              ? Colors.white.withOpacity(0.07)
                              : Colors.white.withOpacity(0.70),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide.none,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscurePin
                                  ? Icons.visibility_rounded
                                  : Icons.visibility_off_rounded,
                              color: isDark ? Colors.white54 : Colors.black38,
                              size: 20,
                            ),
                            onPressed: () {
                              setState(() {
                                obscurePin = !obscurePin;
                              });
                            },
                          ),
                        ),
                        onSubmitted: (_) => unlockApp(),
                      ),
                    ),

                    const SizedBox(height: 20),
                    FutureBuilder<bool>(
                      future: BiometricService.isFingerprintAvailable(),
                      builder: (context, snapshot) {
                        if (snapshot.data != true) return const SizedBox.shrink();
                        return Column(
                          children: [
                            const SizedBox(height: 12),
                            GestureDetector(
                              onTap: tryBiometric,
                              child: Container(
                                height: 52,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.white.withOpacity(0.08)
                                      : Colors.white.withOpacity(0.60),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: const Color(0xff7F5AF0).withOpacity(0.40),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.fingerprint_rounded,
                                      color: const Color(0xff7F5AF0),
                                      size: 28,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      "Use Fingerprint",
                                      style: TextStyle(
                                        color: isDark ? Colors.white : const Color(0xff151225),
                                        fontWeight: FontWeight.w800,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                        );
                      },
                    ),

                    GradientButton(
                      text: "Unlock VibeNote",
                      icon: Icons.arrow_forward_rounded,
                      onTap: unlockApp,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}