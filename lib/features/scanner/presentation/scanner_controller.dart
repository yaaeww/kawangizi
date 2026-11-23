import 'dart:async';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../data/scan_repository.dart';
import '../domain/scan_models.dart';

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

  Future<void> startScan(ImagePicker picker, BuildContext context) async {
    if (_qrToken.trim().isEmpty || _holdingTemp.isEmpty || _releaseTemp.isEmpty) {
      _showAlert(context, 'Data pemeriksaan belum lengkap',
          'Isi token QR boks serta suhu holding dan suhu lepas dapur yang benar-benar diukur.');
      return;
    }

    _isAnalyzing = true;
    _backendError = null;
    _backendScan = null;
    _isChatOpen = false;
    notifyListeners();

    try {
      final image = await _pickImage(picker, context);
      if (image == null) return;

      _capturedPhoto = image.path;
      _hasScanned = true;
      notifyListeners();

      await _runBackendScan(image);
    } catch (e) {
      _backendError = e.toString();
      _resetScanState();
    } finally {
      _isAnalyzing = false;
      notifyListeners();
    }
  }

  Future<XFile?> _pickImage(ImagePicker picker, BuildContext context) async {
    // For Android, use camera intent
    try {
      final result = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1080,
      );
      return result;
    } catch (e) {
      _showAlert(context, 'Kamera Tidak Tersedia',
          'Terjadi kendala saat membuka kamera. Hasil scan tidak dibuat; coba lagi atau gunakan perangkat lain.');
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
      // Parse result into ScanResult (simplified)
      // In a real app, you'd parse the full JSON. Here we create a minimal ScanResult.
      _backendScan = _parseScanResult(result);
      _capturedPhoto = _capturedPhoto; // keep local photo
    } catch (e) {
      _backendError = e.toString();
      _resetScanState();
    }
  }

  ScanResult _parseScanResult(Map<String, dynamic> data) {
    // Minimal parsing; in production you'd map all fields.
    return ScanResult(
      id: data['id']?.toString() ?? '',
      boxId: data['boxId']?.toString() ?? '',
      qrToken: data['qrToken']?.toString() ?? '',
      batchId: data['batchId']?.toString(),
      menuName: data['menuName']?.toString(),
      menuClass: data['menuClass']?.toString(),
      menuDisplay: data['menuDisplay']?.toString(),
      menuConfidence: (data['menuConfidence'] as num?)?.toDouble(),
      freshnessClass: data['freshnessClass']?.toString(),
      freshnessDisplay: data['freshnessDisplay']?.toString(),
      freshnessConfidence: (data['freshnessConfidence'] as num?)?.toDouble(),
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
                      energy: (data['batchInfo']['macros']['energy'] as num?)?.toDouble() ?? 0,
                      protein: (data['batchInfo']['macros']['protein'] as num?)?.toDouble() ?? 0,
                      carbs: (data['batchInfo']['macros']['carbs'] as num?)?.toDouble() ?? 0,
                      fat: (data['batchInfo']['macros']['fat'] as num?)?.toDouble() ?? 0,
                      fiber: (data['batchInfo']['macros']['fiber'] as num?)?.toDouble() ?? 0,
                    )
                  : null,
            )
          : null,
      scannedAt: data['scannedAt']?.toString() ?? '',
      score: (data['score'] as num?)?.toDouble() ?? 0,
      verdict: Verdict.values.firstWhere(
        (v) => v.name == (data['verdict']?.toString() ?? 'layak'),
        orElse: () => Verdict.layak,
      ),
      verdictLabel: data['verdictLabel']?.toString() ?? '',
      releaseTemp: (data['releaseTemp'] as num?)?.toDouble() ?? 0,
      holdTemp: (data['holdTemp'] as num?)?.toDouble() ?? 0,
      checks: (data['checks'] as List?)?.map((c) => ScanCheck(
            label: c['label']?.toString() ?? '',
            ok: c['ok'] as bool? ?? false,
            note: c['note']?.toString() ?? '',
          )).toList() ?? [],
      compartments: (data['compartments'] as List?)?.map((c) => CompartmentMatch(
            index: c['index'] as int? ?? 0,
            cell: c['cell']?.toString() ?? '',
            bboxNorm: (c['bboxNorm'] as List?)?.map((e) => (e as num).toDouble()).toList(),
            bboxQuad: (c['bboxQuad'] as List?)?.map((e) => (e as List).map((f) => (f as num).toDouble()).toList()).toList(),
            empty: c['empty'] as bool? ?? false,
            predicted: c['predicted']?.toString(),
            predictedDisplay: c['predictedDisplay']?.toString(),
            component: c['component']?.toString(),
            confidence: (c['confidence'] as num?)?.toDouble() ?? 0,
            mixed: c['mixed'] as bool?,
            status: c['status']?.toString() ?? '',
            note: c['note']?.toString() ?? '',
          )).toList(),
      macros: data['macros'] != null
          ? Macros(
              energy: (data['macros']['energy'] as num?)?.toDouble() ?? 0,
              protein: (data['macros']['protein'] as num?)?.toDouble() ?? 0,
              carbs: (data['macros']['carbs'] as num?)?.toDouble() ?? 0,
              fat: (data['macros']['fat'] as num?)?.toDouble() ?? 0,
              fiber: (data['macros']['fiber'] as num?)?.toDouble() ?? 0,
            )
          : null,
      nutrition: data['nutrition'] as List?,
      nutritionNote: data['nutritionNote']?.toString(),
      rating: data['rating'] as int?,
      feedback: data['feedback']?.toString(),
      note: data['note']?.toString() ?? '',
      aiClass: data['aiClass']?.toString() ?? '',
      aiConfidence: (data['aiConfidence'] as num?)?.toDouble() ?? 0,
      aiLatencyMs: (data['aiLatencyMs'] as num?)?.toDouble(),
      scanMode: ScanMode.values.firstWhere(
        (m) => m.name == (data['scanMode']?.toString() ?? 'nutrisi'),
        orElse: () => ScanMode.nutrisi,
      ),
      duplicateImage: data['duplicateImage'] as bool?,
      kelayakan: data['kelayakan'] != null
          ? KelayakanReport(
              namaHidangan: data['kelayakan']['nama_hidangan']?.toString() ?? '',
              statusKelayakan: data['kelayakan']['status_kelayakan']?.toString() ?? '',
              skorKesegaran: (data['kelayakan']['skor_kesegaran'] as num?)?.toDouble() ?? 0,
              indikatorVisual: (data['kelayakan']['indikator_visual'] as List?)?.map((e) => e.toString()).toList() ?? [],
              peringatanKeamanan: data['kelayakan']['peringatan_keamanan']?.toString(),
              rekomendasi: data['kelayakan']['rekomendasi']?.toString() ?? '',
            )
          : null,
      nutrisi: data['nutrisi'] != null
          ? NutrisiReport(
              namaHidangan: data['nutrisi']['nama_hidangan']?.toString() ?? '',
              estimasiBeratPorsi: data['nutrisi']['estimasi_berat_porsi']?.toString() ?? '',
              rincianBahan: (data['nutrisi']['rincian_bahan'] as List?)?.map((b) => NutrisiBahan(
                    bahan: b['bahan']?.toString() ?? '',
                    porsiEstimasi: b['porsi_estimasi']?.toString() ?? '',
                    weightG: (b['weight_gram'] as num?)?.toDouble() ?? 0,
                  )).toList() ?? [],
              makronutrisi: MakronutrisiReport(
                kaloriTotal: (data['nutrisi']['makronutrisi']['kalori_total'] as num?)?.toDouble() ?? 0,
                protein: (data['nutrisi']['makronutrisi']['protein'] as num?)?.toDouble() ?? 0,
                karbohidrat: (data['nutrisi']['makronutrisi']['karbohidrat'] as num?)?.toDouble() ?? 0,
                lemak: (data['nutrisi']['makronutrisi']['lemak'] as num?)?.toDouble() ?? 0,
                serat: (data['nutrisi']['makronutrisi']['serat'] as num?)?.toDouble() ?? 0,
              ),
              ringkasanGizi: data['nutrisi']['ringkasan_gizi']?.toString() ?? '',
            )
          : null,
    );
  }

  void _resetScanState() {
    _capturedPhoto = null;
    _hasScanned = false;
    _backendScan = null;
    _backendError = null;
  }

  void resetScan() {
    _capturedPhoto = null;
    _hasScanned = false;
    _backendScan = null;
    _backendError = null;
    _isImageViewerOpen = false;
    _selectedItem = null;
    _rotation = 0;
    _zoomScale = 1.0;
    _activeTab = ScanMode.nutrisi;
    _isChatOpen = false;
    notifyListeners();
  }

  void handleAction(bool approved) {
    if (_backendScan == null) return;
    // In the original, this just shows an alert. We'll replicate.
  }

  void _showAlert(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Mengerti'))],
      ),
    );
  }
}
