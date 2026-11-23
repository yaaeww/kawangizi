import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:kawangizi_mobile/core/theme/app_colors.dart';

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

class ProfileAvatarButton extends StatelessWidget {
  const ProfileAvatarButton({super.key, required this.name, required this.onTap});

  final String name;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: CircleAvatar(
        radius: 20,
        backgroundColor: AppColors.primarySoft,
        child: Text(
          getInitials(name),
          style: const TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.w800, fontSize: 14),
        ),
      ),
    );
  }
}
