import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:kawangizi_mobile/core/theme/app_colors.dart';
import 'package:kawangizi_mobile/features/auth/presentation/auth_controller.dart';

class IncidentScreen extends StatefulWidget {
  const IncidentScreen({super.key});

  @override
  State<IncidentScreen> createState() => _IncidentScreenState();
}

class _IncidentScreenState extends State<IncidentScreen> {
  final List<String> _categories = [];
  final TextEditingController _affectedController = TextEditingController();
  final TextEditingController _arrivalTempController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  int _evidenceCount = 0;
  _IncidentTicket? _ticket;

  static const _categoriesList = [
    {'key': 'aroma', 'label': 'Aroma asam atau basi', 'hint': 'Bau menyengat, berbusa, atau rasa asam', 'class': 'kontaminasi'},
    {'key': 'benda_asing', 'label': 'Benda asing', 'hint': 'Serangga, rambut, kawat cuci, serpihan plastik', 'class': 'kontaminasi'},
    {'key': 'kematangan', 'label': 'Kematangan tidak sempurna', 'hint': 'Daging masih berdarah atau mentah di bagian dalam', 'class': 'kontaminasi'},
    {'key': 'alergi', 'label': 'Reaksi alergi atau siswa mengeluh sakit', 'hint': 'Gatal, pusing, atau mual pasca mencicipi', 'class': 'kontaminasi'},
    {'key': 'suhu_drop', 'label': 'Suhu drop dan basi logistik', 'hint': 'Boks sampai sekolah di bawah 50°C', 'class': 'logistik'},
    {'key': 'kemasan_pecah', 'label': 'Kemasan pecah atau bocor', 'hint': 'Segel terbuka dan makanan tercemar debu jalan', 'class': 'logistik'},
  ];

  static const _firstAidSteps = [
    'Amankan dan pisahkan boks yang bermasalah dari jangkauan anak-anak.',
    'Masukkan satu sampel ke plastik steril untuk uji laboratorium.',
    'Beri air putih matang kepada siswa yang sempat mencicipi, lalu bawa ke ruang UKS.',
  ];

  _SeverityInfo? _severity;

  @override
  void dispose() {
    _affectedController.dispose();
    _arrivalTempController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _toggleCategory(String key) {
    setState(() {
      if (_categories.contains(key)) {
        _categories.remove(key);
      } else {
        _categories.add(key);
      }
      _updateSeverity();
    });
  }

  void _updateSeverity() {
    final affected = int.tryParse(_affectedController.text) ?? 0;
    final temp = double.tryParse(_arrivalTempController.text);
    _severity = _deriveSeverity(_categories, affected, temp);
  }

  void _handleSubmit() {
    if (_categories.isEmpty) {
      _showAlert('Laporan belum lengkap', 'Pilih minimal satu kategori insiden.');
      return;
    }
    if ((int.tryParse(_affectedController.text) ?? 0) <= 0) {
      _showAlert('Laporan belum lengkap', 'Isi jumlah porsi yang terdampak.');
      return;
    }
    setState(() {
      _ticket = _IncidentTicket(
        id: _buildTicketId(),
        createdAt: DateTime.now(),
        categories: List.from(_categories),
        affectedPortions: int.parse(_affectedController.text),
        severity: _severity?.severity ?? _Severity.rendah,
        sentToCommandCenter: false,
      });
    });
  }

  _SeverityInfo _deriveSeverity(List<String> categories, int affectedPortions, double? arrivalTemp) {
    const contaminationKeys = {'aroma', 'benda_asing', 'kematangan', 'alergi'};
    const logisticsKeys = {'suhu_drop', 'kemasan_pecah'};

    var level = _Severity.rendah;
    final reasons = <String>[];

    if (categories.any(contaminationKeys.contains)) {
      level = _Severity.tinggi;
      reasons.add('Kontaminasi pada ${categories.where(contaminationKeys.contains).map((k) => _categoryLabel(k)).join(', ')}');
    }

    if (categories.contains('suhu_drop')) {
      if (arrivalTemp == null) {
        level = _maxSeverity(level, _Severity.sedang);
        reasons.add('Suhu boks saat tiba belum dicatat');
      } else if (arrivalTemp < 50) {
        level = _maxSeverity(level, _Severity.tinggi);
        reasons.add('Suhu tiba ${arrivalTemp.toStringAsFixed(1)}°C, batas basi 50°C');
      } else {
        level = _maxSeverity(level, _Severity.sedang);
        reasons.add('Suhu tiba ${arrivalTemp.toStringAsFixed(1)}°C, di atas batas basi');
      }
    }

    if (categories.contains('kemasan_pecah')) {
      reasons.add('Kemasan pecah, bisa diselesaikan dengan menyisihkan porsi');
    }

    if (affectedPortions > 2) {
      level = _maxSeverity(level, _Severity.sedang);
      reasons.add('$affectedPortions porsi terdampak, di atas batas 2 porsi yang boleh disisihkan');
    }

    final copy = _severityCopy(level);
    final instruction = level == _Severity.tinggi
        ? 'Isolasi seluruh boks yang ada di sekolah ini.'
        : level == _Severity.sedang
            ? 'Sisihkan porsi terdampak, minta penggantinya, dan catat nomor boksnya.'
            : 'Sisihkan 1 sampai 2 boks dan ganti dengan porsi cadangan sekolah.';

    return _SeverityInfo(
      severity: level,
      label: copy['label']!,
      color: copy['color']!,
      instruction: instruction,
      isolatesWholeBatch: level == _Severity.tinggi,
      reasons: reasons,
    );
  }

  _Severity _maxSeverity(_Severity a, _Severity b) {
    const order = [_Severity.rendah, _Severity.sedang, _Severity.tinggi];
    return order.indexOf(a) >= order.indexOf(b) ? a : b;
  }

  Map<String, String> _severityCopy(_Severity level) {
    switch (level) {
      case _Severity.rendah:
        return {'label': 'Rendah', 'color': '#B45309'};
      case _Severity.sedang:
        return {'label': 'Sedang', 'color': '#C2410C'};
      case _Severity.tinggi:
        return {'label': 'Tinggi, darurat merah', 'color': '#B91C1C'};
    }
  }

  String _categoryLabel(String key) {
    return _categoriesList.firstWhere((c) => c['key'] == key)['label']!;
  }

  String _buildTicketId() {
    const cityCode = 'JKT';
    const npsnSuffix = 'SDN01P';
    final now = DateTime.now();
    final ymd = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    return 'INS/MBG-$cityCode/${ymd}/$npsnSuffix-001';
  }

  void _showAlert(String title, String message) {
    showDialog(context: context, builder: (_) => AlertDialog(title: Text(title), content: Text(message), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Mengerti'))]));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            FeatureHeader(
              title: 'Lapor Insiden',
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
                        'Kamera belum terhubung, jadi bukti foto tidak bisa dilampirkan. Laporan tersimpan di perangkat dan belum dikirim ke Satuan Tugas MBG.',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ),
                    // Categories
                    Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Kategori Insiden', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.text)),
                          const SizedBox(height: 4),
                          const Text('Pilih semua yang sesuai, bukan hanya yang pertama.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          const SizedBox(height: 12),
                          ..._categoriesList.map((c) {
                            final selected = _categories.contains(c['key']);
                            return InkWell(
                              onTap: () => setState(() => _toggleCategory(c['key']!)),
                              borderRadius: BorderRadius.circular(12),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: selected ? (c['class'] == 'kontaminasi' ? const Color(0xFFFEF2F2) : const Color(0xFFFFFBEB)) : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: selected ? (c['class'] == 'kontaminasi' ? const Color(0xFFEF4444) : const Color(0xFFF59E0B)) : AppColors.border),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 24,
                                      height: 24,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: selected ? (c['class'] == 'kontaminasi' ? const Color(0xFFEF4444) : const Color(0xFFF59E0B)) : Colors.transparent,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: selected ? (c['class'] == 'kontaminasi' ? const Color(0xFFEF4444) : const Color(0xFFF59E0B)) : AppColors.border, width: 2),
                                      ),
                                      child: selected ? const Icon(LucideIcons.check, size: 14, color: Colors.white) : null,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(c['label']!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.text)),
                                          Text(c['hint']!, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                        ],
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
                    // Affected portions
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Jumlah Porsi Terdampak', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.text)),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _affectedController,
                            keyboardType: TextInputType.number,
                            onChanged: (_) => setState(_updateSeverity),
                            decoration: const InputDecoration(labelText: 'Porsi', hintText: '0', border: OutlineInputBorder()),
                          ),
                        ],
                      ),
                    ),
                    // Arrival temp
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Suhu Tiba (°C)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.text)),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _arrivalTempController,
                            keyboardType: TextInputType.number,
                            onChanged: (_) => setState(_updateSeverity),
                            decoration: const InputDecoration(labelText: 'Suhu', hintText: '50', border: OutlineInputBorder()),
                          ),
                        ],
                      ),
                    ),
                    // Notes
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Catatan Tambahan', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.text)),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _notesController,
                            maxLines: 3,
                            decoration: const InputDecoration(hintText: 'Catatan tambahan...', border: OutlineInputBorder()),
                          ),
                        ],
                      ),
                    ),
                    // Evidence placeholder
                    Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Bukti Foto (Maks 3)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.text)),
                          const SizedBox(height: 8),
                          Text('Kamera belum terhubung. $_evidenceCount / 3 bukti', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(child: OutlinedButton.icon(onPressed: () {}, icon: const Icon(LucideIcons.camera), label: const Text('Tambah Foto'))),
                              const SizedBox(width: 12),
                              Expanded(child: OutlinedButton.icon(onPressed: () {}, icon: const Icon(LucideIcons.image), label: const Text('Dari Galeri'))),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Severity display
                    if (_severity != null)
                      Container(
                        margin: const EdgeInsets.all(16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Color(int.parse(_severity!.color.replaceFirst('#', '0xFF'))).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Color(int.parse(_severity!.color.replaceFirst('#', '0xFF')))),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(width: 8, height: 8, decoration: BoxDecoration(color: Color(int.parse(_severity!.color.replaceFirst('#', '0xFF'))), shape: BoxShape.circle)),
                                const SizedBox(width: 8),
                                Text(_severity!.label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(int.parse(_severity!.color.replaceFirst('#', '0xFF'))))),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(_severity!.instruction, style: const TextStyle(fontSize: 13, color: AppColors.text)),
                            const SizedBox(height: 8),
                            if (_severity!.reasons.isNotEmpty) ...[
                              const Text('Alasan:', style: TextStyle(fontWeight: FontWeight.w700)),
                              const SizedBox(height: 4),
                              ..._severity!.reasons.map((r) => Padding(padding: const EdgeInsets.only(left: 16, bottom: 2), child: Text('• $r', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)))),
                            ],
                          ],
                        ),
                      ),
                    // First aid steps
                    Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Langkah Pertama', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.text)),
                          const SizedBox(height: 8),
                          ..._firstAidSteps.map((s) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Text('• $s', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)))),
                        ],
                      ),
                    ),
                    // Submit button
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: FilledButton(
                          onPressed: _categories.isEmpty || (int.tryParse(_affectedController.text) ?? 0) <= 0 ? null : _handleSubmit,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.text,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: const Text('Simpan laporan siaga', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                        ),
                      ),
                    ),
                    // Ticket display
                    if (_ticket != null)
                      Container(
                        margin: const EdgeInsets.all(16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Laporan Tersimpan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.text)),
                            const SizedBox(height: 8),
                            _DetailRow(label: 'Nomor Tiket', value: _ticket!.id),
                            _DetailRow(label: 'Waktu', value: formatClock(_ticket!.createdAt)),
                            _DetailRow(label: 'Kategori', value: _ticket!.categories.map(_categoryLabel).join(', ')),
                            _DetailRow(label: 'Porsi Terdampak', value: '${_ticket!.affectedPortions}'),
                            _DetailRow(label: 'Derajat', value: _ticket!.severity.name),
                            _DetailRow(label: 'Terkirim ke Pusat', value: _ticket!.sentToCommandCenter ? 'Ya' : 'Belum (prototipe)'),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IncidentTicket {
  const _IncidentTicket({
    required this.id,
    required this.createdAt,
    required this.categories,
    required this.affectedPortions,
    required this.severity,
    required this.sentToCommandCenter,
  });
  final String id;
  final DateTime createdAt;
  final List<String> categories;
  final int affectedPortions;
  final _Severity severity;
  final bool sentToCommandCenter;
}

enum _Severity { rendah, sedang, tinggi }

class _SeverityInfo {
  const _SeverityInfo({
    required this.severity,
    required this.label,
    required this.color,
    required this.instruction,
    required this.isolatesWholeBatch,
    required this.reasons,
  });
  final _Severity severity;
  final String label;
  final String color;
  final String instruction;
  final bool isolatesWholeBatch;
  final List<String> reasons;
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 120, child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.text))),
        ],
      ),
    );
  }
}
