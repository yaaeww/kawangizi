import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import 'package:kawangizi_mobile/core/theme/app_colors.dart';
import 'package:kawangizi_mobile/core/utils/relative_time.dart';
import 'package:kawangizi_mobile/features/auth/presentation/auth_controller.dart';
import '../domain/scan_models.dart';
import 'scanner_controller.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            FeatureHeader(
              title: 'Pindai Boks',
              onOpenProfile: onOpenProfile,
              onExit: onExit,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Input Form
                    _InputForm(controller: controller),
                    const SizedBox(height: 16),
                    // Scan Button
                    _ScanButton(controller: controller, picker: picker),
                    const SizedBox(height: 16),
                    // Captured Photo & Result
                    if (controller.hasScanned) ...[
                      _CapturedPhotoSection(controller: controller, photoKey: photoKey),
                      const SizedBox(height: 16),
                      if (controller.backendScan != null)
                        _ResultSection(controller: controller),
                      if (controller.backendError != null)
                        _ErrorSection(error: controller.backendError!, onRetry: () => controller.startScan(ImagePicker(), context)),
                    ],
                  ],
                ),
              ),
            ),
            // Bottom tabs for gizi/kelayakan
            if (controller.hasScanned && controller.backendScan != null)
              _BottomTabBar(controller: controller),
            // Chat / Guide buttons
            if (controller.hasScanned && controller.backendScan != null)
              _ActionButtons(controller: controller),
          ],
        ),
      ),
    );
  }
}

// ===================== FeatureHeader (shared) =====================
class FeatureHeader extends StatelessWidget {
  const FeatureHeader({
    super.key,
    required this.title,
    this.onOpenProfile,
    this.onExit,
  });

  final String title;
  final VoidCallback? onOpenProfile;
  final VoidCallback? onExit;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          if (onExit != null)
            IconButton(
              icon: const Icon(LucideIcons.chevronLeft, size: 22, color: AppColors.text),
              onPressed: onExit,
              splashRadius: 24,
            ),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.text,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          if (onOpenProfile != null)
            ProfileAvatarButton(name: 'User', onTap: onOpenProfile!),
        ],
      ),
    );
  }
}

// ===================== InputForm =====================
class _InputForm extends StatelessWidget {
  const _InputForm({required this.controller});

  final ScannerController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Data Pemeriksaan',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.text),
          ),
          const SizedBox(height: 12),
          _InputField(
            label: 'Token QR Boks',
            hint: 'Masukkan token QR',
            value: controller.qrToken,
            onChanged: controller.setQrToken,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _InputField(
                  label: 'Suhu Holding (°C)',
                  hint: '60',
                  value: controller.holdingTemp,
                  onChanged: controller.setHoldingTemp,
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _InputField(
                  label: 'Suhu Lepas (°C)',
                  hint: '75',
                  value: controller.releaseTemp,
                  onChanged: controller.setReleaseTemp,
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  const _InputField({
    required this.label,
    required this.hint,
    required this.value,
    required this.onChanged,
    this.keyboardType = TextInputType.text,
  });

  final String label;
  final String hint;
  final String value;
  final ValueChanged<String> onChanged;
  final TextInputType keyboardType;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: TextEditingController(text: value),
          keyboardType: keyboardType,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.textMuted),
            filled: true,
            fillColor: AppColors.surfaceMuted,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}

// ===================== ScanButton =====================
class _ScanButton extends StatelessWidget {
  const _ScanButton({required this.controller, required this.picker});

  final ScannerController controller;
  final ImagePicker picker;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: FilledButton.icon(
          onPressed: controller.isAnalyzing
              ? null
              : () => controller.startScan(picker, context),
          icon: controller.isAnalyzing
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(LucideIcons.camera, size: 22),
          label: Text(
            controller.isAnalyzing ? 'Menganalisis...' : 'Mulai Scan',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          ),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.text,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ),
    );
  }
}

// ===================== CapturedPhotoSection =====================
class _CapturedPhotoSection extends StatelessWidget {
  const _CapturedPhotoSection({required this.controller, required this.photoKey});

  final ScannerController controller;
  final GlobalKey photoKey;

  @override
  Widget build(BuildContext context) {
    if (!controller.hasScanned || controller.capturedPhoto == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.file(
              controller.capturedPhoto! as dynamic, // XFile path
              key: photoKey,
              width: double.infinity,
              height: 300,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: IconButton(
              icon: const Icon(LucideIcons.x, color: Colors.white, size: 22),
              onPressed: controller.resetScan,
              style: IconButton.styleFrom(
                backgroundColor: Colors.black.withValues(alpha: 0.5),
                shape: const CircleBorder(),
              ),
            ),
          ),
          if (controller.isAnalyzing)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.4),
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ===================== ResultSection =====================
class _ResultSection extends StatelessWidget {
  const _ResultSection({required this.controller});

  final ScannerController controller;

  @override
  Widget build(BuildContext context) {
    final scan = controller.backendScan!;
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Verdict badge
          _VerdictBadge(verdict: scan.verdict),
          const SizedBox(height: 16),
          // Temperature info
          Row(
            children: [
              Expanded(child: _InfoChip(label: 'Suhu Lepas', value: '${scan.releaseTemp.toStringAsFixed(1)}°C')),
              const SizedBox(width: 12),
              Expanded(child: _InfoChip(label: 'Suhu Holding', value: '${scan.holdTemp.toStringAsFixed(1)}°C')),
            ],
          ),
          const SizedBox(height: 16),
          // Checks
          const Text('Checklist', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.text)),
          const SizedBox(height: 8),
          ...scan.checks.map((c) => _CheckRow(check: c)),
          const SizedBox(height: 16),
          // AI Class & Confidence
          Row(
            children: [
              Expanded(child: _InfoChip(label: 'Kelas AI', value: scan.aiClass)),
              const SizedBox(width: 12),
              Expanded(child: _InfoChip(label: 'Kepercayaan', value: '${(scan.aiConfidence * 100).round()}%')),
            ],
          ),
          const SizedBox(height: 16),
          // Compartments if any
          if (scan.compartments != null && scan.compartments!.isNotEmpty) ...[
            const Text('Kompartemen', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.text)),
            const SizedBox(height: 8),
            ...scan.compartments!.map((c) => _CompartmentRow(compartment: c)),
            const SizedBox(height: 16),
          ],
          // Nutrition / Kelayakan tabs content
          if (controller.activeTab == ScanMode.nutrisi && scan.nutrisi != null)
            _NutrisiContent(nutrisi: scan.nutrisi!),
          if (controller.activeTab == ScanMode.kelayakan && scan.kelayakan != null)
            _KelayakanContent(kelayakan: scan.kelayakan!),
        ],
      ),
    );
  }
}

class _VerdictBadge extends StatelessWidget {
  const _VerdictBadge({required this.verdict});

  final Verdict verdict;

  @override
  Widget build(BuildContext context) {
    final (color, label) = _verdictInfo(verdict);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_verdictIcon(verdict), color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  (Color, String) _verdictInfo(Verdict v) {
    switch (v) {
      case Verdict.layak:
        return (AppColors.green, 'Layak Konsumsi');
      case Verdict.waspada:
        return (AppColors.amber, 'Perlu Verifikasi');
      case Verdict.ditolak:
        return (AppColors.red, 'Tidak Layak');
    }
  }

  IconData _verdictIcon(Verdict v) {
    switch (v) {
      case Verdict.layak:
        return LucideIcons.checkCircle2;
      case Verdict.waspada:
        return LucideIcons.alertTriangle;
      case Verdict.ditolak:
        return LucideIcons.xCircle;
    }
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.text)),
        ],
      ),
    );
  }
}

class _CheckRow extends StatelessWidget {
  const _CheckRow({required this.check});

  final ScanCheck check;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(check.ok ? LucideIcons.check : LucideIcons.x,
              size: 18, color: check.ok ? AppColors.green : AppColors.red),
          const SizedBox(width: 8),
          Expanded(child: Text(check.label, style: const TextStyle(fontSize: 13, color: AppColors.text))),
          if (check.note.isNotEmpty)
            Text(check.note, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _CompartmentRow extends StatelessWidget {
  const _CompartmentRow({required this.compartment});

  final CompartmentMatch compartment;

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(compartment.status);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(8)),
            child: Text('${compartment.index + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(compartment.predicted ?? 'Kosong',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.text)),
                Text('${compartment.component ?? ''} • ${(compartment.confidence * 100).round()}%',
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              compartment.status,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: statusColor),
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'match':
        return AppColors.green;
      case 'review':
        return AppColors.amber;
      case 'mismatch':
        return AppColors.red;
      case 'empty':
        return AppColors.textSecondary;
      default:
        return AppColors.textSecondary;
    }
  }
}

class _NutrisiContent extends StatelessWidget {
  const _NutrisiContent({required this.nutrisi});

  final NutrisiReport nutrisi;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Rincian Nutrisi', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.text)),
        const SizedBox(height: 12),
        ...nutrisi.rincianBahan.map((b) => _NutrientRow(bahan: b)),
        const SizedBox(height: 12),
        _MacroRow(label: 'Kalori', value: '${nutrisi.makronutrisi.kaloriTotal.round()} kkal'),
        _MacroRow(label: 'Protein', value: '${nutrisi.makronutrisi.protein.round()} g'),
        _MacroRow(label: 'Karbohidrat', value: '${nutrisi.makronutrisi.karbohidrat.round()} g'),
        _MacroRow(label: 'Lemak', value: '${nutrisi.makronutrisi.lemak.round()} g'),
        _MacroRow(label: 'Serat', value: '${nutrisi.makronutrisi.serat.round()} g'),
        const SizedBox(height: 8),
        Text(nutrisi.ringkasanGizi, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }
}

class _KelayakanContent extends StatelessWidget {
  const _KelayakanContent({required this.kelayakan});

  final KelayakanReport kelayakan;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DetailRow(label: 'Menu', value: kelayakan.namaHidangan),
        _DetailRow(label: 'Status', value: kelayakan.statusKelayakan),
        _DetailRow(label: 'Skor Kesegaran', value: '${kelayakan.skorKesegaran.toStringAsFixed(1)}'),
        const SizedBox(height: 8),
        const Text('Indikator Visual:', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        ...kelayakan.indikatorVisual.map((i) => Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 2),
              child: Text('• $i', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            )),
        if (kelayakan.peringatanKeamanan != null) ...[
          const SizedBox(height: 8),
          Text('Peringatan: ${kelayakan.peringatanKeamanan}', style: const TextStyle(color: AppColors.red, fontSize: 12)),
        ],
        const SizedBox(height: 8),
        Text('Rekomendasi: ${kelayakan.rekomendasi}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }
}

class _NutrientRow extends StatelessWidget {
  const _NutrientRow({required this.bahan});

  final NutrisiBahan bahan;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(bahan.bahan, style: const TextStyle(fontSize: 13, color: AppColors.text))),
          Text('${bahan.porsiEstimasi} (${bahan.weightG.toStringAsFixed(1)}g)',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _MacroRow extends StatelessWidget {
  const _MacroRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.text)),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 120, child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.text))),
        ],
      ),
    );
  }
}

// ===================== ErrorSection =====================
class _ErrorSection extends StatelessWidget {
  const _ErrorSection({required this.error, required this.onRetry});

  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.redSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.red.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.alertCircle, color: AppColors.red, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text(error, style: const TextStyle(color: AppColors.red, fontSize: 13))),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onRetry,
              child: const Text('Coba Lagi'),
            ),
          ),
        ],
      ),
    );
  }
}

// ===================== BottomTabBar =====================
class _BottomTabBar extends StatelessWidget {
  const _BottomTabBar({required this.controller});

  final ScannerController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: _TabButton(
              label: 'Gizi',
              active: controller.activeTab == ScanMode.nutrisi,
              onTap: () => controller.setActiveTab(ScanMode.nutrisi),
            ),
          ),
          Expanded(
            child: _TabButton(
              label: 'Kelayakan',
              active: controller.activeTab == ScanMode.kelayakan,
              onTap: () => controller.setActiveTab(ScanMode.kelayakan),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({required this.label, required this.active, required this.onTap});

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: active ? AppColors.text : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

// ===================== ActionButtons =====================
class _ActionButtons extends StatelessWidget {
  const _ActionButtons({required this.controller});

  final ScannerController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: controller.isChatOpen ? null : () => controller.openChat(),
              icon: const Icon(LucideIcons.messageSquare, size: 20),
              label: const Text('AI Chat'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: controller.isGuideOpen ? null : () => controller.openGuide(),
              icon: const Icon(LucideIcons.helpCircle, size: 20),
              label: const Text('Panduan'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                side: const BorderSide(color: AppColors.border),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
