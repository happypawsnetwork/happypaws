import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/services/location_service.dart';
import '../../../../../../core/services/geocoding_service.dart';
import '../../../../../../core/services/google_places_service.dart';
import '../../../controllers/create_post_controller.dart';
import '../../../widgets/create_post_app_bar.dart';

class SelectLocationMapScreen extends StatefulWidget {
  const SelectLocationMapScreen({super.key});

  @override
  State<SelectLocationMapScreen> createState() =>
      _SelectLocationMapScreenState();
}

class _SelectLocationMapScreenState extends State<SelectLocationMapScreen> {
  final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  LatLng _currentPosition = const LatLng(37.7749, -122.4194); // Default to SF
  bool _isLoading = true;
  List<GooglePlace> _searchResults = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    final locationService = const LocationService();
    try {
      final position = await locationService.getCurrentPosition();
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
        _isLoading = false;
      });
      _updateAddress(_currentPosition);
    } catch (e) {
      // Fallback or handle error
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateAddress(LatLng position) async {
    final address = await GeocodingService.getAddressFromCoordinates(
      position.latitude,
      position.longitude,
    );
    if (address != null && mounted) {
      setState(() {
        _addressController.text = address;
      });
    }
  }

  void _onCameraIdle() async {
    final GoogleMapController controller = await _controller.future;
    // Getting the center coordinates
    final LatLngBounds bounds = await controller.getVisibleRegion();
    final double lat =
        (bounds.northeast.latitude + bounds.southwest.latitude) / 2;
    final double lng =
        (bounds.northeast.longitude + bounds.southwest.longitude) / 2;
    _currentPosition = LatLng(lat, lng);
    _updateAddress(_currentPosition);
  }

  Future<void> _searchPlaces(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }
    setState(() {
      _isSearching = true;
    });
    final results = await GooglePlacesService.searchPlaces(query);
    if (mounted) {
      setState(() {
        _searchResults = results;
      });
    }
  }

  Future<void> _selectPlace(GooglePlace place) async {
    FocusScope.of(context).unfocus();
    setState(() {
      _isSearching = false;
      _searchResults = [];
      _searchController.text = place.description;
    });

    final coords = await GooglePlacesService.getPlaceCoordinates(place.placeId);
    if (coords != null && mounted) {
      final newPos = LatLng(coords['lat']!, coords['lng']!);
      final GoogleMapController controller = await _controller.future;
      controller.animateCamera(CameraUpdate.newLatLngZoom(newPos, 16));
      _currentPosition = newPos;
      _updateAddress(_currentPosition);
    }
  }

  void _saveLocation() {
    final createPostController = context.read<CreatePostController>();
    createPostController.lat = _currentPosition.latitude;
    createPostController.lon = _currentPosition.longitude;
    createPostController.locationLabel = _addressController.text.trim();
    context.pop();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CreatePostAppBar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _currentPosition,
                    zoom: 15,
                  ),
                  onMapCreated: (GoogleMapController controller) {
                    _controller.complete(controller);
                  },
                  onCameraIdle: _onCameraIdle,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                ),
                // Center Pin
                const Center(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 35.0),
                    child: Icon(
                      Icons.location_pin,
                      size: 40,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                // Search Bar Overlay
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: _searchPlaces,
                          decoration: InputDecoration(
                            hintText: 'Search for a place',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      _searchController.clear();
                                      _searchPlaces('');
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                        ),
                      ),
                      if (_isSearching && _searchResults.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          constraints: const BoxConstraints(maxHeight: 200),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: _searchResults.length,
                            itemBuilder: (context, index) {
                              final place = _searchResults[index];
                              return ListTile(
                                leading: const Icon(
                                  Icons.location_on,
                                  color: Colors.grey,
                                ),
                                title: Text(place.description),
                                onTap: () => _selectPlace(place),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
                // Bottom Panel
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          offset: Offset(0, -2),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Address Details',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _addressController,
                          decoration: InputDecoration(
                            hintText: 'Fetching address...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: AppColors.primary,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: _saveLocation,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Confirm Location',
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Locate Me FAB
                Positioned(
                  bottom: 220,
                  right: 16,
                  child: FloatingActionButton(
                    heroTag: 'locate_me_fab',
                    backgroundColor: Colors.white,
                    child: const Icon(
                      Icons.my_location,
                      color: AppColors.primary,
                    ),
                    onPressed: () async {
                      final pos = await const LocationService()
                          .getCurrentPosition();
                      final GoogleMapController controller =
                          await _controller.future;
                      controller.animateCamera(
                        CameraUpdate.newLatLng(
                          LatLng(pos.latitude, pos.longitude),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
