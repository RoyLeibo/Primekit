import 'dart:typed_data';

/// A simplified contact with display name, email, and optional photo.
class PkContact {
  const PkContact({
    required this.displayName,
    required this.email,
    this.photoBytes,
  });

  final String displayName;
  final String email;
  final Uint8List? photoBytes;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PkContact &&
          runtimeType == other.runtimeType &&
          email == other.email;

  @override
  int get hashCode => email.hashCode;
}
