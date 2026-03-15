import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../core.dart';
import '../../permissions.dart';
import 'speech_locale.dart';

/// Configuration for a speech listening session.
final class PkSpeechListenOptions {
  const PkSpeechListenOptions({
    this.locale,
    this.pauseFor = const Duration(seconds: 3),
    this.listenFor = const Duration(seconds: 30),
    this.partialResults = true,
    this.autoPunctuation = true,
    this.enableHapticFeedback = true,
  });

  /// The locale to use for speech recognition.
  /// Defaults to system locale if not provided.
  final PkSpeechLocale? locale;

  /// Duration of silence before speech recognition automatically stops.
  final Duration pauseFor;

  /// Maximum duration to listen before automatically stopping.
  final Duration listenFor;

  /// Whether to emit partial (in-progress) results.
  final bool partialResults;

  /// Whether to enable automatic punctuation.
  final bool autoPunctuation;

  /// Whether to enable haptic feedback during listening.
  final bool enableHapticFeedback;
}

/// A speech recognition result delivered via the [onResult] callback.
final class PkSpeechResult {
  const PkSpeechResult({
    required this.recognizedWords,
    required this.isFinal,
  });

  /// The recognized text so far.
  final String recognizedWords;

  /// Whether this is the final result (speech recognition has finished).
  final bool isFinal;
}

/// Core speech-to-text service for PrimeKit.
///
/// Wraps the `speech_to_text` package and integrates with PrimeKit's
/// permissions module for automatic microphone permission handling.
///
/// Usage:
/// ```dart
/// final speech = PkSpeechService.instance;
/// await speech.initialize();
///
/// await speech.startListening(
///   onResult: (result) {
///     print(result.recognizedWords);
///   },
/// );
/// ```
final class PkSpeechService {
  PkSpeechService._();

  static final PkSpeechService _instance = PkSpeechService._();

  /// The singleton instance of [PkSpeechService].
  static PkSpeechService get instance => _instance;

  static const String _tag = 'PkSpeechService';

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isInitialized = false;

  /// Whether the speech recognition engine has been initialized.
  bool get isInitialized => _isInitialized;

  /// Whether the device supports speech recognition.
  bool get isAvailable => _isInitialized;

  /// Whether speech recognition is currently active.
  bool get isListening => _speech.isListening;

  /// Initializes the speech recognition engine.
  ///
  /// Automatically requests microphone permission via PrimeKit's
  /// [PermissionHelper]. Throws [SpeechException] if initialization fails.
  Future<void> initialize() async {
    if (_isInitialized) return;

    final micGranted = await PermissionHelper.request(PkPermission.microphone);
    if (!micGranted) {
      PrimekitLogger.warning(
        'Microphone permission denied during initialization',
        tag: _tag,
      );
      throw const SpeechPermissionException();
    }

    try {
      final available = await _speech.initialize(
        onStatus: (status) => PrimekitLogger.verbose(
          'Speech status: $status',
          tag: _tag,
        ),
        onError: (error) => PrimekitLogger.warning(
          'Speech error: ${error.errorMsg}',
          tag: _tag,
        ),
      );

      if (!available) {
        throw const SpeechException(
          message: 'Speech recognition not available on this device',
          code: 'NOT_AVAILABLE',
        );
      }

      _isInitialized = true;
      PrimekitLogger.info('Speech recognition initialized', tag: _tag);
    } catch (e) {
      if (e is PrimekitException) rethrow;
      PrimekitLogger.error(
        'Failed to initialize speech recognition: $e',
        tag: _tag,
      );
      throw SpeechException(
        message: 'Failed to initialize speech recognition',
        code: 'INIT_FAILED',
        cause: e,
      );
    }
  }

  /// Starts listening for speech input.
  ///
  /// [onResult] is called with each recognition result (partial and final).
  /// [options] configures the listening session.
  ///
  /// Throws [SpeechException] if not initialized or if listening fails.
  Future<void> startListening({
    required void Function(PkSpeechResult result) onResult,
    PkSpeechListenOptions options = const PkSpeechListenOptions(),
  }) async {
    _ensureInitialized();

    final locale = options.locale ?? PkSpeechLocale.fromSystem();

    try {
      await _speech.listen(
        onResult: (val) {
          final result = PkSpeechResult(
            recognizedWords: val.recognizedWords,
            isFinal: val.finalResult,
          );
          onResult(result);
        },
        listenOptions: stt.SpeechListenOptions(
          partialResults: options.partialResults,
          cancelOnError: true,
          listenMode: stt.ListenMode.confirmation,
          autoPunctuation: options.autoPunctuation,
          enableHapticFeedback: options.enableHapticFeedback,
        ),
        pauseFor: options.pauseFor,
        listenFor: options.listenFor,
        localeId: locale.localeId,
      );

      PrimekitLogger.info(
        'Started listening with locale: ${locale.localeId}',
        tag: _tag,
      );
    } catch (e) {
      PrimekitLogger.error('Failed to start listening: $e', tag: _tag);
      throw SpeechException(
        message: 'Failed to start speech recognition',
        code: 'LISTEN_FAILED',
        cause: e,
      );
    }
  }

  /// Stops listening and finalizes the current recognition result.
  Future<void> stopListening() async {
    try {
      await _speech.stop();
      PrimekitLogger.info('Stopped listening', tag: _tag);
    } catch (e) {
      PrimekitLogger.warning('Error stopping speech: $e', tag: _tag);
    }
  }

  /// Cancels the current listening session without finalizing.
  Future<void> cancelListening() async {
    try {
      await _speech.cancel();
      PrimekitLogger.info('Cancelled listening', tag: _tag);
    } catch (e) {
      PrimekitLogger.warning('Error cancelling speech: $e', tag: _tag);
    }
  }

  /// Returns the list of available speech recognition locales.
  ///
  /// Throws [SpeechException] if not initialized.
  Future<List<PkSpeechLocale>> availableLocales() async {
    _ensureInitialized();

    try {
      final locales = await _speech.locales();
      return List.unmodifiable(
        locales.map(
          (l) => PkSpeechLocale(
            localeId: l.localeId,
            name: l.name,
          ),
        ),
      );
    } catch (e) {
      PrimekitLogger.warning('Failed to get locales: $e', tag: _tag);
      throw SpeechException(
        message: 'Failed to retrieve available locales',
        code: 'LOCALES_FAILED',
        cause: e,
      );
    }
  }

  void _ensureInitialized() {
    if (!_isInitialized) {
      throw const SpeechException(
        message: 'PkSpeechService has not been initialized. '
            'Call initialize() first.',
        code: 'NOT_INITIALIZED',
      );
    }
  }
}
