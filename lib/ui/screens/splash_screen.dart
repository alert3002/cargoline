import 'dart:async';
import 'dart:math' as math;

import 'package:cargo_line_tj/core/greeting.dart';
import 'package:flutter/material.dart';

/// Fast welcome (~4.8s): logo → brand → greeting + full-screen slow fireflies.
class CargoSplashScreen extends StatefulWidget {
  const CargoSplashScreen({
    super.key,
    required this.onReady,
    this.displayNameOverride,
  });

  final VoidCallback onReady;
  final String? displayNameOverride;

  @override
  State<CargoSplashScreen> createState() => _CargoSplashScreenState();
}

class _CargoSplashScreenState extends State<CargoSplashScreen>
    with TickerProviderStateMixin {
  static const _totalMs = 4800;
  static const _brand = 'Cargo Line.Tj';

  bool _done = false;
  int _brandVisible = 0;
  bool _showGreeting = false;
  bool _showName = false;
  Timer? _end;
  Timer? _typeTimer;
  late final AnimationController _logoSlide;
  late final AnimationController _fireflies;
  late final AnimationController _nameFade;
  late final List<_Firefly> _flies;

  @override
  void initState() {
    super.initState();
    final rng = math.Random(19);
    _flies = List.generate(42, (_) => _Firefly.random(rng));

    _logoSlide = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    )..forward();
    // Slow drift across the whole screen.
    _fireflies = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 11000),
    )..repeat();
    _nameFade = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );

    Future<void>.delayed(const Duration(milliseconds: 180), () {
      if (!mounted) return;
      _startTypewriter();
    });

    _end = Timer(const Duration(milliseconds: _totalMs), _finish);
  }

  @override
  void didUpdateWidget(covariant CargoSplashScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.displayNameOverride != widget.displayNameOverride &&
        _showName) {
      setState(() {});
    }
  }

  void _startTypewriter() {
    _typeTimer = Timer.periodic(const Duration(milliseconds: 95), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_brandVisible >= _brand.length) {
        t.cancel();
        _onBrandDone();
        return;
      }
      setState(() => _brandVisible++);
    });
  }

  Future<void> _onBrandDone() async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    if (!mounted) return;
    setState(() => _showGreeting = true);
    await Future<void>.delayed(const Duration(milliseconds: 420));
    if (!mounted) return;
    setState(() => _showName = true);
    _nameFade.forward();
  }

  void _finish() {
    if (_done) return;
    _done = true;
    _end?.cancel();
    _typeTimer?.cancel();
    widget.onReady();
  }

  @override
  void dispose() {
    _end?.cancel();
    _typeTimer?.cancel();
    _logoSlide.dispose();
    _fireflies.dispose();
    _nameFade.dispose();
    super.dispose();
  }

  String get _userName {
    final n = widget.displayNameOverride?.trim();
    if (n != null && n.isNotEmpty) return n;
    return 'Рады вас видеть!';
  }

  @override
  Widget build(BuildContext context) {
    final day = isDayGreetingPeriod();
    final asset =
        day ? 'assets/images/welcome_day.jpg' : 'assets/images/welcome_night.jpg';
    final top = MediaQuery.paddingOf(context).top;
    final greeting = getGreeting();
    final userName = _userName;
    final sky = day ? const Color(0xFF1A2744) : const Color(0xFF0A1020);

    final logoOffset = Tween<Offset>(
      begin: const Offset(-0.22, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _logoSlide, curve: Curves.easeOutCubic));

    return Scaffold(
      backgroundColor: sky,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            asset,
            fit: BoxFit.cover,
            alignment: const Alignment(0.0, -0.08),
            filterQuality: FilterQuality.low,
            gaplessPlayback: true,
            errorBuilder: (_, __, ___) => ColoredBox(color: sky),
          ),
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.center,
                  colors: [Color(0x55000000), Color(0x00000000)],
                ),
              ),
            ),
          ),
          // Full-screen slow fireflies for the whole welcome.
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _fireflies,
                builder: (_, __) => CustomPaint(
                  painter: _FireflyPainter(
                    flies: _flies,
                    t: _fireflies.value,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: top + 32,
            left: 22,
            right: 22,
            child: IgnorePointer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SlideTransition(
                    position: logoOffset,
                    child: FadeTransition(
                      opacity: _logoSlide,
                      child: Row(
                        children: [
                          Image.asset(
                            'assets/images/welcome_logo.png',
                            height: 42,
                            width: 42,
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.medium,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.local_shipping_rounded,
                              color: Colors.white,
                              size: 38,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _brand.substring(0, _brandVisible),
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                height: 1.05,
                                color: Colors.white,
                                shadows: [
                                  Shadow(blurRadius: 14, color: Colors.black87),
                                  Shadow(blurRadius: 3, color: Colors.black54),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_showGreeting) ...[
                    const SizedBox(height: 14),
                    Text(
                      greeting,
                      style: const TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.w800,
                        height: 1.15,
                        color: Colors.white,
                        shadows: [
                          Shadow(blurRadius: 18, color: Color(0xAAFFD54F)),
                          Shadow(blurRadius: 10, color: Colors.black87),
                        ],
                      ),
                    ),
                  ],
                  if (_showName) ...[
                    const SizedBox(height: 8),
                    FadeTransition(
                      opacity: _nameFade,
                      child: Text(
                        userName,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          shadows: [
                            Shadow(blurRadius: 12, color: Colors.black87),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Firefly {
  _Firefly({
    required this.nx,
    required this.ny,
    required this.ampX,
    required this.ampY,
    required this.phase,
    required this.size,
    required this.speed,
  });

  factory _Firefly.random(math.Random rng) {
    return _Firefly(
      nx: rng.nextDouble(),
      ny: rng.nextDouble(),
      ampX: 6 + rng.nextDouble() * 22,
      ampY: 5 + rng.nextDouble() * 18,
      phase: rng.nextDouble() * math.pi * 2,
      size: 1.2 + rng.nextDouble() * 2.4,
      speed: 0.25 + rng.nextDouble() * 0.55,
    );
  }

  final double nx;
  final double ny;
  final double ampX;
  final double ampY;
  final double phase;
  final double size;
  final double speed;
}

class _FireflyPainter extends CustomPainter {
  _FireflyPainter({required this.flies, required this.t});

  final List<_Firefly> flies;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    for (final f in flies) {
      final a = (t * math.pi * 2 * f.speed) + f.phase;
      final x = f.nx * size.width + math.sin(a) * f.ampX;
      final y = f.ny * size.height + math.cos(a * 0.9) * f.ampY;
      final pulse = 0.3 + 0.7 * (0.5 + 0.5 * math.sin(a * 1.4));
      // Soft glow without expensive MaskFilter (safer on mid-range phones).
      final glow = Paint()
        ..color = Color.fromRGBO(255, 226, 120, 0.16 * pulse);
      final mid = Paint()
        ..color = Color.fromRGBO(255, 240, 170, 0.45 * pulse);
      final core = Paint()
        ..color = Color.fromRGBO(255, 252, 230, 0.95 * pulse);
      canvas.drawCircle(Offset(x, y), f.size * 3.4, glow);
      canvas.drawCircle(Offset(x, y), f.size * 1.7, mid);
      canvas.drawCircle(Offset(x, y), f.size, core);
    }
  }

  @override
  bool shouldRepaint(covariant _FireflyPainter old) => old.t != t;
}
