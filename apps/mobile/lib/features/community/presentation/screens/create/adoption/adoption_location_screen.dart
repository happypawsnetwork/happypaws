import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../../../../core/services/location_service.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../controllers/create_post_controller.dart';
import '../../../widgets/create_post_app_bar.dart';

class AdoptionLocationScreen extends StatefulWidget {
  const AdoptionLocationScreen({super.key});

  @override
  State<AdoptionLocationScreen> createState() => _AdoptionLocationScreenState();
}

class _AdoptionLocationScreenState extends State<AdoptionLocationScreen> {
  final _locationController = TextEditingController();
  bool _isLoadingGps = false;

  final _locationService = const LocationService();

  @override
  void initState() {
    super.initState();
    final controller = context.read<CreatePostController>();
    _locationController.text = controller.locationLabel;
    _locationController.addListener(_updateState);
  }

  void _updateState() {
    setState(() {});
  }

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _autoFillGPS() async {
    setState(() => _isLoadingGps = true);
    try {
      final position = await _locationService.getCurrentPosition();
      if (mounted) {
        final controller = context.read<CreatePostController>();
        final label =
            'Current Location (${position.latitude.toStringAsFixed(4)}, '
            '${position.longitude.toStringAsFixed(4)})';
        setState(() {
          _locationController.text = label;
          controller.locationLabel = label;
          controller.lat = position.latitude;
          controller.lon = position.longitude;
        });
      }
    } on LocationException catch (e) {
      if (mounted) LocationService.showError(context, e);
    } finally {
      if (mounted) setState(() => _isLoadingGps = false);
    }
  }

  bool get _isValid => _locationController.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CreatePostAppBar(),
      body: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              offset: const Offset(0, -4),
              blurRadius: 10,
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: FilledButton(
              onPressed: _isValid
                  ? () {
                      final controller = context.read<CreatePostController>();
                      controller.locationLabel = _locationController.text
                          .trim();
                      context.push('/community/create/adoption/review');
                    }
                  : null,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Next',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
