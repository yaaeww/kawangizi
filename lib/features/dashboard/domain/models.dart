enum UserRole { guru }

class UserProfile {
  const UserProfile({
    required this.id,
    required this.name,
    required this.role,
    required this.roleTitle,
    required this.schoolName,
    required this.npsn,
    required this.assignedSPPG,
  });

  final String id;
  final String name;
  final UserRole role;
  final String roleTitle;
  final String schoolName;
  final String npsn;
  final String assignedSPPG;
}

class DayItem {
  const DayItem({
    required this.id,
    required this.dayName,
    required this.dayNumber,
    required this.hasDelivery,
  });

  final String id;
  final String dayName;
  final int dayNumber;
  final bool hasDelivery;
}

class HeroMealStatus {
  const HeroMealStatus({
    required this.id,
    required this.sessionTitle,
    required this.greeting,
    required this.menuName,
    required this.sideDish,
    required this.fruitAndDrink,
    required this.allergens,
    required this.totalPortions,
    required this.masterTotes,
    required this.armadaStatus,
    required this.etaDelivery,
    required this.fleetPlate,
    required this.driverName,
    this.driverPhone,
    required this.haccpRemainingMinutes,
  });

  final String id;
  final String sessionTitle;
  final String greeting;
  final String menuName;
  final String sideDish;
  final String fruitAndDrink;
  final List<String> allergens;
  final int totalPortions;
  final int masterTotes;
  final ArmadaStatus armadaStatus;
  final String etaDelivery;
  final String fleetPlate;
  final String driverName;
  final String? driverPhone;
  final int haccpRemainingMinutes;
}

enum ArmadaStatus { enRoute, arrived, delayed }

enum Tone { neutral, urgent, safe, warning }

class QuickActionItem {
  const QuickActionItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.tagLeft,
    required this.tagRight,
    required this.tone,
    required this.flow,
    this.targetScreen,
  });

  final String id;
  final String title;
  final String subtitle;
  final String tagLeft;
  final String tagRight;
  final Tone tone;
  final List<String> flow;
  final String? targetScreen; // 'scanner', 'handover', 'incident'
}

class NutrientCapsuleItem {
  const NutrientCapsuleItem({
    required this.id,
    required this.name,
    required this.amount,
    required this.percentage,
    required this.status,
  });

  final String id;
  final String name;
  final String amount;
  final int percentage;
  final NutrientStatus status;
}

enum NutrientStatus { optimal, warning, alert }

class DashboardMetricSummary {
  const DashboardMetricSummary({
    required this.totalTarget,
    required this.juniorTarget,
    required this.seniorTarget,
    required this.completedCount,
    required this.rejectedCount,
  });

  final int totalTarget;
  final int juniorTarget;
  final int seniorTarget;
  final int completedCount;
  final int rejectedCount;
}
