import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import 'package:kawangizi_mobile/core/theme/app_colors.dart';
import 'package:kawangizi_mobile/core/theme/app_theme.dart';
import 'package:kawangizi_mobile/core/utils/initials.dart';
import 'package:kawangizi_mobile/core/utils/relative_time.dart';
import 'package:kawangizi_mobile/features/auth/presentation/auth_controller.dart';
import 'package:kawangizi_mobile/features/shell/presentation/app_shell.dart';
import 'package:kawangizi_mobile/features/handover/presentation/handover_screen.dart';
import 'package:kawangizi_mobile/features/incident/presentation/incident_screen.dart';
import 'package:kawangizi_mobile/features/profile/presentation/profile_screen.dart';
import '../data/mock_validator_data.dart';
import '../domain/models.dart';
import '../utils/haccp.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _selectedDayId = 'd-4';
  QuickActionItem? _activeAction;
  bool _menuDetailVisible = false;
  int _haccpMinutes = mockHeroMealGuru.haccpRemainingMinutes;

  @override
  void initState() {
    super.initState();
    _startHaccpTimer();
  }

  void _startHaccpTimer() {
    Future.delayed(const Duration(seconds: 15), () {
      if (mounted) {
        setState(() {
          if (_haccpMinutes > 0) _haccpMinutes--;
        });
        _startHaccpTimer();
      }
    });
  }

  void _closeSheets() {
    setState(() {
      _activeAction = null;
      _menuDetailVisible = false;
    });
  }

  void _handleSelectAction(QuickActionItem action) {
    if (action.targetScreen == 'scanner') {
      _handleStartValidation();
      return;
    }
    if (action.targetScreen == 'handover') {
      context.go('/handover');
      return;
    }
    if (action.targetScreen == 'incident') {
      context.go('/incident');
      return;
    }
    setState(() => _activeAction = action);
  }

  void _handleStartValidation() {
    final haccp = getHaccpView(_haccpMinutes);
    if (haccp.state == HaccpState.critical) return;
    context.go('/scanner');
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final user = mockGuruUser;
    final haccp = getHaccpView(_haccpMinutes);
    final scanLocked = haccp.state == HaccpState.critical;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            DashboardHeader(user: user, onOpenProfile: () => context.go('/profile')),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 110),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Greeting
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Halo, ${user.name}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: AppColors.text,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Text(
                                user.schoolName,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 6),
                                child: Text('•', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFDEBC8),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'Guru Validator',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF7C4A03),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Weekly Calendar
                    WeeklyCalendarStrip(
                      days: mockWeeklyDays,
                      selectedDayId: _selectedDayId,
                      onSelectDay: (day) => setState(() => _selectedDayId = day.id),
                    ),
                    // HACCP Countdown
                    HaccpCountdown(minutes: _haccpMinutes),
                    // Hero Meal Card
                    HeroMealCard(
                      mealStatus: mockHeroMealGuru,
                      validatedCount: mockDashboardMetrics.completedCount,
                      onPressDetail: () => setState(() => _menuDetailVisible = true),
                      onPressSecondary: () => _showAfternoonDialog(),
                    ),
                    // Quick Actions
                    QuickActionSection(
                      actions: mockQuickActionsGuru,
                      onSelectAction: _handleSelectAction,
                    ),
                    // Nutrient Capsules
                    NutrientCapsuleSection(
                      totalTarget: mockDashboardMetrics.totalTarget,
                      juniorTarget: mockDashboardMetrics.juniorTarget,
                      seniorTarget: mockDashboardMetrics.seniorTarget,
                      completedCount: mockDashboardMetrics.completedCount,
                      rejectedCount: mockDashboardMetrics.rejectedCount,
                      nutrients: mockNutrientCapsulesGuru,
                      onStartValidation: _handleStartValidation,
                      lockReason: scanLocked
                          ? 'Jam aman konsumsi habis. Scan boks dikunci sampai batch ditarik.'
                          : null,
                    ),
                  ],
                ),
              ),
            ),
            // Bottom sheets
            if (_menuDetailVisible)
              MenuDetailSheet(
                visible: true,
                onClose: _closeSheets,
                meal: mockHeroMealGuru,
                haccp: haccp,
              ),
            if (_activeAction != null)
              ActionDetailSheet(
                visible: true,
                onClose: _closeSheets,
                action: _activeAction!,
              ),
          ],
        ),
      ),
    );
  }

  void _showAfternoonDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sesi Siang'),
        content: const Text(
          'Jadwal sesi makan siang 12:30 WIB. Rincian menu sesi siang belum tersedia di prototipe ini.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Mengerti')),
        ],
      ),
    );
  }
}

// ===================== DashboardHeader =====================
class DashboardHeader extends StatelessWidget {
  const DashboardHeader({super.key, required this.user, required this.onOpenProfile});

  final UserProfile user;
  final VoidCallback onOpenProfile;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'KawanGizi',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  'Validator MBG',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(LucideIcons.bell, size: 22, color: AppColors.text),
                onPressed: () {},
                splashRadius: 24,
              ),
              const SizedBox(width: 4),
              ProfileAvatarButton(
                name: user.name,
                onTap: onOpenProfile,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ===================== WeeklyCalendarStrip =====================
class WeeklyCalendarStrip extends StatelessWidget {
  const WeeklyCalendarStrip({
    super.key,
    required this.days,
    required this.selectedDayId,
    required this.onSelectDay,
  });

  final List<DayItem> days;
  final String selectedDayId;
  final ValueChanged<DayItem> onSelectDay;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 84,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final day = days[i];
          final selected = day.id == selectedDayId;
          return GestureDetector(
            onTap: () => onSelectDay(day),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 56,
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: selected ? AppColors.primary : AppColors.border,
                  width: selected ? 0 : 1,
                ),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    day.dayName,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: selected ? Colors.white : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${day.dayNumber}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: selected ? Colors.white : AppColors.text,
                    ),
                  ),
                  if (day.hasDelivery) ...[
                    const SizedBox(height: 4),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ===================== HaccpCountdown =====================
class HaccpCountdown extends StatelessWidget {
  const HaccpCountdown({super.key, required this.minutes});

  final int minutes;

  @override
  Widget build(BuildContext context) {
    final haccp = getHaccpView(minutes);
    final progress = haccp.ratio / 100;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: haccp.color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(
                haccp.label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: haccp.color,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$minutes menit tersisa',
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Stack(
            children: [
              Container(
                height: 6,
                decoration: BoxDecoration(
                  color: AppColors.borderSoft,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              FractionallySizedBox(
                widthFactor: progress.clamp(0.0, 1.0),
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: haccp.color,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            haccp.guidance,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

// ===================== HeroMealCard =====================
class HeroMealCard extends StatelessWidget {
  const HeroMealCard({
    super.key,
    required this.mealStatus,
    required this.validatedCount,
    required this.onPressDetail,
    required this.onPressSecondary,
  });

  final HeroMealStatus mealStatus;
  final int validatedCount;
  final VoidCallback onPressDetail;
  final VoidCallback onPressSecondary;

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(mealStatus.armadaStatus);
    final ratio = mealStatus.totalPortions > 0
        ? validatedCount / mealStatus.totalPortions
        : 0.0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          InkWell(
            onTap: onPressDetail,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status row
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _statusLabel(mealStatus.armadaStatus),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: statusColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Tiba ${mealStatus.etaDelivery}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mealStatus.sessionTitle,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.text,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${mealStatus.fleetPlate} • ${mealStatus.driverName}',
                          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  // Progress
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '$validatedCount dari ${mealStatus.totalPortions} porsi',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.text,
                              ),
                            ),
                            Text(
                              'tervalidasi • data contoh',
                              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: ratio.clamp(0.0, 1.0),
                            minHeight: 6,
                            backgroundColor: AppColors.borderSoft,
                            valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Illustration placeholder
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: AspectRatio(
                      aspectRatio: 2.5,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFFDEBC8),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: Icon(
                            LucideIcons.sunrise,
                            size: 48,
                            color: AppColors.primary.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Secondary card
          InkWell(
            onTap: onPressSecondary,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  const Text(
                    'Sesi Siang',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '12:30',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Belum ada rincian',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }
  }

  Color _statusColor(ArmadaStatus status) {
    switch (status) {
      case ArmadaStatus.enRoute:
        return const Color(0xFF7C4A03);
      case ArmadaStatus.arrived:
        return const Color(0xFF14532D);
      case ArmadaStatus.delayed:
        return const Color(0xFF7F1D1D);
    }
  }

  String _statusLabel(ArmadaStatus status) {
    switch (status) {
      case ArmadaStatus.enRoute:
        return 'Menuju Sekolah';
      case ArmadaStatus.arrived:
        return 'Tiba di Gerbang';
      case ArmadaStatus.delayed:
        return 'Tertunda';
    }
  }
}

// ===================== QuickActionSection =====================
class QuickActionSection extends StatelessWidget {
  const QuickActionSection({
    super.key,
    required this.actions,
    required this.onSelectAction,
  });

  final List<QuickActionItem> actions;
  final ValueChanged<QuickActionItem> onSelectAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Aksi Cepat',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 12),
          ...actions.map(
            (action) => _QuickActionCard(action: action, onTap: () => onSelectAction(action)),
          ),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({required this.action, required this.onTap});

  final QuickActionItem action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final toneColor = _toneColor(action.tone);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: toneColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_toneIcon(action.tone), color: toneColor, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    action.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    action.subtitle,
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                _Tag(label: action.tagLeft, color: AppColors.primary),
                const SizedBox(width: 6),
                _Tag(label: action.tagRight, color: AppColors.textSecondary),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _toneColor(Tone tone) {
    switch (tone) {
      case Tone.urgent:
        return const Color(0xFFEF4444);
      case Tone.safe:
        return const Color(0xFF15803D);
      case Tone.warning:
        return const Color(0xFFF59E0B);
      case Tone.neutral:
        return const Color(0xFF64748B);
    }
  }

  IconData _toneIcon(Tone tone) {
    switch (tone) {
      case Tone.urgent:
        return LucideIcons.camera;
      case Tone.safe:
        return LucideIcons.fileText;
      case Tone.warning:
        return LucideIcons.alertTriangle;
      case Tone.neutral:
        return LucideIcons.helpCircle;
    }
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

// ===================== NutrientCapsuleSection =====================
class NutrientCapsuleSection extends StatelessWidget {
  const NutrientCapsuleSection({
    super.key,
    required this.totalTarget,
    required this.juniorTarget,
    required this.seniorTarget,
    required this.completedCount,
    required this.rejectedCount,
    required this.nutrients,
    required this.onStartValidation,
    this.lockReason,
  });

  final int totalTarget;
  final int juniorTarget;
  final int seniorTarget;
  final int completedCount;
  final int rejectedCount;
  final List<NutrientCapsuleItem> nutrients;
  final VoidCallback onStartValidation;
  final String? lockReason;

  @override
  Widget build(BuildContext context) {
    final percent = totalTarget > 0 ? completedCount / totalTarget : 0.0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Target summary
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Target Kuota',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                      ),
                    ),
                    Text(
                      '${(percent * 100).round()}% terpenuhi',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: percent.clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor: AppColors.borderSoft,
                    valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _TargetItem(label: 'SD Bawah', value: '$juniorTarget porsi', color: const Color(0xFF60A5FA)),
                    _TargetItem(label: 'SD Atas', value: '$seniorTarget porsi', color: const Color(0xFF34D399)),
                    _TargetItem(label: 'Ditolak', value: '$rejectedCount porsi', color: const Color(0xFFF87171)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Nutrient capsules
          const Text(
            'Kecukupan Gizi (AKG SD Atas)',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: nutrients
                .map(
                  (n) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: _NutrientCapsule(nutrient: n),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 16),
          // Start validation button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton(
              onPressed: lockReason != null ? null : onStartValidation,
              style: FilledButton.styleFrom(
                backgroundColor: lockReason != null ? AppColors.border : AppColors.primary,
                foregroundColor: lockReason != null ? AppColors.textSecondary : AppColors.text,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: lockReason != null
                  ? Text(
                      lockReason!,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
                    )
                  : const Text(
                      'Mulai Validasi',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                    ),
            ),
          ),
        ],
      );
    }
  }
}

class _TargetItem extends StatelessWidget {
  const _TargetItem({required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _NutrientCapsule extends StatelessWidget {
  const _NutrientCapsule({required this.nutrient});

  final NutrientCapsuleItem nutrient;

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(nutrient.status);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Text(
            nutrient.name,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 8),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 56,
                height: 56,
                child: CircularProgressIndicator(
                  value: (nutrient.percentage / 100).clamp(0.0, 1.0),
                  strokeWidth: 6,
                  backgroundColor: AppColors.borderSoft,
                  valueColor: AlwaysStoppedAnimation(statusColor),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${nutrient.percentage}%',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: statusColor,
                    ),
                  ),
                  Text(
                    nutrient.amount,
                    style: const TextStyle(fontSize: 9, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              _statusLabel(nutrient.status),
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: statusColor,
              ),
            ),
          ),
        ],
      );
    }
  }

  Color _statusColor(NutrientStatus status) {
    switch (status) {
      case NutrientStatus.optimal:
        return const Color(0xFF15803D);
      case NutrientStatus.warning:
        return const Color(0xFFF59E0B);
      case NutrientStatus.alert:
        return const Color(0xFFEF4444);
    }
  }

  String _statusLabel(NutrientStatus status) {
    switch (status) {
      case NutrientStatus.optimal:
        return 'Optimal';
      case NutrientStatus.warning:
        return 'Peringatan';
      case NutrientStatus.alert:
        return 'Darurat';
    }
  }
}

// ===================== MenuDetailSheet =====================
class MenuDetailSheet extends StatelessWidget {
  const MenuDetailSheet({
    super.key,
    required this.visible,
    required this.onClose,
    required this.meal,
    required this.haccp,
  });

  final bool visible;
  final VoidCallback onClose;
  final HeroMealStatus meal;
  final HaccpView haccp;

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();

    return _BottomSheetWrapper(
      onClose: onClose,
      title: 'Rincian Menu',
      subtitle: meal.sessionTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DetailRow(label: 'Menu Utama', value: meal.menuName),
          _DetailRow(label: 'Lauk & Sayur', value: meal.sideDish),
          _DetailRow(label: 'Buah & Minuman', value: meal.fruitAndDrink),
          _DetailRow(label: 'Total Porsi', value: '${meal.totalPortions}'),
          _DetailRow(label: 'Master Tote', value: '${meal.masterTotes} x 50 porsi'),
          _DetailRow(label: 'Armada', value: '${meal.fleetPlate} • ${meal.driverName}'),
          _DetailRow(label: 'Jam Aman (HACCP)', value: '${meal.haccpRemainingMinutes} menit (${haccp.label})'),
          if (meal.allergens.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text('Alergen:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: meal.allergens
                  .map(
                    (a) => Chip(
                      label: Text(a, style: const TextStyle(fontSize: 11)),
                      backgroundColor: const Color(0xFFFEF3C7),
                      side: BorderSide.none,
                      labelStyle: const TextStyle(fontSize: 11, color: Color(0xFFB45309)),
                      padding: EdgeInsets.zero,
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

// ===================== ActionDetailSheet =====================
class ActionDetailSheet extends StatelessWidget {
  const ActionDetailSheet({
    super.key,
    required this.visible,
    required this.onClose,
    required this.action,
  });

  final bool visible;
  final VoidCallback onClose;
  final QuickActionItem action;

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();

    return _BottomSheetWrapper(
      onClose: onClose,
      title: action.title,
      subtitle: action.subtitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Alur Kerja:',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          ),
          const SizedBox(height: 8),
          ...action.flow.asMap().entries.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEBA338),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${e.key + 1}',
                      style: const TextStyle(
                        color: Color(0xFF1E293B),
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      e.value,
                      style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B), height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ===================== Shared Sheet Wrapper =====================
class _BottomSheetWrapper extends StatelessWidget {
  const _BottomSheetWrapper({
    required this.onClose,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final VoidCallback onClose;
  final String title;
  final String subtitle;
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
                maxHeight: MediaQuery.of(context).size.height * 0.85,
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
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.text,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                subtitle,
                                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(LucideIcons.x, size: 22),
                          onPressed: onClose,
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: AppColors.border),
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

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, color: AppColors.text, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
