import 'package:geolocator_platform_interface/geolocator_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockGeolocatorPlatform extends GeolocatorPlatform
    with MockPlatformInterfaceMixin {
  LocationPermission permissionState = LocationPermission.whileInUse;
  bool isServiceEnabled = true;

  @override
  Future<LocationPermission> checkPermission() async => permissionState;

  @override
  Future<LocationPermission> requestPermission() async => permissionState;

  @override
  Future<bool> isLocationServiceEnabled() async => isServiceEnabled;

  @override
  Future<Position> getCurrentPosition({
    LocationSettings? locationSettings,
  }) async => Position(
    latitude: 6.9271,
    longitude: 79.8612,
    timestamp: DateTime.now(),
    altitude: 0.0,
    altitudeAccuracy: 0.0,
    accuracy: 10.0,
    heading: 0.0,
    headingAccuracy: 0.0,
    speed: 0.0,
    speedAccuracy: 0.0,
  );

  @override
  Future<Position?> getLastKnownPosition({
    bool forceLocationManager = false,
  }) async => Position(
    latitude: 6.9271,
    longitude: 79.8612,
    timestamp: DateTime.now(),
    altitude: 0.0,
    altitudeAccuracy: 0.0,
    accuracy: 10.0,
    heading: 0.0,
    headingAccuracy: 0.0,
    speed: 0.0,
    speedAccuracy: 0.0,
  );
}
