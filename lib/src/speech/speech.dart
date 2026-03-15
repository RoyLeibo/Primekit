// Primekit speech module.
//
// Provides speech-to-text recognition with automatic microphone permission
// handling via PrimeKit's permissions module.
export '../core/exceptions.dart' show SpeechException, SpeechPermissionException;
export 'listening_dialog.dart' show PkListeningDialog, PkListeningDialogConfig;
export 'speech_locale.dart' show PkSpeechLocale;
export 'speech_service.dart'
    show PkSpeechListenOptions, PkSpeechResult, PkSpeechService;
