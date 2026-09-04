import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../../core/theme/app_colors.dart';

import 'package:provider/provider.dart';

import '../../../controllers/create_post_controller.dart';

import '../../../widgets/create_post_app_bar.dart';

class TransportDetailsScreen extends StatefulWidget {
  const TransportDetailsScreen({super.key});

  @override
  State<TransportDetailsScreen> createState() => _TransportDetailsScreenState();
}

class _TransportDetailsScreenState extends State<TransportDetailsScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _descController;
  late final TextEditingController _speciesController;
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    final controller = context.read<CreatePostController>();

    String initialTitle = controller.title;
    if (initialTitle.isEmpty &&
        controller.locationLabel.isNotEmpty &&
        controller.dropoffLocationLabel.isNotEmpty) {
      initialTitle =
          'Transport needed: ${controller.locationLabel} to ${controller.dropoffLocationLabel}';
      // It's max 120 chars, let's just substring if needed
      if (initialTitle.length > 120) {
        initialTitle = initialTitle.substring(0, 120);
      }
      controller.title = initialTitle;
    }

    _titleController = TextEditingController(text: initialTitle);
    _descController = TextEditingController(text: controller.body);
    _speciesController = TextEditingController(text: controller.species);
    _nameController = TextEditingController(text: controller.animalName);

    _titleController.addListener(
      () => controller.title = _titleController.text,
    );
    _descController.addListener(() => controller.body = _descController.text);
    _speciesController.addListener(
      () => controller.species = _speciesController.text,
    );
    _nameController.addListener(
      () => controller.animalName = _nameController.text,
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _speciesController.dispose();
    _nameController.dispose();
    super.dispose();
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
              valueListenable: _titleController,
              builder: (context, value, child) {
                final isValid = value.text.trim().isNotEmpty;
                return FilledButton(
                  onPressed: isValid
                      ? () {
                          context.push('/community/create/transport/review');
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
