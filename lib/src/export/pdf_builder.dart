import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Configuration for a single table column.
class PkPdfTableColumn {
  const PkPdfTableColumn({
    required this.header,
    this.width,
    this.alignment = pw.Alignment.centerLeft,
  });

  /// Header label displayed in the table header row.
  final String header;

  /// Optional fixed width. When null, the column flexes.
  final double? width;

  /// Cell alignment within the column.
  final pw.Alignment alignment;
}

/// Configuration for rendering a table in a PDF.
class PkPdfTableConfig {
  const PkPdfTableConfig({
    required this.columns,
    required this.rows,
    this.headerBackground = PdfColors.grey300,
    this.headerTextColor = PdfColors.black,
    this.alternateRowColor,
    this.borderColor = PdfColors.grey400,
    this.cellPadding = const pw.EdgeInsets.all(4),
    this.headerFontSize = 10,
    this.cellFontSize = 10,
  });

  final List<PkPdfTableColumn> columns;
  final List<List<String>> rows;
  final PdfColor headerBackground;
  final PdfColor headerTextColor;
  final PdfColor? alternateRowColor;
  final PdfColor borderColor;
  final pw.EdgeInsets cellPadding;
  final double headerFontSize;
  final double cellFontSize;
}

/// A section within a PDF document containing a title and content widgets.
class PkPdfSection {
  const PkPdfSection({
    required this.title,
    required this.content,
    this.level = 1,
  });

  /// Section heading text.
  final String title;

  /// Widgets displayed beneath the heading.
  final List<pw.Widget> content;

  /// Heading level (1 = largest).
  final int level;
}

/// Page configuration for the PDF document.
class PkPdfPageConfig {
  const PkPdfPageConfig({
    this.pageFormat = PdfPageFormat.a4,
    this.margin = const pw.EdgeInsets.all(40),
    this.showPageNumbers = true,
    this.pageNumberFontSize = 10,
  });

  final PdfPageFormat pageFormat;
  final pw.EdgeInsets margin;
  final bool showPageNumbers;
  final double pageNumberFontSize;
}

/// A fluent, immutable builder for constructing PDF documents.
///
/// Each mutation method returns a **new** builder instance, preserving
/// immutability. Call [build] to produce the final PDF bytes.
///
/// ```dart
/// final bytes = await PkPdfBuilder()
///     .withPageConfig(const PkPdfPageConfig())
///     .addTitle('Health Report', subtitle: 'Generated today')
///     .addSection(PkPdfSection(title: 'Vaccines', content: [...]))
///     .addTable(tableConfig)
///     .build();
/// ```
class PkPdfBuilder {
  const PkPdfBuilder({
    PkPdfPageConfig pageConfig = const PkPdfPageConfig(),
    List<pw.Widget> widgets = const [],
  })  : _pageConfig = pageConfig,
        _widgets = widgets;

  final PkPdfPageConfig _pageConfig;
  final List<pw.Widget> _widgets;

  /// Returns a new builder with the given page configuration.
  PkPdfBuilder withPageConfig(PkPdfPageConfig config) {
    return PkPdfBuilder(pageConfig: config, widgets: _widgets);
  }

  /// Returns a new builder with a title block appended.
  PkPdfBuilder addTitle(
    String title, {
    String? subtitle,
    String? generatedLabel,
    double titleFontSize = 24,
    double subtitleFontSize = 14,
  }) {
    final children = <pw.Widget>[
      pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: titleFontSize,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    ];

    if (subtitle != null) {
      children.addAll([
        pw.SizedBox(height: 4),
        pw.Text(subtitle, style: pw.TextStyle(fontSize: subtitleFontSize)),
      ]);
    }

    if (generatedLabel != null) {
      children.addAll([
        pw.SizedBox(height: 4),
        pw.Text(
          generatedLabel,
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
        ),
      ]);
    }

    children.add(pw.Divider());

    final widget = pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: children,
    );

    return PkPdfBuilder(
      pageConfig: _pageConfig,
      widgets: [..._widgets, widget],
    );
  }

  /// Returns a new builder with a styled header banner appended.
  ///
  /// Unlike [addTitle], this renders a colored container with rounded corners.
  PkPdfBuilder addBanner({
    required String title,
    String? subtitle,
    String? footnote,
    PdfColor backgroundColor = PdfColors.teal,
    PdfColor textColor = PdfColors.white,
    PdfColor footnoteColor = PdfColors.tealAccent,
    double borderRadius = 8,
  }) {
    final children = <pw.Widget>[
      pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 20,
          fontWeight: pw.FontWeight.bold,
          color: textColor,
        ),
      ),
    ];

    if (subtitle != null) {
      children.addAll([
        pw.SizedBox(height: 6),
        pw.Text(
          subtitle,
          style: pw.TextStyle(fontSize: 14, color: textColor),
        ),
      ]);
    }

    if (footnote != null) {
      children.addAll([
        pw.SizedBox(height: 4),
        pw.Text(
          footnote,
          style: pw.TextStyle(fontSize: 10, color: footnoteColor),
        ),
      ]);
    }

    final widget = pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: backgroundColor,
        borderRadius: pw.BorderRadius.circular(borderRadius),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: children,
      ),
    );

    return PkPdfBuilder(
      pageConfig: _pageConfig,
      widgets: [..._widgets, widget],
    );
  }

  /// Returns a new builder with a [PkPdfSection] appended.
  PkPdfBuilder addSection(PkPdfSection section) {
    final widget = pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Header(level: section.level, text: section.title),
        ...section.content,
      ],
    );

    return PkPdfBuilder(
      pageConfig: _pageConfig,
      widgets: [..._widgets, widget],
    );
  }

  /// Returns a new builder with a table appended from [PkPdfTableConfig].
  PkPdfBuilder addTable(PkPdfTableConfig config) {
    final widget = _buildTable(config);
    return PkPdfBuilder(
      pageConfig: _pageConfig,
      widgets: [..._widgets, widget],
    );
  }

  /// Returns a new builder with plain text appended.
  PkPdfBuilder addText(
    String text, {
    double fontSize = 12,
    PdfColor? color,
    pw.FontWeight? fontWeight,
  }) {
    final widget = pw.Text(
      text,
      style: pw.TextStyle(
        fontSize: fontSize,
        color: color,
        fontWeight: fontWeight,
      ),
    );

    return PkPdfBuilder(
      pageConfig: _pageConfig,
      widgets: [..._widgets, widget],
    );
  }

  /// Returns a new builder with a callout box (colored left border).
  PkPdfBuilder addCallout(
    String text, {
    PdfColor backgroundColor = PdfColors.grey100,
    PdfColor borderColor = PdfColors.grey400,
    double borderWidth = 3,
    double fontSize = 9,
    PdfColor textColor = PdfColors.grey700,
  }) {
    final widget = pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: backgroundColor,
        border: pw.Border(
          left: pw.BorderSide(color: borderColor, width: borderWidth),
        ),
      ),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontSize: fontSize, color: textColor),
      ),
    );

    return PkPdfBuilder(
      pageConfig: _pageConfig,
      widgets: [..._widgets, widget],
    );
  }

  /// Returns a new builder with a vertical spacer appended.
  PkPdfBuilder addSpacing([double height = 20]) {
    return PkPdfBuilder(
      pageConfig: _pageConfig,
      widgets: [..._widgets, pw.SizedBox(height: height)],
    );
  }

  /// Returns a new builder with a page break appended.
  PkPdfBuilder addPageBreak() {
    return PkPdfBuilder(
      pageConfig: _pageConfig,
      widgets: [..._widgets, pw.NewPage()],
    );
  }

  /// Returns a new builder with an arbitrary [pw.Widget] appended.
  PkPdfBuilder addWidget(pw.Widget widget) {
    return PkPdfBuilder(
      pageConfig: _pageConfig,
      widgets: [..._widgets, widget],
    );
  }

  /// Builds the PDF document and returns its bytes.
  Future<Uint8List> build() async {
    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        pageFormat: _pageConfig.pageFormat,
        margin: _pageConfig.margin,
        footer: _pageConfig.showPageNumbers ? _buildPageFooter : null,
        build: (_) => List<pw.Widget>.of(_widgets),
      ),
    );

    return doc.save();
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  static pw.Widget _buildPageFooter(pw.Context context) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      child: pw.Text(
        'Page ${context.pageNumber} of ${context.pagesCount}',
        style: const pw.TextStyle(fontSize: 10),
      ),
    );
  }

  static pw.Widget _buildTable(PkPdfTableConfig config) {
    final columnWidths = <int, pw.TableColumnWidth>{};
    for (var i = 0; i < config.columns.length; i++) {
      final col = config.columns[i];
      columnWidths[i] = col.width != null
          ? pw.FixedColumnWidth(col.width!)
          : const pw.FlexColumnWidth();
    }

    return pw.Table(
      border: pw.TableBorder.all(color: config.borderColor, width: 0.5),
      columnWidths: columnWidths,
      children: [
        _buildHeaderRow(config),
        for (var i = 0; i < config.rows.length; i++)
          _buildDataRow(config, config.rows[i], i),
      ],
    );
  }

  static pw.TableRow _buildHeaderRow(PkPdfTableConfig config) {
    return pw.TableRow(
      decoration: pw.BoxDecoration(color: config.headerBackground),
      children: config.columns.map((col) {
        return pw.Padding(
          padding: config.cellPadding,
          child: pw.Align(
            alignment: col.alignment,
            child: pw.Text(
              col.header,
              style: pw.TextStyle(
                fontSize: config.headerFontSize,
                fontWeight: pw.FontWeight.bold,
                color: config.headerTextColor,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  static pw.TableRow _buildDataRow(
    PkPdfTableConfig config,
    List<String> row,
    int index,
  ) {
    final bg = config.alternateRowColor != null && index.isOdd
        ? config.alternateRowColor
        : null;

    return pw.TableRow(
      decoration: bg != null ? pw.BoxDecoration(color: bg) : null,
      children: List.generate(config.columns.length, (colIndex) {
        final value = colIndex < row.length ? row[colIndex] : '';
        return pw.Padding(
          padding: config.cellPadding,
          child: pw.Align(
            alignment: config.columns[colIndex].alignment,
            child: pw.Text(
              value,
              style: pw.TextStyle(fontSize: config.cellFontSize),
            ),
          ),
        );
      }),
    );
  }
}
