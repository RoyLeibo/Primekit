# export — PDF, CSV, and File Sharing

**Purpose:** Generic, immutable builders for PDF documents and CSV files, plus platform-aware sharing/download.

**Key exports:**
- `PkPdfBuilder` — fluent immutable PDF builder: `addTitle()`, `addBanner()`, `addSection()`, `addTable()`, `addText()`, `addCallout()`, `addSpacing()`, `addPageBreak()`, `addWidget()`, `build()` -> `Uint8List`
- `PkPdfSection` — section with title + content widgets
- `PkPdfTableConfig` — table rendering config (columns, rows, colors, padding)
- `PkPdfTableColumn` — column definition (header, width, alignment)
- `PkPdfPageConfig` — page format, margins, page numbering
- `PkCsvBuilder<T>` — immutable CSV builder: `addHeaders()`, `addRow()`, `addRows()`, `build()` -> `String`
  - `PkCsvBuilder.fromList()` — factory from typed list + column extractors
- `PkExportShare` — platform-conditional (web blob download vs mobile share sheet)
  - `shareFile()`, `shareText()`, `sharePdf()`, `shareCsv()`

**Dependencies:** `pdf`, `printing`, `share_plus`, `path_provider` (mobile only via conditional export).

**Consumers:** PawTrack (health reports, travel passports, insurance exports), Splitly (expense CSV + PDF reports).

**Maintenance:** Update when builder API changes or new export format added.
