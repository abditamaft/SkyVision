import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'onboarding_screen.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<double> _slideAnim;

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);

    _slideAnim = Tween<double>(
      begin: 20,
      end: 0,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));

    _animController.forward();
    _checkFirstLaunch();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _checkFirstLaunch() async {
    await Future.delayed(const Duration(milliseconds: 2800));
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool seenOnboard = prefs.getBool('seenOnboard') ?? false;

    if (mounted) {
      if (seenOnboard) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const OnboardingScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: Stack(
          children: [
            // Subtle background accent — circle atas kanan
            Positioned(
              top: -60,
              right: -60,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF1A73E8).withOpacity(0.06),
                ),
              ),
            ),
            // Subtle background accent — circle bawah kiri
            Positioned(
              bottom: -80,
              left: -80,
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF1A73E8).withOpacity(0.05),
                ),
              ),
            ),

            // Konten tengah
            Center(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: AnimatedBuilder(
                  animation: _slideAnim,
                  builder: (context, child) => Transform.translate(
                    offset: Offset(0, _slideAnim.value),
                    child: child,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo container dengan border tipis
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: const Color(0xFFE8E8E8),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(20),
                        child: Image.asset(
                          'assets/images/skyvision_logo.png',
                          fit: BoxFit.contain,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // App name
                      Text(
                        'SkyVision',
                        style: GoogleFonts.inter(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0D0D0D),
                          letterSpacing: -1.0,
                          height: 1.1,
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Tagline
                      Text(
                        'Weather · Intelligence · Clarity',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF9E9E9E),
                          letterSpacing: 1.8,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Loading indicator bawah
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 48.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: const Color(0xFF1A73E8).withOpacity(0.5),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Developed by Abditama',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFFBBBBBB),
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
