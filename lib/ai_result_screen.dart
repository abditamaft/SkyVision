import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class AiResultScreen extends StatefulWidget {
  final File imageFile;
  const AiResultScreen({super.key, required this.imageFile});

  @override
  State<AiResultScreen> createState() => _AiResultScreenState();
}

class _AiResultScreenState extends State<AiResultScreen> {
  bool isDetecting = true;
  Interpreter? _interpreter;
  ui.Image? _maskImage;

  String detectedCloud = "Memproses...";
  String rainProbability = "--";
  String description = "";
  double cloudPercentage = 0.0;

  @override
  void initState() {
    super.initState();
    _initAndRunModel();
  }

  @override
  void dispose() {
    _interpreter?.close();
    super.dispose();
  }

  Future<void> _initAndRunModel() async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));

      _interpreter = await Interpreter.fromAsset(
        'assets/models/model_awan_ultimate_resnet.tflite',
      );

      final inputShape = _interpreter!.getInputTensor(0).shape;
      final outputShape = _interpreter!.getOutputTensor(0).shape;

      // Shape: [1, H, W, C]
      final int modelH = inputShape[1];
      final int modelW = inputShape[2];
      final int outH = outputShape[1];
      final int outW = outputShape[2];
      final int outC = outputShape[3]; // 4 kelas

      debugPrint('▶ Input : ${modelH}x${modelW}x3');
      debugPrint('▶ Output: ${outH}x${outW}x$outC');

      // Baca & resize gambar
      final rawBytes = await widget.imageFile.readAsBytes();
      final img.Image? original = img.decodeImage(rawBytes);
      if (original == null) throw Exception("Gagal decode gambar");

      final img.Image resized = img.copyResize(
        original,
        width: modelW,
        height: modelH,
        interpolation: img.Interpolation.linear,
      );

      // ✅ FIX UTAMA: Preprocessing ResNet50 yang BENAR
      // Keras resnet50.preprocess_input(img) dengan img range [0,255]:
      //   1. Konversi RGB → BGR
      //   2. Subtract mean ImageNet: B-103.939, G-116.779, R-123.68
      // TIDAK ada perkalian 255 karena pixel sudah [0,255]
      final inputTensor = List.generate(
        1,
        (_) => List.generate(
          modelH,
          (y) => List.generate(modelW, (x) {
            final p = resized.getPixel(x, y);
            return [
              p.b.toDouble() - 103.939, // B (index 0)
              p.g.toDouble() - 116.779, // G (index 1)
              p.r.toDouble() - 123.68, // R (index 2)
            ];
          }),
        ),
      );

      // Output tensor
      final outputTensor = List.generate(
        1,
        (_) => List.generate(
          outH,
          (_) => List.generate(outW, (_) => List.filled(outC, 0.0)),
        ),
      );

      // Jalankan inferensi
      _interpreter!.run(inputTensor, outputTensor);

      // Post-processing: argmax per piksel
      // Mapping kelas (sesuai fuzzy logic Python training):
      //   kelas 0 → background
      //   kelas 1 → background
      //   kelas 2 → awan menengah   ← isCloud
      //   kelas 3 → awan tebal CB   ← isCloud + isThick
      int cloudPixelCount = 0;
      int thickPixelCount = 0;
      final maskPixels = Uint8List(outW * outH * 4);

      for (int y = 0; y < outH; y++) {
        for (int x = 0; x < outW; x++) {
          final idx = (y * outW + x) * 4;

          // Argmax
          int argmax = 0;
          double maxVal = outputTensor[0][y][x][0];
          for (int c = 1; c < outC; c++) {
            if (outputTensor[0][y][x][c] > maxVal) {
              maxVal = outputTensor[0][y][x][c];
              argmax = c;
            }
          }

          final bool isCloud = argmax >= 2;
          final bool isThick = argmax == 3;

          if (isCloud) {
            cloudPixelCount++;
            if (isThick) {
              thickPixelCount++;
              maskPixels[idx] = 255; // R — oranye untuk awan tebal
              maskPixels[idx + 1] = 100;
              maskPixels[idx + 2] = 0;
              maskPixels[idx + 3] = 150;
            } else {
              maskPixels[idx] = 0; // G — hijau untuk awan ringan
              maskPixels[idx + 1] = 220;
              maskPixels[idx + 2] = 80;
              maskPixels[idx + 3] = 130;
            }
          }
          // background → semua 0 (transparan), Uint8List default sudah 0
        }
      }

      ui.decodeImageFromPixels(maskPixels, outW, outH, ui.PixelFormat.rgba8888, (
        ui.Image maskImg,
      ) {
        if (!mounted) return;
        setState(() {
          _maskImage = maskImg;

          final int total = outW * outH;
          cloudPercentage = cloudPixelCount / total * 100;
          final double thickPct = thickPixelCount / total * 100;

          debugPrint(
            '☁ Cloud: ${cloudPercentage.toStringAsFixed(1)}%'
            ' | Thick: ${thickPct.toStringAsFixed(1)}%',
          );

          if (thickPct > 15) {
            detectedCloud = "Cumulonimbus";
            rainProbability =
                "${(thickPct * 2 + cloudPercentage).clamp(0, 100).toStringAsFixed(0)}%";
            description =
                "Terdeteksi awan konvektif tebal (Cumulonimbus) mencakup "
                "${thickPct.toStringAsFixed(1)}% area. Potensi hujan lebat hingga sangat lebat.";
          } else if (cloudPercentage > 25) {
            detectedCloud = "Awan Tebal";
            rainProbability =
                "${(cloudPercentage + 15).clamp(0, 100).toStringAsFixed(0)}%";
            description =
                "Cakupan awan ${cloudPercentage.toStringAsFixed(1)}%. "
                "Potensi hujan sedang hingga lebat.";
          } else if (cloudPercentage > 8) {
            detectedCloud = "Awan Menengah";
            rainProbability = "35%";
            description =
                "Awan terdeteksi ${cloudPercentage.toStringAsFixed(1)}% area. "
                "Berpotensi gerimis atau hujan ringan.";
          } else {
            detectedCloud = "Cerah Berawan";
            rainProbability = "10%";
            description =
                "Hanya ${cloudPercentage.toStringAsFixed(1)}% area tertutup awan. "
                "Tidak ada indikasi hujan signifikan.";
          }

          isDetecting = false;
        });
      });
    } catch (e, st) {
      debugPrint('❌ Error: $e\n$st');
      if (mounted) {
        setState(() {
          detectedCloud = "Error";
          description = "Gagal memproses: $e";
          isDetecting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A2342),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Hasil Segmentasi AI",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: isDetecting ? _buildLoading() : _buildResult(),
    );
  }

  Widget _buildLoading() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CircularProgressIndicator(
          color: Colors.lightBlueAccent,
          strokeWidth: 4,
        ),
        const SizedBox(height: 24),
        Text(
          "Memproses Pola Awan...",
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  );

  Widget _buildResult() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Gambar + overlay mask
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                Image.file(
                  widget.imageFile,
                  height: 350,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                ),
                if (_maskImage != null)
                  Positioned.fill(
                    child: CustomPaint(painter: MaskPainter(mask: _maskImage!)),
                  ),
              ],
            ),
          ),

          // Legenda
          if (_maskImage != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _legend(const Color(0xFF00DC50), "Awan ringan"),
                  const SizedBox(width: 16),
                  _legend(const Color(0xFFFF6400), "Awan tebal"),
                ],
              ),
            ),

          const SizedBox(height: 20),

          // Kartu hasil
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  detectedCloud,
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF0A2342),
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Divider(height: 30),
                Row(
                  children: [
                    const Icon(
                      Icons.water_drop,
                      color: Colors.lightBlueAccent,
                      size: 28,
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Potensi Hujan",
                          style: GoogleFonts.poppins(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          rainProbability,
                          style: GoogleFonts.poppins(
                            color: Colors.lightBlue,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "Cakupan Awan",
                          style: GoogleFonts.poppins(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          "${cloudPercentage.toStringAsFixed(1)}%",
                          style: GoogleFonts.poppins(
                            color: const Color(0xFF0A2342),
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  "Deskripsi:",
                  style: GoogleFonts.poppins(
                    color: Colors.grey.shade800,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  description,
                  style: GoogleFonts.poppins(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.lightBlueAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.home, color: Colors.white),
              label: Text(
                "Kembali ke Beranda",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _legend(Color color, String label) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          color: color.withOpacity(0.8),
          borderRadius: BorderRadius.circular(3),
        ),
      ),
      const SizedBox(width: 5),
      Text(
        label,
        style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12),
      ),
    ],
  );
}

/// MaskPainter dengan alignment BoxFit.cover + center yang matematis benar
class MaskPainter extends CustomPainter {
  final ui.Image mask;
  const MaskPainter({required this.mask});

  @override
  void paint(Canvas canvas, Size size) {
    final double maskAspect = mask.width / mask.height;
    final double canvasAspect = size.width / size.height;

    double srcX, srcY, srcW, srcH;
    if (maskAspect > canvasAspect) {
      // Mask lebih lebar: crop kiri-kanan, center horizontal
      srcH = mask.height.toDouble();
      srcW = srcH * canvasAspect;
      srcX = (mask.width - srcW) / 2.0;
      srcY = 0;
    } else {
      // Mask lebih tinggi: crop atas-bawah, center vertikal
      srcW = mask.width.toDouble();
      srcH = srcW / canvasAspect;
      srcX = 0;
      srcY = (mask.height - srcH) / 2.0;
    }

    canvas.drawImageRect(
      mask,
      Rect.fromLTWH(srcX, srcY, srcW, srcH),
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..filterQuality = FilterQuality.medium,
    );
  }

  @override
  bool shouldRepaint(covariant MaskPainter old) => old.mask != mask;
}
