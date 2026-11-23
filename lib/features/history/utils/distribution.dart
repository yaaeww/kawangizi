class ClassReconciliation {
  const ClassReconciliation({
    required this.id,
    required this.name,
    required this.quota,
    required this.hadir,
    required this.sakit,
    required this.porsiDiterahkan,
    required this.porsiSisa,
    required this.inconsistent,
    required this.note,
  });

  final String id;
  final String name;
  final int quota;
  final int hadir;
  final int sakit;
  final int porsiDiterahkan;
  final int porsiSisa;
  final bool inconsistent;
  final String note;
}

ClassReconciliation reconcileClass(ClassInput input) {
  final porsiSisa = input.quota - input.hadir;
  final inconsistent = input.hadir + input.sakit > input.quota || porsiSisa < 0;

  return ClassReconciliation(
    id: input.id,
    name: input.name,
    quota: input.quota,
    hadir: input.hadir,
    sakit: input.sakit,
    porsiDiterahkan: input.hadir,
    porsiSisa: porsiSisa,
    inconsistent: inconsistent,
    note: inconsistent
        ? 'Jumlah hadir dan sakit melebihi kuota. Periksa absensi.'
        : porsiSisa > 0
            ? '$porsiSisa porsi sisa menunggu alokasi'
            : 'Porsi terbagi semua',
  );
}

class DistributionTotals {
  const DistributionTotals({
    required this.quota,
    required this.hadir,
    required this.sakit,
    required this.porsiDiterahkan,
    required this.porsiSisa,
    required this.incompleteClasses,
  });

  final int quota;
  final int hadir;
  final int sakit;
  final int porsiDiterahkan;
  final int porsiSisa;
  final List<String> incompleteClasses;
}

DistributionTotals sumDistribution(List<ClassReconciliation> classes) {
  return classes.fold(
    DistributionTotals(quota: 0, hadir: 0, sakit: 0, porsiDiterahkan: 0, porsiSisa: 0, incompleteClasses: []),
    (total, item) => DistributionTotals(
      quota: total.quota + item.quota,
      hadir: total.hadir + item.hadir,
      sakit: total.sakit + item.sakit,
      porsiDiterahkan: total.porsiDiterahkan + item.porsiDiterahkan,
      porsiSisa: total.porsiSisa + item.porsiSisa,
      incompleteClasses: item.porsiSisa > 0
          ? [...total.incompleteClasses, item.name]
          : total.incompleteClasses,
    ),
  );
}

enum SurplusAllocation { staf, snackSore, belum }

const List<SurplusOption> surplusOptions = [
  SurplusOption(
    key: SurplusAllocation.staf,
    label: 'Diserahkan ke staf sekolah',
    hint: 'Penjaga atau petugas kebersihan sekolah menerima porsi sisa',
  ),
  SurplusOption(
    key: SurplusAllocation.snackSore,
    label: 'Disimpan untuk makanan tambahan sore',
    hint: 'Disimpan di lemari pendingin sekolah sesuai SOP',
  ),
  SurplusOption(
    key: SurplusAllocation.belum,
    label: 'Belum dialokasikan',
    hint: 'Porsi sisa menunggu keputusan guru',
  ),
];

class SurplusOption {
  const SurplusOption({required this.key, required this.label, required this.hint});
  final SurplusAllocation key;
  final String label;
  final String hint;
}

String describeAllocation(SurplusRecord record) {
  switch (record.allocation) {
    case SurplusAllocation.staf:
      return '${record.portions} porsi diserahkan ke staf sekolah';
    case SurplusAllocation.snackSore:
      return '${record.portions} porsi disimpan untuk makanan tambahan sore';
    case SurplusAllocation.belum:
      return '${record.portions} porsi sisa belum dialokasikan';
  }
}

class SurplusRecord {
  const SurplusRecord({required this.portions, required this.allocation});
  final int portions;
  final SurplusAllocation allocation;
}
