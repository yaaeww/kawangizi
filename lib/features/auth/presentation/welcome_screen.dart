import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:kawangizi_mobile/core/utils/relative_time.dart';
import 'package:kawangizi_mobile/shared/widgets/feature_header.dart';
import 'auth_controller.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final _carouselController = PageController(viewportFraction: 0.85);
  int _activeSlide = 0;
  bool _showSopModal = false;
  bool _showInfoModal = false;
  bool _guestLoading = false;

  static const _slides = [
    _FeatureSlide(
      id: 'slide-1',
      title: 'Skrining Kamera Instan',
      desc: 'Deteksi visual risiko basi, kontaminasi mikroba, dan anomali aroma dalam 3 detik sebelum distribusi ke ruang kelas.',
      icon: LucideIcons.scan,
      iconColor: Color(0xFFD97706),
      iconBg: Color(0xFFFEF3C7),
    ),
    _FeatureSlide(
      id: 'slide-2',
      title: 'Kalkulasi Gizi Otomatis',
      desc: 'Estimasi presisi karbohidrat, protein hewani, serat sayur, dan kecukupan kalori standar Bappenas & Kemenkes.',
      icon: LucideIcons.pieChart,
      iconColor: Color(0xFF059669),
      iconBg: Color(0xFFDCFCE7),
    ),
    _FeatureSlide(
      id: 'slide-3',
      title: 'Terkoneksi Satgas MBG',
      desc: 'BAST digital otomatis terunggah ke dasbor pusat, mengunci akuntabilitas katering dan kepastian keselamatan siswa.',
      icon: LucideIcons.shieldCheck,
      iconColor: Color(0xFF2563EB),
      iconBg: Color(0xFFDBEAFE),
    ),
  ];

  void _navigateLogin() => context.go('/login');
  void _openSop() => setState(() => _showSopModal = true);
  void _closeSop() => setState(() => _showSopModal = false);
  void _openInfo() => setState(() => _showInfoModal = true);
  void _closeInfo() => setState(() => _showInfoModal = false);

  Future<void> _guestExplore(AuthController auth) async {
    setState(() => _guestLoading = true);
    try {
      await auth.loginAsGuest();
      if (!mounted) return;
      context.go('/');
    } catch (_) {
      if (!mounted) return;
      _navigateLogin();
    } finally {
      if (mounted) setState(() => _guestLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthController>();
    return Scaffold(
      backgroundColor: const Color(0xFFF9F8F6),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                const SizedBox(height: 16),
                Expanded(
                  child: PageView.builder(
                    controller: _carouselController,
                    onPageChanged: (i) => setState(() => _activeSlide = i),
                    itemCount: _slides.length,
                    itemBuilder: (_, i) => _SlideCard(slide: _slides[i]),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _slides.length,
                    (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _activeSlide == i ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _activeSlide == i
                            ? const Color(0xFFEBA338)
                            : const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      FilledButton.icon(
                        onPressed: _guestLoading ? null : () => _guestExplore(auth),
                        icon: _guestLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                                : const Icon(LucideIcons.userPlus, size: 20),
                        label: const Text('Jelajahi sebagai Tamu'),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                          backgroundColor: const Color(0xFFEBA338),
                          foregroundColor: const Color(0xFF1E293B),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _navigateLogin,
                        icon: const Icon(LucideIcons.logIn, size: 20),
                        label: const Text('Masuk sebagai Validator'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                          foregroundColor: const Color(0xFF1E293B),
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: _openSop,
                        child: const Text(
                          'Lihat SOP & Panduan',
                          style: TextStyle(
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: _openInfo,
                        child: const Text(
                          'Tentang Aplikasi',
                          style: TextStyle(
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
            if (_showSopModal) _SopModal(onClose: _closeSop),
            if (_showInfoModal) _InfoModal(onClose: _closeInfo),
          ],
        ),
      ),
    );
  }
}

class _FeatureSlide {
  const _FeatureSlide({
    required this.id,
    required this.title,
    required this.desc,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
  });

  final String id;
  final String title;
  final String desc;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
}

class _SlideCard extends StatelessWidget {
  const _SlideCard({required this.slide});

  final _FeatureSlide slide;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Card(
        elevation: 0,
        color: const Color(0xFFFFFFFF),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: slide.iconBg,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(slide.icon, size: 28, color: slide.iconColor),
              ),
              const SizedBox(height: 20),
              Text(
                slide.title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E293B),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                slide.desc,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SopModal extends StatelessWidget {
  const _SopModal({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return ModalBottomSheet(
      title: 'SOP Validasi MBG',
      subtitle: 'Standar Operasional Prosedur untuk validator sekolah',
      onClose: onClose,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStep('1', 'Pindai Master QR kontainer termal saat tiba di gerbang.'),
          _buildStep('2', 'Verifikasi asal SPPG, nomor SLHS, dan jam aman konsumsi (4 jam).'),
          _buildStep('3', 'Catat suhu holding boks minimal 60°C untuk hidangan hangat.'),
          _buildStep(
              '4', 'Lakukan deteksi visual: warna, lendir, benda asing, kematangan.'),
          _buildStep(
              '5', 'Setujui porsi layak, atau tolak & amankan sampel untuk laboratorium.'),
          _buildStep('6', 'Tandatangani BAST digital bersama sopir pengantar.'),
          _buildStep(
              '7', 'Lapor insiden ke Satuan Tugas MBG jika ada benda asing/basi.'),
        ],
      ),
    );
  }

  static Widget _buildStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFEBA338),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              number,
              style: const TextStyle(
                color: Color(0xFF1E293B),
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF1E293B),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoModal extends StatelessWidget {
  const _InfoModal({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return ModalBottomSheet(
      title: 'Tentang KawanGizi',
      subtitle: 'Aplikasi validasi Makan Bergizi Gratis untuk validator sekolah',
      onClose: onClose,
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Versi 1.0.0',
            style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
          ),
          SizedBox(height: 16),
          Text(
            'KawanGizi membantu guru validator melakukan pemeriksaan mutu makanan, '
            'penerbitan BAST, pelaporan insiden, dan komunikasi komunitas.',
            style: TextStyle(fontSize: 14, color: Color(0xFF1E293B), height: 1.5),
          ),
        ],
      ),
    );
  }
}

class ModalBottomSheet extends StatelessWidget {
  const ModalBottomSheet({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onClose,
    required this.child,
  });

  final String title;
  final String subtitle;
  final VoidCallback onClose;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onClose,
      child: Container(
        color: Colors.black.withValues(alpha: 0.4),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: GestureDetector(
            onTap: () {},
            child: Container(
              width: double.infinity,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.8,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(LucideIcons.x, size: 22),
                              onPressed: onClose,
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: Color(0xFFE7E9EC)),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: child,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
