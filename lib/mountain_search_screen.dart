import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;

// ══════════════════════════════════════════════════════════════
// DATA MODEL
// ══════════════════════════════════════════════════════════════
class MountainData {
  final String name;
  final String location;
  final String province;
  final double lat;
  final double lon;
  final int elevation;
  final String difficulty; // Mudah / Sedang / Sulit / Ekstrem
  final String description;
  final Color accentColor;

  const MountainData({
    required this.name,
    required this.location,
    required this.province,
    required this.lat,
    required this.lon,
    required this.elevation,
    required this.difficulty,
    required this.description,
    required this.accentColor,
  });
}

// ══════════════════════════════════════════════════════════════
// DATA GUNUNG — 55 GUNUNG INDONESIA
// ══════════════════════════════════════════════════════════════
const List<MountainData> kMountainList = [
  // ── JAWA TIMUR ─────────────────────────────────────────────
  MountainData(
    name: 'Semeru',
    location: 'Malang–Lumajang, Jawa Timur',
    province: 'Jawa Timur',
    lat: -8.1086,
    lon: 112.9220,
    elevation: 3676,
    difficulty: 'Sulit',
    description:
        'Mahameru — puncak tertinggi di Pulau Jawa, aktif dengan letusan rutin dari kawah Jonggring Saloko.',
    accentColor: Color(0xFFEF4444),
  ),
  MountainData(
    name: 'Arjuno',
    location: 'Malang–Pasuruan, Jawa Timur',
    province: 'Jawa Timur',
    lat: -7.7292,
    lon: 112.5941,
    elevation: 3339,
    difficulty: 'Sedang',
    description:
        'Jalur Tretes dan Lawang populer dengan hutan pinus dan puncak memanjang yang memukau.',
    accentColor: Color(0xFFC4B5FD),
  ),
  MountainData(
    name: 'Welirang',
    location: 'Mojokerto–Pasuruan, Jawa Timur',
    province: 'Jawa Timur',
    lat: -7.6431,
    lon: 112.5793,
    elevation: 3156,
    difficulty: 'Sedang',
    description:
        'Gunung berapi aktif dengan kawah belerang dan pos penambang tradisional yang unik.',
    accentColor: Color(0xFFFB923C),
  ),
  MountainData(
    name: 'Argopuro',
    location: 'Probolinggo–Jember, Jawa Timur',
    province: 'Jawa Timur',
    lat: -7.9823,
    lon: 113.5681,
    elevation: 3088,
    difficulty: 'Sulit',
    description:
        'Jalur terpanjang di Jawa dengan padang edelweiss dan danau Taman Hidup yang misterius.',
    accentColor: Color(0xFFF472B6),
  ),
  MountainData(
    name: 'Bromo',
    location: 'Probolinggo–Malang, Jawa Timur',
    province: 'Jawa Timur',
    lat: -7.9425,
    lon: 112.9530,
    elevation: 2329,
    difficulty: 'Mudah',
    description:
        'Lautan pasir ikonik dan kawah aktif Bromo — destinasi wisata alam paling terkenal di Indonesia.',
    accentColor: Color(0xFFF59E0B),
  ),
  MountainData(
    name: 'Ijen',
    location: 'Banyuwangi–Bondowoso, Jawa Timur',
    province: 'Jawa Timur',
    lat: -8.0580,
    lon: 114.2420,
    elevation: 2799,
    difficulty: 'Sedang',
    description:
        'Api biru (blue fire) alami satu-satunya di dunia dan danau kawah asam terbesar di bumi.',
    accentColor: Color(0xFF38BDF8),
  ),
  MountainData(
    name: 'Raung',
    location: 'Banyuwangi–Jember, Jawa Timur',
    province: 'Jawa Timur',
    lat: -8.1253,
    lon: 114.0440,
    elevation: 3344,
    difficulty: 'Ekstrem',
    description:
        'Kawah aktif dengan kaldera luas dan medan teknis yang sangat menantang para pendaki berpengalaman.',
    accentColor: Color(0xFFFF4500),
  ),
  MountainData(
    name: 'Penanggungan',
    location: 'Mojokerto–Pasuruan, Jawa Timur',
    province: 'Jawa Timur',
    lat: -7.6258,
    lon: 112.6277,
    elevation: 1653,
    difficulty: 'Sedang',
    description:
        'Gunung sakral dengan ratusan situs candi Hindu di lerengnya, disebut sebagai Mahameru versi mini.',
    accentColor: Color(0xFFD97706),
  ),
  MountainData(
    name: 'Lemongan',
    location: 'Lumajang, Jawa Timur',
    province: 'Jawa Timur',
    lat: -8.0041,
    lon: 113.3541,
    elevation: 1671,
    difficulty: 'Mudah',
    description:
        'Gunung kecil aktif dengan danau kawah hijau di puncaknya, jalur pendek dan cocok untuk pemula.',
    accentColor: Color(0xFF84CC16),
  ),

  // ── JAWA TENGAH ────────────────────────────────────────────
  MountainData(
    name: 'Merbabu',
    location: 'Magelang–Boyolali, Jawa Tengah',
    province: 'Jawa Tengah',
    lat: -7.4554,
    lon: 110.4397,
    elevation: 3142,
    difficulty: 'Sedang',
    description:
        'Padang savana luas dengan pemandangan Merapi yang ikonik dari puncak Syarif dan Kenteng Songo.',
    accentColor: Color(0xFF8B5CF6),
  ),
  MountainData(
    name: 'Merapi',
    location: 'Sleman–Magelang',
    province: 'Jawa Tengah / DIY',
    lat: -7.5407,
    lon: 110.4457,
    elevation: 2930,
    difficulty: 'Ekstrem',
    description:
        'Gunung berapi paling aktif di Indonesia, terlarang didaki saat status awas atau siaga.',
    accentColor: Color(0xFFF97316),
  ),
  MountainData(
    name: 'Sindoro',
    location: 'Temanggung–Wonosobo',
    province: 'Jawa Tengah',
    lat: -7.3006,
    lon: 109.9988,
    elevation: 3153,
    difficulty: 'Sedang',
    description:
        'Kembar dengan Sumbing, jalur Kledung terkenal dengan sunrise dramatis dan ladang tembakau di kaki.',
    accentColor: Color(0xFFA3E635),
  ),
  MountainData(
    name: 'Sumbing',
    location: 'Magelang–Wonosobo–Temanggung',
    province: 'Jawa Tengah',
    lat: -7.3844,
    lon: 110.0607,
    elevation: 3371,
    difficulty: 'Sulit',
    description:
        'Padang rumput luas di puncak dengan jalur yang cukup menantang dan pemandangan 360 derajat.',
    accentColor: Color(0xFFBEF264),
  ),
  MountainData(
    name: 'Prau',
    location: 'Wonosobo–Batang, Jawa Tengah',
    province: 'Jawa Tengah',
    lat: -7.1843,
    lon: 109.9227,
    elevation: 2565,
    difficulty: 'Mudah',
    description:
        'Destinasi favorit pemula dengan golden sunrise dan lautan awan spektakuler Dieng.',
    accentColor: Color(0xFFFBBF24),
  ),
  MountainData(
    name: 'Lawu',
    location: 'Karanganyar–Magetan',
    province: 'Jawa Tengah / Jawa Timur',
    lat: -7.6268,
    lon: 111.1927,
    elevation: 3265,
    difficulty: 'Sedang',
    description:
        'Sarat nilai budaya dan spiritual, warung Mbok Yem di ketinggian 3100 mdpl adalah legenda tersendiri.',
    accentColor: Color(0xFFA78BFA),
  ),
  MountainData(
    name: 'Slamet',
    location: 'Brebes–Purbalingga, Jawa Tengah',
    province: 'Jawa Tengah',
    lat: -7.2434,
    lon: 109.2078,
    elevation: 3428,
    difficulty: 'Sulit',
    description:
        'Gunung tertinggi di Jawa Tengah dengan kawah aktif Kawah Barat, jalur Bambangan paling populer.',
    accentColor: Color(0xFF34D399),
  ),
  MountainData(
    name: 'Andong',
    location: 'Magelang, Jawa Tengah',
    province: 'Jawa Tengah',
    lat: -7.4312,
    lon: 110.4040,
    elevation: 1726,
    difficulty: 'Mudah',
    description:
        'Gunung ramah keluarga dengan empat puncak dan panorama gunung-gunung Jawa Tengah yang memukau.',
    accentColor: Color(0xFF6EE7B7),
  ),
  MountainData(
    name: 'Telomoyo',
    location: 'Magelang–Semarang, Jawa Tengah',
    province: 'Jawa Tengah',
    lat: -7.3763,
    lon: 110.3869,
    elevation: 1894,
    difficulty: 'Mudah',
    description:
        'Puncak dengan jalan aspal hingga gardu pandang, populer untuk pemula dan wisata keluarga.',
    accentColor: Color(0xFF93C5FD),
  ),

  // ── JAWA BARAT ─────────────────────────────────────────────
  MountainData(
    name: 'Gede',
    location: 'Cianjur–Sukabumi, Jawa Barat',
    province: 'Jawa Barat',
    lat: -6.7821,
    lon: 106.9841,
    elevation: 2958,
    difficulty: 'Sedang',
    description:
        'Gunung ikonik dekat Jakarta dengan alun-alun Suryakencana yang dipenuhi edelweiss memesona.',
    accentColor: Color(0xFF34D399),
  ),
  MountainData(
    name: 'Pangrango',
    location: 'Cianjur, Jawa Barat',
    province: 'Jawa Barat',
    lat: -6.7908,
    lon: 106.9895,
    elevation: 3019,
    difficulty: 'Sedang',
    description:
        'Berdampingan dengan Gede, dikenal dengan hutan lumut lebat dan hamparan edelweiss yang indah.',
    accentColor: Color(0xFF4ADE80),
  ),
  MountainData(
    name: 'Papandayan',
    location: 'Garut, Jawa Barat',
    province: 'Jawa Barat',
    lat: -7.3196,
    lon: 107.7307,
    elevation: 2665,
    difficulty: 'Mudah',
    description:
        'Kawah aktif belerang, hutan mati eksotis, dan camping ground indah di Pondok Salada.',
    accentColor: Color(0xFF06B6D4),
  ),
  MountainData(
    name: 'Ciremai',
    location: 'Kuningan–Majalengka, Jawa Barat',
    province: 'Jawa Barat',
    lat: -6.8924,
    lon: 108.4064,
    elevation: 3078,
    difficulty: 'Sulit',
    description:
        'Puncak tertinggi Jawa Barat dengan kawah ganda yang ikonik, jalur Palutungan dan Apuy terkenal.',
    accentColor: Color(0xFF7DD3FC),
  ),
  MountainData(
    name: 'Salak',
    location: 'Bogor–Sukabumi, Jawa Barat',
    province: 'Jawa Barat',
    lat: -6.7220,
    lon: 106.7300,
    elevation: 2211,
    difficulty: 'Sedang',
    description:
        'Gunung misterius dengan vegetasi lebat dan sering diselimuti kabut tebal sepanjang hari.',
    accentColor: Color(0xFF6B7280),
  ),
  MountainData(
    name: 'Tampomas',
    location: 'Sumedang, Jawa Barat',
    province: 'Jawa Barat',
    lat: -6.7680,
    lon: 107.9620,
    elevation: 1684,
    difficulty: 'Mudah',
    description:
        'Gunung pendek dengan jalur ramah pemula, panorama kota Sumedang dari puncaknya sangat menawan.',
    accentColor: Color(0xFF22D3EE),
  ),
  MountainData(
    name: 'Guntur',
    location: 'Garut, Jawa Barat',
    province: 'Jawa Barat',
    lat: -7.1462,
    lon: 107.8387,
    elevation: 2249,
    difficulty: 'Sedang',
    description:
        'Gunung berapi aktif di Garut dengan jalur pasir vulkanik dan kawah yang masih mengeluarkan asap.',
    accentColor: Color(0xFFFCD34D),
  ),
  MountainData(
    name: 'Cikurai',
    location: 'Garut, Jawa Barat',
    province: 'Jawa Barat',
    lat: -7.2826,
    lon: 107.8626,
    elevation: 2821,
    difficulty: 'Sedang',
    description:
        'Puncak berlumpur dengan padang edelweiss yang luas dan jalur yang cukup menantang di Garut.',
    accentColor: Color(0xFF86EFAC),
  ),

  // ── SUMATERA ───────────────────────────────────────────────
  MountainData(
    name: 'Kerinci',
    location: 'Kerinci, Jambi',
    province: 'Jambi',
    lat: -1.6974,
    lon: 101.2642,
    elevation: 3805,
    difficulty: 'Sulit',
    description:
        'Puncak tertinggi Sumatera dan gunung berapi tertinggi di Indonesia dengan kawah aktif di puncak.',
    accentColor: Color(0xFF10B981),
  ),
  MountainData(
    name: 'Singgalang',
    location: 'Agam, Sumatera Barat',
    province: 'Sumatera Barat',
    lat: -0.3773,
    lon: 100.3200,
    elevation: 2877,
    difficulty: 'Sedang',
    description:
        'Gunung mati dengan telaga di kaldera puncaknya, hutan tropis lebat dan jalur yang menantang.',
    accentColor: Color(0xFF2DD4BF),
  ),
  MountainData(
    name: 'Marapi',
    location: 'Agam–Tanah Datar, Sumatera Barat',
    province: 'Sumatera Barat',
    lat: -0.3814,
    lon: 100.4730,
    elevation: 2891,
    difficulty: 'Sulit',
    description:
        'Gunung berapi paling aktif di Sumatera Barat, pendakian harus sangat memperhatikan status aktivitas.',
    accentColor: Color(0xFFFF6B6B),
  ),
  MountainData(
    name: 'Talang',
    location: 'Solok, Sumatera Barat',
    province: 'Sumatera Barat',
    lat: -1.0126,
    lon: 100.6802,
    elevation: 2597,
    difficulty: 'Mudah',
    description:
        'Gunung berapi aktif dengan danau kembar Talang di lerengnya dan jalur yang relatif mudah ditempuh.',
    accentColor: Color(0xFF67E8F9),
  ),
  MountainData(
    name: 'Sibayak',
    location: 'Karo, Sumatera Utara',
    province: 'Sumatera Utara',
    lat: 3.2350,
    lon: 98.5130,
    elevation: 2212,
    difficulty: 'Mudah',
    description:
        'Gunung berapi aktif dekat Berastagi dengan kawah belerang dan jalur wisata yang sangat ramah pemula.',
    accentColor: Color(0xFFA78BFA),
  ),
  MountainData(
    name: 'Sinabung',
    location: 'Karo, Sumatera Utara',
    province: 'Sumatera Utara',
    lat: 3.1700,
    lon: 98.3920,
    elevation: 2460,
    difficulty: 'Ekstrem',
    description:
        'Gunung berapi sangat aktif, pendakian ditutup total karena erupsi yang terus berlangsung sejak 2010.',
    accentColor: Color(0xFFDC2626),
  ),
  MountainData(
    name: 'Leuser',
    location: 'Aceh Tenggara, Aceh',
    province: 'Aceh',
    lat: 3.7564,
    lon: 97.1806,
    elevation: 3404,
    difficulty: 'Ekstrem',
    description:
        'Puncak tertinggi Aceh di jantung kawasan ekosistem Leuser, jalur sangat panjang dan terpencil.',
    accentColor: Color(0xFF059669),
  ),
  MountainData(
    name: 'Dempo',
    location: 'Pagaralam, Sumatera Selatan',
    province: 'Sumatera Selatan',
    lat: -4.0290,
    lon: 103.1310,
    elevation: 3159,
    difficulty: 'Sulit',
    description:
        'Puncak tertinggi Sumatera Selatan dengan danau kawah berwarna hijau toska di kalderanya.',
    accentColor: Color(0xFF14B8A6),
  ),

  // ── BALI & NUSA TENGGARA ───────────────────────────────────
  MountainData(
    name: 'Rinjani',
    location: 'Lombok, NTB',
    province: 'Nusa Tenggara Barat',
    lat: -8.4120,
    lon: 116.4670,
    elevation: 3726,
    difficulty: 'Sulit',
    description:
        'Gunung berapi aktif kedua tertinggi Indonesia dengan danau kawah Segara Anak yang memukau.',
    accentColor: Color(0xFF0EA5E9),
  ),
  MountainData(
    name: 'Batur',
    location: 'Kintamani, Bali',
    province: 'Bali',
    lat: -8.2421,
    lon: 115.3750,
    elevation: 1717,
    difficulty: 'Mudah',
    description:
        'Sunrise di atas kaldera danau Batur — trekking populer dengan pemandangan Danau Batur yang cantik.',
    accentColor: Color(0xFFFF6B9D),
  ),
  MountainData(
    name: 'Agung',
    location: 'Karangasem, Bali',
    province: 'Bali',
    lat: -8.3428,
    lon: 115.5080,
    elevation: 3142,
    difficulty: 'Sulit',
    description:
        'Gunung suci tertinggi di Bali, pusat spiritual Pura Besakih — pendakian melewati hutan sakral.',
    accentColor: Color(0xFFFF8C42),
  ),
  MountainData(
    name: 'Tambora',
    location: 'Bima, NTB',
    province: 'Nusa Tenggara Barat',
    lat: -8.2459,
    lon: 117.9924,
    elevation: 2851,
    difficulty: 'Sulit',
    description:
        'Kaldera raksasa letusan 1815 — salah satu pendakian paling epik dengan cekungan 6 km di puncak.',
    accentColor: Color(0xFFE879F9),
  ),
  MountainData(
    name: 'Kelimutu',
    location: 'Ende, NTT',
    province: 'Nusa Tenggara Timur',
    lat: -8.7700,
    lon: 121.8200,
    elevation: 1639,
    difficulty: 'Mudah',
    description:
        'Tiga danau kawah warna-warni (merah, hijau, hitam) yang berubah warna secara berkala di Flores.',
    accentColor: Color(0xFF8B5CF6),
  ),
  MountainData(
    name: 'Inerie',
    location: 'Ngada, NTT',
    province: 'Nusa Tenggara Timur',
    lat: -8.8700,
    lon: 121.0200,
    elevation: 2245,
    difficulty: 'Sedang',
    description:
        'Kerucut sempurna di Flores dengan pemandangan kota Bajawa dan Laut Flores yang menakjubkan.',
    accentColor: Color(0xFFF472B6),
  ),

  // ── KALIMANTAN ─────────────────────────────────────────────
  MountainData(
    name: 'Bukit Raya',
    location: 'Katingan, Kalimantan Tengah',
    province: 'Kalimantan Tengah',
    lat: -0.5130,
    lon: 112.6820,
    elevation: 2278,
    difficulty: 'Ekstrem',
    description:
        'Puncak tertinggi Kalimantan dan Pulau Borneo — jalur sangat panjang menembus hutan tropis lebat.',
    accentColor: Color(0xFF15803D),
  ),
  MountainData(
    name: 'Bukit Baka',
    location: 'Melawi, Kalimantan Barat',
    province: 'Kalimantan Barat',
    lat: -0.5000,
    lon: 112.5000,
    elevation: 1617,
    difficulty: 'Sulit',
    description:
        'Perbatasan Kalimantan Barat dan Tengah, kawasan Taman Nasional dengan biodiversitas luar biasa.',
    accentColor: Color(0xFF22C55E),
  ),

  // ── SULAWESI ───────────────────────────────────────────────
  MountainData(
    name: 'Latimojong',
    location: 'Enrekang, Sulawesi Selatan',
    province: 'Sulawesi Selatan',
    lat: -3.3777,
    lon: 119.9738,
    elevation: 3478,
    difficulty: 'Sulit',
    description:
        'Atap Sulawesi — jalur panjang menembus hutan tropis dengan keanekaragaman hayati luar biasa.',
    accentColor: Color(0xFF60A5FA),
  ),
  MountainData(
    name: 'Lokon',
    location: 'Tomohon, Sulawesi Utara',
    province: 'Sulawesi Utara',
    lat: 1.3581,
    lon: 124.7928,
    elevation: 1579,
    difficulty: 'Mudah',
    description:
        'Gunung berapi aktif dekat kota Tomohon dengan kawah Tompaluan yang masih mengeluarkan uap.',
    accentColor: Color(0xFF2DD4BF),
  ),
  MountainData(
    name: 'Mahawu',
    location: 'Tomohon, Sulawesi Utara',
    province: 'Sulawesi Utara',
    lat: 1.3580,
    lon: 124.8620,
    elevation: 1331,
    difficulty: 'Mudah',
    description:
        'Gunung dekat Tomohon dengan danau kawah berwarna toska dan jalur yang sangat mudah ditempuh.',
    accentColor: Color(0xFF34D399),
  ),
  MountainData(
    name: 'Klabat',
    location: 'Minahasa Utara, Sulawesi Utara',
    province: 'Sulawesi Utara',
    lat: 1.4720,
    lon: 125.0310,
    elevation: 1995,
    difficulty: 'Sedang',
    description:
        'Gunung tertinggi di Minahasa dengan trek yang melewati hutan hujan dan pemandangan Manado.',
    accentColor: Color(0xFF7C3AED),
  ),
  MountainData(
    name: 'Soputan',
    location: 'Minahasa Selatan, Sulawesi Utara',
    province: 'Sulawesi Utara',
    lat: 1.1120,
    lon: 124.7250,
    elevation: 1784,
    difficulty: 'Sulit',
    description:
        'Gunung berapi aktif di Minahasa Selatan, pendakian harus memantau status aktivitas vulkanik.',
    accentColor: Color(0xFFEF4444),
  ),

  // ── MALUKU & PAPUA ─────────────────────────────────────────
  MountainData(
    name: 'Binaiya',
    location: 'Seram, Maluku',
    province: 'Maluku',
    lat: -3.1710,
    lon: 129.4700,
    elevation: 3027,
    difficulty: 'Ekstrem',
    description:
        'Puncak tertinggi Maluku dan Kepulauan Seram — butuh persiapan sangat matang dan waktu lama.',
    accentColor: Color(0xFF34D399),
  ),
  MountainData(
    name: 'Carstensz Pyramid',
    location: 'Puncak Jaya, Papua',
    province: 'Papua Tengah',
    lat: -4.0788,
    lon: 137.1564,
    elevation: 4884,
    difficulty: 'Ekstrem',
    description:
        'Tertinggi di Indonesia & Oceania — salah satu Seven Summits dunia, butuh izin dan pemandu khusus.',
    accentColor: Color(0xFFF8FAFC),
  ),
  MountainData(
    name: 'Trikora',
    location: 'Puncak Jaya, Papua',
    province: 'Papua',
    lat: -4.6740,
    lon: 138.6560,
    elevation: 4730,
    difficulty: 'Ekstrem',
    description:
        'Puncak tertinggi kedua di Papua dengan salju abadi, pendakian memerlukan tim ekspedisi khusus.',
    accentColor: Color(0xFFE2E8F0),
  ),
  MountainData(
    name: 'Mandala',
    location: 'Pegunungan Bintang, Papua',
    province: 'Papua',
    lat: -4.7000,
    lon: 140.4170,
    elevation: 4700,
    difficulty: 'Ekstrem',
    description:
        'Puncak ketiga tertinggi di Papua — ekspedisi panjang menembus hutan Papua yang sangat terpencil.',
    accentColor: Color(0xFFCBD5E1),
  ),

  // ── TAMBAHAN POPULER ───────────────────────────────────────
  MountainData(
    name: 'Ceremai',
    location: 'Kuningan, Jawa Barat',
    province: 'Jawa Barat',
    lat: -6.8924,
    lon: 108.4064,
    elevation: 3078,
    difficulty: 'Sulit',
    description:
        'Jalur pendakian dengan hutan pinus dan kawah ganda, salah satu yang terpopuler di Jawa Barat.',
    accentColor: Color(0xFF38BDF8),
  ),
  MountainData(
    name: 'Ungaran',
    location: 'Semarang, Jawa Tengah',
    province: 'Jawa Tengah',
    lat: -7.1820,
    lon: 110.3390,
    elevation: 2050,
    difficulty: 'Mudah',
    description:
        'Gunung dekat Semarang dengan beberapa jalur, pemandangan lampu kota malam hari yang spektakuler.',
    accentColor: Color(0xFF818CF8),
  ),
  MountainData(
    name: 'Muria',
    location: 'Kudus, Jawa Tengah',
    province: 'Jawa Tengah',
    lat: -6.6053,
    lon: 110.9247,
    elevation: 1602,
    difficulty: 'Mudah',
    description:
        'Gunung bersejarah dengan makam Sunan Muria di lerengnya, nilai religi dan wisata alam menyatu.',
    accentColor: Color(0xFFC084FC),
  ),
  MountainData(
    name: 'Penanggungan',
    location: 'Mojokerto, Jawa Timur',
    province: 'Jawa Timur',
    lat: -7.6258,
    lon: 112.6277,
    elevation: 1653,
    difficulty: 'Sedang',
    description:
        'Gunung sakral dengan ratusan situs candi Hindu di lerengnya, disebut sebagai miniatur Semeru.',
    accentColor: Color(0xFFD97706),
  ),
  MountainData(
    name: 'Burangrang',
    location: 'Bandung Barat, Jawa Barat',
    province: 'Jawa Barat',
    lat: -6.7008,
    lon: 107.5153,
    elevation: 2064,
    difficulty: 'Sedang',
    description:
        'Gunung di utara Bandung dengan panorama kota Bandung dan Tangkuban Perahu dari puncaknya.',
    accentColor: Color(0xFF6366F1),
  ),
  MountainData(
    name: 'Tangkuban Perahu',
    location: 'Bandung, Jawa Barat',
    province: 'Jawa Barat',
    lat: -6.7701,
    lon: 107.6098,
    elevation: 2084,
    difficulty: 'Mudah',
    description:
        'Gunung berapi legendaris Bandung dengan kawah Ratu, Domas, dan Upas — wisata favorit semua kalangan.',
    accentColor: Color(0xFF94A3B8),
  ),
  MountainData(
    name: 'Galunggung',
    location: 'Tasikmalaya, Jawa Barat',
    province: 'Jawa Barat',
    lat: -7.2523,
    lon: 108.0573,
    elevation: 2168,
    difficulty: 'Mudah',
    description:
        'Kawah besar dengan danau berwarna toska di dalamnya, pemandangan dari tepi kawah sangat dramatis.',
    accentColor: Color(0xFF0891B2),
  ),
];

// ══════════════════════════════════════════════════════════════
// TIME-BASED SKY THEME (sama seperti halaman home)
// ══════════════════════════════════════════════════════════════
class _SkyTheme {
  final Color skyTop;
  final Color skyMid;
  final Color skyBottom;
  final Color mountainDark;
  final Color mountainMid;
  final Color starColor;
  final Color accentGlow;
  final bool showStars;
  final bool showMoon;
  final String timeLabel;

  const _SkyTheme({
    required this.skyTop,
    required this.skyMid,
    required this.skyBottom,
    required this.mountainDark,
    required this.mountainMid,
    required this.starColor,
    required this.accentGlow,
    required this.showStars,
    required this.showMoon,
    required this.timeLabel,
  });
}

_SkyTheme _getSkyTheme() {
  final hour = DateTime.now().hour;

  if (hour >= 5 && hour < 7) {
    // Fajar / Subuh
    return const _SkyTheme(
      skyTop: Color(0xFF1A0A2E),
      skyMid: Color(0xFF4A1A3E),
      skyBottom: Color(0xFFFF6B35),
      mountainDark: Color(0xFF0D0818),
      mountainMid: Color(0xFF1A0F28),
      starColor: Color(0xFFFFEECC),
      accentGlow: Color(0xFFFF8C42),
      showStars: true,
      showMoon: true,
      timeLabel: 'Fajar',
    );
  } else if (hour >= 7 && hour < 10) {
    // Pagi
    return const _SkyTheme(
      skyTop: Color(0xFF0B3D6E),
      skyMid: Color(0xFF1B6CA8),
      skyBottom: Color(0xFFFFCC80),
      mountainDark: Color(0xFF0D1929),
      mountainMid: Color(0xFF0A1520),
      starColor: Color(0x00FFFFFF),
      accentGlow: Color(0xFFFFB347),
      showStars: false,
      showMoon: false,
      timeLabel: 'Pagi',
    );
  } else if (hour >= 10 && hour < 15) {
    // Siang
    return const _SkyTheme(
      skyTop: Color(0xFF0066CC),
      skyMid: Color(0xFF2196F3),
      skyBottom: Color(0xFF87CEEB),
      mountainDark: Color(0xFF1A2744),
      mountainMid: Color(0xFF152038),
      starColor: Color(0x00FFFFFF),
      accentGlow: Color(0xFF64B5F6),
      showStars: false,
      showMoon: false,
      timeLabel: 'Siang',
    );
  } else if (hour >= 15 && hour < 18) {
    // Sore
    return const _SkyTheme(
      skyTop: Color(0xFF1A237E),
      skyMid: Color(0xFFE65100),
      skyBottom: Color(0xFFFF8F00),
      mountainDark: Color(0xFF0D1117),
      mountainMid: Color(0xFF1A1A2E),
      starColor: Color(0x00FFFFFF),
      accentGlow: Color(0xFFFF7043),
      showStars: false,
      showMoon: false,
      timeLabel: 'Sore',
    );
  } else if (hour >= 18 && hour < 20) {
    // Senja / Maghrib
    return const _SkyTheme(
      skyTop: Color(0xFF0D0D2B),
      skyMid: Color(0xFF6B1E3E),
      skyBottom: Color(0xFFFF4500),
      mountainDark: Color(0xFF050810),
      mountainMid: Color(0xFF0A0D1A),
      starColor: Color(0xFFFFEECC),
      accentGlow: Color(0xFFFF6B35),
      showStars: true,
      showMoon: false,
      timeLabel: 'Senja',
    );
  } else {
    // Malam
    return const _SkyTheme(
      skyTop: Color(0xFF020408),
      skyMid: Color(0xFF06101E),
      skyBottom: Color(0xFF0D1929),
      mountainDark: Color(0xFF040810),
      mountainMid: Color(0xFF060D1A),
      starColor: Color(0xFFE8D5A3),
      accentGlow: Color(0xFF1E3A5F),
      showStars: true,
      showMoon: true,
      timeLabel: 'Malam',
    );
  }
}

// ══════════════════════════════════════════════════════════════
// SCREEN
// ══════════════════════════════════════════════════════════════
class MountainSearchScreen extends StatefulWidget {
  final double currentLat;
  final double currentLon;

  const MountainSearchScreen({
    super.key,
    required this.currentLat,
    required this.currentLon,
  });

  @override
  State<MountainSearchScreen> createState() => _MountainSearchScreenState();
}

class _MountainSearchScreenState extends State<MountainSearchScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<MountainData> _filtered = kMountainList;
  bool _isSearching = false;
  MountainData? _lastMountain;
  late _SkyTheme _sky;

  late AnimationController _entryCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  // Filter
  String _activeFilter = 'Semua';
  final List<String> _filters = [
    'Semua',
    'Mudah',
    'Sedang',
    'Sulit',
    'Ekstrem',
  ];

  Color _diffColor(String d) {
    switch (d) {
      case 'Mudah':
        return const Color(0xFF4ADE80);
      case 'Sedang':
        return const Color(0xFFFBBF24);
      case 'Sulit':
        return const Color(0xFFF97316);
      case 'Ekstrem':
        return const Color(0xFFEF4444);
      default:
        return Colors.white38;
    }
  }

  @override
  void initState() {
    super.initState();
    _sky = _getSkyTheme();

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

    _loadLastMountain();
    _focusNode.addListener(() {
      setState(() => _isSearching = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _focusNode.dispose();
    _entryCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadLastMountain() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('last_mountain_name');
    if (name != null) {
      final found = kMountainList.where((m) => m.name == name).firstOrNull;
      if (found != null && mounted) setState(() => _lastMountain = found);
    }
  }

  void _applyFilter() {
    final q = _searchCtrl.text.trim().toLowerCase();
    setState(() {
      _filtered = kMountainList.where((m) {
        final matchQuery =
            q.isEmpty ||
            m.name.toLowerCase().contains(q) ||
            m.location.toLowerCase().contains(q) ||
            m.province.toLowerCase().contains(q);
        final matchDiff =
            _activeFilter == 'Semua' || m.difficulty == _activeFilter;
        return matchQuery && matchDiff;
      }).toList();
    });
  }

  void _onSearchChanged(String q) => _applyFilter();

  Future<void> _selectMountain(MountainData m) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_mountain_name', m.name);
    await prefs.setDouble('saved_lat', m.lat);
    await prefs.setDouble('saved_lon', m.lon);

    if (mounted) {
      Navigator.pop(context, {
        'cityName': 'G. ${m.name}',
        'subLocation': '${m.location}, ${m.province}',
        'lat': m.lat,
        'lon': m.lon,
        'mountain': m,
      });
    }
  }

  // ── Stats per difficulty ──────────────────────────────────
  int _countByDiff(String d) =>
      kMountainList.where((m) => m.difficulty == d).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _sky.skyTop,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: Stack(
            children: [
              // ── Dynamic time-based background ──
              Positioned.fill(
                child: CustomPaint(painter: _MountainBgPainter(theme: _sky)),
              ),

              SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTopBar(),
                    if (!_isSearching) _buildFilterChips(),
                    Expanded(
                      child: _isSearching
                          ? _buildSearchResults()
                          : _buildDefaultView(),
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

  // ── Top bar ───────────────────────────────────────────────
  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.12),
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
              const SizedBox(width: 14),
              if (!_isSearching)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Cuaca Gunung",
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 22,
                          letterSpacing: -0.6,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            "Pendakian di Indonesia",
                            style: GoogleFonts.inter(
                              color: Colors.white38,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Time badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _sky.accentGlow.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: _sky.accentGlow.withOpacity(0.35),
                                width: 0.5,
                              ),
                            ),
                            child: Text(
                              _sky.timeLabel,
                              style: GoogleFonts.inter(
                                color: _sky.accentGlow,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              if (!_isSearching)
                // Stats ringkas
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                      width: 0.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${kMountainList.length}',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Gunung',
                        style: GoogleFonts.inter(
                          color: Colors.white38,
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
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
                    ? _sky.accentGlow.withOpacity(0.5)
                    : Colors.white.withOpacity(0.1),
                width: 0.5,
              ),
            ),
            child: Row(
              children: [
                const SizedBox(width: 14),
                Icon(
                  Icons.search_rounded,
                  color: _isSearching ? _sky.accentGlow : Colors.white38,
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
                      hintText: "Cari nama, kota, atau provinsi...",
                      hintStyle: GoogleFonts.inter(
                        color: Colors.white30,
                        fontSize: 13,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    cursorColor: _sky.accentGlow,
                  ),
                ),
                if (_searchCtrl.text.isNotEmpty || _isSearching)
                  GestureDetector(
                    onTap: () {
                      _searchCtrl.clear();
                      _focusNode.unfocus();
                      setState(() {
                        _isSearching = false;
                        _filtered = kMountainList;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        "Batal",
                        style: GoogleFonts.inter(
                          color: _sky.accentGlow,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  // ── Filter chips by difficulty ────────────────────────────
  Widget _buildFilterChips() {
    return SizedBox(
      height: 36,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _filters.length,
        itemBuilder: (_, i) {
          final f = _filters[i];
          final isActive = f == _activeFilter;
          final chipColor = f == 'Semua' ? _sky.accentGlow : _diffColor(f);
          return GestureDetector(
            onTap: () {
              setState(() => _activeFilter = f);
              _applyFilter();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
              ), // Hapus vertical padding, biarkan auto
              alignment: Alignment
                  .center, // <-- KUNCI REVISI: Selalu rata tengah atas-bawah
              decoration: BoxDecoration(
                color: isActive
                    ? chipColor.withOpacity(0.2)
                    : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isActive
                      ? chipColor.withOpacity(0.6)
                      : Colors.white.withOpacity(0.1),
                  width: isActive ? 1 : 0.5,
                ),
              ),
              child: Text(
                f == 'Semua' ? 'Semua (${kMountainList.length})' : f,
                style: GoogleFonts.inter(
                  color: isActive ? chipColor : Colors.white38,
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                  height:
                      1.0, // <-- KUNCI REVISI 2: Menghapus spasi default dari font
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Default view ──────────────────────────────────────────
  Widget _buildDefaultView() {
    // Group by pulau/region
    final Map<String, List<MountainData>> grouped = {};
    for (final m in _filtered) {
      final region = _getRegion(m.province);
      grouped.putIfAbsent(region, () => []).add(m);
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card gunung terakhir
          if (_lastMountain != null && _activeFilter == 'Semua') ...[
            _buildSectionLabel("TERAKHIR DIPILIH"),
            const SizedBox(height: 8),
            _buildMountainCard(_lastMountain!, isLast: true),
            const SizedBox(height: 20),
          ],

          // Stats bar
          if (_activeFilter == 'Semua') ...[
            _buildStatsBar(),
            const SizedBox(height: 20),
          ],

          // Grouped list
          if (_filtered.isEmpty)
            _buildEmpty()
          else
            ...grouped.entries.map(
              (entry) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionLabel(
                    '${entry.key.toUpperCase()}  ·  ${entry.value.length} gunung',
                  ),
                  const SizedBox(height: 8),
                  ...entry.value.map((m) => _buildMountainCard(m)),
                  const SizedBox(height: 16),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // Stats bar
  Widget _buildStatsBar() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08), width: 0.5),
      ),
      child: Row(
        children: [
          _buildStat('Mudah', _countByDiff('Mudah'), const Color(0xFF4ADE80)),
          _buildStatDivider(),
          _buildStat('Sedang', _countByDiff('Sedang'), const Color(0xFFFBBF24)),
          _buildStatDivider(),
          _buildStat('Sulit', _countByDiff('Sulit'), const Color(0xFFF97316)),
          _buildStatDivider(),
          _buildStat(
            'Ekstrem',
            _countByDiff('Ekstrem'),
            const Color(0xFFEF4444),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, int count, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            '$count',
            style: GoogleFonts.inter(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.inter(color: Colors.white38, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildStatDivider() => Container(
    width: 0.5,
    height: 28,
    color: Colors.white.withOpacity(0.1),
    margin: const EdgeInsets.symmetric(horizontal: 4),
  );

  String _getRegion(String province) {
    if ([
      'Jawa Timur',
      'Jawa Tengah',
      'Jawa Barat',
      'Jawa Tengah / DIY',
      'Jawa Tengah / Jawa Timur',
      'DI Yogyakarta',
      'DKI Jakarta',
    ].any((p) => province.contains('Jawa') || province.contains('DIY'))) {
      return 'Pulau Jawa';
    } else if ([
      'Bali',
      'Nusa Tenggara Barat',
      'Nusa Tenggara Timur',
    ].contains(province)) {
      return 'Bali & Nusa Tenggara';
    } else if (province.contains('Sumatera') ||
        province.contains('Aceh') ||
        province.contains('Jambi') ||
        province.contains('Riau') ||
        province.contains('Bengkulu') ||
        province.contains('Lampung')) {
      return 'Pulau Sumatera';
    } else if (province.contains('Kalimantan')) {
      return 'Pulau Kalimantan';
    } else if (province.contains('Sulawesi')) {
      return 'Pulau Sulawesi';
    } else if (province.contains('Maluku')) {
      return 'Kepulauan Maluku';
    } else if (province.contains('Papua')) {
      return 'Papua';
    }
    return 'Lainnya';
  }

  Widget _buildSectionLabel(String text) => Text(
    text,
    style: GoogleFonts.inter(
      color: Colors.white38,
      fontSize: 10,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.4,
    ),
  );

  Widget _buildMountainCard(MountainData m, {bool isLast = false}) {
    return GestureDetector(
      onTap: () => _selectMountain(m),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isLast
              ? m.accentColor.withOpacity(0.12)
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isLast
                ? m.accentColor.withOpacity(0.35)
                : Colors.white.withOpacity(0.08),
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            // Icon gunung
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: m.accentColor.withOpacity(0.13),
                borderRadius: BorderRadius.circular(13),
              ),
              child: CustomPaint(
                painter: _MiniMountainIconPainter(color: m.accentColor),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          m.name,
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            letterSpacing: -0.3,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _diffColor(m.difficulty).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          m.difficulty,
                          style: GoogleFonts.inter(
                            color: _diffColor(m.difficulty),
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    m.location,
                    style: GoogleFonts.inter(
                      color: Colors.white38,
                      fontSize: 11,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Icon(
                        Icons.terrain_rounded,
                        color: m.accentColor.withOpacity(0.7),
                        size: 11,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        "${m.elevation} mdpl",
                        style: GoogleFonts.inter(
                          color: m.accentColor.withOpacity(0.85),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (isLast) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: m.accentColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            "Terakhir",
                            style: GoogleFonts.inter(
                              color: m.accentColor,
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.white.withOpacity(0.2),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  // ── Search results ────────────────────────────────────────
  Widget _buildSearchResults() {
    if (_filtered.isEmpty) return _buildEmpty();

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
      itemCount: _filtered.length + 1,
      itemBuilder: (_, i) {
        if (i == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              '${_filtered.length} gunung ditemukan',
              style: GoogleFonts.inter(color: Colors.white38, fontSize: 12),
            ),
          );
        }
        return _buildMountainCard(_filtered[i - 1]);
      },
    );
  }

  Widget _buildEmpty() => Center(
    child: Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.terrain_rounded, color: Colors.white12, size: 52),
          const SizedBox(height: 12),
          Text(
            "Gunung tidak ditemukan",
            style: GoogleFonts.inter(color: Colors.white24, fontSize: 14),
          ),
          const SizedBox(height: 6),
          Text(
            "Coba nama, kota, atau provinsi",
            style: GoogleFonts.inter(color: Colors.white12, fontSize: 12),
          ),
        ],
      ),
    ),
  );
}

// ══════════════════════════════════════════════════════════════
// CUSTOM PAINTERS
// ══════════════════════════════════════════════════════════════

/// Background dinamis sesuai waktu
class _MountainBgPainter extends CustomPainter {
  final _SkyTheme theme;
  _MountainBgPainter({required this.theme});

  @override
  void paint(Canvas canvas, Size size) {
    // Gradient langit
    final skyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [theme.skyTop, theme.skyMid, theme.skyBottom],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), skyPaint);

    // Glow horizon
    final glowPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0, 0.3),
        radius: 0.8,
        colors: [theme.accentGlow.withOpacity(0.15), Colors.transparent],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), glowPaint);

    // Bintang
    if (theme.showStars) {
      final starPaint = Paint()..style = PaintingStyle.fill;
      final r = math.Random(42);
      for (int i = 0; i < 55; i++) {
        final x = r.nextDouble() * size.width;
        final y = r.nextDouble() * size.height * 0.42;
        final opacity = 0.2 + r.nextDouble() * 0.65;
        final radius = 0.5 + r.nextDouble() * 1.3;
        starPaint.color = theme.starColor.withOpacity(opacity);
        canvas.drawCircle(Offset(x, y), radius, starPaint);
      }
    }

    // Bulan
    if (theme.showMoon) {
      final moonPaint = Paint()
        ..color = theme.starColor.withOpacity(0.85)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(
        Offset(size.width * 0.82, size.height * 0.10),
        11,
        moonPaint,
      );
      // Crescent shadow
      final shadowPaint = Paint()
        ..color = theme.skyTop.withOpacity(0.88)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(
        Offset(size.width * 0.85, size.height * 0.09),
        10,
        shadowPaint,
      );
    }

    // Layer gunung belakang
    final p1 = Paint()..color = theme.mountainDark;
    final path1 = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, size.height * 0.62)
      ..lineTo(size.width * 0.12, size.height * 0.38)
      ..lineTo(size.width * 0.25, size.height * 0.50)
      ..lineTo(size.width * 0.38, size.height * 0.28)
      ..lineTo(size.width * 0.52, size.height * 0.46)
      ..lineTo(size.width * 0.65, size.height * 0.20)
      ..lineTo(size.width * 0.78, size.height * 0.40)
      ..lineTo(size.width * 0.90, size.height * 0.30)
      ..lineTo(size.width, size.height * 0.44)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path1, p1);

    // Layer gunung depan
    final p2 = Paint()..color = theme.mountainMid;
    final path2 = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, size.height * 0.76)
      ..lineTo(size.width * 0.08, size.height * 0.58)
      ..lineTo(size.width * 0.20, size.height * 0.70)
      ..lineTo(size.width * 0.32, size.height * 0.48)
      ..lineTo(size.width * 0.46, size.height * 0.64)
      ..lineTo(size.width * 0.60, size.height * 0.42)
      ..lineTo(size.width * 0.74, size.height * 0.60)
      ..lineTo(size.width * 0.87, size.height * 0.50)
      ..lineTo(size.width, size.height * 0.62)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path2, p2);

    // Kontur tipis
    final linePaint = Paint()
      ..color = theme.accentGlow.withOpacity(0.12)
      ..strokeWidth = 0.6
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path2, linePaint);
  }

  @override
  bool shouldRepaint(covariant _MountainBgPainter old) =>
      old.theme.timeLabel != theme.timeLabel;
}

/// Ikon gunung mini untuk card
class _MiniMountainIconPainter extends CustomPainter {
  final Color color;
  _MiniMountainIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Gunung utama
    final paint = Paint()
      ..color = color.withOpacity(0.85)
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(cx, cy - 13)
      ..lineTo(cx - 14, cy + 9)
      ..lineTo(cx + 14, cy + 9)
      ..close();
    canvas.drawPath(path, paint);

    // Gunung kecil kiri
    final path2 = Path()
      ..moveTo(cx - 9, cy + 2)
      ..lineTo(cx - 18, cy + 9)
      ..lineTo(cx - 2, cy + 9)
      ..close();
    canvas.drawPath(path2, paint..color = color.withOpacity(0.4));

    // Salju puncak
    final snowPath = Path()
      ..moveTo(cx, cy - 13)
      ..lineTo(cx - 4, cy - 6)
      ..lineTo(cx + 4, cy - 6)
      ..close();
    canvas.drawPath(snowPath, Paint()..color = Colors.white.withOpacity(0.9));
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
