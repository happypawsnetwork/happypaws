import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../controllers/create_post_controller.dart';
import '../../../widgets/create_post_app_bar.dart';

class FosterUpdateContentScreen extends StatefulWidget {
  const FosterUpdateContentScreen({super.key});

  @override
  State<FosterUpdateContentScreen> createState() =>
      _FosterUpdateContentScreenState();
}

class _FosterUpdateContentScreenState extends State<FosterUpdateContentScreen> {
  late TextEditingController _titleController;
  late TextEditingController _bodyController;

  @override
  void initState() {
    super.initState();
    final controller = context.read<CreatePostController>();
    _titleController = TextEditingController(text: controller.title);
    _bodyController = TextEditingController(text: controller.body);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  void _updateState() {
    final controller = context.read<CreatePostController>();
    controller.title = _titleController.text.trim();
    controller.body = _bodyController.text.trim();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final bool canProceed =
        _titleController.text.trim().isNotEmpty &&
        _bodyController.text.trim().isNotEmpty;

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
              onPressed: canProceed
                  ? () {
                      context.push('/community/create/foster-update/photos');
                    }
                  : null,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor: AppColors.primary.withValues(
                  alpha: 0.5,
                ),
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
