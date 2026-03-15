import 'package:flutter/material.dart';

import '../../core.dart';
import 'speech_locale.dart';
import 'speech_service.dart';

/// Configuration for [PkListeningDialog].
final class PkListeningDialogConfig {
  const PkListeningDialogConfig({
    this.locale,
    this.promptText,
    this.processingText,
    this.hintText,
    this.maxDuration = const Duration(seconds: 30),
    this.pauseDuration = const Duration(seconds: 3),
  });

  /// The locale for speech recognition.
  final PkSpeechLocale? locale;

  /// Text shown while listening (defaults to `'Listening...'`).
  final String? promptText;

  /// Text shown while processing (defaults to `'Processing...'`).
  final String? processingText;

  /// Hint text shown below the mic (defaults to `'Tap the microphone to stop'`).
  final String? hintText;

  /// Maximum duration for listening.
  final Duration maxDuration;

  /// Duration of silence before auto-stop.
  final Duration pauseDuration;
}

/// A reusable listening dialog that shows real-time speech recognition feedback.
///
/// Shows an animated microphone indicator with sound wave visualization,
/// real-time transcription, and cancel/confirm controls.
///
/// Use the static [show] method for the simplest integration:
/// ```dart
/// final result = await PkListeningDialog.show(context);
/// if (result != null) {
///   // Use the recognized text
/// }
/// ```
class PkListeningDialog extends StatefulWidget {
  const PkListeningDialog({
    super.key,
    this.config = const PkListeningDialogConfig(),
  });

  /// Configuration for the dialog behavior and appearance.
  final PkListeningDialogConfig config;

  /// Shows the listening dialog and returns the recognized text.
  ///
  /// Returns `null` if the user cancels or no speech is detected.
  static Future<String?> show(
    BuildContext context, {
    PkListeningDialogConfig config = const PkListeningDialogConfig(),
  }) {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PkListeningDialog(config: config),
    );
  }

  @override
  State<PkListeningDialog> createState() => _PkListeningDialogState();
}

class _PkListeningDialogState extends State<PkListeningDialog>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final AnimationController _waveController;
  late final Animation<double> _pulseAnimation;
  late final Animation<double> _waveAnimation;

  String _currentResult = '';
  bool _isProcessing = false;
  bool _hasError = false;
  String _errorMessage = '';

  PkListeningDialogConfig get _config => widget.config;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startListening();
  }

  void _initAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _waveController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _waveAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _waveController,
      curve: Curves.easeInOut,
    ));

    _pulseController.repeat(reverse: true);
    _waveController.repeat(reverse: true);
  }

  Future<void> _startListening() async {
    final speech = PkSpeechService.instance;

    try {
      if (!speech.isInitialized) {
        await speech.initialize();
      }

      await speech.startListening(
        onResult: _handleResult,
        options: PkSpeechListenOptions(
          locale: _config.locale,
          listenFor: _config.maxDuration,
          pauseFor: _config.pauseDuration,
        ),
      );
    } on PrimekitException catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e.userMessage;
        });
      }
    }
  }

  void _handleResult(PkSpeechResult result) {
    if (!mounted) return;

    setState(() {
      _currentResult = result.recognizedWords;
    });

    if (result.isFinal && result.recognizedWords.isNotEmpty) {
      _confirmResult(result.recognizedWords);
    }
  }

  void _confirmResult(String text) {
    if (!mounted) return;
    setState(() {
      _isProcessing = true;
    });
    Navigator.of(context).pop(text);
  }

  Future<void> _handleCancel() async {
    await PkSpeechService.instance.cancelListening();
    if (mounted) {
      Navigator.of(context).pop(null);
    }
  }

  Future<void> _handleStop() async {
    await PkSpeechService.instance.stopListening();
    if (mounted) {
      if (_currentResult.isNotEmpty) {
        _confirmResult(_currentResult);
      } else {
        Navigator.of(context).pop(null);
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return _buildErrorDialog(context);
    }
    return _buildListeningDialog(context);
  }

  Widget _buildErrorDialog(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.mic_off,
              size: 48,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage,
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('OK'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListeningDialog(BuildContext context) {
    final theme = Theme.of(context);
    final promptText = _isProcessing
        ? (_config.processingText ?? 'Processing...')
        : (_config.promptText ?? 'Listening...');

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTitle(theme, promptText),
            const SizedBox(height: 24),
            _buildMicrophoneArea(theme),
            const SizedBox(height: 24),
            _buildResultArea(theme),
            const SizedBox(height: 24),
            if (_isProcessing) ...[
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
            ],
            _buildHintText(theme),
            const SizedBox(height: 16),
            _buildActions(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildTitle(ThemeData theme, String text) {
    return Text(
      text,
      style: theme.textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.bold,
        color: _isProcessing
            ? theme.colorScheme.secondary
            : theme.colorScheme.primary,
      ),
    );
  }

  Widget _buildMicrophoneArea(ThemeData theme) {
    return SizedBox(
      height: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ...List.generate(
            3,
            (index) => _buildWaveRing(theme, index),
          ),
          _buildPulsingMic(theme),
        ],
      ),
    );
  }

  Widget _buildWaveRing(ThemeData theme, int index) {
    return AnimatedBuilder(
      animation: _waveAnimation,
      builder: (context, child) => Container(
        width: 60 + (index * 20) + (_waveAnimation.value * 15),
        height: 60 + (index * 20) + (_waveAnimation.value * 15),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: theme.colorScheme.primary.withValues(
              alpha: (0.3 - index * 0.1) * (1 - _waveAnimation.value),
            ),
            width: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildPulsingMic(ThemeData theme) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) => Transform.scale(
        scale: _pulseAnimation.value,
        child: InkWell(
          onTap: _isProcessing ? null : _handleStop,
          borderRadius: BorderRadius.circular(30),
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: _isProcessing
                  ? theme.colorScheme.secondary
                  : theme.colorScheme.primary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (_isProcessing
                          ? theme.colorScheme.secondary
                          : theme.colorScheme.primary)
                      .withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              _isProcessing ? Icons.psychology : Icons.mic,
              color: theme.colorScheme.onPrimary,
              size: 32,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultArea(ThemeData theme) {
    final displayText = _isProcessing
        ? 'Processing your request...\n"$_currentResult"'
        : (_currentResult.isEmpty ? 'Say something...' : _currentResult);

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 60),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        displayText,
        style: theme.textTheme.bodyLarge?.copyWith(
          color: (_currentResult.isEmpty && !_isProcessing)
              ? theme.colorScheme.onSurface.withValues(alpha: 0.6)
              : theme.colorScheme.onSurface,
          fontStyle:
              (_currentResult.isEmpty && !_isProcessing) ? FontStyle.italic : null,
        ),
        textAlign: TextAlign.center,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildHintText(ThemeData theme) {
    final hint = _isProcessing
        ? (_config.processingText ?? 'Processing...')
        : (_config.hintText ?? 'Tap the microphone to stop listening');

    return Text(
      hint,
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildActions(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TextButton.icon(
          onPressed: _isProcessing ? null : _handleCancel,
          icon: const Icon(Icons.close),
          label: const Text('Cancel'),
        ),
      ],
    );
  }
}
