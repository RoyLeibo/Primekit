# home_widget — Home Screen Widget Bridge

**Purpose:** Generic bridge for pushing data to iOS/Android home screen widgets via the `home_widget` package.

**Key exports:**
- `PkHomeWidgetService` — initialize, push data, read values, register tap callback
- `PkWidgetData` — abstract base class; subclass and implement `toWidgetMap()`
- `PkWidgetName` — immutable pair of iOS + Android widget identifiers
- `HomeWidgetException` — `PrimekitException` subtype for widget failures

**Pattern:**
```dart
final svc = PkHomeWidgetService(appGroupId: 'group.com.app.widget');
await svc.initialize();
await svc.updateWidget(
  widgetName: PkWidgetName(ios: 'MyWidget', android: 'MyWidgetProvider'),
  data: myData, // extends PkWidgetData
);
```

**Dependencies:** `core` (exceptions, logger), `home_widget` package

**Consumers:** PawTrack

**Maintenance:** Update when new widget data operations added or callback API changes.
