import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import 'package:kawangizi_mobile/core/theme/app_colors.dart';
import 'package:kawangizi_mobile/core/utils/initials.dart';
import 'package:kawangizi_mobile/features/auth/presentation/auth_controller.dart';

class FeatureHeader extends StatelessWidget {
  const FeatureHeader({
    super.key,
    required this.title,
    this.onOpenProfile,
    this.onExit,
    this.onNotificationPress,
  });

  final String title;
  final VoidCallback? onOpenProfile;
  final VoidCallback? onExit;
  final VoidCallback? onNotificationPress;

  void _handleBellPress(BuildContext context) {
    if (onNotificationPress != null) {
      onNotificationPress!();
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(LucideIcons.bell, color: AppColors.primary, size: 20),
            SizedBox(width: 8),
            Text(
              'Pemberitahuan MBG',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.text),
            ),
          ],
        ),
        content: const Text(
          'Armada B-9281-KBA dari SPPG Menteng dijadwalkan tiba pukul 07:10 WIB untuk serah terima porsi hari ini.',
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup', style: TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final userName = auth.user?.fullName ?? 'Ibu Siti Aminah, S.Pd.';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: Row(
        children: [
          if (onExit != null) ...[
            InkWell(
              onTap: onExit,
              borderRadius: BorderRadius.circular(12),
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(LucideIcons.chevronLeft, size: 22, color: AppColors.text),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
                letterSpacing: -0.5,
              ),
            ),
          ),
          // Notification Bell
          InkWell(
            onTap: () => _handleBellPress(context),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFF8FAFC),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(LucideIcons.bell, size: 20, color: AppColors.text),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Profile Avatar Button
          ProfileAvatarButton(
            name: userName,
            onTap: onOpenProfile ?? () => context.go('/profile'),
          ),
        ],
      ),
    );
  }
}

class ProfileAvatarButton extends StatelessWidget {
  const ProfileAvatarButton({
    super.key,
    required this.name,
    required this.onTap,
    this.size = 40,
  });

  final String name;
  final VoidCallback onTap;
  final double size;

  void _showProfileDropdown(BuildContext context) {
    final auth = context.read<AuthController>();
    final user = auth.user;
    final displayName = user?.fullName ?? name;
    final roleTitle = user?.role == 'guest' ? 'Mode Tamu' : 'Guru Validator';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.primary,
                  child: Text(
                    getInitials(displayName),
                    style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.text),
                      ),
                      Text(
                        roleTitle,
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 28),
            ListTile(
              leading: const Icon(LucideIcons.user, color: AppColors.text),
              title: const Text('Profil Akun', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.text)),
              onTap: () {
                Navigator.pop(ctx);
                onTap();
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.logOut, color: Color(0xFFEF4444)),
              title: const Text('Keluar dari Akun', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFFEF4444))),
              onTap: () async {
                Navigator.pop(ctx);
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (dCtx) => AlertDialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    title: const Text('Keluar dari Akun?'),
                    content: const Text('Anda harus masuk kembali untuk menggunakan aplikasi.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(dCtx, false), child: const Text('Batal')),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEF4444),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => Navigator.pop(dCtx, true),
                        child: const Text('Ya, Keluar'),
                      ),
                    ],
                  ),
                );
                if (confirm == true && context.mounted) {
                  await auth.logout();
                  if (context.mounted) context.go('/welcome');
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _showProfileDropdown(context),
      borderRadius: BorderRadius.circular(size / 2),
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(
          getInitials(name),
          style: TextStyle(
            color: AppColors.text,
            fontWeight: FontWeight.w700,
            fontSize: size > 36 ? 14 : 12,
          ),
        ),
      ),
    );
  }
}
