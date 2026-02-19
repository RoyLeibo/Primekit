/// Billing — In-app purchase, subscription management, entitlements, and
/// paywall logic for Primekit applications.
///
/// ## Quick start
///
/// ```dart
/// import 'package:primekit/billing.dart';
///
/// // 1. Build the product catalog.
/// final catalog = ProductCatalog();
/// catalog.register([
///   Product(
///     id: 'app_pro_monthly',
///     title: 'App Pro – Monthly',
///     description: 'Unlock all pro features',
///     type: ProductType.subscription,
///     pricing: PricingInfo(
///       amount: 9.99,
///       currency: 'USD',
///       period: BillingPeriod.monthly,
///       trialPeriod: const Duration(days: 7),
///     ),
///     features: ['No ads', 'Unlimited exports', 'Priority support'],
///     platformProductId: 'com.example.app.pro.monthly',
///   ),
/// ]);
///
/// // 2. Set up the subscription manager (inject your platform data source).
/// final manager = SubscriptionManager(dataSource: MyBillingDataSource());
/// await manager.refresh();
///
/// // 3. Configure the entitlement checker.
/// EntitlementChecker.configure(
///   subscriptionManager: manager,
///   featureToProductMap: {
///     'export_pdf': ['app_pro_monthly', 'app_pro_yearly'],
///   },
/// );
///
/// // 4. Gate features.
/// if (await EntitlementChecker.instance.canAccess('export_pdf')) {
///   performExport();
/// } else {
///   paywallController.show(featureName: 'export_pdf');
/// }
/// ```
library primekit_billing;

export 'billing_events.dart';
export 'entitlement_checker.dart';
export 'paywall_controller.dart';
export 'pricing_formatter.dart';
export 'product_catalog.dart';
export 'subscription_manager.dart';
