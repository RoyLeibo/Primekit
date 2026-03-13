/// Immutable configuration for legal document URLs.
///
/// Pass once at app initialisation and supply wherever [LegalLinksWidget]
/// or [LegalConsentWidget] is used.
///
/// ```dart
/// const config = LegalLinksConfig(
///   privacyPolicyUrl: 'https://example.com/privacy',
///   termsOfServiceUrl: 'https://example.com/terms',
/// );
/// ```
class LegalLinksConfig {
  /// Creates an immutable legal links configuration.
  ///
  /// [privacyPolicyUrl] and [termsOfServiceUrl] are both nullable — a link is
  /// only rendered when the corresponding value is non-null.
  const LegalLinksConfig({
    this.privacyPolicyUrl,
    this.termsOfServiceUrl,
    this.privacyPolicyLabel = 'Privacy Policy',
    this.termsOfServiceLabel = 'Terms of Service',
  });

  /// URL of the Privacy Policy document. Omit to hide the link.
  final String? privacyPolicyUrl;

  /// URL of the Terms of Service document. Omit to hide the link.
  final String? termsOfServiceUrl;

  /// Display label for the Privacy Policy link.
  ///
  /// Defaults to `'Privacy Policy'`.
  final String privacyPolicyLabel;

  /// Display label for the Terms of Service link.
  ///
  /// Defaults to `'Terms of Service'`.
  final String termsOfServiceLabel;

  /// Returns a copy of this config with the given fields replaced.
  LegalLinksConfig copyWith({
    String? privacyPolicyUrl,
    String? termsOfServiceUrl,
    String? privacyPolicyLabel,
    String? termsOfServiceLabel,
  }) {
    return LegalLinksConfig(
      privacyPolicyUrl: privacyPolicyUrl ?? this.privacyPolicyUrl,
      termsOfServiceUrl: termsOfServiceUrl ?? this.termsOfServiceUrl,
      privacyPolicyLabel: privacyPolicyLabel ?? this.privacyPolicyLabel,
      termsOfServiceLabel: termsOfServiceLabel ?? this.termsOfServiceLabel,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LegalLinksConfig &&
          runtimeType == other.runtimeType &&
          privacyPolicyUrl == other.privacyPolicyUrl &&
          termsOfServiceUrl == other.termsOfServiceUrl &&
          privacyPolicyLabel == other.privacyPolicyLabel &&
          termsOfServiceLabel == other.termsOfServiceLabel;

  @override
  int get hashCode => Object.hash(
    privacyPolicyUrl,
    termsOfServiceUrl,
    privacyPolicyLabel,
    termsOfServiceLabel,
  );

  @override
  String toString() =>
      'LegalLinksConfig('
      'privacyPolicyUrl: $privacyPolicyUrl, '
      'termsOfServiceUrl: $termsOfServiceUrl, '
      'privacyPolicyLabel: $privacyPolicyLabel, '
      'termsOfServiceLabel: $termsOfServiceLabel)';
}
