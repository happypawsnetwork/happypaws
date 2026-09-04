import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../../core/services/location_service.dart';
import '../../../../../../core/theme/app_colors.dart';

import 'package:provider/provider.dart';

import '../../../controllers/create_post_controller.dart';
import '../../../widgets/create_post_app_bar.dart';

class TransportDropoffScreen extends StatefulWidget {
  const TransportDropoffScreen({super.key});

  @override
  State<TransportDropoffScreen> createState() => _TransportDropoffScreenState();
}

class _TransportDropoffScreenState extends State<TransportDropoffScreen> {
  late final TextEditingController _locationController;

  final _locationService = const LocationService();

  @override
  void initState() {
    super.initState();
    final controller = context.read<CreatePostController>();
    _locationController = TextEditingController(
      text: controller.dropoffLocationLabel,
    );
    _locationController.addListener(() {
      controller.dropoffLocationLabel = _locationController.text;
    });
  }

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await _locationService.getCurrentPosition();
      if (mounted) {
        final controller = context.read<CreatePostController>();
        controller.dropoffLat = position.latitude;
        controller.dropoffLon = position.longitude;
        _locationController.text =
            'Current Location (${position.latitude.toStringAsFixed(2)}, '
            '${position.longitude.toStringAsFixed(2)})';
        controller.dropoffLocationLabel = _locationController.text;
      }
    } on LocationException catch (e) {
      if (mounted) LocationService.showError(context, e);
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
            child: ValueListenableBuilder<TextEditingValue>(
              valueListenable: _locationController,
              builder: (context, value, child) {
                final isValid = value.text.trim().isNotEmpty;
                return FilledButton(
                  onPressed: isValid
                      ? () {
                          context.push('/community/create/transport/details');
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
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
