import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import 'package:kawangizi_mobile/core/theme/app_colors.dart';
import 'package:kawangizi_mobile/core/utils/relative_time.dart';
import 'package:kawangizi_mobile/features/auth/presentation/auth_controller.dart';
import '../data/mock_class_data.dart';
import '../data/scan_log_store.dart';
import '../utils/distribution.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final ScanLogStore _scanLogStore = ScanLogStore();
  List<ClassInput> _classes = mockClasses;
  SurplusAllocation _allocation = SurplusAllocation.belum;
  HistoryRange _range = HistoryRange.hariIni;
  String _query = '';
  bool _exportPreview = false;
  String _activeTabMode = 'presensi'; // 'presensi' | 'log_pindaian'

  @override
  void initState() {
    super.initState();
    ScanLogStore().initDefault();
  }

  List<ClassReconciliation> get _rows => _classes.map(reconcileClass).toList();
  DistributionTotals get _totals => sumDistribution(_rows);

  List<ScanLogEntry> get _log {
    final ranged = filterByRange(ScanLogStore().getLog(), _range);
    return searchBatch(ranged, _query);
  }

  int get _distributed => _log.where((e) => isDistributed(e.severity)).fold(0, (sum, e) => sum + e.portions);
  int get _rejected => _log.where((e) => e.severity == ScanSeverity.ditolak).fold(0, (sum, e) => sum + e.portions);

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

  void _handleSimulateExportPDF() {
    setState(() => _exportPreview = true);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Unduh Lembar Rekonsiliasi PDF'),
        content: Text('Dokumen Rekapitulasi Presensi & BAST ${_handoverSchoolName()} berhasil diunduh. File tersimpan di folder Dokumen Sekolah.'),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Buka File'))],
      ),
    );
  }

  void _handleShareWhatsApp() {
    setState(() => _exportPreview = true);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Kirim ke Komite Sekolah'),
        content: Text('Tembusan laporan harian ($_distributed porsi diserahkan, ${_totals.porsiSisa} porsi sisa) siap dibagikan ke grup resmi Komite Sekolah.'),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Kirim Salinan'))],
      ),
    );
  }

  String _handoverSchoolName() => 'SDN Menteng 01 Pagi';

  int get _percentServed => _totals.quota > 0 ? ((_totals.porsiDiterahkan / _totals.quota) * 100).round() : 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            FeatureHeader(
              title: 'Riwayat & Presensi',
              onOpenProfile: () => context.go('/profile'),
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sub header
                    Container(
                      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
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
                              Row(
                                children: [
                                  const Icon(LucideIcons.shieldCheck, size: 14, color: Color(0xFF10B981)),
                                  const SizedBox(width: 6),
                                  Text(
                                    _handoverSchoolName(),
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.text),
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 6),
                                    child: Text('•', style: TextStyle(color: AppColors.textSecondary)),
                                  ),
                                  const Text('Dapodik Resmi', style: TextStyle(fontSize: 11, color: Color(0xFF15803D), fontWeight: FontWeight.w700)),
                                ],
                              ),
                              OutlinedButton.icon(
                                onPressed: () => setState(() => _exportPreview = true),
                                icon: const Icon(LucideIcons.fileText, size: 16, color: AppColors.primary),
                                label: const Text('Laporan', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.primary,
                                  side: const BorderSide(color: AppColors.primary),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(LucideIcons.calendar, size: 13, color: AppColors.textSecondary),
                              const SizedBox(width: 6),
                              const Text('Kamis, 10 Oktober 2026 • Sesi Makan Siang Bergizi',
                                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Range filter
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _RangeChip(label: 'Hari Ini', selected: _range == HistoryRange.hariIni, onTap: () => setState(() => _range = HistoryRange.hariIni)),
                            _RangeChip(label: '7 Hari', selected: _range == HistoryRange.tujuhHari, onTap: () => setState(() => _range = HistoryRange.tujuhHari)),
                            _RangeChip(label: 'Bulan Ini', selected: _range == HistoryRange.bulanIni, onTap: () => setState(() => _range = HistoryRange.bulanIni)),
                          ],
                        ),
                      ),
                    ),
                    // Search
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: TextField(
                        onChanged: (v) => setState(() => _query = v),
                        decoration: InputDecoration(
                          hintText: 'Cari kode batch...',
                          hintStyle: const TextStyle(color: AppColors.textMuted),
                          prefixIcon: const Icon(LucideIcons.search, color: AppColors.textSecondary),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    // Mode tabs
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: _ModeTab(label: 'Presensi', selected: _activeTabMode == 'presensi', onTap: () => setState(() => _activeTabMode = 'presensi')),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _ModeTab(label: 'Log Pindaian', selected: _activeTabMode == 'log_pindaian', onTap: () => setState(() => _activeTabMode = 'log_pindaian')),
                          ),
                        ],
                      ),
                    ),
                    // Tab content
                    if (_activeTabMode == 'presensi') _buildPresensiTab() else _buildLogTab(),
                    // Export preview
                    if (_exportPreview) _buildExportPreview(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresensiTab() {
    final rows = _rows;
    final totals = _totals;
    final percentServed = _percentServed;

    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary cards
          Row(
            children: [
              Expanded(child: _SummaryCard(title: 'Total Kuota', value: '${_totals.quota} porsi', color: AppColors.blue)),
              const SizedBox(width: 12),
              Expanded(child: _SummaryCard(title: 'Terserahkan', value: '${totals.porsiDiterahkan} porsi', color: AppColors.green)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _SummaryCard(title: 'Porsi Sisa', value: '${totals.porsiSisa} porsi', color: totals.porsiSisa > 0 ? AppColors.amber : AppColors.green)),
              const SizedBox(width: 12),
              Expanded(child: _SummaryCard(title: 'Terserahkan', value: '$percentServed%', color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 16),
          // Class list
          const Text('Rekonsiliasi per Kelas', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.text)),
          const SizedBox(height: 12),
          ...rows.map((r) => _ClassRow(
                reconciliation: r,
                onSetAllPresent: () => _handleSetAllPresent(r.id, r.quota),
                onUpdateHadir: (delta) => _handleUpdateCount(r.id, 'hadir', delta, r.quota),
                onUpdateSakit: (delta) => _handleUpdateCount(r.id, 'sakit', delta, r.quota),
              )),
          const SizedBox(height: 16),
          // Surplus allocation
          Card(
            color: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppColors.border)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Alokasi Porsi Sisa', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.text)),
                  const SizedBox(height: 12),
                  ...surplusOptions.map((opt) => RadioListTile<SurplusAllocation>(
                        value: opt.key,
                        groupValue: _allocation,
                        onChanged: (v) => setState(() => _allocation = v!),
                        title: Text(opt.label, style: const TextStyle(fontSize: 13, color: AppColors.text)),
                        subtitle: Text(opt.hint, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        activeColor: AppColors.primary,
                        contentPadding: EdgeInsets.zero,
                      )),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Export buttons
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _handleSimulateExportPDF,
                  icon: const Icon(LucideIcons.fileText, size: 20),
                  label: const Text('Pratinjau Lembar Rekapitulasi MBG'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.text,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _handleShareWhatsApp,
                  icon: const Icon(LucideIcons.share2, size: 20),
                  label: const Text('Bagikan via WhatsApp'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLogTab() {
    final log = _log;

    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Buku Log Pindaian Boks', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.text)),
              Text('${log.length} entri', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 12),
          if (log.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    const Icon(LucideIcons.fileText, size: 48, color: AppColors.textSecondary),
                    const SizedBox(height: 12),
                    const Text('Belum ada log pindaian', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: log.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) => _LogRow(entry: log[i]),
            ),
      ],
    );
  }

  Widget _buildExportPreview() {
    return Container(
      margin: const EdgeInsets.all(16),
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
              const Text('Pratinjau Lembar Rekapitulasi MBG', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.text)),
              IconButton(icon: const Icon(LucideIcons.x, size: 22), onPressed: () => setState(() => _exportPreview = false)),
            ],
          ),
          const Divider(height: 24),
          _buildPreviewTable(),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: FilledButton.icon(onPressed: () => setState(() => _exportPreview = false), icon: const Icon(LucideIcons.fileText), label: const Text('Buka File'))),
              const SizedBox(width: 12),
              Expanded(child: OutlinedButton.icon(onPressed: () => setState(() => _exportPreview = false), icon: const Icon(LucideIcons.share2), label: const Text('Kirim Salinan'))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewTable() {
    final rows = _rows;
    final totals = _totals;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('RINGKASAN DISTRIBUSI KELAS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        Table(
          columnWidths: const {0: FlexColumnWidth(2), 1: FlexColumnWidth(1), 2: FlexColumnWidth(1), 3: FlexColumnWidth(1), 4: FlexColumnWidth(1)},
          border: TableBorder.all(color: AppColors.border, width: 0.5),
          children: [
            _buildTableHeader(['Kelas', 'Kuota', 'Hadir', 'Sakit', 'Sisa']),
            ...rows.map((r) => TableRow(
                  children: [
                    _cell(r.name),
                    _cell('${r.quota}'),
                    _cell('${r.hadir}'),
                    _cell('${r.sakit}'),
                    _cell('${r.porsiSisa}', color: r.porsiSisa > 0 ? AppColors.amber : AppColors.green),
                  ],
                )),
            TableRow(
              decoration: const BoxDecoration(color: AppColors.surfaceMuted),
              children: [
                _cell('TOTAL', bold: true),
                _cell('${totals.quota}', bold: true),
                _cell('${totals.hadir}', bold: true),
                _cell('${totals.sakit}', bold: true),
                _cell('${totals.porsiSisa}', bold: true, color: totals.porsiSisa > 0 ? AppColors.amber : AppColors.green),
              ],
            ),
          ],
        ),
      ],
    );
  }

  TableCell _cell(String text, {bool bold = false, Color? color}) {
    return TableCell(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Text(text, style: TextStyle(fontSize: 11, fontWeight: bold ? FontWeight.w700 : FontWeight.w500, color: color ?? AppColors.text)),
      ),
    );
  }

  TableRow _buildTableHeader(List<String> headers) {
    return TableRow(
      decoration: const BoxDecoration(color: AppColors.surfaceMuted),
      children: headers.map((h) => TableCell(child: Padding(padding: const EdgeInsets.all(8), child: Text(h, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary))))).toList(),
    );
  }
}

class _RangeChip extends StatelessWidget {
  const _RangeChip({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label, style: TextStyle(color: selected ? Colors.white : AppColors.textSecondary, fontWeight: FontWeight.w600, fontSize: 12)),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: AppColors.primary,
        backgroundColor: Colors.white,
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }
}

class _ModeTab extends StatelessWidget {
  const _ModeTab({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? AppColors.primary : AppColors.border),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: selected ? AppColors.text : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.title, required this.value, required this.color});
  final String title;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Row(
            children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Expanded(child: Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.text))),
            ],
          ),
        ],
      ),
    );
  }
}

class _ClassRow extends StatelessWidget {
  const _ClassRow({
    required this.reconciliation,
    required this.onSetAllPresent,
    required this.onUpdateHadir,
    required this.onUpdateSakit,
  });

  final ClassReconciliation reconciliation;
  final VoidCallback onSetAllPresent;
  final ValueChanged<int> onUpdateHadir;
  final ValueChanged<int> onUpdateSakit;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: reconciliation.inconsistent ? AppColors.red : AppColors.border)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(reconciliation.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.text)),
                if (reconciliation.inconsistent)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: AppColors.redSoft, borderRadius: BorderRadius.circular(8)),
                    child: const Text('Tidak Konsisten', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.red)),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _CountControl(label: 'Hadir', value: reconciliation.hadir, max: reconciliation.quota, onChanged: onUpdateHadir),
                const SizedBox(width: 12),
                _CountControl(label: 'Sakit', value: reconciliation.sakit, max: reconciliation.quota, onChanged: onUpdateSakit),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _InfoItem(label: 'Kuota', value: '${reconciliation.quota} porsi')),
                Expanded(child: _InfoItem(label: 'Diterahkan', value: '${reconciliation.porsiDiterahkan} porsi')),
                Expanded(child: _InfoItem(label: 'Sisa', value: '${reconciliation.porsiSisa} porsi', valueColor: reconciliation.porsiSisa > 0 ? AppColors.amber : AppColors.green)),
              ],
            ),
            if (reconciliation.porsiSisa > 0) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onSetAllPresent,
                  icon: const Icon(LucideIcons.check, size: 16),
                  label: const Text('Set Semua Hadir'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(reconciliation.note, style: TextStyle(fontSize: 11, color: reconciliation.inconsistent ? AppColors.red : AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _CountControl extends StatelessWidget {
  const _CountControl({required this.label, required this.value, required this.max, required this.onChanged});
  final String label;
  final int value;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Row(
            children: [
              _CountButton(icon: LucideIcons.minus, onTap: () => onChanged(-1), disabled: value <= 0),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: AppColors.surfaceMuted, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
                  child: Text('$value', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.text)),
                ),
              ),
              const SizedBox(width: 8),
              _CountButton(icon: LucideIcons.plus, onTap: () => onChanged(1), disabled: value >= max),
            ],
          ),
        ],
      ),
    );
  }
}

class _CountButton extends StatelessWidget {
  const _CountButton({required this.icon, required this.onTap, this.disabled = false});
  final IconData icon;
  final VoidCallback onTap;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: disabled ? null : onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: disabled ? AppColors.surfaceMuted : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: disabled ? AppColors.border : AppColors.border),
        ),
        child: Icon(icon, size: 18, color: disabled ? AppColors.textMuted : AppColors.text),
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  const _InfoItem({required this.label, required this.value, this.valueColor});
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: valueColor ?? AppColors.text)),
      ],
    );
  }
}

class _LogRow extends StatelessWidget {
  const _LogRow({required this.entry});
  final ScanLogEntry entry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: severityBg[entry.severity]!, borderRadius: BorderRadius.circular(12)),
            child: Icon(_severityIcon(entry.severity), color: severityColor[entry.severity], size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.batchCode, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.text)),
                const SizedBox(height: 2),
                Text('${formatClock(entry.scannedAt)} • ${entry.portions} porsi', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: severityBg[entry.severity]!, borderRadius: BorderRadius.circular(10)),
                child: Text(severityLabel[entry.severity]!, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: severityColor[entry.severity])),
              ),
              const SizedBox(height: 4),
              Text('Skor ${entry.score}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }
}

IconData _severityIcon(ScanSeverity s) {
  switch (s) {
    case ScanSeverity.layak:
      return LucideIcons.checkCircle2;
    case ScanSeverity.waspada:
      return LucideIcons.alertTriangle;
    case ScanSeverity.ditolak:
      return LucideIcons.xCircle;
  }
}
