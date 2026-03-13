import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'legal_links_config.dart';

// ---------------------------------------------------------------------------
// LegalLinksWidget
// ---------------------------------------------------------------------------

/// Renders Privacy Policy and/or Terms of Service hyperlinks.
///
/// Links are only shown when the corresponding URL in [config] is non-null.
/// Supports both horizontal (inline) and vertical layouts.
///
/// ```dart
/// // Horizontal row (default) — suitable for login screens
/// LegalLinksWidget(
///   config: LegalLinksConfig(
///     privacyPolicyUrl: 'https://example.com/privacy',
///     termsOfServiceUrl: 'https://example.com/terms',
///   ),
/// )
///
/// // Vertical column
/// LegalLinksWidget(
///   config: config,
///   axis: Axis.vertical,
/// )
/// ```
class LegalLinksWidget extends StatelessWidget {
  /// Creates a [LegalLinksWidget].
  const LegalLinksWidget({
    required this.config,
    this.axis = Axis.horizontal,
    this.textStyle,
    this.linkColor,
    this.separator = ' · ',
    super.key,
  });

  /// Legal document URLs and labels.
  final LegalLinksConfig config;

  /// Layout direction. Defaults to [Axis.horizontal].
  final Axis axis;

  /// Base text style applied to both separator and link text.
  /// Falls back to `Theme.of(context).textTheme.bodySmall`.
  final TextStyle? textStyle;

  /// Colour applied to link text. Falls back to `colorScheme.primary`.
  final Color? linkColor;

  /// String placed between links when [axis] is [Axis.horizontal].
  /// Defaults to `' · '`.
  final String separator;

  @override
  Widget build(BuildContext context) {
    final links = _buildLinks(context);
    if (links.isEmpty) return const SizedBox.shrink();

    if (axis == Axis.vertical) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: links
            .map(
              (link) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: link,
              ),
            )
            .toList(),
      );
    }

    // Horizontal: join links with separator text spans.
    return _HorizontalLegalLinks(
      config: config,
      textStyle: textStyle,
      linkColor: linkColor,
      separator: separator,
    );
  }

  List<Widget> _buildLinks(BuildContext context) {
    final color = linkColor ?? Theme.of(context).colorScheme.primary;
    final style =
        textStyle ?? Theme.of(context).textTheme.bodySmall ?? const TextStyle();
    final linkStyle = style.copyWith(
      color: color,
      decoration: TextDecoration.underline,
    );

    return [
      if (config.privacyPolicyUrl != null)
        GestureDetector(
          onTap: () => _launch(config.privacyPolicyUrl!),
          child: Text(config.privacyPolicyLabel, style: linkStyle),
        ),
      if (config.termsOfServiceUrl != null)
        GestureDetector(
          onTap: () => _launch(config.termsOfServiceUrl!),
          child: Text(config.termsOfServiceLabel, style: linkStyle),
        ),
    ];
  }
}

// ---------------------------------------------------------------------------
// Internal horizontal layout using RichText for inline separator
// ---------------------------------------------------------------------------

class _HorizontalLegalLinks extends StatelessWidget {
  const _HorizontalLegalLinks({
    required this.config,
    required this.separator,
    this.textStyle,
    this.linkColor,
  });

  final LegalLinksConfig config;
  final String separator;
  final TextStyle? textStyle;
  final Color? linkColor;

  @override
  Widget build(BuildContext context) {
    final color = linkColor ?? Theme.of(context).colorScheme.primary;
    final base =
        textStyle ?? Theme.of(context).textTheme.bodySmall ?? const TextStyle();
    final linkStyle = base.copyWith(
      color: color,
      decoration: TextDecoration.underline,
    );

    final spans = <InlineSpan>[];

    if (config.privacyPolicyUrl != null) {
      spans.add(
        TextSpan(
          text: config.privacyPolicyLabel,
          style: linkStyle,
          recognizer: TapGestureRecognizer()
            ..onTap = () => _launch(config.privacyPolicyUrl!),
        ),
      );
    }

    if (config.privacyPolicyUrl != null && config.termsOfServiceUrl != null) {
      spans.add(TextSpan(text: separator, style: base));
    }

    if (config.termsOfServiceUrl != null) {
      spans.add(
        TextSpan(
          text: config.termsOfServiceLabel,
          style: linkStyle,
          recognizer: TapGestureRecognizer()
            ..onTap = () => _launch(config.termsOfServiceUrl!),
        ),
      );
    }

    return RichText(text: TextSpan(children: spans));
  }
}

// ---------------------------------------------------------------------------
// LegalConsentWidget
// ---------------------------------------------------------------------------

/// A checkbox row that asks the user to agree to Privacy Policy and/or
/// Terms of Service before proceeding.
///
/// ```dart
/// LegalConsentWidget(
///   config: LegalLinksConfig(
///     privacyPolicyUrl: 'https://example.com/privacy',
///     termsOfServiceUrl: 'https://example.com/terms',
///   ),
///   value: _agreed,
///   onChanged: (v) => setState(() => _agreed = v ?? false),
/// )
/// ```
class LegalConsentWidget extends StatelessWidget {
  /// Creates a [LegalConsentWidget].
  const LegalConsentWidget({
    required this.config,
    required this.value,
    required this.onChanged,
    this.textStyle,
    this.linkColor,
    super.key,
  });

  /// Legal document URLs and labels.
  final LegalLinksConfig config;

  /// Whether the checkbox is currently checked.
  final bool value;

  /// Called when the user toggles the checkbox.
  final ValueChanged<bool?> onChanged;

  /// Style for the consent text. Falls back to `textTheme.bodySmall`.
  final TextStyle? textStyle;

  /// Colour for the hyperlinks. Falls back to `colorScheme.primary`.
  final Color? linkColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Checkbox(value: value, onChanged: onChanged),
        Flexible(child: _buildConsentText(context)),
      ],
    );
  }

  Widget _buildConsentText(BuildContext context) {
    final color = linkColor ?? Theme.of(context).colorScheme.primary;
    final base =
        textStyle ?? Theme.of(context).textTheme.bodySmall ?? const TextStyle();
    final linkStyle = base.copyWith(
      color: color,
      decoration: TextDecoration.underline,
    );

    final hasPrivacy = config.privacyPolicyUrl != null;
    final hasTerms = config.termsOfServiceUrl != null;

    final spans = <InlineSpan>[
      TextSpan(text: 'I agree to the ', style: base),
    ];

    if (hasPrivacy) {
      spans.add(
        TextSpan(
          text: config.privacyPolicyLabel,
          style: linkStyle,
          recognizer: TapGestureRecognizer()
            ..onTap = () => _launch(config.privacyPolicyUrl!),
        ),
      );
    }

    if (hasPrivacy && hasTerms) {
      spans.add(TextSpan(text: ' and ', style: base));
    }

    if (hasTerms) {
      spans.add(
        TextSpan(
          text: config.termsOfServiceLabel,
          style: linkStyle,
          recognizer: TapGestureRecognizer()
            ..onTap = () => _launch(config.termsOfServiceUrl!),
        ),
      );
    }

    return RichText(text: TextSpan(children: spans));
  }
}

// ---------------------------------------------------------------------------
// Shared URL launcher helper
// ---------------------------------------------------------------------------

Future<void> _launch(String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null) return;
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
