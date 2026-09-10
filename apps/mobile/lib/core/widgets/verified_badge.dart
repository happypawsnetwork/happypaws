import 'package:flutter/material.dart';

/// Renders a verified checkmark badge next to a user's name when they are verified for at least one role.
class VerifiedBadge extends StatelessWidget {
  final double size;

  const VerifiedBadge({super.key, this.size = 18});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Verified',
      child: Icon(
        Icons.verified_rounded,
        size: size,
        color: const Color(0xFF0064E0),
      ),
    );
  }
}
