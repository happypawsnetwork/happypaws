import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/sri_lanka_locations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/searchable_dropdown_field.dart';
import '../../domain/models/user_profile.dart';
import '../controllers/edit_profile_controller.dart';
import '../controllers/profile_controller.dart';

/// Modal dialog for editing the user's home address in Sri Lanka.
class EditAddressDialog extends StatefulWidget {
  final UserProfile? currentUser;

  const EditAddressDialog({super.key, required this.currentUser});

  static Future<bool?> show(
    BuildContext context, {
    required UserProfile? currentUser,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => EditAddressDialog(currentUser: currentUser),
    );
  }

  @override
  State<EditAddressDialog> createState() => _EditAddressDialogState();
}

class _EditAddressDialogState extends State<EditAddressDialog> {
  late final TextEditingController _address1Controller;
  late final TextEditingController _address2Controller;
  late final TextEditingController _postalController;

  String? _selectedProvince;
  String? _selectedCity;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final user = widget.currentUser;
    _address1Controller = TextEditingController(text: user?.addressLine1 ?? '');
    _address2Controller = TextEditingController(text: user?.addressLine2 ?? '');
    _postalController = TextEditingController(text: user?.postalCode ?? '');

    // Pre-populate province and city if valid
    final currentProvince = user?.state;
    if (SriLankaLocations.isValidProvince(currentProvince)) {
      _selectedProvince = currentProvince;
      final currentCity = user?.city;
      if (SriLankaLocations.isValidCity(currentProvince, currentCity)) {
        _selectedCity = currentCity;
      }
    } else if (user?.city != null && user!.city!.isNotEmpty) {
      _selectedCity = user.city;
    }
  }

  @override
  void dispose() {
    _address1Controller.dispose();
    _address2Controller.dispose();
    _postalController.dispose();
    super.dispose();
  }

  bool get _canSave {
    final hasAddressLine1 = _address1Controller.text.trim().isNotEmpty;
    final hasProvince =
        _selectedProvince != null && _selectedProvince!.trim().isNotEmpty;
    final hasCity = _selectedCity != null && _selectedCity!.trim().isNotEmpty;
    return hasAddressLine1 && hasProvince && hasCity;
  }

  void _onProvinceChanged(String? newProvince) {
    if (newProvince != _selectedProvince) {
      setState(() {
        _selectedProvince = newProvince;
        // Reset selected city when province changes
        _selectedCity = null;
      });
    }
  }

  void _onCityChanged(String? newCity) {
    setState(() {
      _selectedCity = newCity;
    });
  }

  Future<void> _handleSave() async {
    if (!_canSave || _isSaving) return;

    setState(() {
      _isSaving = true;
    });

    final editController = context.read<EditProfileController>();
    final profileController = context.read<ProfileController>();
    final user = profileController.userProfile ?? widget.currentUser;

    final success = await editController.updateLocationAndAddress(
      addressLine1: _address1Controller.text.trim(),
      addressLine2: _address2Controller.text.trim().isEmpty
          ? null
          : _address2Controller.text.trim(),
      city: _selectedCity,
      state: _selectedProvince,
      postalCode: _postalController.text.trim().isEmpty
          ? null
          : _postalController.text.trim(),
      country: 'Sri Lanka',
      homeLatitude: user?.homeLatitude,
      homeLongitude: user?.homeLongitude,
    );

    if (!mounted) return;

    if (success) {
      await profileController.loadProfile(forceRefresh: true);
      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Address updated successfully')),
        );
      }
    } else {
      setState(() {
        _isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            editController.errorMessage ?? 'Failed to update address',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cityOptions = SriLankaLocations.getCitiesForProvince(
      _selectedProvince,
    );

    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
      title: const Text(
        'Edit Address',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Country field (uneditable)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Country',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Semantics(
                  label: 'Country: Sri Lanka (fixed)',
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.public_rounded,
                          size: 20,
                          color: Color(0xFF94A3B8),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Sri Lanka',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ),
                        Icon(
                          Icons.lock_outline_rounded,
                          size: 18,
                          color: Color(0xFF94A3B8),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Province combo box
            SearchableDropdownField(
              label: 'Province *',
              value: _selectedProvince,
              hintText: 'Select province',
              items: SriLankaLocations.provinces,
              prefixIcon: Icons.map_outlined,
              sheetTitle: 'Select province',
              onChanged: _onProvinceChanged,
            ),
            const SizedBox(height: 14),

            // City combo box (dependent on province)
            SearchableDropdownField(
              label: 'City *',
              value: _selectedCity,
              hintText: 'Select city',
              items: cityOptions,
              enabled:
                  _selectedProvince != null &&
                  _selectedProvince!.trim().isNotEmpty,
              disabledHint: 'Select province first',
              prefixIcon: Icons.location_city_outlined,
              sheetTitle: 'Select city',
              onChanged: _onCityChanged,
            ),
            const SizedBox(height: 14),

            // Address Line 1
            TextFormField(
              controller: _address1Controller,
              decoration: const InputDecoration(
                labelText: 'Address Line 1 *',
                hintText: 'e.g. 123 Galle Road',
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 14),

            // Address Line 2
            TextFormField(
              controller: _address2Controller,
              decoration: const InputDecoration(
                labelText: 'Address Line 2 (Optional)',
                hintText: 'Apartment, suite, or landmark',
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Postal Code
            TextFormField(
              controller: _postalController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Postal Code (Optional)',
                hintText: 'e.g. 00300',
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(false),
          style: TextButton.styleFrom(minimumSize: const Size(80, 48)),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _canSave && !_isSaving ? _handleSave : null,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(100, 48),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            disabledBackgroundColor: const Color(0xFFE2E8F0),
            disabledForegroundColor: const Color(0xFF94A3B8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text(
                  'Save',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
        ),
      ],
    );
  }
}
