// Chat exceptions are defined in core/exceptions.dart alongside other
// PrimekitException subtypes (sealed class constraint).
//
// This file re-exports them for convenience:
//   import 'package:primekit/chat.dart'; // includes ChatException
export '../core/exceptions.dart' show ChatException, MessageValidationException;
