import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import 'package:kawangizi_mobile/core/theme/app_colors.dart';
import 'package:kawangizi_mobile/core/utils/initials.dart';
import 'package:kawangizi_mobile/features/auth/domain/backend_user.dart';
import 'package:kawangizi_mobile/features/auth/presentation/auth_controller.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _showLogoutModal = false;
  bool _isLoggingOut = false;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final user = auth.user;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            FeatureHeader(
              title: 'Profil Pengguna',
              onOpenProfile: null,
              onExit: () => context.go('/'),
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    // Profile card
                    Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.border)),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 48,
                            backgroundColor: AppColors.primarySoft,
                            child: Text(getInitials(user?.fullName ?? 'User'), style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: AppColors.primaryDark)),
                          ),
                          const SizedBox(height: 16),
                          Text(user?.fullName ?? 'User', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.text)),
                          const SizedBox(height: 4),
                          Text(
                            user?.role == 'guest' ? 'Mode Tamu (Pratinjau)' : 'Validator Lapangan (Guru & Staf)',
                            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(20)),
                            child: const Text('Mode Guru / Validator', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primaryDark)),
                          ),
                        ],
                      ),
                    ),
                    // Info section
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Informasi Penugasan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.text)),
                          const SizedBox(height: 16),
                          _InfoRow(icon: LucideIcons.mail, label: 'Email Akun', value: user?.email ?? '-'),
                          _InfoRow(icon: LucideIcons.school, label: 'Sekolah Induk', value: user?.schoolName ?? 'SDN Menteng 01 Pagi'),
                          _InfoRow(icon: LucideIcons.shield, label: 'NPSN', value: user?.npsn ?? '20101234'),
                          _InfoRow(icon: LucideIcons.userCheck, label: 'Dapur SPPG Mitra', value: user?.sppgId ?? 'SPPG Menteng Jaya (Dapur #04)'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Logout button
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _isLoggingOut ? null : () => setState(() => _showLogoutModal = true),
                          icon: const Icon(LucideIcons.logOut, size: 20, color: AppColors.red),
                          label: const Text('Keluar dari Aplikasi', style: TextStyle(color: AppColors.red, fontSize: 15, fontWeight: FontWeight.w700)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.red,
                            side: const BorderSide(color: AppColors.red),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            if (_showLogoutModal) _LogoutModal(onConfirm: _confirmLogout, onCancel: () => setState(() => _showLogoutModal = false), isLoggingOut: _isLoggingOut),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmLogout() async {
    setState(() => _isLoggingOut = true);
    try {
      await context.read<AuthController>().logout();
      if (mounted) context.go('/welcome');
    } finally {
      if (mounted) setState(() => _isLoggingOut = false);
    }
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
                Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text)),
              ],
            ),
          ),
        ],
      );
    }
  }
}

class _LogoutModal extends StatelessWidget {
  const _LogoutModal({required this.onConfirm, required this.onCancel, required this.isLoggingOut});
  final VoidCallback onConfirm;
  final VoidCallback onCancel;
  final bool isLoggingOut;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoggingOut ? null : onCancel,
      child: Container(
        color: Colors.black.withValues(alpha: 0.4),
        child: Align(
          alignment: Alignment.center,
          child: GestureDetector(
            onTap: () {},
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(color: AppColors.redSoft, borderRadius: BorderRadius.circular(16)),
                    child: const Icon(LucideIcons.logOut, size: 26, color: AppColors.red),
                  ),
                  const SizedBox(height: 16),
                  const Text('Keluar dari Aplikasi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.text)),
                  const SizedBox(height: 8),
                  const Text('Apakah Anda yakin ingin mengakhiri sesi akun ini? Anda harus masuk kembali untuk menggunakan aplikasi.', style: TextStyle(fontSize: 13, color: AppColors.textSecondary), textAlign: TextAlign.center),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: isLoggingOut ? null : onCancel,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textSecondary,
                            side: const BorderSide(color: AppColors.border),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Batal', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: isLoggingOut ? null : onConfirm,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: isLoggingOut
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Text('Ya, Keluar', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                        ),
                      ),
                    ],
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
