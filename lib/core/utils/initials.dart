String getInitials(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  return parts
      .take(2)
      .map((part) => part.characters.first.toUpperCase())
      .join();
}

extension _FirstCharacter on String {
  Iterable<String> get characters => runes.map(String.fromCharCode);
}
