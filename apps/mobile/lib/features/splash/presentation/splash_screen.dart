import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/services/location_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/domain/repositories/i_auth_repository.dart';
import 'widgets/animated_splash_logo.dart';
import 'widgets/connection_error_bottom_sheet.dart';

/// Splash screen that displays the Happy Paws logo while verifying connectivity and session state.
class SplashScreen extends StatefulWidget {
  final VoidCallback onAuthenticated;
  final VoidCallback onUnauthenticated;

  /// Creates a splash screen.
  const SplashScreen({
    super.key,
    required this.onAuthenticated,
    required this.onUnauthenticated,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  // Request location permission once here so the OS dialog appears at a
  // natural pause and never interrupts the user mid-post-creation flow.
  final _locationService = const LocationService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _checkNetworkAndAuth();
      }
    });
  }

  Future<void> _checkNetworkAndAuth() async {
    bool isAuthenticated = false;
    try {
      final authRepo = context.read<IAuthRepository>();
      isAuthenticated = await authRepo.checkSessionStatus();
    } catch (e, st) {
      debugPrint('SplashScreen auth/network error: $e\n$st');
      if (!mounted) return;
      ConnectionErrorBottomSheet.show(
        context,
        onTryAgain: _checkNetworkAndAuth,
      );
      return;
    }

    if (!mounted) return;

    try {
      // Request location regardless of auth state so the dialog fires once
      // during the splash rather than when the user opens a rescue or
      // transport post form.
      await _locationService.requestPermission();
    } catch (e, st) {
      debugPrint('SplashScreen location error ignored: $e\n$st');
    }

    if (!mounted) return;

    if (isAuthenticated) {
      widget.onAuthenticated();
    } else {
      widget.onUnauthenticated();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.splashBackground,
      body: Center(
        child: Semantics(
          label: 'Happy Paws logo',
          image: true,
          child: const AnimatedSplashLogo(size: 220.0),
        ),
      ),
    );
  }
}
