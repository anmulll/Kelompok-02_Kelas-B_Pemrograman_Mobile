import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/routes/app_routes.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  late final Animation<double> _circlePosition;
  late final Animation<double> _circleBurst;
  late final Animation<double> _burstOpacity;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _logoScale;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    );

    // Circle bergerak dari bawah menuju tengah.
    _circlePosition = Tween<double>(begin: 1.35, end: 0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.40, curve: Curves.easeOutCubic),
      ),
    );

    // Circle meledak / membesar di tengah.
    _circleBurst = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.38, 0.70, curve: Curves.easeOutExpo),
    );

    // Circle menghilang setelah ledakan.
    _burstOpacity = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.70, 0.84, curve: Curves.easeIn),
      ),
    );

    // Logo muncul.
    _logoOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.65, 0.83, curve: Curves.easeOut),
    );

    _logoScale = Tween<double>(begin: 0.75, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.65, 0.86, curve: Curves.easeOutBack),
      ),
    );

    _startSplash();
  }

  Future<void> _startSplash() async {
    await _controller.forward();

    if (!mounted) return;

    Navigator.pushReplacementNamed(context, AppRoutes.home);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0B0C),
      body: SizedBox.expand(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final screenSize = MediaQuery.sizeOf(context);
            final maxDimension = math.max(screenSize.width, screenSize.height);

            // Ukuran circle cukup besar untuk menutupi seluruh layar.
            final burstScale = (maxDimension * 1.8) / 32;

            return Stack(
              alignment: Alignment.center,
              children: [
                // Background.
                const Positioned.fill(
                  child: ColoredBox(color: Color(0xFF0B0B0C)),
                ),

                // Circle yang bergerak dan meledak.
                Align(
                  alignment: Alignment(0, _circlePosition.value),
                  child: Opacity(
                    opacity: _burstOpacity.value,
                    child: Transform.scale(
                      scale: 1 + (_circleBurst.value * burstScale),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                          color: Color(0xFFC3F53C),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ),

                // Logo selalu berada tepat di tengah layar.
                Center(
                  child: Opacity(
                    opacity: _logoOpacity.value,
                    child: Transform.scale(
                      scale: _logoScale.value,
                      child: const _CourtMateLogo(),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CourtMateLogo extends StatelessWidget {
  const _CourtMateLogo();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 48,
          height: 48,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF1C1D1F),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF232528)),
          ),
          child: CustomPaint(painter: _CourtLogoPainter()),
        ),
        const SizedBox(height: 12),
        const Text(
          'CourtMate',
          style: TextStyle(
            color: Color(0xFFF2F3F0),
            fontSize: 24,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'BOOKING LAPANGAN OLAHRAGA',
          style: TextStyle(
            color: Color(0xFF8B8D88),
            fontSize: 10,
            fontWeight: FontWeight.w500,
            letterSpacing: 1.4,
          ),
        ),
      ],
    );
  }
}

class _CourtLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFC3F53C)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Outline lapangan.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(1, 1, size.width - 2, size.height - 2),
        const Radius.circular(2),
      ),
      paint,
    );

    // Garis tengah lapangan.
    canvas.drawLine(
      Offset(size.width / 2, 1),
      Offset(size.width / 2, size.height - 1),
      paint,
    );

    // Lingkaran tengah.
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.width * 0.16,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
