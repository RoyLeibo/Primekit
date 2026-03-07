import 'package:collection/collection.dart';

/// Classifies how a product is consumed after purchase.
enum ProductType {
  /// Single-use products consumed upon redemption (e.g. coins, credits).
  consumable,

  /// One-time purchases that persist indefinitely (e.g. remove ads, pro unlock).
  nonConsumable,

  /// Recurring subscriptions with an associated [BillingPeriod].
  subscription,
}

/// The billing cycle for a subscription product.
enum BillingPeriod {
  /// Billed every 7 days.
  weekly,

  /// Billed every 30 days.
  monthly,

  /// Billed every 3 months.
  quarterly,

  /// Billed every 12 months.
  yearly,

  /// One-time payment granting lifetime access.
  lifetime,
}

/// Pricing information for a [Product], including optional trial details.
///
/// All amounts are in the specified [currency] (ISO 4217 code, e.g. `'USD'`).
///
/// ```dart
/// final pricing = PricingInfo(
///   amount: 9.99,
///   currency: 'USD',
///   period: BillingPeriod.monthly,
///   trialPeriod: const Duration(days: 7),
/// );
/// print(pricing.formatted);      // 'USD 9.99'
/// print(pricing.perMonthPrice);  // 9.99
/// ```
final class PricingInfo {
  /// Creates pricing information.
  ///
  /// [amount] must be non-negative. [currency] must be a non-empty ISO 4217
  /// currency code. [period] is required for subscription products.
  const PricingInfo({
    required this.amount,
    required this.currency,
    this.period,
    this.trialPeriod,
  }) : assert(amount >= 0, 'PricingInfo.amount must be non-negative');

  /// The price amount in [currency] units.
  final double amount;

  /// ISO 4217 currency code (e.g. `'USD'`, `'EUR'`, `'GBP'`).
  final String currency;

  /// Billing cycle. `null` for one-time purchases.
  final BillingPeriod? period;

  /// Free-trial period before the first charge. `null` if no trial is offered.
  final Duration? trialPeriod;

  /// Human-readable price string, e.g. `'USD 9.99'`.
  String get formatted => '$currency $amount';

  /// Monthly-equivalent price for comparison purposes.
  ///
  /// Returns the raw [amount] for non-subscription or already-monthly products.
  /// Returns `null` for [BillingPeriod.lifetime] (no recurring charge).
  double? get perMonthPrice => switch (period) {
    null => amount,
    BillingPeriod.weekly => amount * (52 / 12),
    BillingPeriod.monthly => amount,
    BillingPeriod.quarterly => amount / 3,
    BillingPeriod.yearly => amount / 12,
    BillingPeriod.lifetime => null,
  };

  /// Annual-equivalent price for comparison purposes.
  ///
  /// Returns `null` for [BillingPeriod.lifetime] (no recurring charge).
  double? get perYearPrice => switch (period) {
    null => amount,
    BillingPeriod.weekly => amount * 52,
    BillingPeriod.monthly => amount * 12,
    BillingPeriod.quarterly => amount * 4,
    BillingPeriod.yearly => amount,
    BillingPeriod.lifetime => null,
  };

  /// Returns a copy with the given fields replaced.
  PricingInfo copyWith({
    double? amount,
    String? currency,
    BillingPeriod? period,
    Duration? trialPeriod,
  }) => PricingInfo(
    amount: amount ?? this.amount,
    currency: currency ?? this.currency,
    period: period ?? this.period,
    trialPeriod: trialPeriod ?? this.trialPeriod,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PricingInfo &&
          runtimeType == other.runtimeType &&
          amount == other.amount &&
          currency == other.currency &&
          period == other.period &&
          trialPeriod == other.trialPeriod;

  @override
  int get hashCode => Object.hash(amount, currency, period, trialPeriod);

  @override
  String toString() =>
      'PricingInfo(amount: $amount, currency: $currency, '
      'period: $period, trialPeriod: $trialPeriod)';
}

/// A product available for purchase in the app.
///
/// Products are registered with [ProductCatalog] and referenced throughout
/// the billing module by their [id].
///
/// ```dart
/// final pro = Product(
///   id: 'primekit_pro_monthly',
///   title: 'Primekit Pro',
///   description: 'Unlock all pro features',
///   type: ProductType.subscription,
///   pricing: PricingInfo(amount: 9.99, currency: 'USD', period: BillingPeriod.monthly),
///   features: ['No ads', 'Unlimited exports', 'Priority support'],
///   platformProductId: 'com.example.primekit.pro.monthly',
/// );
/// ```
final class Product {
  /// Creates a product definition.
  const Product({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.pricing,
    this.features = const [],
    this.platformProductId,
  }) : assert(id.length > 0, 'Product.id must not be empty'),
       assert(title.length > 0, 'Product.title must not be empty');

  /// Unique identifier used throughout the Primekit billing system.
  final String id;

  /// Localized display name shown to the user.
  final String title;

  /// Localized description of what the product provides.
  final String description;

  /// Whether this is a consumable, non-consumable, or subscription product.
  final ProductType type;

  /// Price, currency, and billing-cycle information.
  final PricingInfo pricing;

  /// Human-readable list of features included in this product.
  final List<String> features;

  /// The App Store (Apple) or Play Store (Google) product SKU.
  ///
  /// `null` when not yet mapped to a platform product.
  final String? platformProductId;

  /// Returns a copy with the given fields replaced.
  Product copyWith({
    String? id,
    String? title,
    String? description,
    ProductType? type,
    PricingInfo? pricing,
    List<String>? features,
    String? platformProductId,
  }) => Product(
    id: id ?? this.id,
    title: title ?? this.title,
    description: description ?? this.description,
    type: type ?? this.type,
    pricing: pricing ?? this.pricing,
    features: features ?? List.unmodifiable(this.features),
    platformProductId: platformProductId ?? this.platformProductId,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Product && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Product(id: $id, title: $title, type: $type)';
}

/// An in-memory registry of all [Product] definitions available in the app.
///
/// Register products once at startup (typically in `main()`) and query them
/// throughout the app without passing product lists around:
///
/// ```dart
/// final catalog = ProductCatalog();
/// catalog.register([proMonthly, proYearly, coinPack]);
///
/// final product = catalog.findById('primekit_pro_monthly');
/// final subs    = catalog.subscriptions;
/// ```
class ProductCatalog {
  /// Creates an empty catalog. Products must be [register]ed before use.
  ProductCatalog();

  final Map<String, Product> _products = {};

  /// Registers [products], making them retrievable by [findById] and the
  /// typed list accessors.
  ///
  /// Calling [register] multiple times merges the product lists; duplicate
  /// [Product.id] values overwrite the previously registered entry.
  void register(List<Product> products) {
    for (final product in products) {
      _products[product.id] = product;
    }
  }

  /// Returns the [Product] with the given [id], or `null` if not registered.
  Product? findById(String id) => _products[id];

  /// Returns all products of the specified [type].
  List<Product> getByType(ProductType type) =>
      _products.values.where((p) => p.type == type).toList(growable: false);

  /// All registered [ProductType.subscription] products.
  List<Product> get subscriptions => getByType(ProductType.subscription);

  /// All registered [ProductType.consumable] and [ProductType.nonConsumable]
  /// products.
  List<Product> get oneTimePurchases => _products.values
      .where(
        (p) =>
            p.type == ProductType.consumable ||
            p.type == ProductType.nonConsumable,
      )
      .toList(growable: false);

  /// All registered products as an unmodifiable list.
  List<Product> get all =>
      List.unmodifiable(_products.values.toList(growable: false));

  /// The number of products currently registered.
  int get length => _products.length;

  /// Whether the catalog contains no products.
  bool get isEmpty => _products.isEmpty;

  /// Removes all registered products (useful in tests).
  void clear() => _products.clear();

  /// Returns the product whose [Product.platformProductId] matches [sku],
  /// or `null` if none is found.
  Product? findByPlatformId(String sku) =>
      _products.values.firstWhereOrNull((p) => p.platformProductId == sku);
}
