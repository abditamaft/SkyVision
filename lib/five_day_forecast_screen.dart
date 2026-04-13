import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;

class FiveDayForecastScreen extends StatefulWidget {
  final List<dynamic> forecastList;
  const FiveDayForecastScreen({super.key, required this.forecastList});

  @override
  State<FiveDayForecastScreen> createState() => _FiveDayForecastScreenState();
}

class _FiveDayForecastScreenState extends State<FiveDayForecastScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _entryCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut));

    _entryCtrl.forward();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    super.dispose();
  }

  // ── Helpers ──────────────────────────────────────
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

  Color _getWeatherColor(String main) {
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
        return const Color(0xFFBAE6FD);
      default:
        return const Color(0xFF93C5FD);
    }
  }

  String _getWeatherLabel(String main) {
    switch (main.toLowerCase()) {
      case 'clear':
        return 'Cerah';
      case 'clouds':
        return 'Berawan';
      case 'rain':
        return 'Hujan';
      case 'thunderstorm':
        return 'Badai';
      case 'drizzle':
        return 'Gerimis';
      case 'snow':
        return 'Salju';
      case 'mist':
      case 'fog':
        return 'Berkabut';
      default:
        return main;
    }
  }

  List<Map<String, dynamic>> _processDailyData() {
    Map<String, Map<String, dynamic>> dailyData = {};

    for (var item in widget.forecastList) {
      DateTime dt = DateTime.fromMillisecondsSinceEpoch(
        item['dt'] * 1000,
        isUtc: true,
      ).toLocal();
      String key =
          "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}";

      double temp = item['main']['temp'].toDouble();
      double windKmH = item['wind']['speed'].toDouble() * 3.6;
      double humidity = item['main']['humidity'].toDouble();

      if (!dailyData.containsKey(key)) {
        dailyData[key] = {
          'date': dt,
          'min': temp,
          'max': temp,
          'main': item['weather'][0]['main'],
          'description': item['weather'][0]['description'],
          'wind': windKmH,
          'humidity': humidity,
          'hourly': <Map<String, dynamic>>[],
        };
      } else {
        if (temp < dailyData[key]!['min']) dailyData[key]!['min'] = temp;
        if (temp > dailyData[key]!['max']) dailyData[key]!['max'] = temp;
        if (windKmH > dailyData[key]!['wind'])
          dailyData[key]!['wind'] = windKmH;
        if (dt.hour >= 12 && dt.hour <= 15) {
          dailyData[key]!['main'] = item['weather'][0]['main'];
          dailyData[key]!['description'] = item['weather'][0]['description'];
        }
      }

      // Simpan data per jam
      (dailyData[key]!['hourly'] as List<Map<String, dynamic>>).add({
        'hour': dt.hour,
        'temp': temp,
        'main': item['weather'][0]['main'],
      });
    }

    return dailyData.values.take(5).toList();
  }

  // ── Build ─────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final days = _processDailyData();
    if (days.isEmpty) {
      return const Scaffold(
        backgroundColor: Color(0xFF0A1628),
        body: Center(
          child: Text("Tidak ada data", style: TextStyle(color: Colors.white)),
        ),
      );
    }

    final List<String> namaHari = [
      "",
      "Senin",
      "Selasa",
      "Rabu",
      "Kamis",
      "Jumat",
      "Sabtu",
      "Minggu",
    ];
    final List<String> namaHariFull = [
      "",
      "Senin",
      "Selasa",
      "Rabu",
      "Kamis",
      "Jumat",
      "Sabtu",
      "Minggu",
    ];
    final List<String> namaBulan = [
      "",
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "Mei",
      "Jun",
      "Jul",
      "Agu",
      "Sep",
      "Okt",
      "Nov",
      "Des",
    ];

    // Hitung global min & max untuk skala grafik
    double globalMin = double.infinity;
    double globalMax = double.negativeInfinity;
    for (var d in days) {
      if (d['min'] < globalMin) globalMin = d['min'];
      if (d['max'] > globalMax) globalMax = d['max'];
    }

    final selectedDay = days[_selectedIndex];
    final selectedColor = _getWeatherColor(selectedDay['main']);

    return Scaffold(
      backgroundColor: const Color(0xFF080E1E),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── AppBar custom ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 12, 20, 0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.07),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.1),
                              width: 0.5,
                            ),
                          ),
                          child: const Icon(
                            Icons.arrow_back_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Ramalan Cuaca",
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 20,
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text(
                            "5 hari ke depan",
                            style: GoogleFonts.inter(
                              color: Colors.white38,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ── Grafik suhu dengan garis ──
                SizedBox(
                  height: 200,
                  child: _TemperatureLineChart(
                    days: days,
                    selectedIndex: _selectedIndex,
                    globalMin: globalMin,
                    globalMax: globalMax,
                    namaHari: namaHari,
                    onTap: (i) => setState(() => _selectedIndex = i),
                  ),
                ),

                const SizedBox(height: 24),

                // ── Daftar hari (horizontal pill) ──
                SizedBox(
                  height: 72,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: days.length,
                    itemBuilder: (_, i) {
                      final d = days[i];
                      final DateTime date = d['date'];
                      final bool selected = i == _selectedIndex;
                      final color = _getWeatherColor(d['main']);
                      String label = i == 0
                          ? "Hari ini"
                          : (i == 1 ? "Besok" : namaHari[date.weekday]);

                      return GestureDetector(
                        onTap: () => setState(() => _selectedIndex = i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeInOut,
                          margin: const EdgeInsets.only(right: 10),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: selected
                                ? color.withOpacity(0.2)
                                : Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: selected
                                  ? color.withOpacity(0.5)
                                  : Colors.white.withOpacity(0.08),
                              width: selected ? 1 : 0.5,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                label,
                                style: GoogleFonts.inter(
                                  color: selected
                                      ? Colors.white
                                      : Colors.white38,
                                  fontWeight: selected
                                      ? FontWeight.w700
                                      : FontWeight.w400,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    _getWeatherIcon(d['main']),
                                    color: selected ? color : Colors.white24,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    "${d['max'].round()}°",
                                    style: GoogleFonts.inter(
                                      color: selected ? color : Colors.white24,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 20),

                // ── Detail card hari terpilih ──
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _buildDetailCard(
                      key: ValueKey(_selectedIndex),
                      data: selectedDay,
                      index: _selectedIndex,
                      color: selectedColor,
                      namaHariFull: namaHariFull,
                      namaBulan: namaBulan,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailCard({
    required Key key,
    required Map<String, dynamic> data,
    required int index,
    required Color color,
    required List<String> namaHariFull,
    required List<String> namaBulan,
  }) {
    final DateTime date = data['date'];
    final String dayLabel = index == 0
        ? "Hari Ini"
        : (index == 1 ? "Besok" : namaHariFull[date.weekday]);
    final String dateStr = "${date.day} ${namaBulan[date.month]} ${date.year}";
    final String desc = () {
      String d = data['description'];
      return d[0].toUpperCase() + d.substring(1);
    }();

    return Container(
      key: key,
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.2), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header detail
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  _getWeatherIcon(data['main']),
                  color: color,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dayLabel,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      letterSpacing: -0.4,
                    ),
                  ),
                  Text(
                    dateStr,
                    style: GoogleFonts.inter(
                      color: Colors.white38,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Text(
                        "${data['max'].round()}°",
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 24,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "/ ${data['min'].round()}°",
                        style: GoogleFonts.inter(
                          color: Colors.white38,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    desc,
                    style: GoogleFonts.inter(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Stat row
          Row(
            children: [
              _StatTile(
                icon: Icons.air_rounded,
                label: "Angin",
                value: "${data['wind'].toStringAsFixed(1)} km/j",
                color: color,
              ),
              const SizedBox(width: 10),
              _StatTile(
                icon: Icons.water_drop_outlined,
                label: "Kelembapan",
                value: "${data['humidity'].round()}%",
                color: color,
              ),
              const SizedBox(width: 10),
              _StatTile(
                icon: Icons.thermostat_rounded,
                label: "Rentang",
                value: "${(data['max'] - data['min']).round()}°C",
                color: color,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Stat Tile ──────────────────────────────────────
class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.07), width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.inter(color: Colors.white38, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// GRAFIK GARIS SUHU (Line Chart Custom)
// ═══════════════════════════════════════════════════════════════
class _TemperatureLineChart extends StatelessWidget {
  final List<Map<String, dynamic>> days;
  final int selectedIndex;
  final double globalMin;
  final double globalMax;
  final List<String> namaHari;
  final ValueChanged<int> onTap;

  const _TemperatureLineChart({
    required this.days,
    required this.selectedIndex,
    required this.globalMin,
    required this.globalMax,
    required this.namaHari,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapUp: (details) {
        // Hitung tap ke kolom mana
        final RenderBox box = context.findRenderObject() as RenderBox;
        final localPos = box.globalToLocal(details.globalPosition);
        final colWidth = box.size.width / days.length;
        final idx = (localPos.dx / colWidth).floor().clamp(0, days.length - 1);
        onTap(idx);
      },
      child: CustomPaint(
        painter: _LineChartPainter(
          days: days,
          selectedIndex: selectedIndex,
          globalMin: globalMin,
          globalMax: globalMax,
          namaHari: namaHari,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> days;
  final int selectedIndex;
  final double globalMin;
  final double globalMax;
  final List<String> namaHari;

  _LineChartPainter({
    required this.days,
    required this.selectedIndex,
    required this.globalMin,
    required this.globalMax,
    required this.namaHari,
  });

  Color _getWeatherColor(String main) {
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
        return const Color(0xFFBAE6FD);
      default:
        return const Color(0xFF93C5FD);
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (days.isEmpty) return;

    final double padTop = 30;
    final double padBottom = 48;
    final double padH = 20;
    final double chartH = size.height - padTop - padBottom;
    final double chartW = size.width - padH * 2;
    final double step = chartW / (days.length - 1);
    final double tempRange = (globalMax - globalMin).clamp(1, double.infinity);

    // Hitung posisi titik MAX dan MIN per hari
    List<Offset> maxPoints = [];
    List<Offset> minPoints = [];

    for (int i = 0; i < days.length; i++) {
      double x = padH + i * step;
      double maxY =
          padTop + chartH * (1 - (days[i]['max'] - globalMin) / tempRange);
      double minY =
          padTop + chartH * (1 - (days[i]['min'] - globalMin) / tempRange);
      maxPoints.add(Offset(x, maxY));
      minPoints.add(Offset(x, minY));
    }

    // ── Area fill max ──
    final maxPath = Path()..moveTo(maxPoints[0].dx, maxPoints[0].dy);
    for (int i = 1; i < maxPoints.length; i++) {
      final cp1 = Offset(
        (maxPoints[i - 1].dx + maxPoints[i].dx) / 2,
        maxPoints[i - 1].dy,
      );
      final cp2 = Offset(
        (maxPoints[i - 1].dx + maxPoints[i].dx) / 2,
        maxPoints[i].dy,
      );
      maxPath.cubicTo(
        cp1.dx,
        cp1.dy,
        cp2.dx,
        cp2.dy,
        maxPoints[i].dx,
        maxPoints[i].dy,
      );
    }
    maxPath
      ..lineTo(maxPoints.last.dx, size.height - padBottom)
      ..lineTo(maxPoints.first.dx, size.height - padBottom)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF60A5FA).withOpacity(0.2),
          const Color(0xFF60A5FA).withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(maxPath, fillPaint);

    // ── Garis MAX (suhu tertinggi) ──
    final maxLinePath = Path()..moveTo(maxPoints[0].dx, maxPoints[0].dy);
    for (int i = 1; i < maxPoints.length; i++) {
      final cp1 = Offset(
        (maxPoints[i - 1].dx + maxPoints[i].dx) / 2,
        maxPoints[i - 1].dy,
      );
      final cp2 = Offset(
        (maxPoints[i - 1].dx + maxPoints[i].dx) / 2,
        maxPoints[i].dy,
      );
      maxLinePath.cubicTo(
        cp1.dx,
        cp1.dy,
        cp2.dx,
        cp2.dy,
        maxPoints[i].dx,
        maxPoints[i].dy,
      );
    }

    final maxLinePaint = Paint()
      ..color = const Color(0xFF60A5FA).withOpacity(0.9)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(maxLinePath, maxLinePaint);

    // ── Garis MIN (suhu terendah) ──
    final minLinePath = Path()..moveTo(minPoints[0].dx, minPoints[0].dy);
    for (int i = 1; i < minPoints.length; i++) {
      final cp1 = Offset(
        (minPoints[i - 1].dx + minPoints[i].dx) / 2,
        minPoints[i - 1].dy,
      );
      final cp2 = Offset(
        (minPoints[i - 1].dx + minPoints[i].dx) / 2,
        minPoints[i].dy,
      );
      minLinePath.cubicTo(
        cp1.dx,
        cp1.dy,
        cp2.dx,
        cp2.dy,
        minPoints[i].dx,
        minPoints[i].dy,
      );
    }

    final minLinePaint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(minLinePath, minLinePaint);

    // ── Garis vertikal selected ──
    if (selectedIndex < days.length) {
      final selX = maxPoints[selectedIndex].dx;
      final selColor = _getWeatherColor(days[selectedIndex]['main']);
      final vLinePaint = Paint()
        ..color = selColor.withOpacity(0.3)
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke;
      canvas.drawLine(
        Offset(selX, padTop - 10),
        Offset(selX, size.height - padBottom),
        vLinePaint,
      );
    }

    // ── Titik per hari ──
    for (int i = 0; i < days.length; i++) {
      final bool isSelected = i == selectedIndex;
      final Color dotColor = _getWeatherColor(days[i]['main']);

      // Titik MAX
      if (isSelected) {
        // Glow ring
        final ringPaint = Paint()
          ..color = dotColor.withOpacity(0.3)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(maxPoints[i], 12, ringPaint);
      }

      final dotPaint = Paint()
        ..color = isSelected ? dotColor : const Color(0xFF60A5FA)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(maxPoints[i], isSelected ? 6 : 4, dotPaint);

      if (isSelected) {
        final innerDotPaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill;
        canvas.drawCircle(maxPoints[i], 2.5, innerDotPaint);
      }

      // Titik MIN (lebih kecil, redup)
      final minDotPaint = Paint()
        ..color = Colors.white.withOpacity(isSelected ? 0.6 : 0.25)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(minPoints[i], isSelected ? 4 : 3, minDotPaint);

      // Koneksikan titik MAX ke MIN dengan garis vertikal tipis
      final connPaint = Paint()
        ..color = Colors.white.withOpacity(isSelected ? 0.2 : 0.08)
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke;
      canvas.drawLine(maxPoints[i], minPoints[i], connPaint);

      // Label suhu MAX
      _drawText(
        canvas,
        "${days[i]['max'].round()}°",
        Offset(maxPoints[i].dx, maxPoints[i].dy - 16),
        isSelected
            ? GoogleFonts.inter(
                color: _getWeatherColor(days[i]['main']),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              )
            : GoogleFonts.inter(
                color: Colors.white54,
                fontSize: 11,
                fontWeight: FontWeight.w400,
              ),
        center: true,
      );

      // Label nama hari (bawah)
      String dayLabel;
      if (i == 0)
        dayLabel = "Hari ini";
      else if (i == 1)
        dayLabel = "Besok";
      else {
        DateTime date = days[i]['date'];
        dayLabel = namaHari[date.weekday];
      }

      _drawText(
        canvas,
        dayLabel,
        Offset(maxPoints[i].dx, size.height - padBottom + 10),
        isSelected
            ? GoogleFonts.inter(
                color: _getWeatherColor(days[i]['main']),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              )
            : GoogleFonts.inter(
                color: Colors.white38,
                fontSize: 10,
                fontWeight: FontWeight.w400,
              ),
        center: true,
      );
    }
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset pos,
    TextStyle style, {
    bool center = false,
  }) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();

    final dx = center ? pos.dx - tp.width / 2 : pos.dx;
    tp.paint(canvas, Offset(dx, pos.dy));
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter old) =>
      old.selectedIndex != selectedIndex || old.days.length != days.length;
}
