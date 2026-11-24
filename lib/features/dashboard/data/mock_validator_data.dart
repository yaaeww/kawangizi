import '../domain/models.dart';

final UserProfile mockGuruUser = UserProfile(
  id: 'usr-guru-001',
  name: 'Ibu Siti Aminah',
  role: UserRole.guru,
  roleTitle: 'Koordinator Validasi & Gizi',
  schoolName: 'SDN Menteng 01 Pagi',
  npsn: '20101234',
  assignedSPPG: 'SPPG Menteng Jaya (Dapur #04)',
);

final List<DayItem> mockWeeklyDays = [
  DayItem(id: 'd-1', dayName: 'Sen', dayNumber: 7, hasDelivery: true),
  DayItem(id: 'd-2', dayName: 'Sel', dayNumber: 8, hasDelivery: true),
  DayItem(id: 'd-3', dayName: 'Rab', dayNumber: 9, hasDelivery: true),
  DayItem(id: 'd-4', dayName: 'Kam', dayNumber: 10, hasDelivery: true),
  DayItem(id: 'd-5', dayName: 'Jum', dayNumber: 11, hasDelivery: true),
  DayItem(id: 'd-6', dayName: 'Sab', dayNumber: 12, hasDelivery: false),
  DayItem(id: 'd-7', dayName: 'Min', dayNumber: 13, hasDelivery: false),
];

final HeroMealStatus mockHeroMealGuru = HeroMealStatus(
  id: 'meal-today-001',
  sessionTitle: 'Sesi Makan Pagi Bergizi',
  greeting: 'Menyambut hari dengan gizi terbaik.',
  menuName: 'Paket A: Nasi Ayam Panggang Madu',
  sideDish: 'Tahu Organik & Capcay Brokoli Wortel',
  fruitAndDrink: 'Pisang Cavendish & Susu UHT 125ml',
  allergens: ['Susu sapi (laktosa)', 'Kedelai', 'Telur'],
  totalPortions: 650,
  masterTotes: 13,
  armadaStatus: ArmadaStatus.arrived,
  etaDelivery: '07:10 WIB',
  fleetPlate: 'Armada B-9281-KBA',
  driverName: 'Bpk. Mulyono',
  driverPhone: null,
  haccpRemainingMinutes: 165,
);

final List<QuickActionItem> mockQuickActionsGuru = [
  QuickActionItem(
    id: 'qa-1',
    title: 'Scan Boks AI',
    subtitle: 'Pindai QR boks dan deteksi mutu visual',
    tagLeft: 'Gerbang sekolah',
    tagRight: '13 master tote',
    tone: Tone.urgent,
    targetScreen: 'scanner',
    flow: [
      'Pindai Master QR kontainer termal, 1 scan untuk 50 porsi.',
      'Verifikasi asal SPPG, nomor SLHS, dan jam aman konsumsi.',
      'Deteksi visual YOLOv8 membuka sampel: warna, lendir, benda asing.',
      'Setujui porsi, atau tolak dan amankan sampel.',
    ],
  ),
  QuickActionItem(
    id: 'qa-2',
    title: 'Serah Terima BAST',
    subtitle: 'Suhu holding, rekonsiliasi porsi, tanda tangan digital',
    tagLeft: 'Sesudah tiba',
    tagRight: 'Tanda tangan digital',
    tone: Tone.safe,
    targetScreen: 'handover',
    flow: [
      'Pindai Master QR kontainer yang diturunkan dari armada.',
      'Catat suhu holding boks, minimal 60°C untuk hidangan hangat.',
      'Rekonsiliasi kuota 650 porsi dengan porsi yang benar-benar diterima.',
      'Tandatangani BAST digital bersama sopir pengantar.',
    ],
  ),
  QuickActionItem(
    id: 'qa-3',
    title: 'Lapor Insiden',
    subtitle: 'Eskalasi makanan basi atau benda asing',
    tagLeft: 'Darurat',
    tagRight: 'Eskalasi Satgas',
    tone: Tone.warning,
    targetScreen: 'incident',
    flow: [
      'Pisahkan dan amankan boks yang bermasalah.',
      'Unggah foto bukti pada modul insiden.',
      'Kirim eskalasi ke Satuan Pengawas untuk penghentian batch.',
    ],
  ),
];

final List<NutrientCapsuleItem> mockNutrientCapsulesGuru = [
  NutrientCapsuleItem(
    id: 'nut-energi',
    name: 'Energi',
    amount: '545 / 550 kkal',
    percentage: 99,
    status: NutrientStatus.optimal,
  ),
  NutrientCapsuleItem(
    id: 'nut-protein',
    name: 'Protein',
    amount: '34 / 30 g',
    percentage: 113,
    status: NutrientStatus.optimal,
  ),
  NutrientCapsuleItem(
    id: 'nut-karbohidrat',
    name: 'Karbohidrat',
    amount: '68 / 70 g',
    percentage: 97,
    status: NutrientStatus.optimal,
  ),
  NutrientCapsuleItem(
    id: 'nut-lemak',
    name: 'Lemak',
    amount: '14 / 15 g',
    percentage: 93,
    status: NutrientStatus.optimal,
  ),
  NutrientCapsuleItem(
    id: 'nut-serat',
    name: 'Serat',
    amount: '7.1 / 6 g',
    percentage: 118,
    status: NutrientStatus.optimal,
  ),
];

final DashboardMetricSummary mockDashboardMetrics = DashboardMetricSummary(
  totalTarget: 650,
  juniorTarget: 300,
  seniorTarget: 350,
  completedCount: 420,
  rejectedCount: 18,
);
