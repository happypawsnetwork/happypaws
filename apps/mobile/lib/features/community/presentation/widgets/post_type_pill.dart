import 'package:flutter/material.dart';

import '../../domain/models/post.dart';
import '../../../../core/theme/app_colors.dart';

import 'package:google_fonts/google_fonts.dart';

class PostTypePill extends StatelessWidget {
  final PostType type;

  const PostTypePill({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    String label = '';
    Color color = AppColors.primary;

    switch (type) {
      case PostType.rescueAlert:
        label = '🚨 Rescue';
        color = PostTypeColors.rescue;
        break;
      case PostType.fosterUpdate:
        label = '🐾 Update';
        color = PostTypeColors.update;
        break;
      case PostType.adoptionListing:
        label = '🏠 Find Home';
        color = PostTypeColors.findHome;
        break;
      case PostType.highlight:
        label = '✨ Highlight';
        color = PostTypeColors.highlight;
        break;
      case PostType.transportRequest:
        label = '🚐 Transport';
        color = PostTypeColors.transport;
        break;
      case PostType.vetRequest:
        label = '💊 Treatment';
        color = PostTypeColors.treatment;
        break;
      case PostType.sponsorshipRequest:
        label = '💛 Sponsor';
        color = PostTypeColors.sponsor;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        label,
        style: GoogleFonts.outfit(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
