/// Email — multi-provider email sending for Flutter applications.
///
/// Supports SendGrid, Resend, and a backend SMTP relay. Includes drop-in
/// contact form and verification mailers with built-in HTML templates, plus
/// an offline-resilient local queue.
///
/// ## Quick-start
///
/// ```dart
/// // 1. Configure a provider once at startup:
/// EmailService.instance.configure(
///   provider: SendGridProvider(
///     apiKey: Env.sendgridApiKey,
///     fromEmail: 'noreply@myapp.com',
///     fromName: 'My App',
///   ),
/// );
///
/// // 2. Send a transactional email:
/// final result = await EmailService.instance.send(
///   EmailMessage(
///     to: 'user@example.com',
///     subject: 'Your order shipped!',
///     htmlBody: '<p>Your order is on its way.</p>',
///   ),
/// );
///
/// result.when(
///   success: (r) => print('Sent: ${r.messageId}'),
///   failure: (r) => print('Failed: ${r.reason}'),
/// );
///
/// // 3. Send a contact form submission:
/// final mailer = ContactFormMailer(toEmail: 'support@myapp.com');
/// await mailer.send(
///   senderName: 'Alice',
///   senderEmail: 'alice@example.com',
///   message: 'Hello, I need help.',
/// );
///
/// // 4. Send a verification OTP:
/// final verifier = VerificationMailer(
///   fromEmail: 'noreply@myapp.com',
///   appName: 'MyApp',
/// );
/// await verifier.sendOtp(toEmail: 'user@example.com', otp: '847261');
///
/// // 5. Queue emails for offline-resilient delivery:
/// await EmailQueue.instance.enqueue(message);
/// await EmailQueue.instance.flush();
/// ```
library primekit_email;

export 'contact_form_mailer.dart';
export 'email_message.dart';
export 'email_provider.dart';
export 'email_queue.dart';
export 'email_service.dart';
export 'verification_mailer.dart';
