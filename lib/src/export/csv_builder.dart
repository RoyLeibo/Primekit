/// A generic, immutable CSV builder that produces RFC 4180 compliant output.
///
/// ```dart
/// final csv = PkCsvBuilder<Expense>.fromList(
///   items: expenses,
///   columns: {
///     'Date': (e) => e.date.toIso8601String(),
///     'Description': (e) => e.description,
///     'Amount': (e) => e.amount.toStringAsFixed(2),
///   },
/// ).build();
/// ```
class PkCsvBuilder<T> {
  const PkCsvBuilder({
    List<String> headers = const [],
    List<List<String>> rows = const [],
    String separator = ',',
    String lineEnding = '\r\n',
  })  : _headers = headers,
        _rows = rows,
        _separator = separator,
        _lineEnding = lineEnding;

  final List<String> _headers;
  final List<List<String>> _rows;
  final String _separator;
  final String _lineEnding;

  /// Creates a builder pre-populated from a list of typed items.
  ///
  /// [columns] maps header names to extraction functions. The insertion
  /// order of the map determines the column order.
  factory PkCsvBuilder.fromList({
    required List<T> items,
    required Map<String, String Function(T)> columns,
    String separator = ',',
    String lineEnding = '\r\n',
  }) {
    final headers = columns.keys.toList();
    final extractors = columns.values.toList();

    final rows = items.map((item) {
      return extractors.map((extract) => extract(item)).toList();
    }).toList();

    return PkCsvBuilder<T>(
      headers: headers,
      rows: rows,
      separator: separator,
      lineEnding: lineEnding,
    );
  }

  /// Returns a new builder with the given headers.
  PkCsvBuilder<T> addHeaders(List<String> headers) {
    return PkCsvBuilder<T>(
      headers: headers,
      rows: _rows,
      separator: _separator,
      lineEnding: _lineEnding,
    );
  }

  /// Returns a new builder with a single row appended.
  PkCsvBuilder<T> addRow(List<String> row) {
    return PkCsvBuilder<T>(
      headers: _headers,
      rows: [..._rows, row],
      separator: _separator,
      lineEnding: _lineEnding,
    );
  }

  /// Returns a new builder with multiple rows appended.
  PkCsvBuilder<T> addRows(List<List<String>> rows) {
    return PkCsvBuilder<T>(
      headers: _headers,
      rows: [..._rows, ...rows],
      separator: _separator,
      lineEnding: _lineEnding,
    );
  }

  /// Returns a new builder with the given field separator.
  PkCsvBuilder<T> withSeparator(String separator) {
    return PkCsvBuilder<T>(
      headers: _headers,
      rows: _rows,
      separator: separator,
      lineEnding: _lineEnding,
    );
  }

  /// Returns a new builder with the given line ending.
  PkCsvBuilder<T> withLineEnding(String lineEnding) {
    return PkCsvBuilder<T>(
      headers: _headers,
      rows: _rows,
      separator: _separator,
      lineEnding: lineEnding,
    );
  }

  /// Builds the CSV string. RFC 4180 compliant.
  String build() {
    final buffer = StringBuffer();

    if (_headers.isNotEmpty) {
      buffer.write(
        _headers.map((h) => _escape(h, _separator)).join(_separator),
      );
      buffer.write(_lineEnding);
    }

    for (final row in _rows) {
      buffer.write(
        row.map((cell) => _escape(cell, _separator)).join(_separator),
      );
      buffer.write(_lineEnding);
    }

    return buffer.toString();
  }

  /// Escapes a value per RFC 4180: wraps in double-quotes if the value
  /// contains the separator, a double-quote, a newline, or a carriage return.
  /// Internal double-quotes are doubled.
  static String _escape(String value, String separator) {
    if (value.contains(separator) ||
        value.contains('"') ||
        value.contains('\n') ||
        value.contains('\r')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }
}
