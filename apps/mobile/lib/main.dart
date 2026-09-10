import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/config/env_config.dart';
import 'core/network/api_client.dart';
import 'core/router/app_router.dart';
import 'core/storage/secure_token_service.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/domain/repositories/i_auth_repository.dart';
import 'features/auth/presentation/controllers/sign_up_controller.dart';
import 'features/auth/presentation/controllers/login_controller.dart';
import 'features/auth/presentation/controllers/forgot_password_controller.dart';
import 'features/profile/presentation/controllers/profile_controller.dart';
import 'features/profile/data/profile_repository.dart';
import 'features/profile/domain/repositories/i_profile_repository.dart';
import 'features/profile/presentation/controllers/edit_profile_controller.dart';
import 'features/profile/data/verification_repository.dart';
import 'features/profile/domain/repositories/i_verification_repository.dart';
import 'features/profile/presentation/controllers/lifestyle_profile_controller.dart';
import 'features/profile/presentation/controllers/verification_controller.dart';
import 'features/community/data/repositories/post_repository.dart';
import 'features/community/domain/repositories/i_post_repository.dart';
import 'features/community/presentation/controllers/community_controller.dart';
import 'features/community/presentation/controllers/create_post_controller.dart';
import 'features/community/presentation/controllers/search_feed_controller.dart';
import 'features/messaging/presentation/controllers/chat_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await EnvConfig.load();

  final tokenService = SecureTokenService();
  final apiClient = ApiClient(tokenService: tokenService);
  final authRepository = AuthRepository(apiClient, tokenService);
  final profileRepository = ProfileRepository(apiClient);
  final verificationRepository = VerificationRepository(apiClient);
  final postRepository = PostRepository(apiClient);

  runApp(
    MultiProvider(
      providers: [
        Provider<ApiClient>.value(value: apiClient),
        Provider<IAuthRepository>.value(value: authRepository),
        Provider<IProfileRepository>.value(value: profileRepository),
        Provider<IVerificationRepository>.value(value: verificationRepository),
        Provider<IPostRepository>.value(value: postRepository),
        ChangeNotifierProvider(create: (_) => SignUpController(authRepository)),
        ChangeNotifierProvider(create: (_) => LoginController(authRepository)),
        ChangeNotifierProvider(
          create: (_) => ForgotPasswordController(authRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => ProfileController(authRepository),
        ),
        ChangeNotifierProvider(
          create: (_) =>
              EditProfileController(profileRepository, authRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => LifestyleProfileController(profileRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => VerificationController(verificationRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => CommunityController(postRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => CreatePostController(postRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => SearchFeedController(postRepository),
        ),
        ChangeNotifierProvider(create: (_) => ChatController()),
      ],
      child: const HappyPawsApp(),
    ),
  );
}

class HappyPawsApp extends StatelessWidget {
  const HappyPawsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Happy Paws',
      theme: AppTheme.lightTheme,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
