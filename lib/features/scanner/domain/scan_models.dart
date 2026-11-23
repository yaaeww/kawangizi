enum ScanMode { kelayakan, nutrisi }

enum Verdict { layak, waspada, ditolak }

class ScanCheck {
  const ScanCheck({required this.label, required this.ok, required this.note});
  final String label;
  final bool ok;
  final String note;
}

class Macros {
  const Macros({
    required this.energy,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.fiber,
  });
  final double energy;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;
}

class CompartmentMatch {
  const CompartmentMatch({
    required this.index,
    required this.cell,
    this.bboxNorm,
    this.bboxQuad,
    required this.empty,
    this.predicted,
    this.predictedDisplay,
    this.component,
    required this.confidence,
    this.mixed,
    required this.status,
    required this.note,
  });
  final int index;
  final String cell;
  final List<double>? bboxNorm;
  final List<List<double>>? bboxQuad;
  final bool empty;
  final String? predicted;
  final String? predictedDisplay;
  final String? component;
  final double confidence;
  final bool? mixed;
  final String status;
  final String note;
}

class BatchIngredient {
  const BatchIngredient({required this.name, required this.weightG});
  final String name;
  final double weightG;
}

class ScanBatchInfo {
  const ScanBatchInfo({
    required this.batchId,
    this.sppgName,
    this.menuName,
    this.productionDate,
    this.note,
    this.components,
    this.ingredients,
    this.macros,
  });
  final String batchId;
  final String? sppgName;
  final String? menuName;
  final String? productionDate;
  final String? note;
  final List<String>? components;
  final List<BatchIngredient>? ingredients;
  final Macros? macros;
}

class KelayakanReport {
  const KelayakanReport({
    required this.namaHidangan,
    required this.statusKelayakan,
    required this.skorKesegaran,
    required this.indikatorVisual,
    this.peringatanKeamanan,
    required this.rekomendasi,
  });
  final String namaHidangan;
  final String statusKelayakan;
  final double skorKesegaran;
  final List<String> indikatorVisual;
  final String? peringatanKeamanan;
  final String rekomendasi;
}

class NutrisiBahan {
  const NutrisiBahan({required this.bahan, required this.porsiEstimasi, required this.weightG});
  final String bahan;
  final String porsiEstimasi;
  final double weightG;
}

class MakronutrisiReport {
  const MakronutrisiReport({
    required this.kaloriTotal,
    required this.protein,
    required this.karbohidrat,
    required this.lemak,
    required this.serat,
  });
  final double kaloriTotal;
  final double protein;
  final double karbohidrat;
  final double lemak;
  final double serat;
}

class NutrisiReport {
  const NutrisiReport({
    required this.namaHidangan,
    required this.estimasiBeratPorsi,
    required this.rincianBahan,
    required this.makronutrisi,
    required this.ringkasanGizi,
  });
  final String namaHidangan;
  final String estimasiBeratPorsi;
  final List<NutrisiBahan> rincianBahan;
  final MakronutrisiReport makronutrisi;
  final String ringkasanGizi;
}

class ScanResult {
  const ScanResult({
    required this.id,
    required this.boxId,
    required this.qrToken,
    this.batchId,
    this.menuName,
    this.menuClass,
    this.menuDisplay,
    this.menuConfidence,
    this.freshnessClass,
    this.freshnessDisplay,
    this.freshnessConfidence,
    this.batchInfo,
    required this.scannedAt,
    required this.score,
    required this.verdict,
    required this.verdictLabel,
    required this.releaseTemp,
    required this.holdTemp,
    required this.checks,
    this.compartments,
    this.macros,
    this.nutrition,
    this.nutritionNote,
    this.rating,
    this.feedback,
    this.note,
    required this.aiClass,
    required this.aiConfidence,
    this.aiLatencyMs,
    required this.scanMode,
    this.duplicateImage,
    this.kelayakan,
    this.nutrisi,
  });

  final String id;
  final String boxId;
  final String qrToken;
  final String? batchId;
  final String? menuName;
  final String? menuClass;
  final String? menuDisplay;
  final double? menuConfidence;
  final String? freshnessClass;
  final String? freshnessDisplay;
  final double? freshnessConfidence;
  final ScanBatchInfo? batchInfo;
  final String scannedAt;
  final double score;
  final Verdict verdict;
  final String verdictLabel;
  final double releaseTemp;
  final double holdTemp;
  final List<ScanCheck> checks;
  final List<CompartmentMatch>? compartments;
  final Macros? macros;
  final List<dynamic>? nutrition;
  final String? nutritionNote;
  final int? rating;
  final String? feedback;
  final String? note;
  final String aiClass;
  final double aiConfidence;
  final double? aiLatencyMs;
  final ScanMode scanMode;
  final bool? duplicateImage;
  final KelayakanReport? kelayakan;
  final NutrisiReport? nutrisi;
}

class DetectedFoodItem {
  const DetectedFoodItem({
    required this.id,
    required this.name,
    this.bbox,
    required this.confidence,
    required this.category,
    this.status,
    this.note,
  });
  final String id;
  final String name;
  final List<double>? bbox;
  final double confidence;
  final String category;
  final String? status;
  final String? note;
}

class QrPayload {
  const QrPayload({
    required this.code,
    required this.producer,
    required this.slhs,
    required this.school,
    required this.cookFinishedAt,
    required this.coreTempC,
  });
  final String code;
  final String producer;
  final String slhs;
  final String school;
  final String cookFinishedAt;
  final int coreTempC;
}

class QrCheck {
  const QrCheck({
    required this.key,
    required this.label,
    required this.value,
    required this.passed,
    required this.requirement,
  });
  final String key;
  final String label;
  final String value;
  final bool passed;
  final String requirement;
}

class QrVerdict {
  const QrVerdict({required this.valid, required this.checks, required this.failures});
  final bool valid;
  final List<QrCheck> checks;
  final List<String> failures;
}
