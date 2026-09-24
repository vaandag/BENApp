import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class LocationSnapshot {
  final LatLng latLng;
  final double accuracy;
  final DateTime timestamp;
  const LocationSnapshot({required this.latLng, required this.accuracy, required this.timestamp});
}

class LocationResult {
  final LocationSnapshot? snapshot;
  final String? errorCode;
  final String? message;
  const LocationResult({this.snapshot, this.errorCode, this.message});
  bool get ok => snapshot != null;
}

class LocationService {
  Future<LocationResult> getCurrent(BuildContext context, {bool showFeedback = true}) async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (showFeedback && context.mounted) {
        await _feedback(context, 'Konum hizmeti kapalı. Telefon ayarlarından konumu açabilirsin.', openSettings: true);
      }
      return const LocationResult(errorCode: 'service_disabled', message: 'Konum hizmeti kapalı.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      if (showFeedback && context.mounted) _snack(context, 'Konum izni verilmedi. Konumsuz da paylaşabilirsin.');
      return const LocationResult(errorCode: 'permission_denied', message: 'Konum izni verilmedi.');
    }
    if (permission == LocationPermission.deniedForever) {
      if (showFeedback && context.mounted) {
        await _feedback(context, 'Konum izni kapalı. İstersen Ayarlar’dan BEN için konumu açabilirsin.', openSettings: false);
      }
      return const LocationResult(errorCode: 'permission_denied_forever', message: 'Konum izni kalıcı olarak kapalı.');
    }

    try {
      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 12)),
        );
      } catch (_) {
        position = await Geolocator.getLastKnownPosition();
      }
      if (position == null) {
        if (showFeedback && context.mounted) _snack(context, 'Konum şu anda alınamadı. Birkaç saniye sonra tekrar deneyebilirsin.');
        return const LocationResult(errorCode: 'unavailable', message: 'Konum alınamadı.');
      }
      if (!position.latitude.isFinite || !position.longitude.isFinite || position.accuracy.isNaN) {
        return const LocationResult(errorCode: 'invalid', message: 'Geçersiz konum verisi.');
      }
      return LocationResult(snapshot: LocationSnapshot(
        latLng: LatLng(position.latitude, position.longitude),
        accuracy: position.accuracy,
        timestamp: position.timestamp,
      ));
    } catch (_) {
      if (showFeedback && context.mounted) _snack(context, 'Konum alınamadı. Tekrar deneyebilirsin.');
      return const LocationResult(errorCode: 'failed', message: 'Konum alınamadı.');
    }
  }

  Future<LatLng?> getCurrentLatLng(BuildContext context) async => (await getCurrent(context)).snapshot?.latLng;

  void _snack(BuildContext context, String message) => ScaffoldMessenger.of(context)..hideCurrentSnackBar()..showSnackBar(SnackBar(behavior: SnackBarBehavior.floating, content: Text(message)));

  Future<void> _feedback(BuildContext context, String message, {required bool openSettings}) async {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)..hideCurrentSnackBar()..showSnackBar(SnackBar(behavior: SnackBarBehavior.floating, content: Text(message)));
    if (openSettings) await Geolocator.openLocationSettings();
  }
}
