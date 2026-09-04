import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

// ---------------------------------------------------------------------------
// Exception hierarchy
// ---------------------------------------------------------------------------

/// Base type for all location failures. Use a switch expression on subtypes
/// to show the correct message to the user.
sealed class LocationException implements Exception {
  const LocationException();
}

/// The device's location services (GPS, network) are switched off in Settings.
final class LocationServiceDisabledException extends LocationException {
  const LocationServiceDisabledException();
}

/// The user denied the permission dialog this session.
final class LocationPermissionDeniedException extends LocationException {
  const LocationPermissionDeniedException();
}

/// The user permanently denied the permission. The OS will not show the dialog
/// again; we must send them to app settings.
final class LocationPermissionPermanentlyDeniedException
    extends LocationException {
  const LocationPermissionPermanentlyDeniedException();
}

/// An unexpected error from the platform geolocator.
final class LocationUnknownException extends LocationException {
  final Object cause;
  const LocationUnknownException(this.cause);
}

// ---------------------------------------------------------------------------
// Service
// ---------------------------------------------------------------------------

/// Wraps [Geolocator] to centralise permission handling.
///
/// Call [requestPermission] once at app startup so the OS dialog appears at a
/// natural pause rather than mid-flow. Subsequent [getCurrentPosition] calls
/// will skip the dialog because the permission is already resolved.
class LocationService {
  const LocationService();

  /// Requests location permission if it has not been granted yet.
  ///
  /// Returns the resolved [LocationPermission]. Does not throw — callers that
  /// only care about the happy path can ignore the return value.
  Future<LocationPermission> requestPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    return permission;
  }

  /// Returns the device's current position or throws a [LocationException].
  Future<Position> getCurrentPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const LocationServiceDisabledException();
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw const LocationPermissionDeniedException();
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw const LocationPermissionPermanentlyDeniedException();
    }

    try {
      return await Geolocator.getCurrentPosition();
    } catch (e) {
      throw LocationUnknownException(e);
    }
  }

  // ---------------------------------------------------------------------------
  // UI helpers
  // ---------------------------------------------------------------------------

  /// Shows a typed error message for a [LocationException].
  ///
  /// When the permission is permanently denied, shows a dialog that explains
  /// why location matters and offers a direct link to app settings. For all
  /// other failures, shows a concise [SnackBar].
  static void showError(BuildContext context, LocationException error) {
    switch (error) {
      case LocationPermissionPermanentlyDeniedException():
        _showPermanentDenialDialog(context);
      case LocationServiceDisabledException():
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Location services are off. Turn them on in your device settings.',
            ),
          ),
        );
      case LocationPermissionDeniedException():
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Location access was denied. Grant it to use the GPS shortcut.',
            ),
          ),
        );
      case LocationUnknownException():
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not get your location. Please try again.'),
          ),
        );
    }
  }

  static void _showPermanentDenialDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Location access needed'),
        content: const Text(
          'You permanently denied location access. Happy Paws uses your '
          'location to pin the animal\'s exact position in rescue and '
          'transport posts.\n\n'
          'Open app settings and enable "Location" to use the GPS shortcut.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Not now'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              Geolocator.openAppSettings();
            },
            child: const Text('Open settings'),
          ),
        ],
      ),
    );
  }
}
