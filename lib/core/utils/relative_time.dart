String formatRelativeTime(DateTime? date, {String fallback = 'Baru saja'}) {
  if (date == null) return fallback;
  final diff = DateTime.now().difference(date);
  if (diff.inSeconds < 45 && diff.inSeconds > -5) return 'Baru saja';
  final seconds = diff.inSeconds.abs();
  final minutes = seconds ~/ 60;
  final hours = minutes ~/ 60;
  final days = hours ~/ 24;
  final weeks = days ~/ 7;
  final months = days ~/ 30;
  final years = days ~/ 365;

  if (minutes < 1) return '$seconds detik yang lalu';
  if (minutes < 60) return '$minutes menit yang lalu';
  if (hours < 24) return '$hours jam yang lalu';
  if (days < 7) return '$days hari yang lalu';
  if (weeks < 4) return '$weeks minggu yang lalu';
  if (months < 12) return '$months bulan yang lalu';
  return '$years tahun yang lalu';
}

String formatClock(DateTime date) {
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '$hour:$minute WIB';
}
