import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import 'location_result.dart';

/// GPS + reverse-geocoding service backed by OpenStreetMap Nominatim.
///
/// Usage:
/// ```dart
/// final loc = await LocationService.instance.getCurrentLocation();
/// if (loc != null) print(loc.address);
/// ```
final class LocationService {
  LocationService._({http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  static final LocationService instance = LocationService._();

  static const String _nominatimBaseUrl =
      'https://nominatim.openstreetmap.org';

  final http.Client _httpClient;

  /// Returns `true` if the device's location hardware is switched on.
  Future<bool> isServiceEnabled() => Geolocator.isLocationServiceEnabled();

  /// Returns `true` if location permission has been granted.
  Future<bool> isPermissionGranted() async {
    final status = await Geolocator.checkPermission();
    return status == LocationPermission.always ||
        status == LocationPermission.whileInUse;
  }

  /// Requests location permission. Returns `true` if granted.
  Future<bool> requestPermission() async {
    final status = await Geolocator.requestPermission();
    return status == LocationPermission.always ||
        status == LocationPermission.whileInUse;
  }

  /// Returns the current GPS position as a [PkLocationResult], including a
  /// reverse-geocoded [PkLocationResult.address] when available.
  ///
  /// Returns `null` if location services are disabled, permission is denied,
  /// or any error occurs.
  Future<PkLocationResult?> getCurrentLocation() async {
    final position = await _getPosition();
    if (position == null) return null;

    final address = await reverseGeocode(
      latitude: position.latitude,
      longitude: position.longitude,
    );

    return PkLocationResult(
      latitude: position.latitude,
      longitude: position.longitude,
      address: address,
    );
  }

  /// Converts GPS coordinates to a human-readable address via Nominatim.
  /// Returns `null` on failure.
  Future<String?> reverseGeocode({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final url = Uri.parse(
        '$_nominatimBaseUrl/reverse?'
        'format=json&lat=$latitude&lon=$longitude&zoom=18&addressdetails=1',
      );

      final response = await _httpClient
          .get(url, headers: {'User-Agent': 'PrimeKit/1.0'}).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final addr = data['address'] as Map<String, dynamic>?;

      if (addr != null) {
        final parts = <String>[];
        final placeName = (addr['amenity'] as String?) ??
            (addr['shop'] as String?) ??
            (addr['building'] as String?);
        final road = addr['road'] as String?;
        final suburb = (addr['suburb'] as String?) ??
            (addr['neighbourhood'] as String?);
        final city = (addr['city'] as String?) ??
            (addr['town'] as String?) ??
            (addr['village'] as String?);

        if (placeName != null) parts.add(placeName);
        if (road != null) parts.add(road);
        if (suburb != null && suburb != city) parts.add(suburb);
        if (city != null) parts.add(city);

        if (parts.isNotEmpty) return parts.join(', ');
      }

      return data['display_name'] as String?;
    } catch (e) {
      debugPrint('[LocationService] reverseGeocode error: $e');
      return null;
    }
  }

  Future<Position?> _getPosition() async {
    try {
      if (!await isServiceEnabled()) {
        debugPrint('[LocationService] location services disabled');
        return null;
      }

      if (!await isPermissionGranted()) {
        final granted = await requestPermission();
        if (!granted) {
          debugPrint('[LocationService] permission denied');
          return null;
        }
      }

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
    } catch (e) {
      debugPrint('[LocationService] _getPosition error: $e');
      return null;
    }
  }
}
