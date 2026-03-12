# device — Device Information & Features

**Purpose:** Device capabilities, geolocation, biometric authentication, and clipboard.

**Key exports:**
- `DeviceInfo` — device model, OS version, screen size, platform
- `AppVersion` — app version + build number (from package_info_plus)
- `LocationService` — geolocation queries (current position, updates)
- `BiometricAuth` — fingerprint/Face ID unlock
- `BiometricTypes` — supported biometric types enum
- `ClipboardHelper` — read/write clipboard

**Dependencies:** device_info_plus 12.3.0, package_info_plus, geolocator 14.0.0, local_auth 3.0.0

**Maintenance:** Update when new device capability added.
