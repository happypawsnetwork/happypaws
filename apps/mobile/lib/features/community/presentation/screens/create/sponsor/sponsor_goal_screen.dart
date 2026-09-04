import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../controllers/create_post_controller.dart';
import '../../../widgets/create_post_app_bar.dart';

class SponsorGoalScreen extends StatefulWidget {
  const SponsorGoalScreen({super.key});

  @override
  State<SponsorGoalScreen> createState() => _SponsorGoalScreenState();
}

class _SponsorGoalScreenState extends State<SponsorGoalScreen> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _amountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final controller = context.read<CreatePostController>();
    _titleController.text = controller.title;
    _bodyController.text = controller.body;
    if (controller.sponsorAmount != null) {
      _amountController.text = controller.sponsorAmount.toString();
    }

    _titleController.addListener(() => setState(() {}));
    _bodyController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _onNext() {
    final controller = context.read<CreatePostController>();
    controller.title = _titleController.text.trim();
    controller.body = _bodyController.text.trim();
    final amountText = _amountController.text.trim();
    if (amountText.isNotEmpty) {
      controller.sponsorAmount = double.tryParse(amountText);
    } else {
      controller.sponsorAmount = null;
    }
    context.push('/community/create/sponsor/proof');
  }

  @override
  Widget build(BuildContext context) {
    final isNextEnabled =
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
              onPressed: isNextEnabled ? _onNext : null,
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
