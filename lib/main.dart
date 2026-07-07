import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:herzon/core/theme/app_theme.dart';
import 'package:herzon/data/repositories/auth_repository.dart';
import 'package:herzon/data/repositories/post_repository.dart';
import 'package:herzon/presentation/providers/auth_provider.dart';
import 'package:herzon/presentation/screens/login_screen.dart';
import 'package:herzon/presentation/screens/home_screen.dart';
import 'package:herzon/presentation/screens/onboarding_screen.dart';
import 'package:herzon/presentation/screens/admin/admin_home_screen.dart';
import 'package:herzon/presentation/screens/comments_screen.dart';
import 'package:herzon/presentation/screens/user_profile_screen.dart';
import 'package:herzon/presentation/screens/create_story_screen.dart';
import 'package:herzon/presentation/screens/leaderboard_screen.dart';
import 'package:herzon/presentation/screens/ride_sharing_screen.dart';
import 'package:herzon/presentation/screens/badges_screen.dart';
import 'package:herzon/presentation/screens/create_post_screen.dart';
import 'package:herzon/services/cache_service.dart';
import 'package:herzon/services/feature_flag_service.dart';
import 'package:herzon/services/notification_service.dart';
import 'package:herzon/services/crashlytics_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize crash reporting FIRST (before anything else)
  await CrashlyticsService.init();

  ErrorWidget.builder = (FlutterErrorDetails details) {
    CrashlyticsService.recordError(
      details.exception,
      details.stack,
      reason: 'ErrorWidget: ${details.context}',
    );
    return Material(
      color: Colors.red.shade900,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Text(
            'RUNTIME ERROR:\n${details.exceptionAsString()}\n\n${details.stack}',
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ),
      ),
    );
  };

  FlutterError.onError = (details) {
    CrashlyticsService.recordError(
      details.exception,
      details.stack,
      reason: 'FlutterError: ${details.context}',
    );
  };

  try {
    await Hive.initFlutter();
  } catch (e) {
    debugPrint('Hive init failed: $e');
  }

  try {
    await CacheService.init();
  } catch (e) {
    debugPrint('CacheService.init failed: $e');
  }

  // Load environment variables from .env
  await dotenv.load(fileName: '.env');

  final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  try {
    await Supabase.initialize(url: supabaseUrl, publishableKey: supabaseAnonKey);
    // Set user in crash reporter
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null) {
      await CrashlyticsService.setUser(userId);
    }
  } catch (e) {
    debugPrint('Supabase init failed: $e');
  }

  try {
    await FeatureFlagService.init();
  } catch (e) {
    debugPrint('FeatureFlagService.init failed: $e');
  }

  try {
    await NotificationService.instance.init();
  } catch (_) {}

  runApp(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(
          SupabaseAuthRepository(supabase: Supabase.instance.client),
        ),
        postRepositoryProvider.overrideWithValue(
          SupabasePostRepository(supabase: Supabase.instance.client),
        ),
      ],
      child: const HerzonApp(),
    ),
  );
}

class HerzonApp extends ConsumerWidget {
  const HerzonApp({super.key});

  Future<bool> _checkOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('onboarding_complete') ?? false;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<bool>(
      future: _checkOnboarding(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(body: Center(child: CircularProgressIndicator())),
          );
        }

        final showOnboarding = !snapshot.data!;
        final auth = ref.watch(authProvider);

        Widget home;
        if (auth.isLoading) {
          home = const Scaffold(body: Center(child: CircularProgressIndicator()));
        } else if (showOnboarding) {
          home = const OnboardingScreen();
        } else if (auth.error != null) {
          home = Scaffold(body: Center(child: Text('Error: ${auth.error}')));
        } else if (auth.isAuthenticated) {
          home = const NotificationTapHandler(child: HomeScreen());
        } else {
          home = const LoginScreen();
        }

        return MaterialApp(
          title: 'Herzon',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.system,
          home: home,
          routes: {
            '/login': (context) => const LoginScreen(),
            '/admin': (context) => const AdminHomeScreen(),
            '/profile': (context) {
              final userId = ModalRoute.of(context)?.settings.arguments as String?;
              return UserProfileScreen(userId: userId ?? '');
            },
            '/comments': (context) {
              final postId = ModalRoute.of(context)?.settings.arguments as String?;
              return CommentsScreen(postId: postId ?? '');
            },
            '/create_story': (context) => const CreateStoryScreen(),
            '/create_post': (context) => const CreatePostScreen(),
            '/leaderboard': (context) => const LeaderboardScreen(),
            '/ride_sharing': (context) => const RideSharingScreen(),
            '/badges': (context) => const BadgesScreen(),
          },
        );
      },
    );
  }
}
