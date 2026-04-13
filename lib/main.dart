import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // <-- 3. Buka brankas .env sebelum aplikasi berjalan
  await dotenv.load(fileName: ".env");

  runApp(const SkyVisionApp());
}

class SkyVisionApp extends StatelessWidget {
  const SkyVisionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SkyVision',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1E88E5)),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}
