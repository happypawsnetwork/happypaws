import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'dart:io';

import 'package:image_picker/image_picker.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../controllers/create_post_controller.dart';
import '../../../widgets/create_post_app_bar.dart';

class AdoptionPhotosScreen extends StatefulWidget {
  const AdoptionPhotosScreen({super.key});

  @override
  State<AdoptionPhotosScreen> createState() => _AdoptionPhotosScreenState();
}

class _AdoptionPhotosScreenState extends State<AdoptionPhotosScreen> {
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
  }

  Future<void> _pickPhotos() async {
    final controller = context.read<CreatePostController>();
    if (controller.photos.length >= 4) return;

    try {
      final List<XFile> picked = await _picker.pickMultiImage();
      if (picked.isNotEmpty) {
        setState(() {
          for (var file in picked) {
            if (controller.photos.length < 4) {
              controller.photos.add(file.path);
            }
          }
        });
      }
    } catch (e) {
      // Stub fallback if not supported
      setState(() {
        if (controller.photos.length < 4) {
          controller.photos.add(
            'stub_photo_path_${DateTime.now().millisecondsSinceEpoch}.jpg',
          );
        }
      });
    }
  }

  void _removePhoto(int index) {
    final controller = context.read<CreatePostController>();
    setState(() {
      controller.photos.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<CreatePostController>();
    final hasPhotos = controller.photos.isNotEmpty;
    final canAddMore = controller.photos.length < 4;

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
              onPressed: hasPhotos
                  ? () {
                      context.push('/community/create/adoption/location');
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

  Widget _buildImage(String path) {
    if (path.startsWith('stub_photo_path')) {
      return Container(
        width: 80,
        height: 80,
        color: Colors.grey.shade300,
        child: const Icon(Icons.image, color: Colors.grey),
      );
    }
    return Image.file(
      File(path),
      width: 80,
      height: 80,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Container(
        width: 80,
        height: 80,
        color: Colors.grey.shade300,
        child: const Icon(Icons.broken_image, color: Colors.grey),
      ),
    );
  }
}
