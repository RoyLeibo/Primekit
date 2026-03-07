/// Result of a location request containing coordinates and optional address.
final class PkLocationResult {
  const PkLocationResult({
    required this.latitude,
    required this.longitude,
    this.address,
  });

  final double latitude;
  final double longitude;

  /// Human-readable address or place name from reverse geocoding (optional).
  final String? address;

  @override
  String toString() =>
      'PkLocationResult(lat: $latitude, lng: $longitude, address: ${address ?? 'N/A'})';
}
