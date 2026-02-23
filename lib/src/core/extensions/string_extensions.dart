/// String extension methods.
extension PrimekitStringExtensions on String {
  // ---------------------------------------------------------------------------
  // Validation helpers
  // ---------------------------------------------------------------------------

  /// Returns `true` if this string is a valid email address.
  bool get isEmail {
    final regex = RegExp(
      r'^[a-zA-Z0-9.!#$%&*+/=?^_`{|}~-]+'
      r'@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?'
      r'(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$',
    );
    return regex.hasMatch(this);
  }

  /// Returns `true` if this string is a valid URL.
  bool get isUrl {
    final uri = Uri.tryParse(this);
    return uri != null && (uri.isScheme('http') || uri.isScheme('https'));
  }

  /// Returns `true` if this string contains only digits.
  bool get isNumeric => RegExp(r'^\d+$').hasMatch(this);

  /// Returns `true` if this string is a valid phone number (E.164 or local).
  bool get isPhone => RegExp(r'^\+?[\d\s\-()]{7,15}$').hasMatch(this);

  // ---------------------------------------------------------------------------
  // Transformation
  // ---------------------------------------------------------------------------

  /// Capitalizes the first letter of this string.
  String get capitalized {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  /// Converts to title case (each word capitalized).
  String get titleCase => split(' ').map((w) => w.capitalized).join(' ');

  /// Converts camelCase or PascalCase to snake_case.
  String get snakeCase => replaceAllMapped(
    RegExp(r'(?<=[a-z\d])[A-Z]'),
    (m) => '_${m.group(0)!.toLowerCase()}',
  ).toLowerCase();

  /// Converts to a URL-safe slug.
  String get slugified => toLowerCase()
      .replaceAll(RegExp(r'[^\w\s-]'), '')
      .replaceAll(RegExp(r'[\s_]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');

  /// Truncates the string to [maxLength] and appends [ellipsis].
  String truncate(int maxLength, {String ellipsis = '…'}) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength - ellipsis.length)}$ellipsis';
  }

  /// Returns `null` if the string is empty, otherwise returns `this`.
  String? get nullIfEmpty => isEmpty ? null : this;

  /// Strips all whitespace from the string.
  String get stripped => replaceAll(RegExp(r'\s'), '');

  /// Masks part of the string (e.g. for PII display).
  ///
  /// `'test@example.com'.masked()` → `'te**@example.com'`
  String masked({int visibleStart = 2, int visibleEnd = 0, String mask = '*'}) {
    if (length <= visibleStart + visibleEnd) return this;
    final start = substring(0, visibleStart);
    final end = visibleEnd > 0 ? substring(length - visibleEnd) : '';
    final middle = mask * (length - visibleStart - visibleEnd);
    return '$start$middle$end';
  }
}

/// Nullable string extensions.
extension PrimekitNullableStringExtensions on String? {
  /// Returns `true` if the string is null or empty.
  bool get isNullOrEmpty => this == null || this!.isEmpty;

  /// Returns the string or a fallback if null/empty.
  String orDefault(String fallback) =>
      (this == null || this!.isEmpty) ? fallback : this!;
}
