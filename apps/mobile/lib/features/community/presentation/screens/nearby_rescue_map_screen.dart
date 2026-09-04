import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/services/location_service.dart';

import 'package:provider/provider.dart';

import '../../domain/models/post.dart';
import '../../domain/repositories/i_post_repository.dart';
import 'post_detail_screen.dart';

class NearbyRescueMapScreen extends StatefulWidget {
  final double topPadding;

  const NearbyRescueMapScreen({super.key, required this.topPadding});

  @override
  State<NearbyRescueMapScreen> createState() => _NearbyRescueMapScreenState();
}

class _NearbyRescueMapScreenState extends State<NearbyRescueMapScreen> {
  final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>();
  Set<Marker> _markers = {};
  LatLng? _currentPosition;
  bool _isLoading = true;
  String? _errorMessage;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _determinePosition() async {
    try {
      final position = await const LocationService().getCurrentPosition();
      if (!mounted) return;
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
        _isLoading = false;
        _errorMessage = null;
      });
    } on LocationException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = _getErrorMessage(e);
      });
      LocationService.showError(context, e);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Could not get your location. Please try again.';
      });
    }
  }

  String _getErrorMessage(LocationException e) {
    switch (e) {
      case LocationPermissionPermanentlyDeniedException():
        return 'Location access permanently denied.';
      case LocationServiceDisabledException():
        return 'Location services are disabled.';
      case LocationPermissionDeniedException():
        return 'Location access was denied.';
      case LocationUnknownException():
        return 'Could not get your location.';
    }
  }

  Future<void> _fetchMapBounds(LatLngBounds bounds) async {
    if (!mounted) return;
    final repository = context.read<IPostRepository>();
    try {
      final posts = await repository.getMapBoundsFeed(
        swLat: bounds.southwest.latitude,
        swLon: bounds.southwest.longitude,
        neLat: bounds.northeast.latitude,
        neLon: bounds.northeast.longitude,
        type: 'RescueAlert', // Only fetch Rescue Alerts
      );

      final newMarkers = posts.map((post) {
        return Marker(
          markerId: MarkerId(post.id),
          position: LatLng(post.latitude!, post.longitude!),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            _getHueForUrgency(post.urgencyLevel),
          ),
          onTap: () => _showRescueDetailsBottomSheet(post),
        );
      }).toSet();

      setState(() {
        _markers = newMarkers;
      });
    } catch (e) {
      // Handle error implicitly or show snackbar
    }
  }

  double _getHueForUrgency(String? urgency) {
    switch (urgency) {
      case 'Critical':
        return BitmapDescriptor.hueRed;
      case 'High':
        return BitmapDescriptor.hueOrange;
      case 'Medium':
        return BitmapDescriptor.hueYellow;
      default:
        return BitmapDescriptor.hueBlue;
    }
  }

  LatLngBounds? _lastFetchedBounds;

  bool _isSignificantlyDifferentBounds(LatLngBounds newBounds) {
    if (_lastFetchedBounds == null) return true;
    final prev = _lastFetchedBounds!;
    // If movement is smaller than ~0.005 degrees (~500m), skip fetching
    const threshold = 0.005;
    final swLatDiff = (newBounds.southwest.latitude - prev.southwest.latitude)
        .abs();
    final swLngDiff = (newBounds.southwest.longitude - prev.southwest.longitude)
        .abs();
    final neLatDiff = (newBounds.northeast.latitude - prev.northeast.latitude)
        .abs();
    final neLngDiff = (newBounds.northeast.longitude - prev.northeast.longitude)
        .abs();
    return swLatDiff > threshold ||
        swLngDiff > threshold ||
        neLatDiff > threshold ||
        neLngDiff > threshold;
  }

  void _onCameraIdle() async {
    final GoogleMapController controller = await _controller.future;
    final LatLngBounds bounds = await controller.getVisibleRegion();

    if (!_isSignificantlyDifferentBounds(bounds)) {
      return;
    }

    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 800), () {
      _lastFetchedBounds = bounds;
      _fetchMapBounds(bounds);
    });
  }

  void _showRescueDetailsBottomSheet(Post post) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                post.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              if (post.urgencyLevel != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Urgency: ${post.urgencyLevel}',
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PostDetailScreen(postId: post.id),
                      ),
                    );
                  },
                  child: const Text('View Details'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_errorMessage != null || _currentPosition == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_errorMessage ?? "Location permission required."),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() => _isLoading = true);
                  _determinePosition();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: GoogleMap(
        padding: EdgeInsets.only(top: widget.topPadding),
        initialCameraPosition: CameraPosition(
          target: _currentPosition!,
          zoom: 14.0,
        ),
        markers: _markers,
        onMapCreated: (GoogleMapController controller) {
          _controller.complete(controller);
        },
        onCameraIdle: _onCameraIdle,
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
      ),
    );
  }
}
