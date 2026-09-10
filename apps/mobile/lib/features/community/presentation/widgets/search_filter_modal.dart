import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../controllers/search_feed_controller.dart';

/// Modal bottom sheet providing filters for species, location, urgency, and post type.
class SearchFilterModal extends StatefulWidget {
  final SearchFeedController controller;

  const SearchFilterModal({super.key, required this.controller});

  static Future<void> show(
    BuildContext context,
    SearchFeedController controller,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SearchFilterModal(controller: controller),
    );
  }

  @override
  State<SearchFilterModal> createState() => _SearchFilterModalState();
}

class _SearchFilterModalState extends State<SearchFilterModal> {
  late String? _selectedSpecies;
  late String? _selectedLocation;
  late String? _selectedUrgency;
  late String? _selectedType;
  late bool _onlyRecommended;

  late final TextEditingController _locationController;
  late final TextEditingController _customSpeciesController;

  static const List<String> _speciesOptions = [
    'All',
    'Dog',
    'Cat',
    'Rabbit',
    'Bird',
  ];

  static const List<String> _urgencyOptions = [
    'All',
    'Critical',
    'High',
    'Medium',
    'Low',
  ];

  static const List<Map<String, String>> _typeOptions = [
    {'label': 'All listings', 'value': 'All'},
    {'label': '🏠 Find Home', 'value': 'AdoptionListing'},
    {'label': '🚨 Rescue', 'value': 'RescueAlert'},
  ];

  static const List<String> _popularCities = [
    'Colombo',
    'Kandy',
    'Galle',
    'Gampaha',
    'Negombo',
    'Jaffna',
    'Matara',
    'Kurunegala',
  ];

  @override
  void initState() {
    super.initState();
    _selectedSpecies = widget.controller.species ?? 'All';
    _selectedLocation = widget.controller.location;
    _selectedUrgency = widget.controller.urgency ?? 'All';
    _selectedType = widget.controller.type ?? 'All';
    _onlyRecommended = widget.controller.onlyRecommended;

    _locationController = TextEditingController(text: _selectedLocation ?? '');
    _customSpeciesController = TextEditingController(
      text: _speciesOptions.contains(_selectedSpecies)
          ? ''
          : (_selectedSpecies ?? ''),
    );
  }

  @override
  void dispose() {
    _locationController.dispose();
    _customSpeciesController.dispose();
    super.dispose();
  }

  void _resetAll() {
    setState(() {
      _selectedSpecies = 'All';
      _selectedLocation = null;
      _selectedUrgency = 'All';
      _selectedType = 'All';
      _onlyRecommended = false;
      _locationController.clear();
      _customSpeciesController.clear();
    });
  }

  void _apply() {
    final locationText = _locationController.text.trim();
    final customSpeciesText = _customSpeciesController.text.trim();

    String? finalSpecies = _selectedSpecies;
    if (_selectedSpecies == 'Other' && customSpeciesText.isNotEmpty) {
      finalSpecies = customSpeciesText;
    }

    widget.controller.applyFilters(
      species: finalSpecies,
      location: locationText.isNotEmpty ? locationText : null,
      urgency: _selectedUrgency,
      type: _selectedType,
      onlyRecommended: _onlyRecommended,
    );

    Navigator.of(context).pop();
  }

  int get _activeCount {
    int count = 0;
    if (_selectedSpecies != null && _selectedSpecies != 'All') count++;
    if (_locationController.text.trim().isNotEmpty) count++;
    if (_selectedUrgency != null && _selectedUrgency != 'All') count++;
    if (_selectedType != null && _selectedType != 'All') count++;
    if (_onlyRecommended) count++;
    return count;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Filters',
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Row(
                    children: [
                      TextButton(
                        onPressed: _resetAll,
                        child: Text(
                          'Reset all',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.close,
                          color: AppColors.textSecondary,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Independence info banner
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      size: 18,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Searches all listed animals directly, independent of your lifestyle profile suggestions.',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: AppColors.primary,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Section: Listing Type
              _buildSectionTitle('Listing type'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _typeOptions.map((opt) {
                  final isSelected = _selectedType == opt['value'];
                  return ChoiceChip(
                    label: Text(
                      opt['label']!,
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w500,
                        color: isSelected
                            ? Colors.white
                            : AppColors.textPrimary,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: AppColors.primary,
                    backgroundColor: const Color(0xFFF1F5F9),
                    showCheckmark: false,
                    onSelected: (_) {
                      setState(() {
                        _selectedType = opt['value'];
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Section: Species
              _buildSectionTitle('Species'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ..._speciesOptions.map((sp) {
                    final isSelected = _selectedSpecies == sp;
                    return ChoiceChip(
                      label: Text(
                        sp,
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : AppColors.textPrimary,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: AppColors.primary,
                      backgroundColor: const Color(0xFFF1F5F9),
                      showCheckmark: false,
                      onSelected: (_) {
                        setState(() {
                          _selectedSpecies = sp;
                          _customSpeciesController.clear();
                        });
                      },
                    );
                  }),
                  ChoiceChip(
                    label: Text(
                      'Other',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w500,
                        color:
                            (_selectedSpecies == 'Other' ||
                                (!_speciesOptions.contains(_selectedSpecies) &&
                                    _selectedSpecies != null &&
                                    _selectedSpecies!.isNotEmpty))
                            ? Colors.white
                            : AppColors.textPrimary,
                      ),
                    ),
                    selected:
                        _selectedSpecies == 'Other' ||
                        (!_speciesOptions.contains(_selectedSpecies) &&
                            _selectedSpecies != null &&
                            _selectedSpecies!.isNotEmpty),
                    selectedColor: AppColors.primary,
                    backgroundColor: const Color(0xFFF1F5F9),
                    showCheckmark: false,
                    onSelected: (_) {
                      setState(() {
                        _selectedSpecies = 'Other';
                      });
                    },
                  ),
                ],
              ),
              if (_selectedSpecies == 'Other' ||
                  (!_speciesOptions.contains(_selectedSpecies) &&
                      _selectedSpecies != null &&
                      _selectedSpecies!.isNotEmpty)) ...[
                const SizedBox(height: 10),
                TextField(
                  controller: _customSpeciesController,
                  decoration: InputDecoration(
                    hintText: 'Enter species (e.g. Turtle, Hamster)',
                    hintStyle: GoogleFonts.outfit(
                      color: AppColors.textSecondary,
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),

              // Section: Urgency
              _buildSectionTitle('Urgency level'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _urgencyOptions.map((urg) {
                  final isSelected = _selectedUrgency == urg;
                  Color chipBg = const Color(0xFFF1F5F9);
                  Color chipText = AppColors.textPrimary;
                  BorderSide side = BorderSide.none;

                  if (urg == 'Critical') {
                    chipBg = isSelected
                        ? UrgencyColors.criticalText
                        : UrgencyColors.criticalBg;
                    chipText = isSelected
                        ? Colors.white
                        : UrgencyColors.criticalText;
                    side = const BorderSide(
                      color: UrgencyColors.criticalBorder,
                    );
                  } else if (urg == 'High') {
                    chipBg = isSelected
                        ? UrgencyColors.highText
                        : UrgencyColors.highBg;
                    chipText = isSelected
                        ? Colors.white
                        : UrgencyColors.highText;
                    side = const BorderSide(color: UrgencyColors.highBorder);
                  } else if (urg == 'Medium') {
                    chipBg = isSelected
                        ? UrgencyColors.mediumText
                        : UrgencyColors.mediumBg;
                    chipText = isSelected
                        ? Colors.white
                        : UrgencyColors.mediumText;
                    side = const BorderSide(color: UrgencyColors.mediumBorder);
                  } else if (urg == 'Low') {
                    chipBg = isSelected
                        ? UrgencyColors.lowText
                        : UrgencyColors.lowBg;
                    chipText = isSelected
                        ? Colors.white
                        : UrgencyColors.lowText;
                    side = const BorderSide(color: UrgencyColors.lowBorder);
                  } else if (isSelected) {
                    chipBg = AppColors.primary;
                    chipText = Colors.white;
                  }

                  return ChoiceChip(
                    label: Text(
                      urg,
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w600,
                        color: chipText,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: chipBg,
                    backgroundColor: chipBg,
                    side: side,
                    showCheckmark: false,
                    onSelected: (_) {
                      setState(() {
                        _selectedUrgency = urg;
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Section: Location
              _buildSectionTitle('Location'),
              TextField(
                controller: _locationController,
                decoration: InputDecoration(
                  hintText: 'City, town, or area (e.g. Colombo)',
                  hintStyle: GoogleFonts.outfit(color: AppColors.textSecondary),
                  prefixIcon: const Icon(
                    Icons.location_on_outlined,
                    color: AppColors.textSecondary,
                  ),
                  suffixIcon: _locationController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            setState(() {
                              _locationController.clear();
                              _selectedLocation = null;
                            });
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                ),
                onChanged: (text) => setState(() {}),
              ),
              const SizedBox(height: 10),

              // Popular cities quick chips
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _popularCities.map((city) {
                  final isSelected =
                      _locationController.text.trim().toLowerCase() ==
                      city.toLowerCase();
                  return ActionChip(
                    label: Text(
                      city,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: isSelected
                            ? Colors.white
                            : AppColors.textSecondary,
                      ),
                    ),
                    backgroundColor: isSelected
                        ? AppColors.primary
                        : const Color(0xFFF1F5F9),
                    side: BorderSide.none,
                    onPressed: () {
                      setState(() {
                        if (isSelected) {
                          _locationController.clear();
                          _selectedLocation = null;
                        } else {
                          _locationController.text = city;
                          _selectedLocation = city;
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Section: Matching Recommendation Toggle (Optional filter)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Lifestyle recommendations only',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            'Only show animals matching your profile',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch.adaptive(
                      value: _onlyRecommended,
                      activeTrackColor: AppColors.primary,
                      onChanged: (val) {
                        setState(() {
                          _onlyRecommended = val;
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Apply button
              FilledButton(
                onPressed: _apply,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  _activeCount > 0
                      ? 'Apply filters ($_activeCount)'
                      : 'Apply filters',
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
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: GoogleFonts.outfit(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}
