# membership — Membership Tiers & Trials

**Purpose:** Membership tier definitions, trial periods, and tier-based feature access control.

**Key exports:**
- `MembershipService` — singleton managing current user's membership tier
- `MembershipTier` — tier definition (Free/Pro/Premium + feature access list)
- `TrialManager` — trial period start/end/expiry tracking
- `AccessPolicy` — tier-based feature access rules
- `TierGate` — widget that shows/hides content based on required tier
- `MemberBadge` — tier indicator widget

**Pattern:**
```dart
final tier = MembershipService.instance.currentTier;
TierGate(required: MembershipTier.pro, child: ProFeature())
```

**Dependencies:** `core`

**Note:** Works alongside `billing` module. Membership handles tiers; billing handles purchases.

**Maintenance:** Update when new tier added or trial logic changes.
