import 'package:go_router/go_router.dart';

import '../../features/splash/presentation/splash_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/sign_up_email_screen.dart';
import '../../features/auth/presentation/screens/sign_up_otp_screen.dart';
import '../../features/auth/presentation/screens/sign_up_profile_screen.dart';
import '../../features/auth/presentation/screens/registration_success_screen.dart';
import '../presentation/screens/main_layout_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_email_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_otp_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_new_password_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_success_screen.dart';
import '../../features/profile/presentation/screens/edit_profile_screen.dart';
import '../../features/profile/presentation/screens/lifestyle_profile_screen.dart';
import '../../features/profile/presentation/screens/my_content_screen.dart';
import '../../features/profile/presentation/screens/adoption_applications_screen.dart';
import '../../features/profile/presentation/screens/my_rescues_screen.dart';
import '../../features/profile/presentation/screens/foster_care_screen.dart';
import '../../features/profile/presentation/screens/animal_transports_screen.dart';
import '../../features/profile/presentation/screens/sponsorships_screen.dart';
import '../../features/profile/presentation/screens/case_reviews_screen.dart';
import '../../features/profile/presentation/screens/verification_screen.dart';
import '../../features/profile/presentation/screens/verification_role_selection_screen.dart';
import '../../features/profile/presentation/screens/verification_upload_screen.dart';
import '../../features/profile/presentation/screens/verification_success_screen.dart';
import '../../features/profile/presentation/screens/public_profile_screen.dart';
import '../../features/community/presentation/screens/search_screen.dart';
import '../../features/community/presentation/screens/post_detail_screen.dart';

import '../../features/community/presentation/screens/create/pick_type_screen.dart';
import '../../features/community/presentation/screens/create/rescue/rescue_photos_screen.dart';
import '../../features/community/presentation/screens/create/rescue/rescue_triage_screen.dart';
import '../../features/community/presentation/screens/create/rescue/rescue_animal_screen.dart';
import '../../features/community/presentation/screens/create/rescue/rescue_location_screen.dart';
import '../../features/community/presentation/screens/create/rescue/rescue_review_screen.dart';
import '../../features/community/presentation/screens/create/foster-update/foster_update_link_rescue_screen.dart';
import '../../features/community/presentation/screens/create/foster-update/foster_update_content_screen.dart';
import '../../features/community/presentation/screens/create/foster-update/foster_update_photos_screen.dart';
import '../../features/community/presentation/screens/create/foster-update/foster_update_review_screen.dart';
import '../../features/community/presentation/screens/create/adoption/adoption_animal_screen.dart';
import '../../features/community/presentation/screens/create/adoption/adoption_lifestyle_screen.dart';
import '../../features/community/presentation/screens/create/adoption/adoption_photos_screen.dart';
import '../../features/community/presentation/screens/create/adoption/adoption_location_screen.dart';
import '../../features/community/presentation/screens/create/adoption/adoption_review_screen.dart';
import '../../features/community/presentation/screens/create/highlight/highlight_content_screen.dart';
import '../../features/community/presentation/screens/create/highlight/highlight_photos_screen.dart';
import '../../features/community/presentation/screens/create/highlight/highlight_review_screen.dart';
import '../../features/community/presentation/screens/create/transport/transport_pickup_screen.dart';
import '../../features/community/presentation/screens/create/transport/transport_dropoff_screen.dart';
import '../../features/community/presentation/screens/create/transport/transport_details_screen.dart';
import '../../features/community/presentation/screens/create/transport/transport_review_screen.dart';
import '../../features/community/presentation/screens/create/vet/vet_animal_screen.dart';
import '../../features/community/presentation/screens/create/vet/vet_details_screen.dart';
import '../../features/community/presentation/screens/create/vet/vet_transport_screen.dart';
import '../../features/community/presentation/screens/create/vet/vet_review_screen.dart';
import '../../features/community/presentation/screens/create/sponsor/sponsor_animal_screen.dart';
import '../../features/community/presentation/screens/create/sponsor/sponsor_goal_screen.dart';
import '../../features/community/presentation/screens/create/sponsor/sponsor_proof_screen.dart';
import '../../features/community/presentation/screens/create/sponsor/sponsor_photos_screen.dart';
import '../../features/community/presentation/screens/create/sponsor/sponsor_review_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/community/create/pick-type',
      builder: (context, state) => const PickTypeScreen(),
    ),
    GoRoute(
      path: '/community/create/rescue/photos',
      builder: (context, state) => const RescuePhotosScreen(),
    ),
    GoRoute(
      path: '/community/create/rescue/triage',
      builder: (context, state) => const RescueTriageScreen(),
    ),
    GoRoute(
      path: '/community/create/rescue/animal',
      builder: (context, state) => const RescueAnimalScreen(),
    ),
    GoRoute(
      path: '/community/create/rescue/location',
      builder: (context, state) => const RescueLocationScreen(),
    ),
    GoRoute(
      path: '/community/create/rescue/review',
      builder: (context, state) => const RescueReviewScreen(),
    ),
    GoRoute(
      path: '/community/create/foster-update/link-rescue',
      builder: (context, state) => const FosterUpdateLinkRescueScreen(),
    ),
    GoRoute(
      path: '/community/create/foster-update/content',
      builder: (context, state) => const FosterUpdateContentScreen(),
    ),
    GoRoute(
      path: '/community/create/foster-update/photos',
      builder: (context, state) => const FosterUpdatePhotosScreen(),
    ),
    GoRoute(
      path: '/community/create/foster-update/review',
      builder: (context, state) => const FosterUpdateReviewScreen(),
    ),
    GoRoute(
      path: '/community/create/adoption/animal',
      builder: (context, state) => const AdoptionAnimalScreen(),
    ),
    GoRoute(
      path: '/community/create/adoption/lifestyle',
      builder: (context, state) => const AdoptionLifestyleScreen(),
    ),
    GoRoute(
      path: '/community/create/adoption/photos',
      builder: (context, state) => const AdoptionPhotosScreen(),
    ),
    GoRoute(
      path: '/community/create/adoption/location',
      builder: (context, state) => const AdoptionLocationScreen(),
    ),
    GoRoute(
      path: '/community/create/adoption/review',
      builder: (context, state) => const AdoptionReviewScreen(),
    ),
    GoRoute(
      path: '/community/create/highlight/content',
      builder: (context, state) => const HighlightContentScreen(),
    ),
    GoRoute(
      path: '/community/create/highlight/photos',
      builder: (context, state) => const HighlightPhotosScreen(),
    ),
    GoRoute(
      path: '/community/create/highlight/review',
      builder: (context, state) => const HighlightReviewScreen(),
    ),
    GoRoute(
      path: '/community/create/transport/pickup',
      builder: (context, state) => const TransportPickupScreen(),
    ),
    GoRoute(
      path: '/community/create/transport/dropoff',
      builder: (context, state) => const TransportDropoffScreen(),
    ),
    GoRoute(
      path: '/community/create/transport/details',
      builder: (context, state) => const TransportDetailsScreen(),
    ),
    GoRoute(
      path: '/community/create/transport/review',
      builder: (context, state) => const TransportReviewScreen(),
    ),
    GoRoute(
      path: '/community/create/vet/animal',
      builder: (context, state) => const VetAnimalScreen(),
    ),
    GoRoute(
      path: '/community/create/vet/details',
      builder: (context, state) => const VetDetailsScreen(),
    ),
    GoRoute(
      path: '/community/create/vet/transport',
      builder: (context, state) => const VetTransportScreen(),
    ),
    GoRoute(
      path: '/community/create/vet/review',
      builder: (context, state) => const VetReviewScreen(),
    ),
    GoRoute(
      path: '/community/create/sponsor/animal',
      builder: (context, state) => const SponsorAnimalScreen(),
    ),
    GoRoute(
      path: '/community/create/sponsor/goal',
      builder: (context, state) => const SponsorGoalScreen(),
    ),
    GoRoute(
      path: '/community/create/sponsor/proof',
      builder: (context, state) => const SponsorProofScreen(),
    ),
    GoRoute(
      path: '/community/create/sponsor/photos',
      builder: (context, state) => const SponsorPhotosScreen(),
    ),
    GoRoute(
      path: '/community/create/sponsor/review',
      builder: (context, state) => const SponsorReviewScreen(),
    ),
    GoRoute(
      path: '/',
      builder: (context, state) => SplashScreen(
        onAuthenticated: () => context.go('/community'),
        onUnauthenticated: () => context.go('/onboarding'),
      ),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(
      path: '/signup/email',
      builder: (context, state) => const SignUpEmailScreen(),
    ),
    GoRoute(
      path: '/signup/otp',
      builder: (context, state) => const SignUpOtpScreen(),
    ),
    GoRoute(
      path: '/signup/profile',
      builder: (context, state) => const SignUpProfileScreen(),
    ),
    GoRoute(
      path: '/signup/complete',
      builder: (context, state) => const RegistrationSuccessScreen(),
    ),
    GoRoute(
      path: '/community',
      builder: (context, state) => const MainLayoutScreen(),
    ),
    GoRoute(
      path: '/forgot-password/email',
      builder: (context, state) => const ForgotPasswordEmailScreen(),
    ),
    GoRoute(
      path: '/forgot-password/otp',
      builder: (context, state) => const ForgotPasswordOtpScreen(),
    ),
    GoRoute(
      path: '/forgot-password/new-password',
      builder: (context, state) => const ForgotPasswordNewPasswordScreen(),
    ),
    GoRoute(
      path: '/forgot-password/success',
      builder: (context, state) => const ForgotPasswordSuccessScreen(),
    ),
    GoRoute(
      path: '/profile/edit',
      builder: (context, state) {
        final openAddress =
            state.uri.queryParameters['openAddress'] == 'true' ||
            (state.extra is Map && (state.extra as Map)['openAddress'] == true);
        return EditProfileScreen(openAddressOnMount: openAddress);
      },
    ),
    GoRoute(
      path: '/profile/lifestyle',
      builder: (context, state) => const LifestyleProfileScreen(),
    ),
    GoRoute(
      path: '/notifications',
      builder: (context, state) => const MainLayoutScreen(initialIndex: 4),
    ),
    GoRoute(
      path: '/profile/content',
      builder: (context, state) => const MyContentScreen(),
    ),
    GoRoute(
      path: '/profile/applications',
      builder: (context, state) => const AdoptionApplicationsScreen(),
    ),
    GoRoute(
      path: '/profile/rescues',
      builder: (context, state) => const MyRescuesScreen(),
    ),
    GoRoute(
      path: '/profile/foster-care',
      builder: (context, state) => const FosterCareScreen(),
    ),
    GoRoute(
      path: '/profile/transports',
      builder: (context, state) => const AnimalTransportsScreen(),
    ),
    GoRoute(
      path: '/profile/sponsorships',
      builder: (context, state) => const SponsorshipsScreen(),
    ),
    GoRoute(
      path: '/profile/case-reviews',
      builder: (context, state) => const CaseReviewsScreen(),
    ),
    GoRoute(
      path: '/verification',
      builder: (context, state) => const VerificationScreen(),
    ),
    GoRoute(
      path: '/verification/role-select',
      builder: (context, state) => const VerificationRoleSelectionScreen(),
    ),
    GoRoute(
      path: '/verification/upload',
      builder: (context, state) => const VerificationUploadScreen(),
    ),
    GoRoute(
      path: '/verification/success',
      builder: (context, state) => const VerificationSuccessScreen(),
    ),
    GoRoute(path: '/search', builder: (context, state) => const SearchScreen()),
    GoRoute(
      path: '/profile/public/:id',
      builder: (context, state) {
        final idStr = state.pathParameters['id'] ?? '0';
        final id = int.tryParse(idStr) ?? 0;
        return PublicProfileScreen(userId: id);
      },
    ),
    GoRoute(
      path: '/community/post/:id',
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        return PostDetailScreen(postId: id);
      },
    ),
  ],
);
