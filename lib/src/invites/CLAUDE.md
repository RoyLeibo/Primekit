# invites — Invite Code & Sharing

**Purpose:** Reusable invite code generation, multi-method sharing UI, and join-by-code form.

**Key exports:**
- `InviteCode` — Generate/validate 6-digit codes and 8-char link identifiers
- `InviteShareSheet` — Bottom sheet with 4 tabs: Link, Code, Share, Contacts
- `InviteShareConfig` — Configuration for share sheet (code, link, app name, callbacks)
- `InviteContactsTab` — Contact picker with multi-select and search
- `InviteJoinForm` — Join-by-code form with validation and auto-join from deep link

**Dependencies:** `share_plus`, `contacts` module (for contact picker)

**Usage:**
```dart
import 'package:primekit/invites.dart';

// Generate a code
final code = InviteCode.generateCode(); // "482917"

// Show share sheet
InviteShareSheet.show(
  context: context,
  config: InviteShareConfig(
    inviteCode: code,
    inviteLink: 'https://app.com/join/$code',
    title: 'Invite Member',
    appName: 'MyApp',
    entityName: 'Team Alpha',
  ),
);
```

**Maintenance:** Update when new sharing methods or invite formats are added.
