import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:single_clik/utils/shar_preferences.dart';
import 'constants/constant_color.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _loaderController;

  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;
  late Animation<Offset> _slideAnim;
  late Animation<double> _quoteAnim;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _checkLogin();
  }

  void _initAnimations() {
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 1600),
      vsync: this,
    );

    _loaderController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    )..repeat();

    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _scaleAnim = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.65, curve: Curves.elasticOut),
      ),
    );

    _slideAnim =
        Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.2, 0.7, curve: Curves.easeOutCubic),
      ),
    );

    _quoteAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.55, 1.0, curve: Curves.easeOut),
      ),
    );

    _mainController.forward();
  }

  void _checkLogin() async {
    final login =
        await SharPreferences.getBoolean(SharPreferences.isLogin) ?? false;
    Timer(const Duration(seconds: 3), () {
      if (login) {
        Get.offNamed('home');
      } else {
        Get.offNamed('getStarted');
      }
    });
  }

  @override
  void dispose() {
    _mainController.dispose();
    _loaderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final w = size.width;
    final h = size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // ── 4 subtle corner bubbles only ──────────────────────
          _bubble(
            left: -h * 0.12,
            top: -h * 0.08,
            size: h * 0.32,
            color: ConstantColor.primary,
            opacity: 0.09,
          ),
          _bubble(
            right: -h * 0.10,
            bottom: -h * 0.08,
            size: h * 0.30,
            color: ConstantColor.primaryDark,
            opacity: 0.08,
          ),
          _bubble(
            right: w * 0.04,
            top: h * 0.06,
            size: h * 0.10,
            color: ConstantColor.primary,
            opacity: 0.10,
          ),
          _bubble(
            left: w * 0.02,
            bottom: h * 0.10,
            size: h * 0.08,
            color: ConstantColor.primaryDark,
            opacity: 0.09,
          ),

          // ── Content ───────────────────────────────────────────
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Column(
                children: [
                  const Spacer(flex: 3),

                  // Logo - Made bigger, removed circles and background
                  ScaleTransition(
                    scale: _scaleAnim,
                    child: _Logo(size: h * 0.28), // Increased from 0.16 to 0.28
                  ),

                  SizedBox(height: h * 0.03),

                  // Brand name + underline
                  SlideTransition(
                    position: _slideAnim,
                    child: _BrandName(width: w),
                  ),

                  SizedBox(height: h * 0.055),

                  // Quotation tagline
                  AnimatedBuilder(
                    animation: _quoteAnim,
                    builder: (_, __) => Opacity(
                      opacity: _quoteAnim.value,
                      child: Transform.translate(
                        offset: Offset(0, 18 * (1 - _quoteAnim.value)),
                        child: _QuotationTagline(width: w),
                      ),
                    ),
                  ),

                  const Spacer(flex: 4),

                  // Loader
                  FadeTransition(
                    opacity: _mainController.drive(
                      Tween<double>(begin: 0.0, end: 1.0).chain(
                        CurveTween(
                          curve:
                              const Interval(0.75, 1.0, curve: Curves.easeIn),
                        ),
                      ),
                    ),
                    child: _Loader(controller: _loaderController, width: w),
                  ),

                  SizedBox(height: h * 0.05),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Helper to create a soft radial bubble positioned anywhere
  Widget _bubble({
    double? left,
    double? right,
    double? top,
    double? bottom,
    required double size,
    required Color color,
    required double opacity,
  }) {
    return Positioned(
      left: left,
      right: right,
      top: top,
      bottom: bottom,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            center: const Alignment(-0.3, -0.3),
            radius: 0.85,
            colors: [
              color.withOpacity(opacity),
              color.withOpacity(0.01),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Logo - Clean version without circles and background
// ─────────────────────────────────────────────────────────────────────────────

class _Logo extends StatelessWidget {
  final double size;
  const _Logo({required this.size});

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: 'logo',
      child: Image.asset(
        'assets/images/sc_logo_new.png',
        width: size,
        height: size,
        fit: BoxFit.contain,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Brand name
// ─────────────────────────────────────────────────────────────────────────────

class _BrandName extends StatelessWidget {
  final double width;
  const _BrandName({required this.width});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            children: [
              TextSpan(
                text: 'SINGLE',
                style: GoogleFonts.poppins(
                  fontSize: width * 0.108,
                  fontWeight: FontWeight.w800,
                  color: ConstantColor.primary,
                  letterSpacing: 4,
                  shadows: [
                    Shadow(
                      blurRadius: 10,
                      color: ConstantColor.primary.withOpacity(0.22),
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
              ),
              TextSpan(
                text: ' CLIK',
                style: GoogleFonts.poppins(
                  fontSize: width * 0.108,
                  fontWeight: FontWeight.w800,
                  color: ConstantColor.primaryDark,
                  letterSpacing: 4,
                  shadows: [
                    Shadow(
                      blurRadius: 10,
                      color: ConstantColor.primaryDark.withOpacity(0.22),
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: width * 0.28,
          height: 2.5,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            gradient: LinearGradient(
              colors: [ConstantColor.primary, ConstantColor.primaryDark],
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Quotation-style tagline
// ─────────────────────────────────────────────────────────────────────────────

class _QuotationTagline extends StatelessWidget {
  final double width;
  const _QuotationTagline({required this.width});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: width * 0.12),
      child: Stack(
        children: [
          // Opening quote mark
          Positioned(
            top: -8,
            left: 0,
            child: Text(
              '\u201C',
              style: GoogleFonts.cormorantGaramond(
                fontSize: 64,
                height: 1,
                color: ConstantColor.primary.withOpacity(0.18),
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          // Closing quote mark
          Positioned(
            bottom: -8,
            right: 0,
            child: Text(
              '\u201D',
              style: GoogleFonts.cormorantGaramond(
                fontSize: 64,
                height: 1,
                color: ConstantColor.primaryDark.withOpacity(0.18),
                fontWeight: FontWeight.w900,
              ),
            ),
          ),

          // Quote text
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: width * 0.06,
              vertical: 10,
            ),
            child: Column(
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [
                      ConstantColor.primary,
                      ConstantColor.primaryDark,
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ).createShader(bounds),
                  child: Text(
                    "Let's Grow Together",
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: width * 0.072,
                      fontWeight: FontWeight.w700,
                      color: Colors.white, // masked by ShaderMask
                      letterSpacing: 0.5,
                      height: 1.45,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                SizedBox(height: width * 0.04),

                // Attribution dash + name
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 28,
                      height: 1.5,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            ConstantColor.primary.withOpacity(0.4),
                            ConstantColor.primaryDark.withOpacity(0.4),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Single Clik',
                      style: GoogleFonts.poppins(
                        fontSize: width * 0.028,
                        fontWeight: FontWeight.w600,
                        color: ConstantColor.primaryDark.withOpacity(0.45),
                        letterSpacing: 1.8,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Loading indicator
// ─────────────────────────────────────────────────────────────────────────────

class _Loader extends StatelessWidget {
  final AnimationController controller;
  final double width;
  const _Loader({required this.controller, required this.width});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: 30,
          height: 30,
          child: AnimatedBuilder(
            animation: controller,
            builder: (_, __) => CircularProgressIndicator(
              value: controller.value,
              strokeWidth: 2.2,
              strokeCap: StrokeCap.round,
              valueColor: AlwaysStoppedAnimation<Color>(
                ConstantColor.primary.withOpacity(0.75),
              ),
              backgroundColor: ConstantColor.primary.withOpacity(0.10),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Loading',
          style: GoogleFonts.poppins(
            fontSize: width * 0.028,
            fontWeight: FontWeight.w600,
            color: ConstantColor.primary.withOpacity(0.40),
            letterSpacing: 2.0,
          ),
        ),
      ],
    );
  }
}
