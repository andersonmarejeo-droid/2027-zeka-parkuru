String contentFingerprint(Iterable<Object?> parts) {
  final String normalized = parts
      .map((Object? value) => _normalizeFingerprintPart('$value'))
      .join('|');

  int hash = 0x811c9dc5;
  for (final int codeUnit in normalized.codeUnits) {
    hash ^= codeUnit;
    hash = (hash * 0x01000193) & 0x7fffffff;
  }

  return hash.toRadixString(16).padLeft(8, '0');
}

String _normalizeFingerprintPart(String value) {
  return value.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
}
