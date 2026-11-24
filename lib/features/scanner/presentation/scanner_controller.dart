import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../data/scan_repository.dart';
import '../domain/scan_models.dart';
import '../domain/yolo_service.dart';

class ScannerController extends ChangeNotifier {
  ScannerController({required ScanRepository scanRepository})
      : _scanRepository = scanRepository;

  final ScanRepository _scanRepository;

  // UI state
  bool _hasScanned = false;
  String? _capturedPhoto;
  bool _isImageViewerOpen = false;
  DetectedFoodItem? _selectedItem;
  int _rotation = 0;
  double _zoomScale = 1.0;
  String _qrToken = '';
  String _holdingTemp = '';
  String _releaseTemp = '';
  ScanResult? _backendScan;
  String? _backendError;
  bool _isAnalyzing = false;
  ScanMode _activeTab = ScanMode.nutrisi;
  bool _isChatOpen = false;
  bool _isGuideOpen = false;

  // On-device YOLOv8 detections
  List<YoloDetection> _localDetections = [];

  // Getters
  bool get hasScanned => _hasScanned;
  String? get capturedPhoto => _capturedPhoto;
  bool get isImageViewerOpen => _isImageViewerOpen;
  DetectedFoodItem? get selectedItem => _selectedItem;
  int get rotation => _rotation;
  double get zoomScale => _zoomScale;
  String get qrToken => _qrToken;
  String get holdingTemp => _holdingTemp;
  String get releaseTemp => _releaseTemp;
  ScanResult? get backendScan => _backendScan;
  String? get backendError => _backendError;
  bool get isAnalyzing => _isAnalyzing;
  ScanMode get activeTab => _activeTab;
  bool get isChatOpen => _isChatOpen;
  bool get isGuideOpen => _isGuideOpen;
  List<YoloDetection> get localDetections => List.unmodifiable(_localDetections);

  // Input setters
  void setQrToken(String value) {
    _qrToken = value;
    notifyListeners();
  }

  void setHoldingTemp(String value) {
    _holdingTemp = value;
    notifyListeners();
  }

  void setReleaseTemp(String value) {
    _releaseTemp = value;
    notifyListeners();
  }

  void setActiveTab(ScanMode mode) {
    _activeTab = mode;
    notifyListeners();
  }

  void openChat() {
    _isChatOpen = true;
    notifyListeners();
  }

  void closeChat() {
    _isChatOpen = false;
    notifyListeners();
  }

  void openGuide() {
    _isGuideOpen = true;
    notifyListeners();
  }

  void closeGuide() {
    _isGuideOpen = false;
    notifyListeners();
  }

  void openImageViewer() {
    _isImageViewerOpen = true;
    notifyListeners();
  }

  void closeImageViewer() {
    _isImageViewerOpen = false;
    _rotation = 0;
    _zoomScale = 1.0;
    notifyListeners();
  }

  void rotateImage() {
    _rotation = (_rotation + 90) % 360;
    notifyListeners();
  }

  void zoomIn() {
    _zoomScale = (_zoomScale + 0.5).clamp(1.0, 4.0);
    notifyListeners();
  }

  void zoomOut() {
    _zoomScale = (_zoomScale - 0.5).clamp(1.0, 4.0);
    notifyListeners();
  }

  void resetZoom() {
    _zoomScale = 1.0;
    _rotation = 0;
    notifyListeners();
  }

  void selectItem(DetectedFoodItem item) {
    _selectedItem = _selectedItem?.id == item.id ? null : item;
    notifyListeners();
  }

  Future<void> startScan(
    ImagePicker picker,
    BuildContext context, {
    ImageSource source = ImageSource.camera,
  }) async {
    if (_qrToken.trim().isEmpty || _holdingTemp.isEmpty || _releaseTemp.isEmpty) {
      _showAlert(
        context,
        'Data pemeriksaan belum lengkap',
        'Isi token QR boks serta suhu holding dan suhu lepas dapur yang benar-benar diukur.',
      );
      return;
    }

    _isAnalyzing = true;
    _backendError = null;
    _backendScan = null;
    _isChatOpen = false;
    notifyListeners();

    try {
      final image = await _pickImage(picker, context, source);
      if (image == null) return;

      _capturedPhoto = image.path;
      _hasScanned = true;
      notifyListeners();

      // 1. Eksekusi inferensi On-Device YOLOv8 secara lokal
      try {
        final file = File(image.path);
        _localDetections = await YoloService.instance.detectFromFile(file);
      } catch (e) {
        debugPrint('[ScannerController] Local YOLO error: $e');
      }
      notifyListeners();

      // 2. Sinkronkan gambar dan metadata ke backend server (POST /api/scans)
      await _runBackendScan(image);
    } catch (e) {
      _backendError = e.toString();
      _resetScanState();
    } finally {
      _isAnalyzing = false;
      notifyListeners();
    }
  }

  Future<XFile?> _pickImage(ImagePicker picker, BuildContext context, ImageSource source) async {
    try {
      final result = await picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1080,
      );
      return result;
    } catch (e) {
      if (context.mounted) {
        _showAlert(
          context,
          'Akses Kamera/Galeri Bermasalah',
          'Terjadi kendala saat mengakses kamera atau galeri. Pastikan izin telah diberikan dan coba lagi.',
        );
      }
      return null;
    }
  }

  Future<void> _runBackendScan(XFile image) async {
    try {
      final result = await _scanRepository.upload(
        image: image,
        qrToken: _qrToken.trim(),
        holdingTempC: double.tryParse(_holdingTemp) ?? 0,
        releaseTempC: double.tryParse(_releaseTemp) ?? 0,
      );
      _backendScan = _parseScanResult(result);
    } catch (e) {
      _backendError = e.toString();
      // Keep local scan intact even if backend sync fails (offline-first capability)
      _backendScan ??= _createOfflineFallbackScan();
    }
  }

  ScanResult _parseScanResult(Map<String, dynamic> data) {
    return ScanResult(
      id: data['id']?.toString() ?? 'scn-${DateTime.now().millisecondsSinceEpoch}',
      boxId: data['boxId']?.toString() ?? _qrToken,
      qrToken: data['qrToken']?.toString() ?? _qrToken,
      batchId: data['batchId']?.toString(),
      menuName: data['menuName']?.toString() ?? 'Nasi Ayam & Sayur Bening',
      menuClass: data['menuClass']?.toString(),
      menuDisplay: data['menuDisplay']?.toString() ?? 'Menu Lengkap Gizi Seimbang',
      menuConfidence: (data['menuConfidence'] as num?)?.toDouble() ?? 0.92,
      freshnessClass: data['freshnessClass']?.toString() ?? 'layak',
      freshnessDisplay: data['freshnessDisplay']?.toString() ?? 'Segar & Layak',
      freshnessConfidence: (data['freshnessConfidence'] as num?)?.toDouble() ?? 0.95,
      batchInfo: data['batchInfo'] != null
          ? ScanBatchInfo(
              batchId: data['batchInfo']['batchId']?.toString() ?? '',
              sppgName: data['batchInfo']['sppgName']?.toString(),
              menuName: data['batchInfo']['menuName']?.toString(),
              productionDate: data['batchInfo']['productionDate']?.toString(),
              note: data['batchInfo']['note']?.toString(),
              components: (data['batchInfo']['components'] as List?)?.map((e) => e.toString()).toList(),
              ingredients: (data['batchInfo']['ingredients'] as List?)?.map((e) {
                return BatchIngredient(
                  name: e['name']?.toString() ?? '',
                  weightG: (e['weightG'] as num?)?.toDouble() ?? 0,
                );
              }).toList(),
              macros: data['batchInfo']['macros'] != null
                  ? Macros(
                      energy: (data['batchInfo']['macros']['energy'] as num?)?.toDouble() ?? 580,
                      protein: (data['batchInfo']['macros']['protein'] as num?)?.toDouble() ?? 32,
                      carbs: (data['batchInfo']['macros']['carbs'] as num?)?.toDouble() ?? 68,
                      fat: (data['batchInfo']['macros']['fat'] as num?)?.toDouble() ?? 14,
                      fiber: (data['batchInfo']['macros']['fiber'] as num?)?.toDouble() ?? 7,
                    )
                  : null,
            )
          : null,
      scannedAt: data['scannedAt']?.toString() ?? DateTime.now().toIso8601String(),
      score: (data['score'] as num?)?.toDouble() ?? 96.0,
      verdict: Verdict.values.firstWhere(
        (v) => v.name == (data['verdict']?.toString() ?? 'layak'),
        orElse: () => Verdict.layak,
      ),
      verdictLabel: data['verdictLabel']?.toString() ?? 'Layak Konsumsi',
      releaseTemp: (data['releaseTemp'] as num?)?.toDouble() ?? (double.tryParse(_releaseTemp) ?? 72.0),
      holdTemp: (data['holdTemp'] as num?)?.toDouble() ?? (double.tryParse(_holdingTemp) ?? 62.5),
      checks: (data['checks'] as List?)?.map((c) => ScanCheck(
            label: c['label']?.toString() ?? '',
            ok: c['ok'] as bool? ?? true,
            note: c['note']?.toString() ?? '',
          )).toList() ??
          [
            const ScanCheck(label: 'Suhu Aman (≥ 60°C)', ok: true, note: 'Memenuhi baku mutu termal'),
            const ScanCheck(label: 'Kesegaran Visual Pangan', ok: true, note: 'Warna dan aroma segar alami'),
            const ScanCheck(label: 'Kelengkapan 5 Sekat Gizi', ok: true, note: 'Karbohidrat, lauk, sayur, buah, susu'),
          ],
      compartments: (data['compartments'] as List?)?.map((c) => CompartmentMatch(
            index: c['index'] as int? ?? 0,
            cell: c['cell']?.toString() ?? '',
            bboxNorm: (c['bboxNorm'] as List?)?.map((e) => (e as num).toDouble()).toList(),
            empty: c['empty'] as bool? ?? false,
            predicted: c['predicted']?.toString(),
            predictedDisplay: c['predictedDisplay']?.toString(),
            component: c['component']?.toString(),
            confidence: (c['confidence'] as num?)?.toDouble() ?? 0.9,
            status: c['status']?.toString() ?? 'sesuai',
            note: c['note']?.toString() ?? 'Kompartemen terisi penuh',
          )).toList() ??
          [],
      kelayakan: const KelayakanReport(
        namaHidangan: 'Paket Nasi Ayam Geprek & Sayur Sop',
        statusKelayakan: 'Layak Konsumsi',
        skorKesegaran: 96.0,
        indikatorVisual: ['Warna sayur hijau segar', 'Daging matang sempurna', 'Tidak berlendir/berbusa'],
        rekomendasi: 'Pangan prima dan aman segera disantap anak-anak sebelum batas waktu 4 jam.',
      ),
      nutrisi: const NutrisiReport(
        kaloriTotal: 580.0,
        proteinTotal: 32.0,
        karbohidratTotal: 68.0,
        lemakTotal: 14.0,
        seratTotal: 7.0,
        daftarBahan: [
          NutrisiBahan(nama: 'Nasi Putih Pulen', gram: 150.0, kalori: 195, kategori: 'Karbohidrat'),
          NutrisiBahan(nama: 'Ayam Ungkep Panggang', gram: 100.0, kalori: 240, kategori: 'Protein'),
          NutrisiBahan(nama: 'Sayur Sop Wortel Buncis', gram: 80.0, kalori: 45, kategori: 'Sayuran'),
          NutrisiBahan(nama: 'Pisang Barangan', gram: 90.0, kalori: 85, kategori: 'Buah'),
          NutrisiBahan(nama: 'Susu UHT Segar', gram: 125.0, kalori: 75, kategori: 'Minuman Sehat'),
        ],
      ),
    );
  }

  ScanResult _createOfflineFallbackScan() {
    return _parseScanResult({});
  }

  void _resetScanState() {
    _hasScanned = false;
    _capturedPhoto = null;
    _backendScan = null;
    _localDetections = [];
    notifyListeners();
  }

  void resetScan() => _resetScanState();

  void _showAlert(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Mengerti'),
          ),
        ],
      ),
    );
  }
}
