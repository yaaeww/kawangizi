import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:kawangizi_mobile/core/theme/app_colors.dart';
import 'custom_bottom_tab_bar.dart';

class AppShell extends StatelessWidget {
  const AppShell({
    super.key,
    required this.navigationShell,
    required this.auth,
  });

  final StatefulNavigationShell navigationShell;
  final AuthController auth;

  static const _validatorTabs = [
    _TabDef(key: 'home', label: 'Beranda', icon: LucideIcons.home, hint: 'Beranda dan ringkasan kuota MBG'),
    _TabDef(key: 'scanner', label: 'Skrining', icon: LucideIcons.camera, hint: 'Pindai boks & evaluasi gizi AI'),
    _TabDef(key: 'history', label: 'Riwayat', icon: LucideIcons.fileText, hint: 'Riwayat BAST dan presensi kehadiran'),
    _TabDef(key: 'community', label: 'Komunitas', icon: LucideIcons.users, hint: 'Forum komunikasi sesama guru validator'),
  ];

  static const _guestTabs = [
    _TabDef(key: 'scanner', label: 'Skrining', icon: LucideIcons.camera, hint: 'Pindai boks & evaluasi gizi AI'),
    _TabDef(key: 'community', label: 'Komunitas', icon: LucideIcons.users, hint: 'Forum komunikasi sesama guru validator'),
  ];

  @override
  Widget build(BuildContext context) {
    final isGuest = auth.isGuest;
    final tabs = isGuest ? _guestTabs : _validatorTabs;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: CustomBottomTabBar(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) => _onTabTapped(index, tabs),
        tabs: tabs,
        isGuest: isGuest,
      ),
    );
  }

  void _onTabTapped(int index, List<_TabDef> tabs) {
    final target = tabs[index].key;
    final isGuest = auth.isGuest;

    if (isGuest) {
      if (target == 'home') {
        // Guest cannot access home, redirect to scanner
        navigationShell.goBranch(1); // scanner branch index 1
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

class _TabDef {
  const _TabDef({
    required this.key,
    required this.label,
    required this.icon,
    required this.hint,
  });

  final String key;
  final String label;
  final IconData icon;
  final String hint;
}
