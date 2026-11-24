import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:kawangizi_mobile/core/theme/app_colors.dart';
import 'package:kawangizi_mobile/shared/widgets/feature_header.dart';
import '../data/mock_class_data.dart';
import '../data/scan_log_store.dart' hide formatClock;
import '../utils/distribution.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<ClassInput> _classes = mockClasses;
  SurplusAllocation _allocation = SurplusAllocation.belum;
  String _range = 'hari_ini';
  String _activeTabMode = 'presensi'; // 'presensi' | 'log_pindaian'

  @override
  void initState() {
    super.initState();
    ScanLogStore().initDefault();
  }

  List<ClassReconciliation> get _rows => _classes.map(reconcileClass).toList();
  DistributionTotals get _totals => sumDistribution(_rows);

  void _handleSetAllPresent(String classId, int quota) {
    setState(() {
      _classes = _classes.map((c) => c.id == classId ? ClassInput(id: c.id, name: c.name, quota: c.quota, hadir: c.quota, sakit: 0) : c).toList();
    });
  }

  void _handleUpdateCount(String classId, String field, int delta, int quota) {
    setState(() {
      _classes = _classes.map((c) {
        if (c.id != classId) return c;
        final current = field == 'hadir' ? c.hadir : c.sakit;
        final next = (current + delta).clamp(0, quota);
        return field == 'hadir'
            ? ClassInput(id: c.id, name: c.name, quota: c.quota, hadir: next, sakit: c.sakit)
            : ClassInput(id: c.id, name: c.name, quota: c.quota, hadir: c.hadir, sakit: next);
      }).toList();
    });
  }

  void _handleShowReportDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Pratinjau Lembar Rekapitulasi MBG'),
        content: Text(
          'Rekapitulasi Presensi & Distribusi Porsi SDN Menteng 01 Pagi:\n\n'
          '• Total Porsi Diserahkan: ${_totals.porsiDiterahkan} porsi\n'
          '• Porsi Sisa: ${_totals.porsiSisa} porsi\n'
          '• Alokasi Sisa: ${_allocation == SurplusAllocation.staf ? "Diserahkan ke staf sekolah" : _allocation == SurplusAllocation.snackSore ? "Disimpan untuk sore" : "Belum dialokasikan"}\n\n'
          'Dokumen siap dicetak untuk Kepala Sekolah & Komite.',
          style: const TextStyle(height: 1.4, fontSize: 13),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tutup')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.text,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Laporan PDF berhasil diunduh ke folder Dokumen Sekolah')),
              );
            },
            child: const Text('Unduh PDF'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Universal Clean Header
            FeatureHeader(
              title: 'Riwayat & Presensi',
              onOpenProfile: () => context.go('/profile'),
            ),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 110),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sub Header (School Badge & Report Button)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Row(
                                children: [
                                  Icon(LucideIcons.shieldCheck, size: 15, color: Color(0xFF10B981)),
                                  SizedBox(width: 6),
                                  Text(
                                    'SDN Menteng 01 Pagi',
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.text),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 5),
                                    child: Text('·', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                                  ),
                                  Text(
                                    'Dapodik Resmi',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF10B981)),
                                  ),
                                ],
                              ),
                              // Laporan Button
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Color(0xFFFBBF24)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                ),
                                onPressed: _handleShowReportDialog,
                                icon: const Icon(LucideIcons.fileText, size: 14, color: AppColors.primary),
                                label: const Text(
                                  'Laporan',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF7C4A03)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          const Row(
                            children: [
                              Icon(LucideIcons.calendar, size: 13, color: AppColors.textSecondary),
                              SizedBox(width: 6),
                              Text(
                                'Kamis, 10 Oktober 2026 · Sesi Makan Siang Bergizi',
                                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // Range Filter Buttons (Hari Ini, 7 hari, Bulan Ini)
                          Row(
                            children: [
                              _buildRangePill('Hari Ini', 'hari_ini'),
                              const SizedBox(width: 8),
                              _buildRangePill('7 hari', 'tujuh_hari'),
                              const SizedBox(width: 8),
                              _buildRangePill('Bulan Ini', 'bulan_ini'),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // 3 Stat Cards Row
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          // Card 1: Porsi Diserahkan
                          Expanded(
                            child: _buildMetricCard(
                              title: 'Nilai Terpenuhi',
                              count: '${_totals.porsiDiterahkan}',
                              subtitle: 'Porsi Diserahkan',
                              caption: 'Dari ${_totals.quota} kuota porsi',
                              icon: LucideIcons.checkCircle2,
                              iconColor: const Color(0xFF10B981),
                              borderColor: const Color(0xFF10B981).withValues(alpha: 0.3),
                              bgColor: const Color(0xFFECFDF5),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Card 2: Porsi Sisa
                          Expanded(
                            child: _buildMetricCard(
                              title: 'Perlu Alokasi',
                              count: '${_totals.porsiSisa}',
                              subtitle: 'Porsi Sisa di Sekolah',
                              caption: 'SOP Regulasi BGN',
                              icon: LucideIcons.alertCircle,
                              iconColor: const Color(0xFFF59E0B),
                              borderColor: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                              bgColor: const Color(0xFFFFFBEB),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Card 3: Siswa Tidak Masuk
                          Expanded(
                            child: _buildMetricCard(
                              title: 'Absensi',
                              count: '${_totals.sakit}',
                              subtitle: 'Siswa Tidak Masuk',
                              caption: 'Tercatat sakit/izin',
                              icon: LucideIcons.users,
                              iconColor: const Color(0xFF8B5CF6),
                              borderColor: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                              bgColor: const Color(0xFFF5F3FF),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Subtabs Pill (Presensi Kelas (6) vs Log Boks (5))
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => setState(() => _activeTabMode = 'presensi'),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: _activeTabMode == 'presensi' ? Colors.white : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: _activeTabMode == 'presensi'
                                      ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))]
                                      : null,
                                ),
                                alignment: Alignment.center,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(LucideIcons.fileText, size: 14, color: _activeTabMode == 'presensi' ? const Color(0xFFB45309) : AppColors.textSecondary),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Presensi Kelas (${_classes.length})',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: _activeTabMode == 'presensi' ? FontWeight.w700 : FontWeight.w500,
                                        color: _activeTabMode == 'presensi' ? AppColors.text : AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: InkWell(
                              onTap: () => setState(() => _activeTabMode = 'log_pindaian'),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: _activeTabMode == 'log_pindaian' ? Colors.white : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: _activeTabMode == 'log_pindaian'
                                      ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))]
                                      : null,
                                ),
                                alignment: Alignment.center,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(LucideIcons.scan, size: 14, color: _activeTabMode == 'log_pindaian' ? const Color(0xFFB45309) : AppColors.textSecondary),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Log Boks (5)',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: _activeTabMode == 'log_pindaian' ? FontWeight.w700 : FontWeight.w500,
                                        color: _activeTabMode == 'log_pindaian' ? AppColors.text : AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (_activeTabMode == 'presensi') ...[
                      // Section: Distribusi per Kelas
                      const Padding(
                        padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Distribusi per Kelas',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.text),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Presensi kehadiran menentukan jumlah porsi yang diserahkan',
                              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),

                      // Class List Cards
                      ..._rows.map((row) => _buildClassCard(row)),

                      // SOP BGN No. 04/2024 Section
                      _buildSopBgnSection(),

                      // Bottom Action CTA
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Column(
                          children: [
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: AppColors.text,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                                onPressed: _handleShowReportDialog,
                                icon: const Icon(LucideIcons.fileText, size: 18, color: AppColors.text),
                                label: const Text(
                                  'Pratinjau Lembar Rekapitulasi MBG',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Dapat dicetak sebagai bukti pertanggungjawaban Kepala Sekolah & Komite.',
                              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      // Log Pindaian View
                      const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(
                          child: Text(
                            '5 boks tervalidasi hari ini.\nSemua suhu holding dan lepas dapur dalam batas aman konsumsi.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRangePill(String label, String key) {
    final selected = _range == key;
    return InkWell(
      onTap: () => setState(() => _range = key),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.text : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? AppColors.text : AppColors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? Colors.white : AppColors.text,
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String count,
    required String subtitle,
    required String caption,
    required IconData icon,
    required Color iconColor,
    required Color borderColor,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: iconColor),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: iconColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            count,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.text),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.text),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            caption,
            style: const TextStyle(fontSize: 9, color: AppColors.textSecondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildClassCard(ClassReconciliation row) {
    final allPresent = row.hadir == row.quota && row.sakit == 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              Text(
                row.name,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.text),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Kuota ${row.quota} Siswa',
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                ),
              ),
              const Spacer(),
              if (allPresent)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.check, size: 11, color: Color(0xFF15803D)),
                      SizedBox(width: 4),
                      Text(
                        'Semua Hadir',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF15803D)),
                      ),
                    ],
                  ),
                )
              else
                InkWell(
                  onTap: () => _handleSetAllPresent(row.id, row.quota),
                  child: const Text(
                    'Set Semua Hadir',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFFB45309)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Stepper & Counts Row
          Row(
            children: [
              // Hadir
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Hadir', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          InkWell(
                            onTap: () => _handleUpdateCount(row.id, 'hadir', -1, row.quota),
                            child: const Padding(
                              padding: EdgeInsets.all(4),
                              child: Icon(LucideIcons.minus, size: 14, color: AppColors.textSecondary),
                            ),
                          ),
                          Text(
                            '${row.hadir}',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.text),
                          ),
                          InkWell(
                            onTap: () => _handleUpdateCount(row.id, 'hadir', 1, row.quota),
                            child: const Padding(
                              padding: EdgeInsets.all(4),
                              child: Icon(LucideIcons.plus, size: 14, color: AppColors.textSecondary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Sakit
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Sakit', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          InkWell(
                            onTap: () => _handleUpdateCount(row.id, 'sakit', -1, row.quota),
                            child: const Padding(
                              padding: EdgeInsets.all(4),
                              child: Icon(LucideIcons.minus, size: 14, color: AppColors.textSecondary),
                            ),
                          ),
                          Text(
                            '${row.sakit}',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.text),
                          ),
                          InkWell(
                            onTap: () => _handleUpdateCount(row.id, 'sakit', 1, row.quota),
                            child: const Padding(
                              padding: EdgeInsets.all(4),
                              child: Icon(LucideIcons.plus, size: 14, color: AppColors.textSecondary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Diserahkan
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text('Diserahkan', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                  const SizedBox(height: 4),
                  Text(
                    '${row.porsiDiterahkan}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.text),
                  ),
                ],
              ),
              const SizedBox(width: 12),

              // Sisa
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text('Sisa', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                  const SizedBox(height: 4),
                  Text(
                    '${row.porsiSisa}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: row.porsiSisa > 0 ? const Color(0xFFB45309) : AppColors.text,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Subtext Indicator
          if (row.porsiSisa > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.alertCircle, size: 12, color: Color(0xFFB45309)),
                  const SizedBox(width: 6),
                  Text(
                    '${row.porsiSisa} porsi sisa: menunggu alokasi',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF7C4A03)),
                  ),
                ],
              ),
            )
          else
            const Row(
              children: [
                Icon(LucideIcons.check, size: 12, color: Color(0xFF15803D)),
                SizedBox(width: 6),
                Text(
                  'Porsi terbagi semua',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF15803D)),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildSopBgnSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(LucideIcons.shieldCheck, size: 18, color: AppColors.primary),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Standar Operasional Prosedur BGN No. 04/2024',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.text),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Porsi makanan yang tidak tersalurkan akibat siswa sakit/izin harus dialokasikan secara terukur agar tidak ada makanan yang terbuang ("zero food waste") dan terhindar dari penyalahgunaan.',
            style: TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 14),

          // Radio Option 1
          _buildRadioCard(
            title: 'Diserahkan ke staf sekolah',
            subtitle: 'Penjaga atau petugas kebersihan sekolah menerima porsi sisa',
            value: SurplusAllocation.staf,
          ),
          const SizedBox(height: 8),

          // Radio Option 2
          _buildRadioCard(
            title: 'Disimpan untuk makanan tambahan sore',
            subtitle: 'Disimpan di lemari pendingin sekolah sesuai SOP',
            value: SurplusAllocation.snackSore,
          ),
          const SizedBox(height: 8),

          // Radio Option 3
          _buildRadioCard(
            title: 'Belum dialokasikan',
            subtitle: 'Porsi sisa menunggu keputusan guru',
            value: SurplusAllocation.belum,
          ),
        ],
      ),
    );
  }

  Widget _buildRadioCard({
    required String title,
    required String subtitle,
    required SurplusAllocation value,
  }) {
    final isSelected = _allocation == value;

    return InkWell(
      onTap: () => setState(() => _allocation = value),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFEF3C7).withValues(alpha: 0.4) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 18,
              height: 18,
              margin: const EdgeInsets.only(top: 2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.primary : const Color(0xFF94A3B8),
                  width: 2,
                ),
              ),
              alignment: Alignment.center,
              child: isSelected
                  ? Container(
                      width: 9,
                      height: 9,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? const Color(0xFF7C4A03) : AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
