import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:kawangizi_mobile/core/theme/app_colors.dart';
import 'package:kawangizi_mobile/features/auth/presentation/auth_controller.dart';
import '../widgets/custom_bottom_tab_bar.dart';

class AppShell extends StatelessWidget {
  const AppShell({
    super.key,
    required this.navigationShell,
    required this.auth,
  });

  final StatefulNavigationShell navigationShell;
  final AuthController auth;

  static const _validatorTabs = [
    TabDef(key: 'home', label: 'Beranda', icon: LucideIcons.home, hint: 'Beranda dan ringkasan kuota Program Gizi Sekolah'),
    TabDef(key: 'scanner', label: 'Skrining', icon: LucideIcons.camera, hint: 'Pindai boks & evaluasi gizi AI'),
    TabDef(key: 'history', label: 'Riwayat', icon: LucideIcons.fileText, hint: 'Riwayat BAST dan presensi kehadiran'),
    TabDef(key: 'community', label: 'Komunitas', icon: LucideIcons.users, hint: 'Forum komunikasi sesama guru validator'),
  ];

  static const _guestTabs = [
    TabDef(key: 'scanner', label: 'Skrining', icon: LucideIcons.camera, hint: 'Pindai boks & evaluasi gizi AI'),
    TabDef(key: 'community', label: 'Komunitas', icon: LucideIcons.users, hint: 'Forum komunikasi sesama guru validator'),
  ];

  @override
  Widget build(BuildContext context) {
    final isGuest = auth.isGuest;
    final tabs = isGuest ? _guestTabs : _validatorTabs;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Navigation Shell Screen Body fills space
          Positioned.fill(
            child: navigationShell,
          ),
          // 2. Floating Tab Bar positioned strictly at the bottom
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: CustomBottomTabBar(
              currentIndex: navigationShell.currentIndex,
              onTap: (index) => _onTabTapped(index, tabs),
              tabs: tabs,
              isGuest: isGuest,
            ),
          ),
        ],
      ),
    );
  }

  void _onTabTapped(int index, List<TabDef> tabs) {
    final target = tabs[index].key;
    final isGuest = auth.isGuest;

    if (isGuest) {
      if (target == 'home') {
        navigationShell.goBranch(1);
        return;
      }
      if (target == 'history') {
        navigationShell.goBranch(1);
        return;
      }
    }

    navigationShell.goBranch(index);
  }
}
