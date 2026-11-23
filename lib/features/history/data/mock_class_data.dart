import 'package:kawangizi_mobile/features/history/utils/distribution.dart';

class ClassInput {
  const ClassInput({
    required this.id,
    required this.name,
    required this.quota,
    required this.hadir,
    required this.sakit,
  });

  final String id;
  final String name;
  final int quota;
  final int hadir;
  final int sakit;
}

final List<ClassInput> mockClasses = [
  ClassInput(id: '1A', name: 'Kelas 1A', quota: 28, hadir: 27, sakit: 1),
  ClassInput(id: '1B', name: 'Kelas 1B', quota: 30, hadir: 30, sakit: 0),
  ClassInput(id: '2A', name: 'Kelas 2A', quota: 29, hadir: 29, sakit: 0),
  ClassInput(id: '2B', name: 'Kelas 2B', quota: 31, hadir: 31, sakit: 0),
  ClassInput(id: '3A', name: 'Kelas 3A', quota: 30, hadir: 29, sakit: 1),
  ClassInput(id: '3B', name: 'Kelas 3B', quota: 33, hadir: 33, sakit: 0),
];
