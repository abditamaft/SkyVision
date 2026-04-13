import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

class CitySearchScreen extends StatefulWidget {
  /// Lokasi yang sedang aktif di home (untuk ditampilkan di card awal)
  final String currentCityName;
  final String currentSubLocation;
  final double currentLat;
  final double currentLon;

  const CitySearchScreen({
    super.key,
    required this.currentCityName,
    required this.currentSubLocation,
    required this.currentLat,
    required this.currentLon,
  });

  @override
  State<CitySearchScreen> createState() => _CitySearchScreenState();
}

class _CitySearchScreenState extends State<CitySearchScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isSearching = false;
  bool _isLoadingResult = false;
  List<Map<String, dynamic>> _searchResults = [];
  Timer? _debounce;

  late AnimationController _entryCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  // Kota populer Indonesia
  final List<String> _popularCities = [
    'Cari lokasi saya',
    'Jakarta',
    'Surabaya',
    'Bandung',
    'Medan',
    'Semarang',
    'Denpasar',
    'Yogyakarta',
    'Makassar',
    'Palembang',
    'Tangerang',
    'Depok',
    'Bekasi',
    'Balikpapan',
    'Banjarmasin',
    'Pontianak',
    'Pekanbaru',
    'Manado',
    'Padang',
    'Mataram',
    'Kupang',
    'Jambi',
    'Palu',
    'Lampung',
    'Batam',
  ];

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
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut));

    _entryCtrl.forward();

    _focusNode.addListener(() {
      setState(() => _isSearching = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _focusNode.dispose();
    _debounce?.cancel();
    _entryCtrl.dispose();
    super.dispose();
  }

  // ── Search dengan debounce 500ms ──────────────────
  void _onSearchChanged(String query) {
    _debounce?.cancel();
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isLoadingResult = false;
      });
      return;
    }
    setState(() => _isLoadingResult = true);
    _debounce = Timer(
      const Duration(milliseconds: 500),
      () => _doSearch(query),
    );
  }

  Future<void> _doSearch(String query) async {
    try {
      // locationFromAddress mencakup: nama jalan, desa, kecamatan, kota, provinsi, negara
      List<Location> locations = await locationFromAddress(query);

      List<Map<String, dynamic>> results = [];
      for (var loc in locations.take(6)) {
        try {
          List<Placemark> marks = await placemarkFromCoordinates(
            loc.latitude,
            loc.longitude,
          );
          if (marks.isNotEmpty) {
            Placemark p = marks[0];
            String name = p.street?.isNotEmpty == true
                ? p.street!
                : p.subLocality?.isNotEmpty == true
                ? p.subLocality!
                : p.locality ?? p.name ?? query;
            String sub = [
              if (p.subLocality?.isNotEmpty == true) p.subLocality,
              if (p.locality?.isNotEmpty == true) p.locality,
              if (p.administrativeArea?.isNotEmpty == true)
                p.administrativeArea,
              if (p.country?.isNotEmpty == true) p.country,
            ].whereType<String>().join(', ');

            results.add({
              'name': name,
              'sub': sub,
              'lat': loc.latitude,
              'lon': loc.longitude,
            });
          }
        } catch (_) {}
      }

      if (mounted) {
        setState(() {
          _searchResults = results;
          _isLoadingResult = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _searchResults = [];
          _isLoadingResult = false;
        });
      }
    }
  }

  // ── Pilih kota populer ────────────────────────────
  Future<void> _selectPopularCity(String cityName) async {
    if (cityName == 'Cari lokasi saya') {
      _useCurrentLocation();
      return;
    }
    setState(() => _isLoadingResult = true);
    try {
      List<Location> locs = await locationFromAddress('$cityName, Indonesia');
      if (locs.isNotEmpty) {
        List<Placemark> marks = await placemarkFromCoordinates(
          locs[0].latitude,
          locs[0].longitude,
        );
        String sub = '';
        if (marks.isNotEmpty) {
          Placemark p = marks[0];
          sub = [
            if (p.locality?.isNotEmpty == true) p.locality,
            if (p.administrativeArea?.isNotEmpty == true) p.administrativeArea,
          ].whereType<String>().join(', ');
        }
        _returnLocation(cityName, sub, locs[0].latitude, locs[0].longitude);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kota tidak ditemukan: $cityName'),
            backgroundColor: const Color(0xFF1A2744),
          ),
        );
        setState(() => _isLoadingResult = false);
      }
    }
  }

  // ── Gunakan GPS ───────────────────────────────────
  Future<void> _useCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('GPS tidak aktif.')));
      return;
    }
    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied) return;
    }
    if (perm == LocationPermission.deniedForever) return;

    setState(() => _isLoadingResult = true);
    try {
      Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      List<Placemark> marks = await placemarkFromCoordinates(
        pos.latitude,
        pos.longitude,
      );
      if (marks.isNotEmpty) {
        Placemark p = marks[0];
        String name = p.street?.isNotEmpty == true
            ? p.street!
            : p.subLocality ?? p.locality ?? 'Lokasi Saya';
        String sub = [
          if (p.subLocality?.isNotEmpty == true) p.subLocality,
          if (p.locality?.isNotEmpty == true) p.locality,
          if (p.administrativeArea?.isNotEmpty == true) p.administrativeArea,
        ].whereType<String>().join(', ');
        _returnLocation(name, sub, pos.latitude, pos.longitude);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingResult = false);
    }
  }

  // ── Simpan ke SharedPreferences & kembali ke Home ─
  Future<void> _returnLocation(
    String name,
    String sub,
    double lat,
    double lon,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_city_name', name);
    await prefs.setString('saved_sub_location', sub);
    await prefs.setDouble('saved_lat', lat);
    await prefs.setDouble('saved_lon', lon);

    if (mounted) {
      Navigator.pop(context, {
        'cityName': name,
        'subLocation': sub,
        'lat': lat,
        'lon': lon,
      });
    }
  }

  // ── UI ────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
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
                _buildTopBar(),
                Expanded(
                  child: _isSearching
                      ? _buildSearchView()
                      : _buildDefaultView(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Top bar ───────────────────────────────────────
  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tombol back
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 38,
              height: 38,
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
                size: 18,
              ),
            ),
          ),

          const SizedBox(height: 20),

          if (!_isSearching)
            Text(
              "Kelola Lokasi",
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.8,
              ),
            ),

          const SizedBox(height: 16),

          // Search field
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(_isSearching ? 0.1 : 0.07),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isSearching
                    ? const Color(0xFF3B82F6).withOpacity(0.5)
                    : Colors.white.withOpacity(0.1),
                width: 0.5,
              ),
            ),
            child: Row(
              children: [
                const SizedBox(width: 14),
                Icon(
                  Icons.search_rounded,
                  color: _isSearching
                      ? const Color(0xFF60A5FA)
                      : Colors.white38,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    focusNode: _focusNode,
                    onChanged: _onSearchChanged,
                    style: GoogleFonts.inter(color: Colors.white, fontSize: 15),
                    decoration: InputDecoration(
                      hintText: "Cari desa, kota, provinsi, negara...",
                      hintStyle: GoogleFonts.inter(
                        color: Colors.white30,
                        fontSize: 14,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    cursorColor: const Color(0xFF60A5FA),
                  ),
                ),
                if (_isSearching)
                  GestureDetector(
                    onTap: () {
                      _searchCtrl.clear();
                      _focusNode.unfocus();
                      setState(() {
                        _isSearching = false;
                        _searchResults = [];
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        "Batal",
                        style: GoogleFonts.inter(
                          color: const Color(0xFF60A5FA),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ── View default (sebelum search) ─────────────────
  Widget _buildDefaultView() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card lokasi aktif sekarang
          _buildCurrentLocationCard(),

          const SizedBox(height: 28),

          Text(
            "Kota Populer",
            style: GoogleFonts.inter(
              color: Colors.white38,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),

          const SizedBox(height: 14),

          // Grid wrap kota populer
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _popularCities.map((city) {
              final bool isGps = city == 'Cari lokasi saya';
              return GestureDetector(
                onTap: () => _selectPopularCity(city),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isGps
                        ? const Color(0xFF3B82F6).withOpacity(0.15)
                        : Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isGps
                          ? const Color(0xFF3B82F6).withOpacity(0.4)
                          : Colors.white.withOpacity(0.08),
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isGps) ...[
                        const Icon(
                          Icons.my_location_rounded,
                          color: Color(0xFF60A5FA),
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        city,
                        style: GoogleFonts.inter(
                          color: isGps
                              ? const Color(0xFF60A5FA)
                              : Colors.white70,
                          fontSize: 13,
                          fontWeight: isGps ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ── Card lokasi aktif ─────────────────────────────
  Widget _buildCurrentLocationCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1D3461), Color(0xFF1A2744)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF3B82F6).withOpacity(0.25),
          width: 0.5,
        ),
      ),
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
              Icons.location_on_rounded,
              color: Color(0xFF60A5FA),
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.currentCityName,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    letterSpacing: -0.3,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                if (widget.currentSubLocation.isNotEmpty)
                  Text(
                    widget.currentSubLocation,
                    style: GoogleFonts.inter(
                      color: Colors.white38,
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF4ADE80).withOpacity(0.12),
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
    );
  }

  // ── View saat searching ───────────────────────────
  Widget _buildSearchView() {
    return _isLoadingResult
        ? Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF60A5FA),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "Mencari lokasi...",
                  style: GoogleFonts.inter(color: Colors.white38, fontSize: 13),
                ),
              ],
            ),
          )
        : _searchCtrl.text.isEmpty
        ? _buildPopularSuggestions()
        : _searchResults.isEmpty
        ? Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.location_off_rounded,
                  color: Colors.white12,
                  size: 48,
                ),
                const SizedBox(height: 12),
                Text(
                  "Lokasi tidak ditemukan",
                  style: GoogleFonts.inter(color: Colors.white24, fontSize: 14),
                ),
              ],
            ),
          )
        : _buildResultList();
  }

  // Saran kota populer saat field kosong tapi sudah fokus
  Widget _buildPopularSuggestions() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Kota Populer",
            style: GoogleFonts.inter(
              color: Colors.white38,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _popularCities.skip(1).map((city) {
              return GestureDetector(
                onTap: () => _selectPopularCity(city),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.08),
                      width: 0.5,
                    ),
                  ),
                  child: Text(
                    city,
                    style: GoogleFonts.inter(
                      color: Colors.white60,
                      fontSize: 13,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // Daftar hasil search
  Widget _buildResultList() {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _searchResults.length,
      itemBuilder: (_, i) {
        final r = _searchResults[i];
        return GestureDetector(
          onTap: () => _returnLocation(r['name'], r['sub'], r['lat'], r['lon']),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.08),
                width: 0.5,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.place_rounded,
                    color: Color(0xFF60A5FA),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r['name'],
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      if ((r['sub'] as String).isNotEmpty)
                        Text(
                          r['sub'],
                          style: GoogleFonts.inter(
                            color: Colors.white38,
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white24,
                  size: 18,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
