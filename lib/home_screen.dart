import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/weather_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'five_day_forecast_screen.dart';
import 'ai_result_screen.dart';
import 'mountain_search_screen.dart';
import 'dart:io';
import 'dart:math' as math;
import 'package:image_picker/image_picker.dart';
import 'city_search_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ══════════════════════════════════════════════════
// HELPER: Tentukan fase waktu hari
// ══════════════════════════════════════════════════
enum _DayPhase { dawn, morning, afternoon, evening, night }

// SESUDAH:
_DayPhase _getDayPhase() {
  final now = DateTime.now();
  final time = now.hour + (now.minute / 60.0);
  // Dawn dari jam 5:00 sampai 6:30
  if (time >= 5.0 && time < 6.5) return _DayPhase.dawn;
  // Morning dari jam 6:30 sampai 12:00
  if (time >= 6.5 && time < 12.0) return _DayPhase.morning;
  if (time >= 12.0 && time < 17.0) return _DayPhase.afternoon;
  if (time >= 17.0 && time < 19.0) return _DayPhase.evening;

  return _DayPhase.night;
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final WeatherService _weatherService = WeatherService();
  bool isLoading = true;

  String cityName = "Menyambungkan...";
  String subLocation = "";
  String currentTemp = "--";
  String weatherDesc = "--";
  String highLowTemp = "--° / --°";
  int aqi = 83;
  List<dynamic> forecastList = [];
  double currentLat = -6.1783;
  double currentLon = 106.6319;
  String weatherMain = "Clear";

  // ── Animation Controllers ───────────────────────
  late AnimationController _pulseController;
  late AnimationController _floatController;
  late AnimationController _shimmerController;

  // Weather BG controllers
  late AnimationController _rainController;
  late AnimationController _cloudController;
  late AnimationController _thunderController;
  late AnimationController _sunRayController;
  late AnimationController _starController;

  late Animation<double> _pulseAnim;
  late Animation<double> _floatAnim;
  late Animation<double> _shimmerAnim;
  late Animation<double> _rainAnim;
  late Animation<double> _cloudAnim;
  late Animation<double> _thunderAnim;
  late Animation<double> _sunRayAnim;
  late Animation<double> _starAnim;

  bool _showThunderFlash = false;
  final _random = math.Random();

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    // Existing controllers
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _pulseAnim = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _floatAnim = Tween<double>(begin: -8, end: 8).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
    _shimmerAnim = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.linear),
    );

    // Weather BG controllers
    _rainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _cloudController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();
    _sunRayController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
    _starController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _thunderController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _rainAnim = Tween<double>(begin: 0, end: 1).animate(_rainController);
    _cloudAnim = Tween<double>(begin: 0, end: 1).animate(_cloudController);
    _sunRayAnim = Tween<double>(begin: 0, end: 1).animate(_sunRayController);
    _starAnim = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _starController, curve: Curves.easeInOut),
    );
    _thunderAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _thunderController, curve: Curves.easeOut),
    );

    // Thunder flash loop
    _startThunderLoop();

    _loadSavedLocation().then((_) => _fetchWeatherData());
  }

  void _startThunderLoop() async {
    while (mounted) {
      final delay = 3000 + _random.nextInt(5000);
      await Future.delayed(Duration(milliseconds: delay));
      if (!mounted) break;
      if (weatherMain.toLowerCase() == 'thunderstorm') {
        setState(() => _showThunderFlash = true);
        _thunderController.forward(from: 0).then((_) {
          if (mounted) setState(() => _showThunderFlash = false);
        });
      }
    }
  }

  Future<void> _loadSavedLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLat = prefs.getDouble('saved_lat');
    final savedLon = prefs.getDouble('saved_lon');
    if (savedLat != null && savedLon != null) {
      currentLat = savedLat;
      currentLon = savedLon;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _floatController.dispose();
    _shimmerController.dispose();
    _rainController.dispose();
    _cloudController.dispose();
    _sunRayController.dispose();
    _starController.dispose();
    _thunderController.dispose();
    super.dispose();
  }

  Future<void> _fetchWeatherData() async {
    setState(() => isLoading = true);
    try {
      final weatherData = await _weatherService.getCurrentWeather(
        currentLat,
        currentLon,
      );
      final forecastData = await _weatherService.getForecast(
        currentLat,
        currentLon,
      );

      String finalLocationName = weatherData['name'];
      String finalSubLocation = "";

      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          currentLat,
          currentLon,
        );
        if (placemarks.isNotEmpty) {
          Placemark place = placemarks[0];
          String desa = place.street ?? place.name ?? '';
          String kecamatan = place.subLocality ?? '';
          String kota = place.locality ?? place.subAdministrativeArea ?? '';
          String provinsi = place.administrativeArea ?? '';

          if (desa.isNotEmpty && desa != kecamatan) {
            finalLocationName = desa;
          } else if (kecamatan.isNotEmpty) {
            finalLocationName = kecamatan;
          }

          List<String> subDetails = [];
          if (kecamatan.isNotEmpty && finalLocationName != kecamatan)
            subDetails.add(kecamatan);
          if (kota.isNotEmpty) subDetails.add(kota);
          if (provinsi.isNotEmpty) subDetails.add(provinsi);
          finalSubLocation = subDetails.join(", ");
        }
      } catch (e) {
        print("Gagal melacak lokasi detail: $e");
      }

      if (mounted) {
        setState(() {
          cityName = finalLocationName;
          subLocation = finalSubLocation;
          currentTemp = weatherData['main']['temp'].round().toString();
          String desc = weatherData['weather'][0]['description'];
          weatherDesc = desc[0].toUpperCase() + desc.substring(1);
          weatherMain = weatherData['weather'][0]['main'];
          highLowTemp =
              "${weatherData['main']['temp_max'].round()}° / ${weatherData['main']['temp_min'].round()}°";
          forecastList = forecastData['list'];
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error API: $e");
      if (mounted) {
        setState(() {
          cityName = e.toString().contains("401")
              ? "API Key Belum Aktif"
              : "Gagal memuat data";
          isLoading = false;
        });
      }
    }
  }

  // ── GPS ──────────────────────────────────────────
  Future<void> _handleLocationPress() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showGpsDisabledDialog();
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Izin lokasi ditolak.')));
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Izin lokasi ditolak permanen.')),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          const Center(child: CircularProgressIndicator(color: Colors.white)),
    );

    try {
      Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      List<Placemark> placemarks = await placemarkFromCoordinates(
        pos.latitude,
        pos.longitude,
      );
      Placemark place = placemarks[0];
      String addr =
          "${place.street}, ${place.subLocality}, ${place.locality}, ${place.administrativeArea}";
      Navigator.pop(context);
      _showAddressConfirmationDialog(addr, pos.latitude, pos.longitude);
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal mendapatkan lokasi.')),
      );
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    try {
      final XFile? picked = await picker.pickImage(source: source);
      if (picked != null && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AiResultScreen(imageFile: File(picked.path)),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal mengambil gambar: $e')));
    }
  }

  // Tambahkan setelah method _pickImage()
  Future<void> _showCameraInstructionDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.85),
      builder: (_) => const _CameraInstructionDialog(),
    );
    // Setelah dialog selesai (2 loop animasi), langsung buka kamera
    if (mounted) _pickImage(ImageSource.camera);
  }

  void _showGpsDisabledDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A2744),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.location_off, color: Color(0xFF60A5FA)),
            const SizedBox(width: 10),
            Text(
              "GPS Tidak Aktif",
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: Text(
          "Aktifkan GPS di pengaturan HP untuk mendeteksi cuaca sekitar.",
          style: GoogleFonts.inter(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Batal",
              style: GoogleFonts.inter(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              Navigator.pop(context);
              await Geolocator.openLocationSettings();
            },
            child: Text(
              "Buka Pengaturan",
              style: GoogleFonts.inter(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddressConfirmationDialog(String address, double lat, double lon) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A2744),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.my_location, color: Color(0xFF60A5FA)),
            const SizedBox(width: 10),
            Text(
              "Lokasi Ditemukan",
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Gunakan lokasi ini?",
              style: GoogleFonts.inter(color: Colors.white70),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Text(
                address,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Batal",
              style: GoogleFonts.inter(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              Navigator.pop(context);
              setState(() {
                currentLat = lat;
                currentLon = lon;
              });
              final prefs = await SharedPreferences.getInstance();
              await prefs.setDouble('saved_lat', lat);
              await prefs.setDouble('saved_lon', lon);
              _fetchWeatherData();
            },
            child: Text(
              "Gunakan",
              style: GoogleFonts.inter(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // ── Weather Icon & Color ──────────────────────────
  IconData _getWeatherIcon(String main) {
    switch (main.toLowerCase()) {
      case 'clouds':
        return Icons.cloud_rounded;
      case 'rain':
        return Icons.water_drop_rounded;
      case 'thunderstorm':
        return Icons.thunderstorm_rounded;
      case 'drizzle':
        return Icons.grain;
      case 'snow':
        return Icons.ac_unit_rounded;
      case 'clear':
        return Icons.wb_sunny_rounded;
      case 'mist':
      case 'fog':
      case 'haze':
        return Icons.blur_on_rounded;
      default:
        return Icons.cloud_rounded;
    }
  }

  Color _getWeatherIconColor(String main) {
    switch (main.toLowerCase()) {
      case 'clear':
        return const Color(0xFFFBBF24);
      case 'clouds':
        return const Color(0xFF93C5FD);
      case 'rain':
        return const Color(0xFF60A5FA);
      case 'thunderstorm':
        return const Color(0xFFC084FC);
      case 'drizzle':
        return const Color(0xFF7DD3FC);
      case 'snow':
        return const Color(0xFFE0F2FE);
      default:
        return const Color(0xFF93C5FD);
    }
  }

  // ══════════════════════════════════════════════════
  // WEATHER + TIME GRADIENT
  // ══════════════════════════════════════════════════
  List<Color> _getWeatherGradient() {
    final phase = _getDayPhase();
    final wm = weatherMain.toLowerCase();

    // Night override — semua cuaca jadi gelap
    if (phase == _DayPhase.night) {
      switch (wm) {
        case 'thunderstorm':
          return [
            const Color(0xFF06030F),
            const Color(0xFF0D0820),
            const Color(0xFF160C35),
          ];
        case 'rain':
        case 'drizzle':
          return [
            const Color(0xFF04080F),
            const Color(0xFF0A1220),
            const Color(0xFF101A2E),
          ];
        default:
          return [
            const Color(0xFF060818),
            const Color(0xFF0D1030),
            const Color(0xFF18154A),
          ];
      }
    }

    // Evening — sedikit gelap + keunguan
    if (phase == _DayPhase.evening) {
      switch (wm) {
        case 'thunderstorm':
          return [
            const Color(0xFF0D0B20),
            const Color(0xFF1A1240),
            const Color(0xFF2A1060),
          ];
        case 'rain':
        case 'drizzle':
          return [
            const Color(0xFF0A1228),
            const Color(0xFF162050),
            const Color(0xFF1E2868),
          ];
        case 'clouds':
          return [
            const Color(0xFF0E0A20),
            const Color(0xFF1A1238),
            const Color(0xFF251848),
          ];
        case 'clear':
          return [
            const Color(0xFF1A0E30),
            const Color(0xFF2E1860),
            const Color(0xFFE05A2B),
          ];
        default:
          return [
            const Color(0xFF0E0A20),
            const Color(0xFF181030),
            const Color(0xFF221440),
          ];
      }
    }

    // Dawn — hangat kemerahan
    if (phase == _DayPhase.dawn) {
      return [
        const Color(0xFF0A0A20),
        const Color(0xFF1A1240),
        const Color(0xFFD4601A),
      ];
    }

    // Morning / Afternoon berdasarkan cuaca
    switch (wm) {
      case 'clear':
        if (phase == _DayPhase.morning) {
          return [
            const Color(0xFF0E4780),
            const Color(0xFF1B6DBF),
            const Color(0xFF62B8F5),
          ];
        }
        return [
          const Color(0xFF0B3A6E),
          const Color(0xFF1660B0),
          const Color(0xFF3A9FE8),
        ];

      case 'clouds':
        return [
          const Color(0xFF1A2845),
          const Color(0xFF253A60),
          const Color(0xFF2F4A78),
        ];

      case 'rain':
      case 'drizzle':
        return [
          const Color(0xFF0D1828),
          const Color(0xFF152438),
          const Color(0xFF1E3352),
        ];

      case 'thunderstorm':
        return [
          const Color(0xFF080818),
          const Color(0xFF10102A),
          const Color(0xFF1E1450),
        ];

      case 'snow':
        return [
          const Color(0xFF1A2F50),
          const Color(0xFF2A4575),
          const Color(0xFF406098),
        ];

      case 'mist':
      case 'fog':
      case 'haze':
        return [
          const Color(0xFF1E2A3A),
          const Color(0xFF2A3A50),
          const Color(0xFF3A4E68),
        ];

      default:
        return [
          const Color(0xFF0C1E4A),
          const Color(0xFF1A2F6B),
          const Color(0xFF2A4A9B),
        ];
    }
  }

  // ══════════════════════════════════════════════════
  // ANIMATED BACKGROUND LAYER
  // ══════════════════════════════════════════════════
  Widget _buildAnimatedBackground(Size size) {
    final wm = weatherMain.toLowerCase();
    final phase = _getDayPhase();

    return Stack(
      children: [
        // ── Base gradient (sudah di parent, ini hanya overlay)

        // ── Clear: sinar matahari / bintang malam
        if (wm == 'clear') ...[
          if (phase == _DayPhase.night || phase == _DayPhase.evening)
            AnimatedBuilder(
              animation: _starAnim,
              builder: (_, __) => CustomPaint(
                size: size,
                painter: _StarfieldPainter(progress: _starAnim.value),
              ),
            )
          else
            AnimatedBuilder(
              animation: _sunRayAnim,
              builder: (_, __) => CustomPaint(
                size: size,
                painter: _SunRayPainter(progress: _sunRayAnim.value),
              ),
            ),
        ],

        // ── Clouds: awan bergerak (semua kondisi berawan)
        if (wm == 'clouds' ||
            wm == 'rain' ||
            wm == 'drizzle' ||
            wm == 'thunderstorm' ||
            wm == 'mist' ||
            wm == 'fog' ||
            wm == 'haze')
          AnimatedBuilder(
            animation: _cloudAnim,
            builder: (_, __) => CustomPaint(
              size: size,
              painter: _MovingCloudsPainter(
                progress: _cloudAnim.value,
                weatherMain: wm,
                dayPhase: phase,
              ),
            ),
          ),

        // ── Rain / Drizzle: tetes hujan
        if (wm == 'rain' || wm == 'drizzle' || wm == 'thunderstorm')
          AnimatedBuilder(
            animation: _rainAnim,
            builder: (_, __) => CustomPaint(
              size: size,
              painter: _RainPainter(
                progress: _rainAnim.value,
                isHeavy: wm == 'thunderstorm',
              ),
            ),
          ),

        // ── Thunder flash
        if (wm == 'thunderstorm' && _showThunderFlash)
          AnimatedBuilder(
            animation: _thunderAnim,
            builder: (_, __) {
              return Container(
                color: Colors.white.withOpacity(
                  0.07 * (1 - _thunderAnim.value),
                ),
              );
            },
          ),

        // ── Thunder lightning bolt
        if (wm == 'thunderstorm')
          AnimatedBuilder(
            animation: _thunderAnim,
            builder: (_, __) => CustomPaint(
              size: size,
              painter: _LightningPainter(
                progress: _thunderAnim.value,
                visible: _showThunderFlash,
              ),
            ),
          ),

        // ── Snow: butiran salju
        if (wm == 'snow')
          AnimatedBuilder(
            animation: _rainAnim,
            builder: (_, __) => CustomPaint(
              size: size,
              painter: _SnowPainter(progress: _rainAnim.value),
            ),
          ),

        // ── Dawn/Evening: color wash overlay
        if (phase == _DayPhase.dawn || phase == _DayPhase.evening)
          IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: phase == _DayPhase.dawn
                      ? const Alignment(0.0, 0.8)
                      : const Alignment(0.6, 0.4),
                  radius: 1.2,
                  colors: [
                    (phase == _DayPhase.dawn
                            ? const Color(0xFFE05A2B)
                            : const Color(0xFFD04A1A))
                        .withOpacity(0.25),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ── WIDGETS ───────────────────────────────────────

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 0),
      child: Row(
        children: [
          _GlassIconButton(
            icon: Icons.add_rounded,
            onTap: () async {
              final result = await Navigator.push(
                context,
                PageRouteBuilder(
                  transitionDuration: const Duration(milliseconds: 500),
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      CitySearchScreen(
                        currentCityName: cityName,
                        currentSubLocation: subLocation,
                        currentLat: currentLat,
                        currentLon: currentLon,
                      ),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                        const begin = Offset(-1.0, 0.0);
                        const end = Offset.zero;
                        const curve = Curves.easeOutCubic;
                        var tween = Tween(
                          begin: begin,
                          end: end,
                        ).chain(CurveTween(curve: curve));
                        return SlideTransition(
                          position: animation.drive(tween),
                          child: child,
                        );
                      },
                ),
              );
              if (result != null && mounted) {
                setState(() {
                  cityName = result['cityName'];
                  subLocation = result['subLocation'];
                  currentLat = result['lat'];
                  currentLon = result['lon'];
                });
                _fetchWeatherData();
              }
            },
          ),
          Expanded(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: cityName.length > 20
                          ? _MarqueeText(
                              text: cityName,
                              style: GoogleFonts.inter(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: -0.5,
                              ),
                            )
                          : Text(
                              cityName,
                              style: GoogleFonts.inter(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: -0.5,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: _handleLocationPress,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.my_location_rounded,
                          color: Color(0xFF60A5FA),
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                if (subLocation.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(
                      subLocation,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: Colors.white.withOpacity(0.5),
                        letterSpacing: 0.2,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
              ],
            ),
          ),
          _GlassIconButton(
            icon: Icons.terrain_rounded,
            onTap: () async {
              final result = await Navigator.push(
                context,
                PageRouteBuilder(
                  transitionDuration: const Duration(milliseconds: 500),
                  pageBuilder: (_, animation, __) => MountainSearchScreen(
                    currentLat: currentLat,
                    currentLon: currentLon,
                  ),
                  transitionsBuilder: (_, animation, __, child) {
                    const begin = Offset(1.0, 0.0);
                    const end = Offset.zero;
                    var tween = Tween(
                      begin: begin,
                      end: end,
                    ).chain(CurveTween(curve: Curves.easeOutCubic));
                    return SlideTransition(
                      position: animation.drive(tween),
                      child: child,
                    );
                  },
                ),
              );
              if (result != null && mounted) {
                setState(() {
                  cityName = result['cityName'];
                  subLocation = result['subLocation'];
                  currentLat = result['lat'];
                  currentLon = result['lon'];
                });
                _fetchWeatherData();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherIllustration() {
    return AnimatedBuilder(
      animation: _floatAnim,
      builder: (_, child) => Transform.translate(
        offset: Offset(0, _floatAnim.value),
        child: child,
      ),
      child: AnimatedBuilder(
        animation: _pulseAnim,
        builder: (_, child) =>
            Transform.scale(scale: _pulseAnim.value, child: child),
        child: SizedBox(
          width: 160,
          height: 160,
          child: _WeatherAnimatedIcon(weatherMain: weatherMain),
        ),
      ),
    );
  }

  Widget _buildMainWeatherInfo() {
    return Column(
      children: [
        const SizedBox(height: 16),
        _buildWeatherIllustration(),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              currentTemp,
              style: GoogleFonts.inter(
                fontSize: 96,
                fontWeight: FontWeight.w200,
                color: Colors.white,
                height: 1.0,
                letterSpacing: -4,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                "°C",
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.w300,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          weatherDesc,
          style: GoogleFonts.inter(
            fontSize: 18,
            color: Colors.white.withOpacity(0.85),
            fontWeight: FontWeight.w400,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          highLowTemp,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: Colors.white.withOpacity(0.55),
            fontWeight: FontWeight.w400,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.15),
              width: 0.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: Color(0xFF4ADE80),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 7),
              Text(
                "IKU $aqi  ·  Kualitas Baik",
                style: GoogleFonts.inter(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _glassCard({required Widget child, EdgeInsets? margin}) {
    return Container(
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.12), width: 0.5),
      ),
      child: child,
    );
  }

  Widget _sectionLabel(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.white38, size: 14),
        const SizedBox(width: 7),
        Text(
          text,
          style: GoogleFonts.inter(
            color: Colors.white38,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }

  Widget _build24HourForecast() {
    final now = DateTime.now();

    // Urutkan berdasarkan waktu ascending
    final sortedList = List.from(forecastList)
      ..sort((a, b) => (a['dt'] as int).compareTo(b['dt'] as int));

    // Cari index slot yang paling dekat dengan waktu sekarang
    int nowIndex = 0;
    int minDiff = 999999;
    for (int i = 0; i < sortedList.length; i++) {
      final dt = DateTime.fromMillisecondsSinceEpoch(
        sortedList[i]['dt'] * 1000,
        isUtc: true,
      ).toLocal();
      final diff = dt.difference(now).inMinutes.abs();
      if (diff < minDiff) {
        minDiff = diff;
        nowIndex = i;
      }
    }

    // Ambil 8 slot mulai dari slot terdekat sekarang
    final relevantList = sortedList.skip(nowIndex).take(8).toList();

    return _glassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel(Icons.schedule_rounded, "RAMALAN 24 JAM"),
          const SizedBox(height: 16),
          if (relevantList.isNotEmpty)
            SizedBox(
              height: 110,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: relevantList.length,
                itemBuilder: (_, i) {
                  var item = relevantList[i];
                  DateTime dt = DateTime.fromMillisecondsSinceEpoch(
                    item['dt'] * 1000,
                    isUtc: true,
                  ).toLocal();

                  final bool isNow = i == 0;
                  String time = isNow
                      ? "Skrg"
                      : "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";

                  String temp = "${item['main']['temp'].round()}°";
                  String main = item['weather'][0]['main'];

                  return Container(
                    width: 64,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: isNow
                          ? Colors.white.withOpacity(0.14)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      border: isNow
                          ? Border.all(
                              color: Colors.white.withOpacity(0.2),
                              width: 0.5,
                            )
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          temp,
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontWeight: isNow
                                ? FontWeight.w600
                                : FontWeight.w400,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Icon(
                          _getWeatherIcon(main),
                          color: _getWeatherIconColor(main),
                          size: 22,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          time,
                          style: GoogleFonts.inter(
                            color: Colors.white.withOpacity(isNow ? 0.9 : 0.45),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            )
          else
            Center(
              child: Text(
                "Menyiapkan data...",
                style: GoogleFonts.inter(color: Colors.white38, fontSize: 13),
              ),
            ),
        ],
      ),
    );
  }

  Widget _build5DayForecast() {
    return _glassCard(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _sectionLabel(Icons.calendar_month_rounded, "RAMALAN 5 HARI"),
              GestureDetector(
                onTap: () {
                  if (forecastList.isNotEmpty) {
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        transitionDuration: const Duration(milliseconds: 500),
                        pageBuilder: (context, animation, secondaryAnimation) =>
                            FiveDayForecastScreen(forecastList: forecastList),
                        transitionsBuilder:
                            (context, animation, secondaryAnimation, child) {
                              const begin = Offset(1.0, 0.0);
                              const end = Offset.zero;
                              const curve = Curves.easeOutCubic;
                              var tween = Tween(
                                begin: begin,
                                end: end,
                              ).chain(CurveTween(curve: curve));
                              return SlideTransition(
                                position: animation.drive(tween),
                                child: child,
                              );
                            },
                      ),
                    );
                  }
                },
                child: Row(
                  children: [
                    Text(
                      "Selengkapnya",
                      style: GoogleFonts.inter(
                        color: const Color(0xFF60A5FA),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFF60A5FA),
                      size: 16,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (forecastList.isNotEmpty)
            _buildAccurateDailyForecasts()
          else
            Center(
              child: Text(
                "Menyiapkan data harian...",
                style: GoogleFonts.inter(color: Colors.white38, fontSize: 13),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAccurateDailyForecasts() {
    DateTime today = DateTime.now();
    Map<String, Map<String, dynamic>> dailyData = {};

    for (var item in forecastList) {
      DateTime dt = DateTime.fromMillisecondsSinceEpoch(
        item['dt'] * 1000,
        isUtc: true,
      ).toLocal();
      if (dt.day == today.day && dt.month == today.month) continue;

      String key =
          "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}";
      double temp = item['main']['temp'].toDouble();

      if (!dailyData.containsKey(key)) {
        dailyData[key] = {
          'date': dt,
          'min_temp': temp,
          'max_temp': temp,
          'description': item['weather'][0]['description'],
          'main': item['weather'][0]['main'],
        };
      } else {
        if (temp < dailyData[key]!['min_temp'])
          dailyData[key]!['min_temp'] = temp;
        if (temp > dailyData[key]!['max_temp'])
          dailyData[key]!['max_temp'] = temp;
        if (dt.hour >= 12 && dt.hour <= 15) {
          dailyData[key]!['description'] = item['weather'][0]['description'];
          dailyData[key]!['main'] = item['weather'][0]['main'];
        }
      }
    }

    List<Map<String, dynamic>> days = dailyData.values.take(3).toList();
    List<String> namaHari = [
      "",
      "Senin",
      "Selasa",
      "Rabu",
      "Kamis",
      "Jumat",
      "Sabtu",
      "Minggu",
    ];

    return Column(
      children: List.generate(days.length, (i) {
        var data = days[i];
        DateTime date = data['date'];
        String dayName = i == 0 ? "Besok" : namaHari[date.weekday];
        String desc = data['description'];
        desc = desc[0].toUpperCase() + desc.substring(1);
        String hi = "${data['max_temp'].round()}°";
        String lo = "${data['min_temp'].round()}°";
        String main = data['main'];

        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Row(
            children: [
              SizedBox(
                width: 60,
                child: Text(
                  dayName,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _getWeatherIconColor(main).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _getWeatherIcon(main),
                  color: _getWeatherIconColor(main),
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  desc,
                  style: GoogleFonts.inter(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                hi,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              Text(
                " / $lo",
                style: GoogleFonts.inter(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildAiDetectionSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1D3461), Color(0xFF1A2744)],
        ),
        border: Border.all(
          color: const Color(0xFF3B82F6).withOpacity(0.3),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: Color(0xFF60A5FA),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Deteksi Awan AI",
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      "Powered by TFLite Model",
                      style: GoogleFonts.inter(
                        color: Colors.white38,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4ADE80).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFF4ADE80),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        "Aktif",
                        style: GoogleFonts.inter(
                          color: Color(0xFF4ADE80),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Text(
              "Foto langit dan AI akan menganalisis jenis awan serta prediksi potensi hujan secara real-time.",
              style: GoogleFonts.inter(
                color: Colors.white.withOpacity(0.5),
                fontSize: 13,
                height: 1.6,
              ),
            ),
          ),
          Divider(height: 1, color: Colors.white.withOpacity(0.07)),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _AiActionButton(
                    icon: Icons.camera_alt_rounded,
                    label: "Kamera",
                    isPrimary: true,
                    onTap: () => _showCameraInstructionDialog(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _AiActionButton(
                    icon: Icons.photo_library_rounded,
                    label: "Galeri",
                    isPrimary: false,
                    onTap: () => _pickImage(ImageSource.gallery),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final gradient = _getWeatherGradient();
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 1200),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradient,
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // ── Animated weather background layer
            Positioned.fill(child: _buildAnimatedBackground(size)),
            // ── Main content
            // GANTI DENGAN:
            SafeArea(
              child: isLoading
                  ? Center(/* ... sama seperti sebelumnya */)
                  : Column(
                      children: [
                        // Header fixed
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                gradient[0].withOpacity(0.95),
                                gradient[0].withOpacity(0.0),
                              ],
                              stops: const [0.6, 1.0],
                            ),
                          ),
                          child: _buildHeader(),
                        ),
                        Expanded(
                          child: RefreshIndicator(
                            onRefresh: _fetchWeatherData,
                            color: Colors.white,
                            backgroundColor: const Color(0xFF1A2744),
                            child: SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(
                                parent: BouncingScrollPhysics(),
                              ),
                              child: Stack(
                                children: [
                                  // ── Animated bg IKUT SCROLL (di dalam SingleChildScrollView)
                                  SizedBox(
                                    height:
                                        420, // cukup tinggi untuk efek bg di atas
                                    width: double.infinity,
                                    child: _buildAnimatedBackground(size),
                                  ),
                                  // ── Konten di atas layer animasi
                                  Column(
                                    children: [
                                      _buildMainWeatherInfo(),
                                      const SizedBox(height: 28),
                                      _build24HourForecast(),
                                      const SizedBox(height: 14),
                                      _build5DayForecast(),
                                      const SizedBox(height: 14),
                                      _buildAiDetectionSection(),
                                      const SizedBox(height: 40),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// WEATHER BACKGROUND PAINTERS
// ══════════════════════════════════════════════════════════════════

/// Partikel hujan jatuh diagonal
class _RainPainter extends CustomPainter {
  final double progress;
  final bool isHeavy;
  _RainPainter({required this.progress, required this.isHeavy});

  static final _random = math.Random(42);
  static late List<List<double>> _drops;
  static bool _initialized = false;

  static void _init() {
    _drops = List.generate(
      70,
      (_) => [
        _random.nextDouble(), // x normalised
        _random.nextDouble(), // y seed (phase offset)
        0.35 + _random.nextDouble() * 0.65, // speed factor
        0.25 + _random.nextDouble() * 0.5, // opacity
      ],
    );
    _initialized = true;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (!_initialized) _init();
    final paint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = isHeavy ? 1.5 : 1.0;

    for (var drop in _drops) {
      final x = drop[0] * size.width;
      // y berjalan 0→1 terus tanpa lompat — modulo murni
      final y = ((progress * drop[2] + drop[1]) % 1.0) * size.height;
      final opacity = drop[3] * (isHeavy ? 0.65 : 0.45);
      paint.color =
          (isHeavy ? const Color(0xFF7B9FCC) : const Color(0xFF93C5FD))
              .withOpacity(opacity);
      final len = isHeavy ? 22.0 : 14.0;
      final dx = isHeavy ? len * 0.28 : len * 0.14;
      canvas.drawLine(Offset(x, y), Offset(x + dx, y + len), paint);
    }
  }

  @override
  bool shouldRepaint(_RainPainter old) => old.progress != progress;
}

/// Awan bergerak pelan
class _MovingCloudsPainter extends CustomPainter {
  final double progress;
  final String weatherMain;
  final _DayPhase dayPhase;

  _MovingCloudsPainter({
    required this.progress,
    required this.weatherMain,
    required this.dayPhase,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final isDark =
        dayPhase == _DayPhase.night ||
        dayPhase == _DayPhase.evening ||
        weatherMain == 'thunderstorm';
    final baseOpacity = isDark ? 0.12 : 0.18;

    final cloudColor = isDark
        ? Colors.white.withOpacity(baseOpacity)
        : (weatherMain == 'clouds'
              ? const Color(0xFFBFDBFE).withOpacity(0.25)
              : Colors.white.withOpacity(baseOpacity));

    // Seamless loop: setiap layer bergerak dari kanan ke kiri
    // offset dimulai dari luar layar kanan, berakhir di luar layar kiri
    // sehingga tidak ada "lompatan" saat loop ulang

    void seamlessCloud(
      double speedFactor,
      double seedOffset,
      double yRatio,
      double w,
      double h,
      Color color,
    ) {
      // totalWidth = lebar layar + lebar awan (agar masuk & keluar mulus)
      final totalTravel = size.width + w;
      // posisi x: mulai dari kanan (size.width), gerak ke kiri (-w)
      final raw = ((progress * speedFactor + seedOffset) % 1.0);
      final x = size.width - raw * totalTravel;
      _drawCloud(canvas, size, x, size.height * yRatio, w, h, color);
    }

    // Layer 1 — lambat, besar
    seamlessCloud(1.0, 0.0, 0.10, 240, 95, cloudColor);
    // Layer 2 — sedang
    seamlessCloud(
      1.5,
      0.38,
      0.06,
      170,
      68,
      cloudColor.withOpacity(baseOpacity * 0.75),
    );
    // Layer 3 — agak cepat
    seamlessCloud(
      2.0,
      0.65,
      0.20,
      140,
      56,
      cloudColor.withOpacity(baseOpacity * 0.55),
    );
    // Layer 4 — lambat, di belakang
    seamlessCloud(
      0.7,
      0.20,
      0.02,
      200,
      80,
      cloudColor.withOpacity(baseOpacity * 0.4),
    );

    if (weatherMain == 'clouds' || weatherMain == 'thunderstorm') {
      seamlessCloud(
        0.9,
        0.55,
        0.28,
        290,
        115,
        cloudColor.withOpacity(baseOpacity * 1.1),
      );
      seamlessCloud(
        1.3,
        0.80,
        0.14,
        210,
        85,
        cloudColor.withOpacity(baseOpacity * 0.85),
      );
    }
  }

  void _drawCloud(
    Canvas canvas,
    Size size,
    double x,
    double y,
    double w,
    double h,
    Color color,
  ) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Gunakan hanya oval yang saling overlap — TANPA addRect
    // sehingga tepi awan tetap melengkung alami di semua sisi
    final path = Path()
      ..addOval(
        Rect.fromCenter(
          center: Offset(x + w * 0.20, y + h * 0.62),
          width: w * 0.48,
          height: h * 0.80,
        ),
      )
      ..addOval(
        Rect.fromCenter(
          center: Offset(x + w * 0.40, y + h * 0.50),
          width: w * 0.50,
          height: h * 0.90,
        ),
      )
      ..addOval(
        Rect.fromCenter(
          center: Offset(x + w * 0.60, y + h * 0.55),
          width: w * 0.52,
          height: h * 0.85,
        ),
      )
      ..addOval(
        Rect.fromCenter(
          center: Offset(x + w * 0.78, y + h * 0.65),
          width: w * 0.40,
          height: h * 0.72,
        ),
      )
      ..addOval(
        Rect.fromCenter(
          center: Offset(x + w * 0.50, y + h * 0.78),
          width: w * 0.80,
          height: h * 0.55,
        ),
      );
    // Oval terakhir di bawah mengisi celah horizontal dengan tetap melengkung

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_MovingCloudsPainter old) => old.progress != progress;
}

/// Sinar matahari berputar
class _SunRayPainter extends CustomPainter {
  final double progress;
  _SunRayPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width * 0.72;
    final cy = size.height * 0.06;
    final angle = progress * math.pi * 2;

    // Outer glow
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [const Color(0xFFFBBF24).withOpacity(0.12), Colors.transparent],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: 180));
    canvas.drawCircle(Offset(cx, cy), 180, glowPaint);

    // Rays
    final rayPaint = Paint()
      ..color = const Color(0xFFFDE68A).withOpacity(0.07)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 12; i++) {
      final a = angle + (i * math.pi * 2 / 12);
      canvas.drawLine(
        Offset(cx + 60 * math.cos(a), cy + 60 * math.sin(a)),
        Offset(cx + 140 * math.cos(a), cy + 140 * math.sin(a)),
        rayPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_SunRayPainter old) => old.progress != progress;
}

/// Bintang berkelip malam
class _StarfieldPainter extends CustomPainter {
  final double progress;
  _StarfieldPainter({required this.progress});

  static final _r = math.Random(99);
  static final _stars = List.generate(
    60,
    (_) => [
      _r.nextDouble(), // x
      _r.nextDouble() * 0.5, // y (upper half)
      0.3 + _r.nextDouble() * 0.7, // base opacity
      1.5 + _r.nextDouble() * 2.0, // size
      _r.nextDouble(), // twinkle phase
    ],
  );

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (var s in _stars) {
      final twinkle =
          (math.sin((progress * math.pi * 2) + s[4] * math.pi * 2) + 1) / 2;
      final opacity = (s[2] * 0.4 + twinkle * 0.6).clamp(0.0, 1.0);
      paint.color = Colors.white.withOpacity(opacity * 0.8);
      canvas.drawCircle(
        Offset(s[0] * size.width, s[1] * size.height),
        s[3],
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_StarfieldPainter old) => old.progress != progress;
}

/// Kilat petir
class _LightningPainter extends CustomPainter {
  final double progress;
  final bool visible;
  _LightningPainter({required this.progress, required this.visible});

  @override
  void paint(Canvas canvas, Size size) {
    if (!visible || progress >= 1.0) return;

    final opacity = (1.0 - progress).clamp(0.0, 1.0);
    final cx = size.width * 0.65;

    final glowPaint = Paint()
      ..color = const Color(0xFFFBBF24).withOpacity(0.2 * opacity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);

    final boltPaint = Paint()
      ..color = const Color(0xFFFDE68A).withOpacity(0.85 * opacity)
      ..style = PaintingStyle.fill;

    final boltPath = Path()
      ..moveTo(cx + 10, size.height * 0.05)
      ..lineTo(cx - 18, size.height * 0.22)
      ..lineTo(cx + 4, size.height * 0.22)
      ..lineTo(cx - 14, size.height * 0.40)
      ..lineTo(cx + 28, size.height * 0.20)
      ..lineTo(cx + 10, size.height * 0.20)
      ..close();

    canvas.drawPath(boltPath, glowPaint);
    canvas.drawPath(boltPath, boltPaint);
  }

  @override
  bool shouldRepaint(_LightningPainter old) =>
      old.progress != progress || old.visible != visible;
}

class _SnowPainter extends CustomPainter {
  final double progress;
  _SnowPainter({required this.progress});

  static final _r = math.Random(77);
  // SESUDAH:
  static final _flakes = List.generate(
    50,
    (_) => [
      _r.nextDouble(), // x normalised
      _r.nextDouble(), // y phase seed (sebar merata 0–1)
      0.4 + _r.nextDouble() * 0.6, // speed: lebih tinggi = loop mulus
      1.5 + _r.nextDouble() * 2.5, // radius lebih kecil & konsisten
      _r.nextDouble() * math.pi * 2, // drift phase
    ],
  );

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (var f in _flakes) {
      // x dengan drift sinusoidal — tidak loncat
      final drift = math.sin(progress * math.pi * 2 + f[4]) * 8;
      final x = (f[0] * size.width + drift).clamp(0.0, size.width);
      // y modulo murni
      final y = ((progress * f[2] + f[1]) % 1.0) * size.height;
      paint.color = Colors.white.withOpacity(0.5);
      canvas.drawCircle(Offset(x, y), f[3], paint);
    }
  }

  @override
  bool shouldRepaint(_SnowPainter old) => old.progress != progress;
}

// ══════════════════════════════════════════════════════════════════
// KOMPONEN REUSABLE (tidak berubah)
// ══════════════════════════════════════════════════════════════════

class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _GlassIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.12), width: 0.5),
        ),
        child: Icon(icon, color: Colors.white70, size: 20),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// CAMERA INSTRUCTION DIALOG
// ══════════════════════════════════════════════════════════════════
class _CameraInstructionDialog extends StatefulWidget {
  const _CameraInstructionDialog();

  @override
  State<_CameraInstructionDialog> createState() =>
      _CameraInstructionDialogState();
}

/// Ilustrasi langit: matahari di belakang awan berlapis
class _SkyScenePainter extends CustomPainter {
  final double progress;
  const _SkyScenePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2 + 8;

    // ── Matahari (di belakang awan) ──
    // Glow luar
    canvas.drawCircle(
      Offset(cx - 28, cy - 8),
      34,
      Paint()
        ..color = const Color(0xFFFBBF24).withOpacity(0.15 * progress)
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      Offset(cx - 28, cy - 8),
      24,
      Paint()..color = const Color(0xFFFBBF24).withOpacity(0.28 * progress),
    );
    // Badan matahari
    canvas.drawCircle(
      Offset(cx - 28, cy - 8),
      16,
      Paint()..color = const Color(0xFFFBBF24).withOpacity(progress),
    );
    // Inner bright
    canvas.drawCircle(
      Offset(cx - 28, cy - 8),
      10,
      Paint()..color = const Color(0xFFFDE68A).withOpacity(progress),
    );

    // Sinar matahari (8 sinar pendek)
    final rayPaint = Paint()
      ..color = const Color(0xFFFBBF24).withOpacity(0.55 * progress)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < 8; i++) {
      final angle = i * 3.14159 * 2 / 8;
      final cos = _cos(angle);
      final sin = _sin(angle);
      canvas.drawLine(
        Offset(cx - 28 + 20 * cos, cy - 8 + 20 * sin),
        Offset(cx - 28 + 30 * cos, cy - 8 + 30 * sin),
        rayPaint,
      );
    }

    // ── Awan belakang (lebih gelap, di belakang matahari sebagian) ──
    _drawCloudShape(
      canvas,
      Offset(cx + 22, cy - 4),
      72,
      32,
      const Color(0xFF93C5FD).withOpacity(0.45 * progress),
    );

    // ── Awan depan utama (menutupi sebagian matahari) ──
    _drawCloudShape(
      canvas,
      Offset(cx - 10, cy + 4),
      86,
      38,
      const Color(0xFFBFDBFE).withOpacity(0.85 * progress),
    );

    // Highlight tepi atas awan depan (rim light dari matahari)
    _drawCloudRim(
      canvas,
      Offset(cx - 10, cy + 4),
      86,
      38,
      const Color(0xFFFDE68A).withOpacity(0.25 * progress),
    );

    // ── Awan kecil kanan ──
    _drawCloudShape(
      canvas,
      Offset(cx + 52, cy + 6),
      44,
      22,
      Colors.white.withOpacity(0.5 * progress),
    );
  }

  void _drawCloudShape(
    Canvas canvas,
    Offset c,
    double w,
    double h,
    Color color,
  ) {
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final path = Path()
      ..addOval(
        Rect.fromCenter(
          center: Offset(c.dx - w * 0.20, c.dy + h * 0.10),
          width: w * 0.46,
          height: h * 0.82,
        ),
      )
      ..addOval(
        Rect.fromCenter(
          center: Offset(c.dx, c.dy - h * 0.05),
          width: w * 0.50,
          height: h * 0.90,
        ),
      )
      ..addOval(
        Rect.fromCenter(
          center: Offset(c.dx + w * 0.20, c.dy + h * 0.08),
          width: w * 0.48,
          height: h * 0.80,
        ),
      )
      ..addOval(
        Rect.fromCenter(
          center: Offset(c.dx, c.dy + h * 0.28),
          width: w * 0.78,
          height: h * 0.52,
        ),
      );
    canvas.drawPath(path, p);
  }

  void _drawCloudRim(Canvas canvas, Offset c, double w, double h, Color color) {
    // Glow tipis di tepi atas awan sebagai rim light dari matahari
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(c.dx, c.dy - h * 0.05),
        width: w * 0.50,
        height: h * 0.90,
      ),
      p,
    );
  }

  // Kalkulasi cos/sin sederhana pakai dart:math
  double _cos(double a) => math.cos(a);
  double _sin(double a) => math.sin(a);

  @override
  bool shouldRepaint(_SkyScenePainter old) => old.progress != progress;
}

class _CameraInstructionDialogState extends State<_CameraInstructionDialog>
    with TickerProviderStateMixin {
  // Controller utama: tilt HP dari posisi normal → arah langit
  late AnimationController _tiltCtrl;
  // Controller: floating naik-turun (idle loop)
  late AnimationController _floatCtrl;
  // Controller: pulse lingkaran panduan
  late AnimationController _pulseCtrl;
  // Controller: fade keseluruhan dialog keluar
  late AnimationController _fadeOutCtrl;

  late Animation<double> _tiltAnim; // rotasi HP: 0° → -55°
  late Animation<double> _floatAnim; // naik turun ±8px
  late Animation<double> _pulseAnim; // scale 1.0 → 1.15
  late Animation<double> _fadeAnim; // opacity 1 → 0

  int _loopCount = 0;
  bool _showDone = false;

  @override
  void initState() {
    super.initState();

    // ── Tilt (HP dimiringkan ke atas) ─────────────
    _tiltCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _tiltAnim = Tween<double>(begin: 0.0, end: -0.96).animate(
      // ~55° dalam radian
      CurvedAnimation(parent: _tiltCtrl, curve: Curves.easeInOut),
    );

    // ── Float (idle naik-turun) ───────────────────
    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _floatAnim = Tween<double>(
      begin: 0,
      end: -10,
    ).animate(CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut));

    // ── Pulse lingkaran ───────────────────────────
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _pulseAnim = Tween<double>(
      begin: 1.0,
      end: 1.18,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeOut));

    // ── Fade out ──────────────────────────────────
    _fadeOutCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _fadeOutCtrl, curve: Curves.easeIn));

    _startSequence();
  }

  Future<void> _startSequence() async {
    // Loop 2 kali
    for (int i = 0; i < 2; i++) {
      // 1. Tilt HP ke atas
      await _tiltCtrl.forward();
      await Future.delayed(const Duration(milliseconds: 100));

      // 2. Float + pulse aktif saat HP sudah miring
      _floatCtrl.repeat(reverse: true);
      _pulseCtrl.repeat(reverse: true);
      await Future.delayed(const Duration(milliseconds: 600));

      // 3. Tilt kembali ke posisi normal
      _floatCtrl.stop();
      _pulseCtrl.stop();
      await _tiltCtrl.reverse();
      await Future.delayed(const Duration(milliseconds: 150));

      _loopCount = i + 1;
    }

    // Setelah 2 loop — tampilkan teks "Siap!" & fade out
    if (mounted) setState(() => _showDone = true);
    await Future.delayed(const Duration(milliseconds: 600));
    await _fadeOutCtrl.forward();

    // Tutup dialog → lanjut buka kamera
    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _tiltCtrl.dispose();
    _floatCtrl.dispose();
    _pulseCtrl.dispose();
    _fadeOutCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _fadeAnim,
      builder: (_, child) => Opacity(
        opacity: (1.0 - _fadeOutCtrl.value).clamp(0.0, 1.0),
        child: child,
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Ilustrasi HP + langit ─────────────────
              SizedBox(
                height: 220,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Lingkaran langit (pulse)
                    AnimatedBuilder(
                      animation: _pulseAnim,
                      builder: (_, __) => Transform.scale(
                        scale: _pulseAnim.value,
                        child: Container(
                          width: 130,
                          height: 130,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF60A5FA).withOpacity(0.10),
                            border: Border.all(
                              color: const Color(0xFF60A5FA).withOpacity(0.3),
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Ring luar
                    AnimatedBuilder(
                      animation: _pulseAnim,
                      builder: (_, __) => Transform.scale(
                        scale: _pulseAnim.value * 0.88,
                        child: Container(
                          width: 170,
                          height: 170,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF60A5FA).withOpacity(0.15),
                              width: 1,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Ikon awan & matahari kecil di atas (langit)
                    // GANTI bagian Positioned(top: 12, ...) dengan ini:
                    Positioned(
                      top: 8,
                      child: AnimatedBuilder(
                        animation: _tiltAnim,
                        builder: (_, __) {
                          final reveal = (-_tiltAnim.value / 0.96).clamp(
                            0.0,
                            1.0,
                          );
                          return Opacity(
                            opacity: reveal,
                            child: Transform.translate(
                              offset: Offset(
                                0,
                                -10 * reveal,
                              ), // naik sedikit saat reveal
                              child: SizedBox(
                                width: 160,
                                height: 70,
                                child: CustomPaint(
                                  painter: _SkyScenePainter(progress: reveal),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    // HP dengan animasi tilt + float
                    AnimatedBuilder(
                      animation: Listenable.merge([_tiltAnim, _floatAnim]),
                      builder: (_, __) => Transform.translate(
                        offset: Offset(0, _floatAnim.value),
                        child: Transform(
                          alignment: Alignment.bottomCenter,
                          transform: Matrix4.identity()
                            ..setEntry(3, 2, 0.001)
                            ..rotateX(_tiltAnim.value),
                          child: _buildPhoneIllustration(),
                        ),
                      ),
                    ),

                    // Panah arah ke atas (muncul saat tilt)
                    Positioned(
                      right: 38,
                      top: 50,
                      child: AnimatedBuilder(
                        animation: _tiltAnim,
                        builder: (_, __) {
                          final opacity = (-_tiltAnim.value / 0.96).clamp(
                            0.0,
                            1.0,
                          );
                          return Opacity(
                            opacity: opacity,
                            child: Column(
                              children: List.generate(
                                3,
                                (i) => Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Icon(
                                    Icons.keyboard_arrow_up_rounded,
                                    color: const Color(
                                      0xFF60A5FA,
                                    ).withOpacity(0.4 + i * 0.2),
                                    size: 18,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // ── Teks instruksi ────────────────────────
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _showDone
                    ? Column(
                        key: const ValueKey('done'),
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4ADE80).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0xFF4ADE80).withOpacity(0.4),
                                width: 0.5,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.check_circle_rounded,
                                  color: Color(0xFF4ADE80),
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "Siap! Membuka kamera...",
                                  style: GoogleFonts.inter(
                                    color: const Color(0xFF4ADE80),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    decoration: TextDecoration.none,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    : // GANTI bagian ValueKey('instruction') dengan ini:
                      Column(
                        key: const ValueKey('instruction'),
                        children: [
                          Text(
                            "Arahkan ke Langit",
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.5,
                              decoration:
                                  TextDecoration.none, // ← FIX underline
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "Miringkan HP ke atas untuk\nmendapatkan foto langit terbaik",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 14,
                              height: 1.6,
                              decoration:
                                  TextDecoration.none, // ← FIX underline
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              2,
                              (i) => AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                width: i < _loopCount ? 20 : 8,
                                height: 6,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  color: i < _loopCount
                                      ? const Color(0xFF60A5FA)
                                      : Colors.white.withOpacity(0.2),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneIllustration() {
    return Container(
      width: 72,
      height: 128,
      decoration: BoxDecoration(
        color: const Color(0xFF1A2744),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF60A5FA).withOpacity(0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Notch
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 24,
            height: 5,
            decoration: BoxDecoration(
              color: const Color(0xFF60A5FA).withOpacity(0.3),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const Spacer(),
          // Lensa kamera
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF0D1829),
              border: Border.all(
                color: const Color(0xFF60A5FA).withOpacity(0.5),
                width: 1.5,
              ),
            ),
            child: Center(
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF1E3A5F),
                  border: Border.all(
                    color: const Color(0xFF93C5FD).withOpacity(0.6),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF60A5FA),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _AiActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isPrimary;
  final VoidCallback onTap;
  const _AiActionButton({
    required this.icon,
    required this.label,
    required this.isPrimary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isPrimary
              ? const Color(0xFF3B82F6)
              : Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isPrimary
                ? Colors.transparent
                : Colors.white.withOpacity(0.15),
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isPrimary ? Colors.white : Colors.white70,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                color: isPrimary ? Colors.white : Colors.white70,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MarqueeText extends StatefulWidget {
  final String text;
  final TextStyle style;
  const _MarqueeText({required this.text, required this.style});

  @override
  State<_MarqueeText> createState() => _MarqueeTextState();
}

class _MarqueeTextState extends State<_MarqueeText>
    with SingleTickerProviderStateMixin {
  late ScrollController _scroll;
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _scroll = ScrollController();
    _ctrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 8))
          ..addListener(_scrollListener)
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed) {
              Future.delayed(const Duration(seconds: 1), () {
                if (mounted) {
                  _scroll.jumpTo(0);
                  _ctrl.forward(from: 0);
                }
              });
            }
          });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) _ctrl.forward();
      });
    });
  }

  void _scrollListener() {
    if (!_scroll.hasClients) return;
    final max = _scroll.position.maxScrollExtent;
    _scroll.jumpTo(_ctrl.value * max);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: _scroll,
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      child: Text(widget.text, style: widget.style),
    );
  }
}

class _WeatherAnimatedIcon extends StatelessWidget {
  final String weatherMain;
  const _WeatherAnimatedIcon({required this.weatherMain});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _WeatherIconPainter(weatherMain: weatherMain));
  }
}

class _WeatherIconPainter extends CustomPainter {
  final String weatherMain;
  _WeatherIconPainter({required this.weatherMain});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final phase = _getDayPhase();
    final isNightTime = phase == _DayPhase.night || phase == _DayPhase.evening;

    switch (weatherMain.toLowerCase()) {
      case 'clear':
        if (isNightTime) {
          _drawMoon(canvas, cx, cy, size);
        } else {
          _drawSun(canvas, cx, cy, size);
        }
        break;
      case 'rain':
      case 'drizzle':
        _drawRain(canvas, cx, cy, size);
        break;
      case 'thunderstorm':
        _drawThunder(canvas, cx, cy, size);
        break;
      case 'snow':
        _drawSnow(canvas, cx, cy, size);
        break;
      default:
        _drawCloudy(canvas, cx, cy, size);
    }
  }

  void _drawSun(Canvas canvas, double cx, double cy, Size size) {
    final glowPaint = Paint()
      ..color = const Color(0xFFFBBF24).withOpacity(0.15)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy), 72, glowPaint);
    final glowPaint2 = Paint()
      ..color = const Color(0xFFFBBF24).withOpacity(0.25)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy), 56, glowPaint2);
    final sunPaint = Paint()..color = const Color(0xFFFBBF24);
    canvas.drawCircle(Offset(cx, cy), 38, sunPaint);
    final innerPaint = Paint()..color = const Color(0xFFFDE68A);
    canvas.drawCircle(Offset(cx, cy), 26, innerPaint);
    final rayPaint = Paint()
      ..color = const Color(0xFFFBBF24)
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < 8; i++) {
      final angle = (i * math.pi * 2 / 8) - math.pi / 8;
      canvas.drawLine(
        Offset(cx + 46 * math.cos(angle), cy + 46 * math.sin(angle)),
        Offset(cx + 60 * math.cos(angle), cy + 60 * math.sin(angle)),
        rayPaint,
      );
    }
  }

  void _drawMoon(Canvas canvas, double cx, double cy, Size size) {
    // Outer glow biru malam
    final glowPaint = Paint()
      ..color = const Color(0xFF93C5FD).withOpacity(0.10)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy), 70, glowPaint);

    final glowPaint2 = Paint()
      ..color = const Color(0xFFBAE6FD).withOpacity(0.18)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy), 52, glowPaint2);

    // Badan bulan — sabit (crescent)
    // Teknik: lingkaran bulan penuh, lalu "potong" dengan lingkaran bayangan
    final moonPaint = Paint()
      ..color = const Color(0xFFE0F2FE)
      ..style = PaintingStyle.fill;

    // Gambar bulan penuh dulu
    canvas.drawCircle(Offset(cx, cy), 36, moonPaint);

    // "Potong" dengan warna bg gelap membentuk sabit — gunakan saveLayer
    final shadowPaint = Paint()
      ..color =
          const Color(0xFF0D1030) // samakan dengan warna bg malam
      ..style = PaintingStyle.fill
      ..blendMode = BlendMode.srcOver;
    canvas.drawCircle(Offset(cx + 14, cy - 6), 30, shadowPaint);

    // Lapisan dalam bulan — sedikit lebih terang di sisi sabit
    final innerPaint = Paint()
      ..color = const Color(0xFFF0F9FF).withOpacity(0.9)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx - 4, cy + 2), 20, innerPaint);
    canvas.drawCircle(Offset(cx + 14, cy - 6), 30, shadowPaint); // potong ulang

    // Bintang kecil di sekitar bulan
    final starPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final starGlowPaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    // Bintang 1 — kanan atas
    canvas.drawCircle(Offset(cx + 44, cy - 28), 3.5, starGlowPaint);
    canvas.drawCircle(Offset(cx + 44, cy - 28), 2.0, starPaint);

    // Bintang 2 — kanan bawah
    canvas.drawCircle(Offset(cx + 52, cy + 10), 2.5, starGlowPaint);
    canvas.drawCircle(Offset(cx + 52, cy + 10), 1.4, starPaint);

    // Bintang 3 — kiri atas
    canvas.drawCircle(Offset(cx - 42, cy - 36), 2.0, starGlowPaint);
    canvas.drawCircle(Offset(cx - 42, cy - 36), 1.2, starPaint);

    // Bintang 4 — bawah kiri
    canvas.drawCircle(Offset(cx - 36, cy + 40), 3.0, starGlowPaint);
    canvas.drawCircle(Offset(cx - 36, cy + 40), 1.8, starPaint);

    // Kilau cincin tipis di tepi bulan
    final rimPaint = Paint()
      ..color = const Color(0xFFBAE6FD).withOpacity(0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(Offset(cx, cy), 36, rimPaint);
  }

  void _drawCloudy(Canvas canvas, double cx, double cy, Size size) {
    _drawCloud(
      canvas,
      Offset(cx + 20, cy - 10),
      60,
      32,
      const Color(0xFF60A5FA).withOpacity(0.4),
    );
    _drawCloud(
      canvas,
      Offset(cx - 8, cy + 12),
      72,
      38,
      const Color(0xFFBFDBFE),
    );
    _drawCloud(
      canvas,
      Offset(cx - 32, cy + 2),
      42,
      24,
      Colors.white.withOpacity(0.6),
    );
  }

  void _drawRain(Canvas canvas, double cx, double cy, Size size) {
    _drawCloud(canvas, Offset(cx, cy - 20), 70, 36, const Color(0xFF93C5FD));
    _drawCloud(
      canvas,
      Offset(cx - 22, cy - 10),
      48,
      26,
      const Color(0xFF60A5FA).withOpacity(0.6),
    );
    final rainPaint = Paint()
      ..color = const Color(0xFF60A5FA)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    final drops = [
      [cx - 22, cy + 22, cx - 26, cy + 40],
      [cx - 4, cy + 28, cx - 8, cy + 46],
      [cx + 14, cy + 22, cx + 10, cy + 40],
      [cx + 30, cy + 28, cx + 26, cy + 46],
    ];
    for (var d in drops)
      canvas.drawLine(Offset(d[0], d[1]), Offset(d[2], d[3]), rainPaint);
  }

  void _drawThunder(Canvas canvas, double cx, double cy, Size size) {
    _drawCloud(
      canvas,
      Offset(cx, cy - 20),
      72,
      36,
      const Color(0xFF8B5CF6).withOpacity(0.7),
    );
    _drawCloud(
      canvas,
      Offset(cx - 18, cy - 10),
      52,
      28,
      const Color(0xFF7C3AED).withOpacity(0.5),
    );
    final boltPaint = Paint()
      ..color = const Color(0xFFFBBF24)
      ..style = PaintingStyle.fill;
    final boltPath = Path()
      ..moveTo(cx + 6, cy + 14)
      ..lineTo(cx - 10, cy + 36)
      ..lineTo(cx + 2, cy + 36)
      ..lineTo(cx - 6, cy + 58)
      ..lineTo(cx + 18, cy + 32)
      ..lineTo(cx + 6, cy + 32)
      ..close();
    final glowPaint = Paint()
      ..color = const Color(0xFFFBBF24).withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawPath(boltPath, glowPaint);
    canvas.drawPath(boltPath, boltPaint);
  }

  void _drawSnow(Canvas canvas, double cx, double cy, Size size) {
    _drawCloud(canvas, Offset(cx, cy - 22), 68, 34, const Color(0xFFBAE6FD));
    final snowPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final flakes = [
      [cx - 20, cy + 28],
      [cx + 2, cy + 36],
      [cx + 22, cy + 26],
      [cx - 8, cy + 46],
      [cx + 14, cy + 48],
    ];
    for (var f in flakes) {
      // Glow luar
      final glowPaint = Paint()
        ..color = Colors.white.withOpacity(0.25)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(f[0], f[1]), 7.0, glowPaint);
      // Bola salju putih bersih
      canvas.drawCircle(Offset(f[0], f[1]), 4.5, snowPaint);
      // Highlight kecil agar terlihat 3D
      final highlightPaint = Paint()
        ..color = Colors.white.withOpacity(0.9)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(f[0] - 1.2, f[1] - 1.2), 1.5, highlightPaint);
    }
  }

  void _drawCloud(
    Canvas canvas,
    Offset center,
    double w,
    double h,
    Color color,
  ) {
    final paint = Paint()..color = color;
    final path = Path()
      ..addOval(
        Rect.fromCenter(
          center: Offset(center.dx - w * 0.22, center.dy + h * 0.12),
          width: w * 0.48,
          height: h * 0.80,
        ),
      )
      ..addOval(
        Rect.fromCenter(
          center: Offset(center.dx + 0, center.dy - h * 0.05),
          width: w * 0.52,
          height: h * 0.90,
        ),
      )
      ..addOval(
        Rect.fromCenter(
          center: Offset(center.dx + w * 0.22, center.dy + h * 0.10),
          width: w * 0.50,
          height: h * 0.82,
        ),
      )
      ..addOval(
        Rect.fromCenter(
          center: Offset(center.dx, center.dy + h * 0.30),
          width: w * 0.80,
          height: h * 0.55,
        ),
      );
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) =>
      (old as _WeatherIconPainter).weatherMain != weatherMain;
}
