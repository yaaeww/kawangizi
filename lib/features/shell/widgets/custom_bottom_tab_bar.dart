import 'package:flutter/material.dart';

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
  final List<TabDef> tabs;
  final bool isGuest;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(
        bottom: bottomPadding > 0 ? bottomPadding + 6 : 14,
        left: 16,
        right: 16,
        top: 22, // Space for the active circle to protrude upward
      ),
      child: Center(
        heightFactor: 1.0,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFE7E9EC)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.07),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 6),
            clipBehavior: Clip.none,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(tabs.length, (index) {
                final tab = tabs[index];
                final active = index == currentIndex;

                return Expanded(
                  child: Semantics(
                    label: tab.label,
                    hint: tab.hint,
                    selected: active,
                    button: true,
                    child: InkWell(
                      onTap: () => onTap(index),
                      splashColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      child: Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.center,
                        children: [
                          if (active)
                            Positioned(
                              top: -20,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 54,
                                    height: 54,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppColors.primary,
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.primary.withValues(alpha: 0.35),
                                          blurRadius: 10,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    alignment: Alignment.center,
                                    child: Icon(
                                      tab.icon,
                                      size: 24,
                                      color: const Color(0xFF1E293B),
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    tab.label,
                                    maxLines: 1,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF7C4A03),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  tab.icon,
                                  size: 22,
                                  color: const Color(0xFF64748B),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  tab.label,
                                  maxLines: 1,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class TabDef {
  const TabDef({
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
