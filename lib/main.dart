import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rainbow_edge_lighting/rainbow_edge_lighting.dart';

import 'Screen/Smart_Notes.dart';
import 'Screen/notification_service.dart';
import 'Screen/biometric_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  try {
    await NotificationService.init();
  } catch (e) {
    debugPrint("Notification initialization failed: $e");
  }

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
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      setState(() {
        isDark = prefs.getBool("isDark") ?? false;
      });
    } catch (e) {
      debugPrint('Theme loading error: $e');
    }
  }

  Future<void> toggleTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final newTheme = !isDark;
      setState(() {
        isDark = newTheme;
      });
      await prefs.setBool("isDark", newTheme);
    } catch (e) {
      debugPrint('Theme toggle error: $e');
    }
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
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: true,
          backgroundColor: Colors.transparent,
          foregroundColor: Color(0xff151225),
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
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: true,
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

// ============================================================
// SPLASH SCREEN
// ============================================================

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _mainController;
  late final AnimationController _particleController;
  late final AnimationController _glowController;

  late final Animation<double> _logoScale;
  late final Animation<double> _logoFade;
  late final Animation<double> _logoRotation;
  late final Animation<Offset> _textSlide;
  late final Animation<double> _textFade;
  late final Animation<double> _progressValue;
  late final Animation<double> _glowPulse;
  late final Animation<double> _particleOpacity;

  late final List<_Particle> _particles;

  String _loadingMessage = "Loading your vibes...";
  Timer? _messageTimer;
  Timer? _navigationTimer;

  static const int _maxParticles = 25;
  static const Duration _splashDuration = Duration(seconds: 3);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initControllers();
    _initParticles();
    _initAnimations();
    _startSplashSequence();
  }

  void _initControllers() {
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
  }

  void _initParticles() {
    final random = math.Random();
    _particles = List.generate(_maxParticles, (index) {
      return _Particle(
        position: Offset(
          random.nextDouble() * 1.2 - 0.1,
          random.nextDouble() * 1.2 - 0.1,
        ),
        size: random.nextDouble() * 4 + 2,
        speed: random.nextDouble() * 0.5 + 0.3,
        opacity: random.nextDouble() * 0.6 + 0.2,
        wobble: random.nextDouble() * 2 * math.pi,
        wobbleSpeed: random.nextDouble() * 2 + 1,
        colorIndex: random.nextInt(3),
      );
    });
  }

  void _initAnimations() {
    _logoScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.7, curve: Curves.elasticOut),
      ),
    );

    _logoFade = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    );

    _logoRotation = Tween<double>(begin: -0.05, end: 0.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    _textSlide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.3, 0.9, curve: Curves.easeOutCubic),
      ),
    );

    _textFade = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.25, 0.7, curve: Curves.easeOut),
    );

    _progressValue = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeInOut),
      ),
    );

    _glowPulse = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(
        parent: _glowController,
        curve: Curves.easeInOut,
      ),
    );

    _particleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
      ),
    );
  }

  void _startSplashSequence() {
    _mainController.forward();

    _messageTimer = Timer.periodic(const Duration(milliseconds: 900), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      final messages = [
        "Loading your vibes...",
        "✨ Polishing your notes...",
        "🎨 Applying magic...",
        "🚀 Almost there...",
      ];

      final currentIndex = messages.indexOf(_loadingMessage);
      final nextIndex = (currentIndex + 1) % messages.length;

      setState(() {
        _loadingMessage = messages[nextIndex];
      });
    });

    _navigationTimer = Timer(_splashDuration, () {
      if (mounted) {
        _navigateToNext();
      }
    });
  }

  Future<void> _navigateToNext() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;

      final appLockOn = prefs.getBool('appLockOn') ?? false;
      final appPin = prefs.getString('appPin');
      final openNoteId = NotificationService.consumePendingOpenNoteId();

      if (!mounted) return;

      Widget nextScreen;
      if (appLockOn && appPin != null && appPin.isNotEmpty) {
        nextScreen = PinLockScreen(
          correctPin: appPin,
          openNoteId: openNoteId,
        );
      } else {
        nextScreen = const MyApp2(openNoteId: null);
      }

      Navigator.pushReplacement(
        context,
        _createPremiumRoute(nextScreen),
      );
    } catch (e) {
      debugPrint('Navigation error: $e');
      if (mounted) {
        Navigator.pushReplacement(
          context,
          _createPremiumRoute(const MyApp2(openNoteId: null)),
        );
      }
    }
  }

  Route _createPremiumRoute(Widget page) {
    return PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 650),
      pageBuilder: (_, animation, __) => page,
      transitionsBuilder: (_, animation, __, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );

        return FadeTransition(
          opacity: curvedAnimation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.95, end: 1.0).animate(curvedAnimation),
            child: child,
          ),
        );
      },
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {}

  @override
  void dispose() {
    _mainController.dispose();
    _particleController.dispose();
    _glowController.dispose();
    _messageTimer?.cancel();
    _navigationTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: AnimatedBuilder(
        animation: Listenable.merge([
          _mainController,
          _particleController,
          _glowController,
        ]),
        builder: (context, _) {
          return Container(
            decoration: BoxDecoration(
              gradient: _buildGradient(isDark),
            ),
            child: Stack(
              children: [
                ..._buildGlowEffects(isDark),
                if (_particleOpacity.value > 0) _buildParticleSystem(),
                ..._buildSparkles(),
                SafeArea(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildLogo(),
                          const SizedBox(height: 28),
                          _buildTextContent(isDark),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Gradient _buildGradient(bool isDark) {
    if (isDark) {
      return const LinearGradient(
        colors: [
          Color(0xff070711),
          Color(0xff130D2D),
          Color(0xff24114A),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
    return const LinearGradient(
      colors: [
        Color(0xffFDF9FF),
        Color(0xffF0E7FF),
        Color(0xffFFE8F4),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  List<Widget> _buildGlowEffects(bool isDark) {
    return [
      Positioned(
        top: -90 * _glowPulse.value,
        right: -70 * _glowPulse.value,
        child: _GlowWidget(
          color: const Color(0xff7F5AF0).withOpacity(0.34),
          size: 240 * _glowPulse.value,
        ),
      ),
      Positioned(
        bottom: -105 * _glowPulse.value,
        left: -75 * _glowPulse.value,
        child: _GlowWidget(
          color: const Color(0xffFF6B9A).withOpacity(0.28),
          size: 260 * _glowPulse.value,
        ),
      ),
      Positioned(
        top: 145,
        left: 28,
        child: _GlowWidget(
          color: const Color(0xff00C2FF).withOpacity(0.12),
          size: 140,
        ),
      ),
    ];
  }

  Widget _buildParticleSystem() {
    return Positioned.fill(
      child: IgnorePointer(
        child: CustomPaint(
          painter: _ParticlePainter(
            particles: _particles,
            time: _particleController.value,
            opacity: _particleOpacity.value,
          ),
        ),
      ),
    );
  }

  List<Widget> _buildSparkles() {
    final sparkleColors = [
      const Color(0xffFF6B9A).withOpacity(0.85),
      const Color(0xffA855F7).withOpacity(0.85),
      const Color(0xffFBBF24).withOpacity(0.85),
    ];

    return [
      _SparkleWidget(
        top: 145,
        left: 58,
        size: 20,
        color: sparkleColors[0],
        opacity: _textFade,
      ),
      _SparkleWidget(
        top: 235,
        left: MediaQuery.of(context).size.width - 86,
        size: 17,
        color: sparkleColors[1],
        opacity: _textFade,
      ),
      _SparkleWidget(
        top: 320,
        left: 40,
        size: 14,
        color: sparkleColors[2],
        opacity: _textFade,
      ),
    ];
  }

  Widget _buildLogo() {
    return FadeTransition(
      opacity: _logoFade,
      child: ScaleTransition(
        scale: _logoScale,
        child: RotationTransition(
          turns: _logoRotation,
          child: Container(
            height: 190,
            width: 190,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white.withOpacity(0.075)
                  : Colors.white.withOpacity(0.35),
              border: Border.all(
                color: Colors.white.withOpacity(
                  Theme.of(context).brightness == Brightness.dark ? 0.15 : 0.25,
                ),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xff7F5AF0).withOpacity(0.35),
                  blurRadius: 50,
                  offset: const Offset(0, 20),
                ),
                BoxShadow(
                  color: const Color(0xffFF6B9A).withOpacity(0.18),
                  blurRadius: 60,
                  offset: const Offset(0, -12),
                ),
              ],
            ),
            child: Hero(
              tag: 'app_logo',
              child: Image.asset(
                "assets/logo/VibeNote_logo_withoutBg.png",
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.note_rounded,
                    size: 80,
                    color: Color(0xff7F5AF0),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextContent(bool isDark) {
    return FadeTransition(
      opacity: _textFade,
      child: SlideTransition(
        position: _textSlide,
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
                  stops: [0.0, 0.5, 1.0],
                ).createShader(bounds);
              },
              child: Text(
                "VibeNote",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                  height: 1.1,
                  color: isDark ? Colors.white : const Color(0xff151225),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "Every Thought Has a Vibe.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: isDark ? Colors.white70 : const Color(0xff6D6680),
              ),
            ),
            const SizedBox(height: 28),
            _buildPremiumLoader(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumLoader(bool isDark) {
    return AnimatedBuilder(
      animation: _progressValue,
      builder: (context, child) {
        return Container(
          width: 200,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(isDark ? 0.08 : 0.3),
                Colors.white.withOpacity(isDark ? 0.04 : 0.15),
              ],
            ),
            border: Border.all(
              color: Colors.white.withOpacity(isDark ? 0.15 : 0.3),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: LinearProgressIndicator(
                  value: _progressValue.value,
                  minHeight: 4,
                  backgroundColor: Colors.white.withOpacity(
                    isDark ? 0.1 : 0.3,
                  ),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xff7F5AF0),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              ShaderMask(
                shaderCallback: (bounds) {
                  return LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.3),
                      Colors.white,
                      Colors.white.withOpacity(0.3),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ).createShader(bounds);
                },
                child: Text(
                  _loadingMessage,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xff151225),
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _GlowWidget extends StatelessWidget {
  final Color color;
  final double size;

  const _GlowWidget({
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
        boxShadow: [
          BoxShadow(
            color: color,
            blurRadius: size * 0.5,
            spreadRadius: size * 0.1,
          ),
        ],
      ),
    );
  }
}

class _SparkleWidget extends StatelessWidget {
  final double top;
  final double left;
  final double size;
  final Color color;
  final Animation<double> opacity;

  const _SparkleWidget({
    required this.top,
    required this.left,
    required this.size,
    required this.color,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: left,
      child: FadeTransition(
        opacity: opacity,
        child: Icon(
          Icons.auto_awesome_rounded,
          size: size,
          color: color,
        ),
      ),
    );
  }
}

class _Particle {
  final Offset position;
  final double size;
  final double speed;
  final double opacity;
  final double wobble;
  final double wobbleSpeed;
  final int colorIndex;

  _Particle({
    required this.position,
    required this.size,
    required this.speed,
    required this.opacity,
    required this.wobble,
    required this.wobbleSpeed,
    required this.colorIndex,
  });
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double time;
  final double opacity;

  _ParticlePainter({
    required this.particles,
    required this.time,
    required this.opacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final colors = [
      const Color(0xff7F5AF0),
      const Color(0xffFF6B9A),
      const Color(0xff00C2FF),
    ];

    for (final particle in particles) {
      final x = size.width * (particle.position.dx +
          math.sin(time * particle.wobbleSpeed + particle.wobble) * 0.02);
      final y = size.height * (particle.position.dy +
          math.cos(time * particle.wobbleSpeed * 0.7 + particle.wobble) * 0.02);

      final paint = Paint()
        ..color = colors[particle.colorIndex].withOpacity(
          particle.opacity * opacity * 0.5,
        )
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

      canvas.drawCircle(
        Offset(x, y),
        particle.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter oldDelegate) {
    return oldDelegate.time != time || oldDelegate.opacity != opacity;
  }
}

// ============================================================
// PIN LOCK SCREEN (NO ANIMATION)
// ============================================================

class PinLockScreen extends StatefulWidget {
  final String correctPin;
  final String? openNoteId;

  const PinLockScreen({
    super.key,
    required this.correctPin,
    this.openNoteId,
  });

  @override
  State<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends State<PinLockScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _pinController = TextEditingController();
  late final AnimationController _dotsLoadingController;

  bool _isUnlocking = false;
  bool _isVerifying = false;
  int _wrongAttempts = 0;
  int _lockoutTimer = 0;
  Timer? _lockoutTimerTick;
  Timer? _biometricDelayTimer;
  String? errorText;

  static const int _maxAttempts = 5;
  static const int _lockoutDurationSeconds = 30;

  @override
  void initState() {
    super.initState();

    _dotsLoadingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _biometricDelayTimer = Timer(const Duration(milliseconds: 800), () {
      if (mounted) _tryBiometric();
    });
  }

  @override
  void dispose() {
    _pinController.dispose();
    _dotsLoadingController.dispose();
    _lockoutTimerTick?.cancel();
    _biometricDelayTimer?.cancel();
    super.dispose();
  }

  // Custom numeric keypad handler (replaces the invisible TextField).
  void _onKeyTap(String digit) {
    if (_isLockedOut) return;
    HapticFeedback.selectionClick();

    if (errorText != null) {
      setState(() => errorText = null);
    }

    if (_pinController.text.length >= 4) return;

    setState(() {
      _pinController.text += digit;
    });

    if (_pinController.text.length == 4) {
      _unlockApp();
    }
  }

  void _onBackspaceTap() {
    if (_isLockedOut) return;
    if (_pinController.text.isEmpty) return;
    HapticFeedback.selectionClick();

    setState(() {
      _pinController.text =
          _pinController.text.substring(0, _pinController.text.length - 1);
    });
  }

  void _showPinError(String message, {bool isError = true}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
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
        backgroundColor: isError ? Colors.redAccent : const Color(0xff2CB67D),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(milliseconds: 2500),
        elevation: 4,
      ),
    );
  }

  void _handlePinError() {
    HapticFeedback.heavyImpact();

    if (!mounted) return;
    setState(() {
      _wrongAttempts++;
    });

    final remaining = _maxAttempts - _wrongAttempts;

    if (remaining <= 0) {
      _startLockout();
      return;
    }

    final message = remaining == 1
        ? "⚠️ Wrong PIN! Last attempt before lockout."
        : "❌ Wrong PIN. $remaining attempts remaining.";

    _showPinError(message);

    if (!mounted) return;
    setState(() {
      _pinController.clear();
    });
  }

  void _startLockout() {
    if (!mounted) return;
    setState(() {
      _lockoutTimer = _lockoutDurationSeconds;
    });

    _showPinError(
      "🔒 Too many attempts! Locked for $_lockoutDurationSeconds seconds.",
    );

    _lockoutTimerTick = Timer.periodic(
      const Duration(seconds: 1),
          (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }

        setState(() {
          _lockoutTimer--;
        });

        if (_lockoutTimer <= 0) {
          timer.cancel();
          setState(() {
            _wrongAttempts = 0;
            _lockoutTimer = 0;
          });
          _showPinError("✅ PIN lockout expired. You can try again.",
              isError: false);
        }
      },
    );

    if (!mounted) return;
    setState(() {
      _pinController.clear();
    });
  }

  bool get _isLockedOut => _lockoutTimer > 0;

  Future<void> _unlockApp() async {
    if (_isUnlocking || _isLockedOut || _isVerifying) {
      if (_isLockedOut) {
        _showPinError("🔒 Wait $_lockoutTimer seconds before retrying.");
      }
      return;
    }

    final pin = _pinController.text.trim();

    if (pin.isEmpty) {
      _showPinError("Please enter your PIN");
      return;
    }

    if (pin.length != 4) {
      _showPinError("PIN must be exactly 4 digits");
      return;
    }

    if (!RegExp(r'^\d{4}$').hasMatch(pin)) {
      _showPinError("PIN must contain only numbers");
      return;
    }

    // Show a brief verifying state where the PIN dots themselves blink/chase
    // (Google Pay style) before revealing whether the PIN was correct or wrong.
    setState(() => _isVerifying = true);
    _dotsLoadingController.repeat();
    await Future.delayed(const Duration(milliseconds: 650));
    if (!mounted) return;
    _dotsLoadingController.stop();
    _dotsLoadingController.reset();
    setState(() => _isVerifying = false);

    if (pin != widget.correctPin) {
      _handlePinError();
      return;
    }

    HapticFeedback.lightImpact();
    _pinController.clear();
    _isUnlocking = true;

    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 550),
        pageBuilder: (_, animation, __) => MyApp2(openNoteId: widget.openNoteId),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.06),
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

  Future<void> _tryBiometric() async {
    if (_isLockedOut) return;

    try {
      final result = await BiometricService.authenticate(
        reason: "Use fingerprint to unlock VibeNote",
      );

      if (!mounted) return;

      switch (result) {
        case BiometricResult.success:
          if (!_isUnlocking) {
            _isUnlocking = true;
            await Navigator.pushReplacement(
              context,
              PageRouteBuilder(
                transitionDuration: const Duration(milliseconds: 550),
                pageBuilder: (_, animation, __) =>
                    MyApp2(openNoteId: widget.openNoteId),
                transitionsBuilder: (_, animation, __, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
              ),
            );
            _isUnlocking = false;
          }
          break;

        case BiometricResult.notAvailable:
        case BiometricResult.notEnrolled:
          _showPinError("🔐 Fingerprint not available. Use PIN.",
              isError: false);
          break;

        case BiometricResult.lockedOut:
          _showPinError("🔒 Too many biometric attempts. Use PIN.");
          break;

        case BiometricResult.failed:
          _showPinError("❌ Biometric failed. Try again or use PIN.");
          break;

        case BiometricResult.error:
          _showPinError("❌ Biometric error. Use PIN instead.");
          break;
      }
    } catch (e) {
      debugPrint('Biometric error: $e');
      if (mounted) {
        _showPinError("❌ Biometric error. Use PIN instead.");
      }
    }
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
                child: RainbowEdgeLighting(
                  glowEnabled: true,
                  radius: 30,
                  thickness: 2.5,
                  enabled: true,
                  speed: 0.6,
                  clip: false,
                  child: GlassCard(
                    padding: const EdgeInsets.all(24),  // 28 thi 24
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          height: 70,  // 80 thi 70
                          width: 70,   // 80 thi 70
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xff7F5AF0), Color(0xffFF6B9A)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xff7F5AF0).withOpacity(0.35),
                                blurRadius: 20,  // 25 thi 20
                                offset: const Offset(0, 10),  // 12 thi 10
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.lock_rounded,
                            size: 32,  // 38 thi 32
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),  // 20 thi 16
                        Text(
                          "Welcome Back",
                          style: TextStyle(
                            fontSize: 24,  // 26 thi 24
                            fontWeight: FontWeight.w900,
                            color: isDark ? Colors.white : const Color(0xff151225),
                          ),
                        ),
                        const SizedBox(height: 4),  // 6 thi 4
                        Text(
                          _isLockedOut
                              ? "🔒 Locked for $_lockoutTimer seconds"
                              : "Enter your PIN to unlock VibeNote",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,  // 14 thi 13
                            color: _isLockedOut
                                ? Colors.redAccent
                                : (isDark ? Colors.white60 : Colors.black54),
                            fontWeight:
                            _isLockedOut ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                        if (_wrongAttempts > 0 && !_isLockedOut) ...[
                          const SizedBox(height: 10),  // 12 thi 10
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,  // 14 thi 12
                              vertical: 6,     // 8 thi 6
                            ),
                            decoration: BoxDecoration(
                              color: Colors.redAccent.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(10),  // 12 thi 10
                              border: Border.all(
                                color: Colors.redAccent.withOpacity(0.30),
                              ),
                            ),
                            child: Text(
                              "$_wrongAttempts/${_maxAttempts} attempts used",
                              style: const TextStyle(
                                color: Colors.redAccent,
                                fontSize: 11,  // 12 thi 11
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),  // 24 thi 20

                        // PIN Container - dots only (no keyboard/TextField)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          width: 260,
                          decoration: BoxDecoration(
                            color: _isLockedOut
                                ? Colors.grey.withOpacity(0.1)
                                : (isDark
                                ? Colors.white.withOpacity(0.07)
                                : Colors.white.withOpacity(0.70)),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: !_isLockedOut
                                  ? const Color(0xff7F5AF0).withOpacity(0.35)
                                  : Colors.transparent,
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildPinDots(),
                              if (errorText != null) ...[
                                const SizedBox(height: 10),
                                Text(
                                  errorText!,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: errorText!.contains("Wrong") ||
                                        errorText!.contains("error")
                                        ? Colors.redAccent
                                        : Colors.orangeAccent,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 22),
                        _buildNumberPad(isDark),
                        const SizedBox(height: 20),  // 20 thi 16
                        FutureBuilder<bool>(
                          future: BiometricService.isFingerprintAvailable(),
                          builder: (context, snapshot) {
                            if (snapshot.data != true || _isLockedOut) {
                              return const SizedBox.shrink();
                            }
                            return GestureDetector(
                              onTap: _tryBiometric,
                              child: Container(
                                height: 58,
                                width: 260,  // Match PIN container width
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xff7F5AF0), Color(0xffFF6B9A)],
                                  ),
                                  borderRadius: BorderRadius.circular(18),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xff7F5AF0).withOpacity(0.35),
                                      blurRadius: 18,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.fingerprint_rounded,
                                      color: Colors.white,
                                      size: 28,
                                    ),
                                    const SizedBox(width: 10),
                                    const Text(
                                      "Use Fingerprint",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        if (_wrongAttempts >= 3 && !_isLockedOut) ...[
                          const SizedBox(height: 12),  // 16 thi 12
                          TextButton(
                            onPressed: () {
                              _showPinError(
                                "🔐 Please restart the app to reset PIN.",
                                isError: false,
                              );
                            },
                            child: Text(
                              "Forgot PIN? Restart app",
                              style: TextStyle(
                                color: isDark ? Colors.white54 : Colors.black54,
                                fontSize: 11,  // 12 thi 11
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.underline,
                              ),
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
        )
    );
  }

  Widget _buildPinDots() {
    final pin = _pinController.text;

    return AnimatedBuilder(
      animation: _dotsLoadingController,
      builder: (context, _) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(4, (index) {
            final bool isFilled = index < pin.length;

            double scale = 1.0;
            double opacity = 1.0;

            if (_isVerifying) {
              // One dot at a time lights up and fades, chasing across all 4 —
              // like the Google Pay PIN-checking animation.
              final phase = (_dotsLoadingController.value * 4 - index) % 4;
              final distance = math.min(phase, 4 - phase);
              final wave = (1 - distance).clamp(0.0, 1.0);
              opacity = 0.30 + (0.70 * wave);
              scale = 0.80 + (0.40 * wave);
            }

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 10),
              child: Opacity(
                opacity: opacity,
                child: Transform.scale(
                  scale: scale,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isFilled
                          ? const Color(0xff7F5AF0)
                          : Colors.grey.shade300,
                      border: Border.all(
                        color: isFilled
                            ? const Color(0xff7F5AF0)
                            : Colors.grey.shade400,
                        width: 1.5,
                      ),
                    ),
                    child: isFilled
                        ? Center(
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                      ),
                    )
                        : null,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildNumberPad(bool isDark) {
    const rows = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', 'back'],
    ];

    return SizedBox(
      width: 260,
      child: Column(
        children: rows.map((row) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: row.map((key) {
                if (key.isEmpty) {
                  return const SizedBox(width: 68, height: 68);
                }
                if (key == 'back') {
                  return _buildKeyButton(
                    isDark: isDark,
                    child: Icon(
                      Icons.backspace_outlined,
                      color: isDark ? Colors.white70 : const Color(0xff151225),
                      size: 24,
                    ),
                    onTap: _onBackspaceTap,
                  );
                }
                return _buildKeyButton(
                  isDark: isDark,
                  child: Text(
                    key,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xff151225),
                    ),
                  ),
                  onTap: () => _onKeyTap(key),
                );
              }).toList(),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildKeyButton({
    required bool isDark,
    required Widget child,
    required VoidCallback onTap,
  }) {
    final disabled = _isLockedOut || _isVerifying;
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: Container(
        width: 68,
        height: 68,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: disabled
              ? Colors.grey.withOpacity(0.08)
              : (isDark
              ? Colors.white.withOpacity(0.08)
              : Colors.white.withOpacity(0.55)),
          border: Border.all(
            color: disabled
                ? Colors.transparent
                : const Color(0xff7F5AF0).withOpacity(0.20),
          ),
        ),
        child: Opacity(
          opacity: disabled ? 0.4 : 1.0,
          child: child,
        ),
      ),
    );
  }
}

// ============================================================
// SHARED WIDGETS
// ============================================================

class AppGradientBackground extends StatelessWidget {
  final Widget child;

  const AppGradientBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? const [Color(0xff090A12), Color(0xff17122B), Color(0xff261A3D)]
              : const [Color(0xffF8F5FF), Color(0xffEFE7FF), Color(0xffFFEAF3)],
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

  const _GlowCircle({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
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
        filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.08)
                : Colors.white.withOpacity(0.55),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withOpacity(0.25)),
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
  final VoidCallback? onTap;
  final IconData? icon;

  const GradientButton({
    super.key,
    required this.text,
    this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = onTap == null;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: isDisabled ? null : onTap,
      child: Container(
        height: 44,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: isDisabled
              ? LinearGradient(
            colors: [
              Colors.grey.withOpacity(0.3),
              Colors.grey.withOpacity(0.2),
            ],
          )
              : const LinearGradient(
            colors: [Color(0xff7F5AF0), Color(0xffFF6B9A)],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: isDisabled
              ? null
              : [
            BoxShadow(
              color: const Color(0xff7F5AF0).withOpacity(0.35),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 6),
            ],
            Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
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