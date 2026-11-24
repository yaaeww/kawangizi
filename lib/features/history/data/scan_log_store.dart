import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class ScanLogEntry {
  const ScanLogEntry({
    required this.id,
    required this.scannedAt,
    required this.batchCode,
    required this.portions,
    required this.score,
    required this.severity,
  });

  final String id;
  final DateTime scannedAt;
  final String batchCode;
  final int portions;
  final int score;
  final ScanSeverity severity;
}

enum ScanSeverity { layak, waspada, ditolak }

class ScanLogStore {
  ScanLogStore._();
  static final ScanLogStore _instance = ScanLogStore._();
  factory ScanLogStore() => _instance;

  final List<ScanLogEntry> _entries = [];

  List<ScanLogEntry> get entries => List.unmodifiable(_entries);

  void initDefault() {
    if (_entries.isNotEmpty) return;
    final now = DateTime.now();
    _entries.addAll([
      ScanLogEntry(
        id: 'scan-init-1',
        scannedAt: DateTime(now.year, now.month, now.day, 7, 5),
        batchCode: 'BATCH-20261010-01A',
        portions: 28,
        score: 98,
        severity: ScanSeverity.layak,
      ),
      ScanLogEntry(
        id: 'scan-init-2',
        scannedAt: DateTime(now.year, now.month, now.day, 7, 12),
        batchCode: 'BATCH-20261010-01B',
        portions: 30,
        score: 97,
        severity: ScanSeverity.layak,
      ),
      ScanLogEntry(
        id: 'scan-init-3',
        scannedAt: DateTime(now.year, now.month, now.day, 7, 18),
        batchCode: 'BATCH-20261010-02A',
        portions: 29,
        score: 99,
        severity: ScanSeverity.layak,
      ),
      ScanLogEntry(
        id: 'scan-init-4',
        scannedAt: DateTime(now.year, now.month, now.day, 7, 24),
        batchCode: 'BATCH-20261010-02B',
        portions: 31,
        score: 96,
        severity: ScanSeverity.layak,
      ),
      ScanLogEntry(
        id: 'scan-init-5',
        scannedAt: DateTime(now.year, now.month, now.day, 7, 30),
        batchCode: 'BATCH-20261010-03B',
        portions: 33,
        score: 98,
        severity: ScanSeverity.layak,
      ),
    ]);
  }

  ScanLogEntry addEntry({
    required DateTime scannedAt,
    required String batchCode,
    required int portions,
    required int score,
    required ScanSeverity severity,
  }) {
    final entry = ScanLogEntry(
      id: Uuid().v4(),
      scannedAt: scannedAt,
      batchCode: batchCode,
      portions: portions,
      score: score,
      severity: severity,
    );
    _entries.insert(0, entry);
    return entry;
  }

  List<ScanLogEntry> getLog() {
    if (_entries.isEmpty) initDefault();
    return List.unmodifiable(_entries);
  }

  void clear() {
    _entries.clear();
  }
}

enum HistoryRange { hariIni, tujuhHari, bulanIni }

List<ScanLogEntry> filterByRange(List<ScanLogEntry> log, HistoryRange range, {DateTime? now}) {
  final current = now ?? DateTime.now();
  final today = DateTime(current.year, current.month, current.day);
  int days;
  switch (range) {
    case HistoryRange.hariIni:
      days = 0;
      break;
    case HistoryRange.tujuhHari:
      days = 6;
      break;
    case HistoryRange.bulanIni:
      days = 29;
      break;
  }
  final from = today.subtract(Duration(days: days));
  return log.where((e) => !e.scannedAt.isBefore(from)).toList();
}

List<ScanLogEntry> searchBatch(List<ScanLogEntry> log, String query) {
  if (query.trim().isEmpty) return log;
  final q = query.trim().toLowerCase();
  return log.where((e) => e.batchCode.toLowerCase().contains(q)).toList();
}

String formatClock(DateTime date) {
  return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')} WIB';
}

const Map<ScanSeverity, String> severityLabel = {
  ScanSeverity.layak: 'Lolos Verifikasi AI',
  ScanSeverity.waspada: 'Lolos (Perlu Hasten)',
  ScanSeverity.ditolak: 'Ditolak / Rusak',
};

const Map<ScanSeverity, Color> severityColor = {
  ScanSeverity.layak: Color(0xFF10B981),
  ScanSeverity.waspada: Color(0xFFF59E0B),
  ScanSeverity.ditolak: Color(0xFFEF4444),
};

const Map<ScanSeverity, Color> severityBg = {
  ScanSeverity.layak: Color(0xFFECFDF5),
  ScanSeverity.waspada: Color(0xFFFFFBEB),
  ScanSeverity.ditolak: Color(0xFFFEF2F2),
};

bool isDistributed(ScanSeverity severity) => severity == ScanSeverity.layak || severity == ScanSeverity.waspada;
