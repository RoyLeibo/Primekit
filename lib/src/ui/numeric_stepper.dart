import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../design_system/pk_radius.dart';
import '../design_system/pk_spacing.dart';

/// A generic numeric stepper with +/- buttons.
///
/// Supports tap and long-press for rapid value changes. Fully parameterized
/// with min/max bounds, step size, and custom label formatting.
///
/// ```dart
/// PkNumericStepper(
///   value: 3,
///   min: 0,
///   max: 99,
///   onChanged: (v) => setState(() => _score = v),
/// )
/// ```
class PkNumericStepper extends StatefulWidget {
  /// Current value.
  final int value;

  /// Minimum allowed value.
  final int min;

  /// Maximum allowed value.
  final int max;

  /// Step amount per tap/tick.
  final int step;

  /// Called when the value changes.
  final ValueChanged<int> onChanged;

  /// Custom label formatter. Defaults to `value.toString()`.
  final String Function(int value)? formatLabel;

  /// Button size (width and height).
  final double buttonSize;

  /// Icon size inside the buttons.
  final double iconSize;

  /// Color for the +/- icons.
  final Color? iconColor;

  /// Background color for the buttons.
  final Color? buttonColor;

  /// Color for a disabled button.
  final Color? disabledColor;

  /// Text style for the value display.
  final TextStyle? valueStyle;

  /// Width of the value display area.
  final double valueWidth;

  /// Interval between ticks during long-press (milliseconds).
  final int longPressIntervalMs;

  /// Haptic feedback on each value change.
  final bool enableHaptics;

  const PkNumericStepper({
    super.key,
    required this.value,
    this.min = 0,
    this.max = 99,
    this.step = 1,
    required this.onChanged,
    this.formatLabel,
    this.buttonSize = 40,
    this.iconSize = 20,
    this.iconColor,
    this.buttonColor,
    this.disabledColor,
    this.valueStyle,
    this.valueWidth = 48,
    this.longPressIntervalMs = 120,
    this.enableHaptics = true,
  });

  @override
  State<PkNumericStepper> createState() => _PkNumericStepperState();
}

class _PkNumericStepperState extends State<PkNumericStepper> {
  Timer? _longPressTimer;

  bool get _canDecrement => widget.value - widget.step >= widget.min;
  bool get _canIncrement => widget.value + widget.step <= widget.max;

  void _increment() {
    if (!_canIncrement) return;
    final next = (widget.value + widget.step).clamp(widget.min, widget.max);
    if (widget.enableHaptics) HapticFeedback.selectionClick();
    widget.onChanged(next);
  }

  void _decrement() {
    if (!_canDecrement) return;
    final next = (widget.value - widget.step).clamp(widget.min, widget.max);
    if (widget.enableHaptics) HapticFeedback.selectionClick();
    widget.onChanged(next);
  }

  void _startLongPress(void Function() action) {
    action();
    _longPressTimer = Timer.periodic(
      Duration(milliseconds: widget.longPressIntervalMs),
      (_) => action(),
    );
  }

  void _stopLongPress() {
    _longPressTimer?.cancel();
    _longPressTimer = null;
  }

  @override
  void dispose() {
    _stopLongPress();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveIconColor =
        widget.iconColor ?? theme.colorScheme.onSurface;
    final effectiveButtonColor =
        widget.buttonColor ?? theme.colorScheme.surfaceContainerHighest;
    final effectiveDisabledColor =
        widget.disabledColor ??
        theme.colorScheme.onSurface.withValues(alpha: 0.2);
    final effectiveValueStyle = widget.valueStyle ??
        theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
        );

    final label = widget.formatLabel?.call(widget.value) ??
        widget.value.toString();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _StepperButton(
          icon: Icons.remove,
          enabled: _canDecrement,
          size: widget.buttonSize,
          iconSize: widget.iconSize,
          iconColor: effectiveIconColor,
          backgroundColor: effectiveButtonColor,
          disabledColor: effectiveDisabledColor,
          onTap: _decrement,
          onLongPressStart: () => _startLongPress(_decrement),
          onLongPressEnd: _stopLongPress,
        ),
        SizedBox(
          width: widget.valueWidth,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: effectiveValueStyle,
          ),
        ),
        _StepperButton(
          icon: Icons.add,
          enabled: _canIncrement,
          size: widget.buttonSize,
          iconSize: widget.iconSize,
          iconColor: effectiveIconColor,
          backgroundColor: effectiveButtonColor,
          disabledColor: effectiveDisabledColor,
          onTap: _increment,
          onLongPressStart: () => _startLongPress(_increment),
          onLongPressEnd: _stopLongPress,
        ),
      ],
    );
  }
}

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final double size;
  final double iconSize;
  final Color iconColor;
  final Color backgroundColor;
  final Color disabledColor;
  final VoidCallback onTap;
  final VoidCallback onLongPressStart;
  final VoidCallback onLongPressEnd;

  const _StepperButton({
    required this.icon,
    required this.enabled,
    required this.size,
    required this.iconSize,
    required this.iconColor,
    required this.backgroundColor,
    required this.disabledColor,
    required this.onTap,
    required this.onLongPressStart,
    required this.onLongPressEnd,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      onLongPressStart: enabled ? (_) => onLongPressStart() : null,
      onLongPressEnd: enabled ? (_) => onLongPressEnd() : null,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: enabled ? backgroundColor : backgroundColor,
          borderRadius: BorderRadius.circular(PkRadius.sm),
        ),
        child: Icon(
          icon,
          size: iconSize,
          color: enabled ? iconColor : disabledColor,
        ),
      ),
    );
  }
}
