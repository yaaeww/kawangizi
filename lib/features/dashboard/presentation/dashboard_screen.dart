import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import 'package:kawangizi_mobile/core/network/api_client.dart';
import 'package:kawangizi_mobile/core/theme/app_colors.dart';
import 'package:kawangizi_mobile/features/auth/presentation/auth_controller.dart';
import 'package:kawangizi_mobile/shared/widgets/feature_header.dart' show ProfileAvatarButton;
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
  int _haccpMinutes = 164; // Matching screenshot default
  int _totalTarget = 650;
  int _juniorTarget = 300;
  int _seniorTarget = 350;
  int _completedCount = 420;
  int _rejectedCount = 18;

  @override
  void initState() {
    super.initState();
    _startHaccpTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchLiveMetrics());
  }

  Future<void> _fetchLiveMetrics() async {
    try {
      final api = context.read<ApiClient>();
      final res = await api.get('/api/v1/history/summary');
      if (res.data is Map && res.data['data'] != null) {
        final d = res.data['data'] as Map;
        final quota = int.tryParse('${d['quota'] ?? d['totalTarget']}');
        final handed = int.tryParse('${d['handed'] ?? d['completedCount']}');
        final leftover = int.tryParse('${d['leftover'] ?? d['rejectedCount']}');
        if (mounted) {
          setState(() {
            if (quota != null && quota > 0) _totalTarget = quota;
            if (handed != null && handed > 0) _completedCount = handed;
            if (leftover != null) _rejectedCount = leftover;
            _juniorTarget = (_totalTarget * 0.46).round();
            _seniorTarget = _totalTarget - _juniorTarget;
          });
        }
      }
    } catch (_) {
      // Fallback gracefully to default
    }
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
    final authUser = auth.user;
    final userName = authUser?.fullName ?? 'Ibu Siti Aminah, S.Pd.';
    final schoolName = authUser?.schoolName ?? 'SDN Menteng 01 Pagi';
    final haccp = getHaccpView(_haccpMinutes);
    final scanLocked = haccp.state == HaccpState.critical;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // 1. Fixed Top App Bar (DashboardHeader)
            DashboardHeader(
              userName: userName,
              onOpenProfile: () => context.go('/profile'),
            ),

            // 2. Scrollable Body
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 110),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Greeting Section
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Halo, $userName',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: AppColors.text,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Text(
                                schoolName,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 6),
                                child: Text('·', style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.bold)),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF3C7),
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

                    // Weekly Calendar Strip
                    WeeklyCalendarStrip(
                      days: mockWeeklyDays,
                      selectedDayId: _selectedDayId,
                      onSelectDay: (day) => setState(() => _selectedDayId = day.id),
                    ),

                    // HACCP Circular Countdown Gauge
                    HaccpCountdown(minutes: _haccpMinutes),

                    // Sesi Hari Ini (HeroMealCard)
                    HeroMealCard(
                      mealStatus: mockHeroMealGuru,
                      validatedCount: _completedCount,
                      onPressDetail: () => setState(() => _menuDetailVisible = true),
                      onPressSecondary: () => _showAfternoonDialog(),
                    ),

                    // Aksi Validasi (QuickActionSection)
                    QuickActionSection(
                      actions: mockQuickActionsGuru,
                      onSelectAction: _handleSelectAction,
                    ),

                    // Big Number & Nutrient Capsules
                    NutrientCapsuleSection(
                      totalTarget: _totalTarget,
                      juniorTarget: _juniorTarget,
                      seniorTarget: _seniorTarget,
                      completedCount: _completedCount,
                      rejectedCount: _rejectedCount,
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

            // Bottom Sheets
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
  const DashboardHeader({super.key, required this.userName, required this.onOpenProfile});

  final String userName;
  final VoidCallback onOpenProfile;

  void _handleBellPress(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(LucideIcons.bell, color: AppColors.primary, size: 20),
            SizedBox(width: 8),
            Text('Pemberitahuan MBG', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.text)),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Left: Logo Badge + Title
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.asset(
                  'assets/images/kawangizi-logo.webp',
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: 10),
              RichText(
                text: const TextSpan(
                  children: [
                    TextSpan(
                      text: 'Kawan',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.text, letterSpacing: -0.5),
                    ),
                    TextSpan(
                      text: 'Gizi',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFFD97706), letterSpacing: -0.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),
          // Right: Bell + Avatar
          Row(
            children: [
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
              ProfileAvatarButton(name: userName, onTap: onOpenProfile),
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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: days.map((day) {
          final isSelected = day.id == selectedDayId;
          return InkWell(
            onTap: () => onSelectDay(day),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    day.dayName,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? AppColors.text : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected ? AppColors.primary : Colors.transparent,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${day.dayNumber}',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                        color: AppColors.text,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (day.hasDelivery && !isSelected)
                    Container(
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        color: Color(0xFFB45309),
                        shape: BoxShape.circle,
                      ),
                    )
                  else
                    const SizedBox(height: 5),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ===================== HaccpCountdown (Circular Gauge) =====================
class HaccpCountdown extends StatelessWidget {
  const HaccpCountdown({super.key, required this.minutes});

  final int minutes;

  @override
  Widget build(BuildContext context) {
    final haccp = getHaccpView(minutes);
    final ratio = haccp.ratio.clamp(0.0, 100.0) / 100.0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          // Circular SVG-style Ring Gauge
          SizedBox(
            width: 124,
            height: 124,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(124, 124),
                  painter: _CircularGaugePainter(
                    ratio: ratio,
                    color: haccp.color,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$minutes',
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: AppColors.text,
                        letterSpacing: -1,
                      ),
                    ),
                    const Text(
                      'menit',
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Right Column Information
          Expanded(
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
                    const SizedBox(width: 6),
                    Text(
                      haccp.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: haccp.color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Batas aman konsumsi',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  haccp.guidance,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF475569),
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Hitung mundur 4 jam sejak makanan selesai dimasak · data contoh',
                  style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CircularGaugePainter extends CustomPainter {
  _CircularGaugePainter({required this.ratio, required this.color});

  final double ratio;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 11.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Track
    final trackPaint = Paint()
      ..color = const Color(0xFFE7E9EC)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius, trackPaint);

    // Progress Arc
    final arcPaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * ratio;
    // Start at top (-pi/2)
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CircularGaugePainter oldDelegate) {
    return oldDelegate.ratio != ratio || oldDelegate.color != color;
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
    final validatedRatio = mealStatus.totalPortions > 0
        ? (validatedCount / mealStatus.totalPortions).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Sesi Hari Ini',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                  letterSpacing: -0.3,
                ),
              ),
              Row(
                children: [
                  InkWell(
                    onTap: () {},
                    child: const Text(
                      'Nomor sopir belum ada',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ),
                  const SizedBox(width: 12),
                  InkWell(
                    onTap: onPressDetail,
                    child: const Text(
                      'Rincian menu',
                      style: TextStyle(fontSize: 12, color: Color(0xFFB45309), fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Cards Row (Main Card + Sesi Siang Peek)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Main Session Card (Golden Sunset Card)
              Expanded(
                flex: 3,
                child: InkWell(
                  onTap: onPressDetail,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      children: [
                        // Card Content
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Status Pill + ETA
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.3),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.circle, size: 7, color: Color(0xFF14532D)),
                                        SizedBox(width: 5),
                                        Text(
                                          'Tiba di Gerbang',
                                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF14532D)),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    'Tiba ${mealStatus.etaDelivery}',
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Session Title & Driver
                              Text(
                                mealStatus.sessionTitle,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.text,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${mealStatus.fleetPlate} · ${mealStatus.driverName}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF451A03),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 14),

                              // Progress Track
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '$validatedCount dari ${mealStatus.totalPortions} porsi',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.text),
                                  ),
                                  const Text(
                                    'tervalidasi · data contoh',
                                    style: TextStyle(fontSize: 10, color: Color(0xFF78350F)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              LayoutBuilder(
                                builder: (context, constraints) => Container(
                                  height: 7,
                                  width: constraints.maxWidth,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.4),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  alignment: Alignment.centerLeft,
                                  child: Container(
                                    height: 7,
                                    width: constraints.maxWidth * validatedRatio,
                                    decoration: BoxDecoration(
                                      color: AppColors.text,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 36), // Spacing for sunset illustration
                            ],
                          ),
                        ),

                        // Sunset Hills Graphic
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          height: 44,
                          child: CustomPaint(
                            painter: _SunsetHillsPainter(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Sesi Siang Peek Card
              Expanded(
                flex: 1,
                child: InkWell(
                  onTap: onPressSecondary,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    height: 180,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sesi Siang',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.text),
                        ),
                        Spacer(),
                        Text(
                          '12:30',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.text),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Belum ada rincian',
                          style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SunsetHillsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0 || size.width.isInfinite) return;
    // Soft Sun
    final sunPaint = Paint()..color = const Color(0xFFFDE68A);
    canvas.drawCircle(Offset(size.width * 0.45, size.height * 0.6), 18, sunPaint);

    // Front Green Hill
    final hillPaint = Paint()..color = const Color(0xFF3F6212);
    final path = Path()
      ..moveTo(0, size.height)
      ..quadraticBezierTo(size.width * 0.25, size.height * 0.4, size.width * 0.5, size.height * 0.6)
      ..quadraticBezierTo(size.width * 0.75, size.height * 0.8, size.width, size.height * 0.5)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, hillPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ===================== QuickActionSection =====================
class QuickActionSection extends StatelessWidget {
  const QuickActionSection({super.key, required this.actions, required this.onSelectAction});

  final List<QuickActionItem> actions;
  final ValueChanged<QuickActionItem> onSelectAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Aksi Validasi',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.text,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 12),
          Column(
            children: actions.map((item) {
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: InkWell(
                  onTap: () => onSelectAction(item),
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.title,
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.text),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item.subtitle,
                                    maxLines: 2,
                                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.3),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(LucideIcons.chevronRight, size: 20, color: Color(0xFF94A3B8)),
                          ],
                        ),
                        if (item.tagLeft.isNotEmpty || item.tagRight.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(item.tagLeft, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
                              Text(
                                item.tagRight,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: item.tone == Tone.safe
                                      ? const Color(0xFF15803D)
                                      : item.tone == Tone.urgent
                                          ? const Color(0xFFB91C1C)
                                          : const Color(0xFF475569),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          // Giant Hero Stat Block
          Center(
            child: Column(
              children: [
                Text(
                  '$completedCount',
                  style: const TextStyle(
                    fontSize: 54,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text,
                    letterSpacing: -1,
                  ),
                ),
                Text(
                  'porsi tervalidasi dari $totalTarget target hari ini · data contoh',
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(
                  'Target $totalTarget porsi: $juniorTarget SD bawah + $seniorTarget SD atas',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 4),
                Text(
                  '$rejectedCount porsi ditolak atau diisolate',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFFB91C1C)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Estimasi Gizi per Porsi Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Estimasi gizi per porsi',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.text),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Nilai estimasi dibanding target AKG kelompok SD atas',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 20),

                // 5 Vertical Capsules
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: nutrients.map((item) {
                    final percentage = item.percentage.clamp(4, 100);
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Vertical capsule pill
                        Container(
                          width: 44,
                          height: 120,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(22),
                          ),
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            width: 44,
                            height: 120.0 * (percentage / 100.0),
                            decoration: BoxDecoration(
                              color: const Color(0xFFB45309),
                              borderRadius: BorderRadius.circular(22),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          item.name,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.text),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${item.percentage}% · ${item.amount}',
                          style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Action Button (Mulai Validasi Porsi Kelas)
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.text,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: lockReason != null ? null : onStartValidation,
              child: Text(
                lockReason ?? 'Mulai Validasi Porsi Kelas',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ===================== Bottom Sheets =====================
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
    return Container();
  }
}

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
    return Container();
  }
}
