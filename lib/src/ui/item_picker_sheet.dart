import 'dart:async';

import 'package:flutter/material.dart';

import '../design_system/pk_radius.dart';
import '../design_system/pk_spacing.dart';

/// A generic searchable bottom sheet for selecting items from a list.
///
/// Supports both single-select and multi-select modes. The caller provides
/// the full item list, a builder for each row, and a search predicate.
///
/// ```dart
/// final result = await PkItemPickerSheet.show<Country>(
///   context: context,
///   title: 'Select Country',
///   items: allCountries,
///   itemBuilder: (country, isSelected) => ListTile(
///     title: Text(country.name),
///     trailing: isSelected ? Icon(Icons.check) : null,
///   ),
///   searchPredicate: (country, query) =>
///       country.name.toLowerCase().contains(query.toLowerCase()),
/// );
/// ```
class PkItemPickerSheet<T> extends StatefulWidget {
  /// All available items.
  final List<T> items;

  /// Builds the widget for each item row.
  final Widget Function(T item, bool isSelected) itemBuilder;

  /// Returns true if [item] matches the search [query].
  final bool Function(T item, String query) searchPredicate;

  /// Sheet title.
  final String title;

  /// Initially selected items.
  final List<T> initialSelection;

  /// Whether multiple items can be selected.
  final bool multiSelect;

  /// Maximum selections allowed in multi-select mode.
  final int? maxSelections;

  /// Called when the user confirms their selection.
  final ValueChanged<List<T>>? onSelect;

  /// Text for the confirm button. Defaults to "Done".
  final String confirmLabel;

  /// Hint text in the search field.
  final String searchHint;

  /// Debounce duration for search input.
  final Duration searchDebounce;

  /// Equality comparator for items. Defaults to `==`.
  final bool Function(T a, T b)? itemEquals;

  const PkItemPickerSheet({
    super.key,
    required this.items,
    required this.itemBuilder,
    required this.searchPredicate,
    this.title = 'Select',
    this.initialSelection = const [],
    this.multiSelect = false,
    this.maxSelections,
    this.onSelect,
    this.confirmLabel = 'Done',
    this.searchHint = 'Search...',
    this.searchDebounce = const Duration(milliseconds: 300),
    this.itemEquals,
  });

  /// Show the picker as a modal bottom sheet and return the selection.
  static Future<List<T>?> show<T>({
    required BuildContext context,
    required List<T> items,
    required Widget Function(T item, bool isSelected) itemBuilder,
    required bool Function(T item, String query) searchPredicate,
    String title = 'Select',
    List<T> initialSelection = const [],
    bool multiSelect = false,
    int? maxSelections,
    String confirmLabel = 'Done',
    String searchHint = 'Search...',
    bool Function(T a, T b)? itemEquals,
  }) {
    return showModalBottomSheet<List<T>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(PkRadius.xl),
        ),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => PkItemPickerSheet<T>(
          items: items,
          itemBuilder: itemBuilder,
          searchPredicate: searchPredicate,
          title: title,
          initialSelection: initialSelection,
          multiSelect: multiSelect,
          maxSelections: maxSelections,
          confirmLabel: confirmLabel,
          searchHint: searchHint,
          itemEquals: itemEquals,
        ),
      ),
    );
  }

  @override
  State<PkItemPickerSheet<T>> createState() => _PkItemPickerSheetState<T>();
}

class _PkItemPickerSheetState<T> extends State<PkItemPickerSheet<T>> {
  final _searchController = TextEditingController();
  Timer? _debounceTimer;
  String _query = '';
  late List<T> _selected;

  bool _itemEquals(T a, T b) =>
      widget.itemEquals?.call(a, b) ?? (a == b);

  bool _isSelected(T item) =>
      _selected.any((s) => _itemEquals(s, item));

  @override
  void initState() {
    super.initState();
    _selected = List<T>.of(widget.initialSelection);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(widget.searchDebounce, () {
      if (mounted && _query != value) {
        setState(() => _query = value);
      }
    });
  }

  void _toggleItem(T item) {
    setState(() {
      if (widget.multiSelect) {
        if (_isSelected(item)) {
          _selected = [
            for (final s in _selected)
              if (!_itemEquals(s, item)) s,
          ];
        } else {
          final max = widget.maxSelections;
          if (max != null && _selected.length >= max) return;
          _selected = [..._selected, item];
        }
      } else {
        _selected = [item];
      }
    });

    // Single-select: auto-confirm
    if (!widget.multiSelect) {
      _confirm();
    }
  }

  void _confirm() {
    widget.onSelect?.call(_selected);
    Navigator.of(context).pop(_selected);
  }

  List<T> get _filteredItems {
    if (_query.isEmpty) return widget.items;
    return [
      for (final item in widget.items)
        if (widget.searchPredicate(item, _query)) item,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filtered = _filteredItems;

    return Column(
      children: [
        // Handle
        Padding(
          padding: const EdgeInsets.only(top: PkSpacing.md),
          child: Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(PkRadius.full),
              ),
            ),
          ),
        ),
        // Header
        Padding(
          padding: const EdgeInsets.all(PkSpacing.lg),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
              Expanded(
                child: Text(
                  widget.title,
                  style: theme.textTheme.titleLarge,
                ),
              ),
              if (widget.multiSelect && _selected.isNotEmpty)
                TextButton(
                  onPressed: _confirm,
                  child: Text(widget.confirmLabel),
                ),
            ],
          ),
        ),
        // Selection count
        if (widget.multiSelect && _selected.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: PkSpacing.lg),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: PkSpacing.sm),
                Text(
                  '${_selected.length}'
                  '${widget.maxSelections != null ? ' of ${widget.maxSelections}' : ''}'
                  ' selected',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        // Search
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: PkSpacing.lg,
            vertical: PkSpacing.sm,
          ),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: widget.searchHint,
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(PkRadius.md),
              ),
            ),
            onChanged: _onSearchChanged,
          ),
        ),
        // List
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Text(
                    'No items found',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: PkSpacing.lg,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    return GestureDetector(
                      onTap: () => _toggleItem(item),
                      behavior: HitTestBehavior.opaque,
                      child: widget.itemBuilder(item, _isSelected(item)),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
