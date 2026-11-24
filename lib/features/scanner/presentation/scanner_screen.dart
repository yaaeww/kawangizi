import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import 'package:kawangizi_mobile/core/theme/app_colors.dart';
import 'package:kawangizi_mobile/shared/widgets/feature_header.dart';
import '../domain/scan_models.dart' show Verdict;
import '../data/scan_repository.dart';
import 'scanner_controller.dart';
import 'widgets/yolo_bounding_box_painter.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> with TickerProviderStateMixin {
  late final ScannerController _controller;
  final ImagePicker _picker = ImagePicker();
  final GlobalKey _photoKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _controller = ScannerController(scanRepository: context.read<ScanRepository>());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _controller,
      child: Consumer<ScannerController>(
        builder: (context, controller, _) => _ScannerView(
          controller: controller,
          picker: _picker,
          photoKey: _photoKey,
          onExit: () => context.go('/'),
          onOpenProfile: () => context.go('/profile'),
        ),
      ),
    );
  }
}

class _ScannerView extends StatelessWidget {
  const _ScannerView({
    required this.controller,
    required this.picker,
    required this.photoKey,
    required this.onExit,
    required this.onOpenProfile,
  });

  final ScannerController controller;
  final ImagePicker picker;
  final GlobalKey photoKey;
  final VoidCallback onExit;
  final VoidCallback onOpenProfile;

  void _showGuideDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Panduan Pemindaian Porsi MBG'),
        content: const Text(
          '1. Masukkan token QR boks atau biarkan kosong jika otomatis.\n'
          '2. Masukkan suhu lepas dapur dan suhu holding saat boks tiba.\n'
          '3. Ambil foto boks terbuka dengan pencahayaan cukup.\n'
          '4. Model AI YOLOv8 akan menganalisis komponen menu dan status kelayakan makanan.',
          style: TextStyle(height: 1.4, fontSize: 13),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tutup')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header: Pindai Boks
            FeatureHeader(
              title: 'Pindai Boks',
              onOpenProfile: onOpenProfile,
              onExit: null, // As seen in screenshot, bottom tab bar handles navigation
            ),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 110),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Amber Card (Matching Screenshot media_1795520353276_277b65bb.jpg)
                    _TopAmberScanCard(
                      controller: controller,
                      picker: picker,
                      onHelp: () => _showGuideDialog(context),
                    ),

                    const SizedBox(height: 16),

                    // Bottom Area: Result if scanned, or Empty State Placeholder
                    if (controller.hasScanned) ...[
                      _CapturedPhotoSection(controller: controller, photoKey: photoKey),
                      const SizedBox(height: 16),
                      if (controller.backendScan != null)
                        _ResultSection(controller: controller),
                      if (controller.backendError != null)
                        _ErrorSection(
                          error: controller.backendError!,
                          onRetry: () => controller.startScan(picker, context),
                        ),
                    ] else ...[
                      // Empty Placeholder Card
                      const _ScanPlaceholderCard(),
                    ],
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

// ===================== Top Amber Scan Card =====================
class _TopAmberScanCard extends StatelessWidget {
  const _TopAmberScanCard({
    required this.controller,
    required this.picker,
    required this.onHelp,
  });

  final ScannerController controller;
  final ImagePicker picker;
  final VoidCallback onHelp;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Badges Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.sparkles, size: 12, color: Colors.white),
                    SizedBox(width: 5),
                    Text(
                      'Pengenal menu + kesegaran matang',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle, size: 7, color: Color(0xFF10B981)),
                    SizedBox(width: 5),
                    Text(
                      'Inferensi server',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Title
          const Text(
            'Scan Hidangan Matang',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),

          // Description
          Text(
            'Foto dinilai oleh model pengenal menu dan model kesegaran hidangan matang. Token QR serta suhu berasal dari pemeriksaan petugas; batch mengisi resep dan gizi bila tersedia di database.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.95),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 18),

          // Input 1: Token QR
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: TextField(
              controller: TextEditingController(text: controller.qrToken)
                ..selection = TextSelection.collapsed(offset: controller.qrToken.length),
              onChanged: controller.setQrToken,
              decoration: const InputDecoration(
                hintText: 'Masukkan token QR boks (manual)',
                hintStyle: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Inputs Row: Suhu lepas dapur & Suhu holding
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: TextField(
                    controller: TextEditingController(text: controller.releaseTemp)
                      ..selection = TextSelection.collapsed(offset: controller.releaseTemp.length),
                    onChanged: controller.setReleaseTemp,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: 'Suhu lepas dapur °C',
                      hintStyle: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: TextField(
                    controller: TextEditingController(text: controller.holdingTemp)
                      ..selection = TextSelection.collapsed(offset: controller.holdingTemp.length),
                    onChanged: controller.setHoldingTemp,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: 'Suhu holding °C',
                      hintStyle: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Action Button Row: [ ] Mulai Pindai Porsi MBG + ? button
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.text,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    ),
                    onPressed: controller.isAnalyzing
                        ? null
                        : () => controller.startScan(picker, context, source: ImageSource.camera),
                    icon: controller.isAnalyzing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.text),
                          )
                        : const Icon(LucideIcons.scan, size: 18, color: AppColors.text),
                    label: Text(
                      controller.isAnalyzing ? 'Menganalisis...' : 'Mulai Pindai Porsi MBG',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.text),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              InkWell(
                onTap: onHelp,
                borderRadius: BorderRadius.circular(25),
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.25),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(LucideIcons.helpCircle, size: 20, color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ===================== Empty Placeholder Card =====================
class _ScanPlaceholderCard extends StatelessWidget {
  const _ScanPlaceholderCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: const Icon(LucideIcons.camera, size: 26, color: Color(0xFF94A3B8)),
            ),
            const SizedBox(height: 16),
            const Text(
              'Data akan muncul di sini setelah pemindaian',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            const Text(
              'Masukkan token QR serta suhu hasil pengukuran, lalu ambil foto untuk mengirimkannya ke model yang sama dengan portal web.',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ===================== Captured Photo Section =====================
class _CapturedPhotoSection extends StatelessWidget {
  const _CapturedPhotoSection({required this.controller, required this.photoKey});

  final ScannerController controller;
  final GlobalKey photoKey;

  @override
  Widget build(BuildContext context) {
    final photoPath = controller.capturedPhoto;
    if (photoPath == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Image.file(
            File(photoPath),
            key: photoKey,
            width: double.infinity,
            height: 240,
            fit: BoxFit.cover,
          ),
          if (controller.localDetections.isNotEmpty)
            Positioned.fill(
              child: CustomPaint(
                painter: YoloBoundingBoxPainter(detections: controller.localDetections),
              ),
            ),
        ],
      ),
    );
  }
}

// ===================== Result Section =====================
class _ResultSection extends StatelessWidget {
  const _ResultSection({required this.controller});

  final ScannerController controller;

  @override
  Widget build(BuildContext context) {
    final scan = controller.backendScan;
    if (scan == null) return const SizedBox.shrink();

    final isLayak = scan.verdict == Verdict.layak;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Verdict Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isLayak ? const Color(0xFFDCFCE7) : const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isLayak ? LucideIcons.checkCircle2 : LucideIcons.alertTriangle,
                      size: 14,
                      color: isLayak ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      scan.verdictLabel.isNotEmpty ? scan.verdictLabel : (isLayak ? '100% Layak' : 'Peringatan Mutu'),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isLayak ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                'Skor: ${(scan.score * 100).round()}%',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.text),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            scan.menuDisplay ?? scan.menuName ?? 'Menu Terdeteksi',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.text),
          ),
          const SizedBox(height: 4),
          Text(
            (scan.note != null && scan.note!.isNotEmpty) ? scan.note! : 'Hidangan telah diperiksa sesuai SOP BGN.',
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.3),
          ),
          const Divider(height: 24),
          // Checks list
          ...scan.checks.map((c) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Icon(
                      c.ok ? LucideIcons.check : LucideIcons.x,
                      size: 14,
                      color: c.ok ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${c.label}: ${c.note}',
                        style: const TextStyle(fontSize: 12, color: AppColors.text),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

// ===================== Error Section =====================
class _ErrorSection extends StatelessWidget {
  const _ErrorSection({required this.error, required this.onRetry});

  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFCA5A5)),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.alertTriangle, size: 20, color: Color(0xFFB91C1C)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(error, style: const TextStyle(fontSize: 12, color: Color(0xFFB91C1C))),
          ),
          TextButton(
            onPressed: onRetry,
            child: const Text('Coba Lagi', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFFB91C1C))),
          ),
        ],
      ),
    );
  }
}
