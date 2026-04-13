import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController(initialPage: 0);
  int _currentPage = 0;
  late AnimationController _illustrationController;

  final List<Map<String, dynamic>> onboardingData = [
    {
      "title": "Cuaca Real-Time\ndi Genggaman",
      "desc":
          "Pantau suhu, kelembaban, dan kondisi cuaca terkini berdasarkan lokasimu secara akurat.",
      "accent": Color(0xFF1A73E8),
      "bgAccent": Color(0xFFE8F0FE),
      "illustration": _WeatherIllustration(),
    },
    {
      "title": "Analisis Awan\ndengan AI",
      "desc":
          "Foto langit dari kameramu dan biarkan AI kami menganalisis jenis awan serta prediksi cuaca.",
      "accent": Color(0xFF0F9D58),
      "bgAccent": Color(0xFFE6F4EA),
      "illustration": _CameraIllustration(),
    },
    {
      "title": "Presisi Tinggi,\nSatu Aplikasi",
      "desc":
          "Data satelit dan Computer Vision berpadu menghadirkan akurasi cuaca terbaik untukmu.",
      "accent": Color(0xFF7B61FF),
      "bgAccent": Color(0xFFF0EDFF),
      "illustration": _AnalyticsIllustration(),
    },
  ];

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    _illustrationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _illustrationController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seenOnboard', true);
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    }
  }

  void _onPageChanged(int value) {
    setState(() => _currentPage = value);
    _illustrationController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final data = onboardingData[_currentPage];
    final Color accent = data["accent"];
    final Color bgAccent = data["bgAccent"];

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Skip button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Dot brand
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: accent,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'SkyVision',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF0D0D0D),
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                  if (_currentPage < onboardingData.length - 1)
                    GestureDetector(
                      onTap: _completeOnboarding,
                      child: Text(
                        'Lewati',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF9E9E9E),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Illustration area (swipeable)
            Expanded(
              flex: 5,
              child: PageView(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                children: onboardingData.map((d) {
                  return Padding(
                    padding: const EdgeInsets.all(32),
                    child: AnimatedBuilder(
                      animation: _illustrationController,
                      builder: (context, child) => Opacity(
                        opacity: _illustrationController.value,
                        child: Transform.translate(
                          offset: Offset(
                            0,
                            20 * (1 - _illustrationController.value),
                          ),
                          child: child,
                        ),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: d["bgAccent"],
                          borderRadius: BorderRadius.circular(32),
                        ),
                        child: d["illustration"],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            // Text content area
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),

                    // Step indicator (dots)
                    Row(
                      children: List.generate(
                        onboardingData.length,
                        (i) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                          width: _currentPage == i ? 24 : 6,
                          height: 6,
                          margin: const EdgeInsets.only(right: 6),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: _currentPage == i
                                ? accent
                                : const Color(0xFFDDDDDD),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Title — animate on page change
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Text(
                        data["title"],
                        key: ValueKey(_currentPage),
                        style: GoogleFonts.inter(
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0D0D0D),
                          letterSpacing: -0.8,
                          height: 1.2,
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Description
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Text(
                        data["desc"],
                        key: ValueKey('desc_$_currentPage'),
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF707070),
                          height: 1.65,
                          letterSpacing: -0.1,
                        ),
                      ),
                    ),

                    const Spacer(),

                    // CTA Button
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accent,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: () {
                            if (_pageController.hasClients) {
                              if (_currentPage == onboardingData.length - 1) {
                                _completeOnboarding();
                              } else {
                                _pageController.nextPage(
                                  duration: const Duration(milliseconds: 400),
                                  curve: Curves.easeInOut,
                                );
                              }
                            }
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _currentPage == onboardingData.length - 1
                                    ? 'Mulai Sekarang'
                                    : 'Selanjutnya',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward_rounded, size: 18),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),
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

// ─────────────────────────────────────────────
// ILUSTRASI CUSTOM PER HALAMAN
// ─────────────────────────────────────────────

class _WeatherIllustration extends StatelessWidget {
  const _WeatherIllustration();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CustomPaint(
        size: const Size(260, 260),
        painter: _WeatherPainter(),
      ),
    );
  }
}

class _WeatherPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Matahari
    final sunPaint = Paint()..color = const Color(0xFFFFC107);
    canvas.drawCircle(Offset(cx, cy - 20), 52, sunPaint);

    // Sinar matahari
    final rayPaint = Paint()
      ..color = const Color(0xFFFFC107).withOpacity(0.35)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 8; i++) {
      final angle = (i * 3.14159 * 2 / 8);
      final startR = 60.0;
      final endR = 78.0;
      canvas.drawLine(
        Offset(cx + startR * _cos(angle), cy - 20 + startR * _sin(angle)),
        Offset(cx + endR * _cos(angle), cy - 20 + endR * _sin(angle)),
        rayPaint,
      );
    }

    // Awan besar
    final cloudPaint = Paint()..color = Colors.white;
    _drawCloud(canvas, cloudPaint, Offset(cx, cy + 38), 80, 36);

    // Awan kecil (aksen)
    final cloudPaint2 = Paint()..color = Colors.white.withOpacity(0.7);
    _drawCloud(canvas, cloudPaint2, Offset(cx - 50, cy + 55), 48, 22);

    // Pin lokasi
    final pinPaint = Paint()..color = const Color(0xFF1A73E8);
    canvas.drawCircle(Offset(cx + 56, cy - 50), 10, pinPaint);
    final path = Path()
      ..moveTo(cx + 56, cy - 34)
      ..lineTo(cx + 50, cy - 44)
      ..lineTo(cx + 62, cy - 44)
      ..close();
    canvas.drawPath(path, pinPaint);

    // Dot dalam pin
    canvas.drawCircle(
      Offset(cx + 56, cy - 50),
      4,
      Paint()..color = Colors.white,
    );

    // Teks suhu (simulasi)
    final tempBg = Paint()
      ..color = const Color(0xFF1A73E8)
      ..style = PaintingStyle.fill;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx - 52, cy + 10), width: 60, height: 28),
      const Radius.circular(10),
    );
    canvas.drawRRect(rrect, tempBg);
  }

  void _drawCloud(
    Canvas canvas,
    Paint paint,
    Offset center,
    double w,
    double h,
  ) {
    final path = Path();
    path.addOval(
      Rect.fromCenter(
        center: Offset(center.dx - w * 0.22, center.dy + h * 0.15),
        width: w * 0.55,
        height: h * 0.9,
      ),
    );
    path.addOval(
      Rect.fromCenter(
        center: Offset(center.dx + w * 0.15, center.dy + h * 0.1),
        width: w * 0.65,
        height: h * 0.85,
      ),
    );
    path.addOval(
      Rect.fromCenter(
        center: Offset(center.dx - w * 0.02, center.dy - h * 0.05),
        width: w * 0.55,
        height: h,
      ),
    );
    path.addRect(
      Rect.fromLTRB(
        center.dx - w / 2,
        center.dy + h * 0.05,
        center.dx + w / 2,
        center.dy + h / 2,
      ),
    );
    canvas.drawPath(path, paint);
  }

  double _cos(double a) => (a == 0)
      ? 1
      : (a == 1.5707963)
      ? 0
      : (a == 3.14159)
      ? -1
      : (a == 4.712389)
      ? 0
      : _cosCalc(a);
  double _sin(double a) => _cosCalc(a - 1.5707963);
  double _cosCalc(double a) {
    double result = 1;
    double term = 1;
    for (int i = 1; i <= 10; i++) {
      term *= -a * a / (2 * i * (2 * i - 1));
      result += term;
    }
    return result;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Halaman 2: Kamera & Awan ──
class _CameraIllustration extends StatelessWidget {
  const _CameraIllustration();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Phone frame
          Container(
            width: 160,
            height: 240,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: const Color(0xFF0F9D58).withOpacity(0.25),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Column(
                children: [
                  // Viewfinder area
                  Expanded(
                    child: Container(
                      color: const Color(0xFFE8F5E9),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Awan besar
                          Positioned(
                            top: 30,
                            child: CustomPaint(
                              size: const Size(120, 50),
                              painter: _MiniCloudPainter(
                                color: const Color(0xFFB2DFDB),
                              ),
                            ),
                          ),
                          // Awan kecil
                          Positioned(
                            top: 50,
                            left: 8,
                            child: CustomPaint(
                              size: const Size(70, 35),
                              painter: _MiniCloudPainter(
                                color: const Color(0xFFA5D6A7),
                              ),
                            ),
                          ),
                          // Scan grid lines
                          CustomPaint(
                            size: const Size(100, 80),
                            painter: _ScanGridPainter(),
                          ),
                          // AI label
                          Positioned(
                            bottom: 20,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F9D58),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'AI Scanning...',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Camera bar
                  Container(
                    height: 44,
                    color: Colors.white,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Icon(
                          Icons.photo_outlined,
                          size: 18,
                          color: Colors.grey.shade400,
                        ),
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF0F9D58),
                              width: 2.5,
                            ),
                          ),
                          child: Center(
                            child: Container(
                              width: 18,
                              height: 18,
                              decoration: const BoxDecoration(
                                color: Color(0xFF0F9D58),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                        Icon(
                          Icons.flip_camera_ios_outlined,
                          size: 18,
                          color: Colors.grey.shade400,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Floating result chip
          Positioned(
            right: 30,
            top: 50,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF0F9D58).withOpacity(0.3),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cumulus',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F9D58),
                    ),
                  ),
                  Text(
                    'Cerah Berawan',
                    style: TextStyle(fontSize: 8, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniCloudPainter extends CustomPainter {
  final Color color;
  _MiniCloudPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final cx = size.width / 2;
    final cy = size.height / 2;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx - size.width * 0.2, cy + size.height * 0.1),
        width: size.width * 0.55,
        height: size.height * 0.8,
      ),
      paint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx + size.width * 0.15, cy + size.height * 0.05),
        width: size.width * 0.6,
        height: size.height * 0.75,
      ),
      paint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx - size.width * 0.02, cy - size.height * 0.1),
        width: size.width * 0.5,
        height: size.height * 0.9,
      ),
      paint,
    );
    canvas.drawRect(
      Rect.fromLTRB(
        cx - size.width / 2,
        cy + size.height * 0.02,
        cx + size.width / 2,
        cy + size.height / 2,
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ScanGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF0F9D58).withOpacity(0.5)
      ..strokeWidth = 1;

    // Corner brackets
    const l = 14.0;
    final corners = [
      [Offset(0, 0), Offset(l, 0), Offset(0, l)],
      [Offset(size.width, 0), Offset(size.width - l, 0), Offset(size.width, l)],
      [
        Offset(0, size.height),
        Offset(l, size.height),
        Offset(0, size.height - l),
      ],
      [
        Offset(size.width, size.height),
        Offset(size.width - l, size.height),
        Offset(size.width, size.height - l),
      ],
    ];

    for (final c in corners) {
      canvas.drawLine(c[0], c[1], paint);
      canvas.drawLine(c[0], c[2], paint);
    }

    // Scan line
    final scanPaint = Paint()
      ..color = const Color(0xFF0F9D58).withOpacity(0.4)
      ..strokeWidth = 1.5;
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      scanPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Halaman 3: Analitik & Presisi ──
class _AnalyticsIllustration extends StatelessWidget {
  const _AnalyticsIllustration();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 260,
        height: 260,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Background ring
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF7B61FF).withOpacity(0.15),
                  width: 20,
                ),
              ),
            ),
            // Middle ring
            Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF7B61FF).withOpacity(0.25),
                  width: 14,
                ),
              ),
            ),

            // Center circle
            Container(
              width: 90,
              height: 90,
              decoration: const BoxDecoration(
                color: Color(0xFF7B61FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.analytics_rounded,
                color: Colors.white,
                size: 36,
              ),
            ),

            // Floating stats chips
            Positioned(
              top: 8,
              right: 8,
              child: _StatChip(
                label: 'Akurasi',
                value: '97%',
                color: Color(0xFF7B61FF),
              ),
            ),
            Positioned(
              bottom: 16,
              left: 8,
              child: _StatChip(
                label: 'Data Satelit',
                value: 'Live',
                color: Color(0xFF0F9D58),
              ),
            ),
            Positioned(
              top: 80,
              left: 0,
              child: _StatChip(
                label: 'Update',
                value: '5 min',
                color: Color(0xFF1A73E8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.25)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: -0.3,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
