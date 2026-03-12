# billing — In-App Purchases & Subscriptions

**Purpose:** Product catalog, purchase flow, and entitlement checking for IAP/subscriptions.

**Key exports:**
- `SubscriptionManager` — manages subscription state and active SKUs
- `ProductCatalog` — loaded product list with pricing
- `EntitlementChecker` — check if user has access to a feature/tier
- `PaywallController` — orchestrates the full purchase flow
- `PricingFormatter` — locale-aware price formatting
- `BillingEvents` — analytics event types for purchase funnel

**Exceptions:** `BillingException`, `PurchaseCancelledException`

**Planned usage:**
- Bullseye: Pro tier
- best_todo_list: AI quota monetization (50 calls/day → unlimited)

**Dependencies:** `core`

**Note:** This is the next sprint to implement. See `../INTEGRATION_REMAINING.md`.

**Maintenance:** Update when new product type supported or purchase flow changes.
