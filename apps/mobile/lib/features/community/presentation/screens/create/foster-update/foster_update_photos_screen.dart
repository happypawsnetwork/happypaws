
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../controllers/create_post_controller.dart';
import '../../../widgets/create_post_app_bar.dart';

class FosterUpdatePhotosScreen extends StatefulWidget {
  const FosterUpdatePhotosScreen({super.key});

  @override
  State<FosterUpdatePhotosScreen> createState() =>
      _FosterUpdatePhotosScreenState();
}

class _FosterUpdatePhotosScreenState extends State<FosterUpdatePhotosScreen> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final controller = context.read<CreatePostController>();
    if (controller.photos.length >= 4) return;

    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          controller.photos.add(image.path);
        });
      }
    } catch (e) {
      // Ignore
    }
  }

  void _removeImage(int index) {
    final controller = context.read<CreatePostController>();
    setState(() {
      controller.photos.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<CreatePostController>();

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
              onPressed: () {
                context.push('/community/create/foster-update/review');
              },
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
