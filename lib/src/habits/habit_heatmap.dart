import 'package:flutter/material.dart';

/// GitHub-style completion heatmap widget for habit tracking.
///
/// Renders a scrollable 52x7 grid of cells coloured by completion intensity.
/// Parameterized for reuse across any app: provide [data] (date -> count),
/// optional [accentColor], [cellSize], [daysBack], and [onDayTap].
class PkHabitHeatmap extends StatefulWidget {
  /// Completion data: date (normalized to midnight) -> count.
  final Map<DateTime, int> data;

  /// Accent colour for filled cells. Falls back to [Theme.colorScheme.primary].
  final Color? accentColor;

  /// Side length of each day cell in logical pixels.
  final double cellSize;

  /// Number of days to display (default 364 = 52 weeks).
  final int daysBack;

  /// Optional callback when a day cell is tapped.
  final void Function(DateTime date, int count)? onDayTap;

  /// Background colour for empty cells. Falls back to a ghost white.
  final Color? emptyCellColor;

  const PkHabitHeatmap({
    super.key,
    required this.data,
    this.accentColor,
    this.cellSize = 10,
    this.daysBack = 364,
    this.onDayTap,
    this.emptyCellColor,
  });

  @override
  State<PkHabitHeatmap> createState() => _PkHabitHeatmapState();
}

class _PkHabitHeatmapState extends State<PkHabitHeatmap> {
  static const int _daysPerWeek = 7;
  static const double _cellGap = 2;
  static const double _monthLabelHeight = 16;

  late ScrollController _scrollController;
  late Map<String, int> _keyedData;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _keyedData = _buildKeyedData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  @override
  void didUpdateWidget(PkHabitHeatmap old) {
    super.didUpdateWidget(old);
    if (old.data != widget.data) {
      _keyedData = _buildKeyedData();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Map<String, int> _buildKeyedData() {
    final result = <String, int>{};
    for (final entry in widget.data.entries) {
      result[_dayKey(entry.key)] = entry.value;
    }
    return result;
  }

  static String _dayKey(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  static DateTime _mondayOf(DateTime date) =>
      DateTime(date.year, date.month, date.day)
          .subtract(Duration(days: date.weekday - 1));

  int _intensity(String key) {
    final count = _keyedData[key] ?? 0;
    if (count == 0) return 0;
    if (count == 1) return 1;
    if (count == 2) return 2;
    return 3;
  }

  Color _cellColor(int intensity, Color accent) {
    return switch (intensity) {
      1 => accent.withValues(alpha: 0.30),
      2 => accent.withValues(alpha: 0.60),
      3 => accent,
      _ => widget.emptyCellColor ?? const Color(0x1FFFFFFF),
    };
  }

  @override
  Widget build(BuildContext context) {
    final accent =
        widget.accentColor ?? Theme.of(context).colorScheme.primary;
    final textColor = Theme.of(context).colorScheme.onSurfaceVariant;

    final today = DateTime.now();
    final todayNorm = DateTime(today.year, today.month, today.day);
    final weeks = (widget.daysBack / _daysPerWeek).ceil();
    final startMonday =
        _mondayOf(todayNorm.subtract(Duration(days: (weeks - 1) * 7)));

    final weekMondays = List.generate(
      weeks,
      (w) => startMonday.add(Duration(days: w * 7)),
    );

    final totalWidth = weeks * (widget.cellSize + _cellGap) - _cellGap;
    final totalHeight = _monthLabelHeight +
        _cellGap +
        _daysPerWeek * (widget.cellSize + _cellGap) -
        _cellGap;

    return SizedBox(
      height: totalHeight,
      child: SingleChildScrollView(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: totalWidth,
          child: CustomPaint(
            size: Size(totalWidth, totalHeight),
            painter: _HeatmapPainter(
              weekMondays: weekMondays,
              todayNorm: todayNorm,
              accent: accent,
              keyedData: _keyedData,
              cellSize: widget.cellSize,
              cellGap: _cellGap,
              monthLabelHeight: _monthLabelHeight,
              intensityFn: _intensity,
              cellColorFn: _cellColor,
              textColor: textColor,
              emptyCellColor:
                  widget.emptyCellColor ?? const Color(0x1FFFFFFF),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Custom painter
// ---------------------------------------------------------------------------

class _HeatmapPainter extends CustomPainter {
  final List<DateTime> weekMondays;
  final DateTime todayNorm;
  final Color accent;
  final Map<String, int> keyedData;
  final double cellSize;
  final double cellGap;
  final double monthLabelHeight;
  final int Function(String) intensityFn;
  final Color Function(int, Color) cellColorFn;
  final Color textColor;
  final Color emptyCellColor;

  const _HeatmapPainter({
    required this.weekMondays,
    required this.todayNorm,
    required this.accent,
    required this.keyedData,
    required this.cellSize,
    required this.cellGap,
    required this.monthLabelHeight,
    required this.intensityFn,
    required this.cellColorFn,
    required this.textColor,
    required this.emptyCellColor,
  });

  static const List<String> _monthAbbr = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  static String _dayKey(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..isAntiAlias = false;
    final cellRadius = const Radius.circular(2);
    int? lastLabelledMonth;

    for (var w = 0; w < weekMondays.length; w++) {
      final monday = weekMondays[w];
      final x = w * (cellSize + cellGap);

      if (monday.month != lastLabelledMonth) {
        lastLabelledMonth = monday.month;
        final tp = TextPainter(
          text: TextSpan(
            text: _monthAbbr[monday.month - 1],
            style: TextStyle(
              fontSize: 9,
              color: textColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(x, 0));
      }

      for (var d = 0; d < 7; d++) {
        final day = monday.add(Duration(days: d));
        if (day.isAfter(todayNorm)) continue;

        final key = _dayKey(day);
        final intensity = intensityFn(key);
        paint.color = cellColorFn(intensity, accent);

        final y = monthLabelHeight + cellGap + d * (cellSize + cellGap);
        final rect = RRect.fromLTRBR(
          x, y, x + cellSize, y + cellSize, cellRadius,
        );
        canvas.drawRRect(rect, paint);

        if (day == todayNorm) {
          final borderPaint = Paint()
            ..color = accent
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5;
          canvas.drawRRect(rect, borderPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(_HeatmapPainter old) =>
      old.keyedData != keyedData ||
      old.accent != accent ||
      old.todayNorm != todayNorm;
}
