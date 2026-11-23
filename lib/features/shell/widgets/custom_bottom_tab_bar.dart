import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:kawangizi_mobile/core/theme/app_colors.dart';

class CustomBottomTabBar extends StatelessWidget {
  const CustomBottomTabBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.tabs,
    this.isGuest = false,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<_TabDef> tabs;
  final bool isGuest;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: AppColors.border)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 72,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(tabs.length, (index) {
              final tab = tabs[index];
              final active = index == currentIndex;
              return Expanded(
                child: InkWell(
                  onTap: () => onTap(index),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeInOut,
                        width: active ? 56 : 44,
                        height: active ? 56 : 44,
                        decoration: BoxDecoration(
                          color: active ? AppColors.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(22),
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          tab.icon,
                          size: 24,
                          color: active ? AppColors.text : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                          color: active ? const Color(0xFF7C4A03) : AppColors.textSecondary,
                        ),
                        child: Text(tab.label, maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
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
