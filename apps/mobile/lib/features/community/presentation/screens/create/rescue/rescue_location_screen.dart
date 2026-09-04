import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../../../../core/services/location_service.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../controllers/create_post_controller.dart';
import '../../../widgets/create_post_app_bar.dart';

class RescueLocationScreen extends StatefulWidget {
  const RescueLocationScreen({super.key});

  @override
  State<RescueLocationScreen> createState() => _RescueLocationScreenState();
}

class _RescueLocationScreenState extends State<RescueLocationScreen> {
  late TextEditingController _locationController;
  final _formKey = GlobalKey<FormState>();
  bool _isLoadingGps = false;

  // Shared service — permission was already requested on the splash screen,
  // so this call will skip the dialog on most devices.
  final _locationService = const LocationService();

  @override
  void initState() {
    super.initState();
    final controller = context.read<CreatePostController>();
    _locationController = TextEditingController(text: controller.locationLabel);
  }

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _getLocation() async {
    setState(() => _isLoadingGps = true);

    try {
      final position = await _locationService.getCurrentPosition();

      if (mounted) {
        final controller = context.read<CreatePostController>();
        controller.lat = position.latitude;
        controller.lon = position.longitude;

        final locText =
            'Current Location (${position.latitude.toStringAsFixed(4)}, '
            '${position.longitude.toStringAsFixed(4)})';
        _locationController.text = locText;
      }
    } on LocationException catch (e) {
      if (mounted) LocationService.showError(context, e);
    } finally {
      if (mounted) setState(() => _isLoadingGps = false);
    }
  }

  void _onNext() {
    if (_formKey.currentState!.validate()) {
      final controller = context.read<CreatePostController>();
      controller.locationLabel = _locationController.text.trim();
      context.push('/community/create/rescue/review');
    }
  }

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
              onPressed: _onNext,
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
