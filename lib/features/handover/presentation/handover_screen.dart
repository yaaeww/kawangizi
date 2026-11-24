import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:kawangizi_mobile/core/theme/app_colors.dart';
import 'package:kawangizi_mobile/shared/widgets/feature_header.dart';
import '../widgets/signature_pad.dart';

class HandoverScreen extends StatefulWidget {
  const HandoverScreen({super.key});

  @override
  State<HandoverScreen> createState() => _HandoverScreenState();
}

class _HandoverScreenState extends State<HandoverScreen> {
  final Map<int, String> _toteTemps = {};
  String _damaged = '0';
  bool _organolepticDone = false;
  String _driverSignature = '';
  String _teacherSignature = '';
  bool _issued = false;

  static const _expectedTotes = 13;
  static const _portionsPerTote = 50;
  static const _orderedPortions = 650;

  @override
  Widget build(BuildContext context) {
    final readings = _evaluateTotes();

    final unsafeReadings = readings.where((r) => !r.isSafe).toList();
    final reconciliation = _reconcile(readings.length);
    final registration = _buildRegistrationNumber();
    final readiness = _checkReadiness(readings.length, unsafeReadings.isNotEmpty);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            FeatureHeader(
              title: 'Serah Terima BAST',
              onOpenProfile: () {},
              onExit: () => context.go('/'),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
                      child: const Text(
                        'Data kuota dan pengantar di halaman ini adalah data contoh. Nomor BAST dibuat di perangkat, tidak ada yang dikirim ke server.',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ),
                    _buildToteSection(readings, unsafeReadings),
                    if (unsafeReadings.isNotEmpty) _buildOrganolepticSection(),
                    _buildReconciliationSection(reconciliation),
                    _buildSignatureSection(),
                    _buildRegistrationSection(_buildRegistrationNumber()),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: FilledButton(
                          onPressed: readiness.ready ? () => setState(() => _issued = true) : null,
                          style: FilledButton.styleFrom(
                            backgroundColor: readiness.ready ? AppColors.primary : AppColors.border,
                            foregroundColor: readiness.ready ? AppColors.text : AppColors.textSecondary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: const Text('Terbitkan BAST', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                        ),
                      ),
                    ),
                    if (!readiness.ready) _buildBlockers(readiness.blockers),
                  ],
                ),
              ),
            ),
            if (_issued) _IssuedBottomSheet(registration: registration, onClose: () => setState(() => _issued = false)),
          ],
        ),
      ),
    );
  }

  List<_ToteReading> _evaluateTotes() {
    return _toteTemps.entries.map((e) {
      final temp = double.tryParse(e.value) ?? double.nan;
      return _ToteReading(tote: e.key, temp: temp);
    }).toList();
  }

  _ReconciliationResult _reconcile(int totesReceived) {
    final receivedPortions = totesReceived * _portionsPerTote;
    final damaged = int.tryParse(_damaged) ?? 0;
    final discrepancy = receivedPortions - damaged - _orderedPortions;
    return _ReconciliationResult(
      receivedPortions: receivedPortions,
      damagedPortions: damaged,
      discrepancy: discrepancy,
      balanced: discrepancy == 0,
      message: discrepancy == 0
          ? 'Porsi diterima, dikurangi kerusakan, sama dengan kuota pesanan.'
          : discrepancy > 0
              ? '$discrepancy porsi lebih banyak dari pesanan.'
              : '${discrepancy.abs()} porsi kurang dari pesanan.',
    );
  }

  _Readiness _checkReadiness(int totesReceived, bool hasUnsafe) {
    final blockers = <String>[];
    if (totesReceived == 0) {
      blockers.add('Belum ada tote yang diterima.');
    } else if (totesReceived < _expectedTotes) {
      blockers.add('${_expectedTotes - totesReceived} tote belum diterima, catatan serah terima belum lengkap.');
    }
    if (hasUnsafe && !_organolepticDone) {
      blockers.add('Masih ada suhu di bawah standar yang belum diuji organoleptik.');
    }
    final reconciliation = _reconcile(_toteTemps.length);
    if (!reconciliation.balanced) blockers.add('Rekonsiliasi porsi belum balance.');
    if (_driverSignature.isEmpty) blockers.add('Tanda tangan petugas pengantar belum ada.');
    if (_teacherSignature.isEmpty) blockers.add('Tanda tangan guru validator belum ada.');
    return _Readiness(ready: blockers.isEmpty, blockers: blockers);
  }

  String _buildRegistrationNumber() {
    const cityCode = 'JKT';
    const npsnSuffix = 'SDN01P';
    final now = DateTime.now();
    final ymd = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    const seq = '042';
    return 'BAST/KG-$cityCode/$ymd/$npsnSuffix-$seq';
  }

  Widget _buildToteSection(List<_ToteReading> readings, List<_ToteReading> unsafe) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Tote Diterima', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.text)),
              Text('1 tote = 50 porsi • Armada B-9281-KBA, Bpk. Mulyono',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 12),
          if (readings.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Icon(LucideIcons.package, size: 48, color: AppColors.textSecondary),
                    const SizedBox(height: 8),
                    const Text('Belum ada tote yang dicatat', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                    const SizedBox(height: 4),
                    const Text('Catat tote satu per satu saat master QR-nya dipindai di gerbang, lalu isi suhu termometernya.',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary), textAlign: TextAlign.center),
                  ],
                ),
              ),
            )
          else
            Column(
              children: readings.map((r) => _ToteRow(
                    tote: r.tote,
                    value: _toteTemps[r.tote] ?? '',
                    reading: r,
                    onChange: (v) => setState(() => _toteTemps[r.tote] = v),
                  )).toList(),
            ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: readings.length >= 13 ? null : () => setState(() => _toteTemps[readings.length + 1] = ''),
              icon: const Icon(LucideIcons.plus, size: 18),
              label: Text(readings.length >= 13 ? 'Semua 13 tote tercatat' : 'Catat tote berikutnya'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.text,
                side: const BorderSide(color: AppColors.border),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrganolepticSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Uji Organoleptik', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.text)),
          const SizedBox(height: 4),
          const Text('Uji organoleptik: rasa, aroma, dan tekstur sampel. Wajib dicatat bila ada tote di bawah 55°C.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          InkWell(
            onTap: () => setState(() => _organolepticDone = !_organolepticDone),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _organolepticDone ? AppColors.greenSoft : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _organolepticDone ? AppColors.green : AppColors.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: _organolepticDone ? AppColors.green : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: _organolepticDone ? AppColors.green : AppColors.border, width: 2),
                    ),
                    child: _organolepticDone ? const Icon(LucideIcons.check, size: 14, color: Colors.white) : null,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(child: Text('Sampel sudah diuji dan hasilnya dicatat', style: TextStyle(fontSize: 13, color: AppColors.text))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReconciliationSection(_ReconciliationResult recon) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Rekonsiliasi Porsi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.text)),
          const SizedBox(height: 4),
          Text(recon.message, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          _ReconRow(label: 'Kuota Pesanan', value: '650 porsi'),
          _ReconRow(label: 'Diterima dari Tote', value: '${recon.receivedPortions} porsi'),
          _ReconRow(
            label: 'Bocor/Rusak',
            child: TextField(
              controller: TextEditingController(text: _damaged),
              onChanged: (v) => setState(() => _damaged = v),
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(hintText: '0', hintStyle: TextStyle(color: AppColors.textMuted), isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10), border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10)), borderSide: BorderSide(color: AppColors.border))),
            ),
          ),
          _ReconRow(
            label: 'Selisih',
            value: recon.discrepancy > 0 ? '+${recon.discrepancy} porsi' : '${recon.discrepancy} porsi',
            valueColor: recon.balanced ? AppColors.green : AppColors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildSignatureSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Tanda Tangan Digital', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.text)),
          const SizedBox(height: 4),
          const Text('Berdua di layar ponsel: petugas pengantar dan guru validator.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          SignaturePad(
            label: 'Pihak Pertama',
            party: 'Petugas pengantar, SPPG Menteng Jaya (Dapur #04)',
            signed: _driverSignature.isNotEmpty,
            onSign: (path) => setState(() => _driverSignature = path),
            onClear: () => setState(() => _driverSignature = ''),
          ),
          const SizedBox(height: 16),
          SignaturePad(
            label: 'Pihak Kedua',
            party: 'Guru validator, SDN Menteng 01 Pagi',
            signed: _teacherSignature.isNotEmpty,
            onSign: (path) => setState(() => _teacherSignature = path),
            onClear: () => setState(() => _teacherSignature = ''),
          ),
        ],
      ),
    );
  }

  Widget _buildRegistrationSection(String reg) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Nomor Registrasi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.text)),
          const SizedBox(height: 8),
          SelectableText(reg, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.primary, fontFamily: 'monospace')),
          const SizedBox(height: 8),
          const Text('Nomor mengikuti format BAST/KG-JKT/YYYYMMDD/NPSN-XXX. Belum terdaftar di server SPPG, jadi belum sah sebagai dokumen hukum.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildBlockers(List<String> blockers) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.redSoft, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.red.withValues(alpha: 0.3))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Yang Belum Lengkap', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.red)),
          const SizedBox(height: 8),
          ...blockers.map((b) => Padding(padding: const EdgeInsets.only(bottom: 4), child: Text('• $b', style: const TextStyle(fontSize: 12, color: AppColors.red)))),
        ],
      ),
    );
  }
}

class _ToteReading {
  const _ToteReading({required this.tote, required this.temp});
  final int tote;
  final double temp;

  bool get isSafe {
    if (temp.isNaN) return false;
    return temp >= 60; // hangat minimal 60°C
  }

  String get statusLabel {
    if (temp.isNaN) return 'Belum diukur';
    if (temp < 55) return 'Zona Bahaya';
    if (temp < 60) return 'Di Bawah Standar';
    return 'Aman';
  }

  Color get statusColor {
    if (temp.isNaN) return AppColors.textSecondary;
    if (temp < 55) return AppColors.red;
    if (temp < 60) return AppColors.amber;
    return AppColors.green;
  }
}

class _ToteRow extends StatelessWidget {
  const _ToteRow({required this.tote, required this.value, required this.reading, required this.onChange});
  final int tote;
  final String value;
  final _ToteReading reading;
  final ValueChanged<String> onChange;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.surfaceMuted, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(8)),
            child: Text('$tote', style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tote $tote', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.text)),
                const SizedBox(height: 2),
                Text('${reading.statusLabel} • ${value.isEmpty ? '-' : '$value°C'}', style: TextStyle(fontSize: 11, color: reading.statusColor)),
              ],
            ),
          ),
          SizedBox(
            width: 120,
            child: TextField(
              controller: TextEditingController(text: value),
              onChanged: onChange,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(hintText: 'Suhu °C', hintStyle: TextStyle(color: AppColors.textMuted), isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8), border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8)), borderSide: BorderSide(color: AppColors.border))),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReconciliationResult {
  const _ReconciliationResult({required this.receivedPortions, required this.damagedPortions, required this.discrepancy, required this.balanced, required this.message});
  final int receivedPortions;
  final int damagedPortions;
  final int discrepancy;
  final bool balanced;
  final String message;
}

class _Readiness {
  const _Readiness({required this.ready, required this.blockers});
  final bool ready;
  final List<String> blockers;
}

class _ReconRow extends StatelessWidget {
  const _ReconRow({required this.label, this.value, this.valueColor, this.child});
  final String label;
  final String? value;
  final Color? valueColor;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w500))),
          if (child != null)
            SizedBox(width: 120, child: child!)
          else
            Text(value ?? '', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: valueColor ?? AppColors.text)),
        ],
      ),
    );
  }
}

class _IssuedBottomSheet extends StatelessWidget {
  const _IssuedBottomSheet({required this.registration, required this.onClose});
  final String registration;
  final VoidCallback onClose;

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
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
                  const SizedBox(height: 16),
                  const Text('BAST diterbitkan di perangkat', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.text)),
                  const SizedBox(height: 8),
                  SelectableText(registration, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.primary, fontFamily: 'monospace')),
                  const SizedBox(height: 16),
                  const Text('Catatan serah terima tersimpan di perangkat ini. Salinan PDF dapat diunduh dan disinkronkan ke server SPPG Dapur dan Satuan Pengawas Mutu Pangan.',
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary), textAlign: TextAlign.center),
                  const SizedBox(height: 24),
                  SizedBox(width: double.infinity, child: FilledButton(onPressed: onClose, child: const Text('Tutup'))),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
