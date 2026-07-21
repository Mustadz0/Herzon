import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:herzon/core/config/app_config.dart';
import 'package:herzon/core/theme/app_theme.dart';
import 'package:herzon/data/repositories/auth_repository.dart';
import 'package:herzon/data/repositories/post_repository.dart';
import 'package:herzon/data/repositories/poll_repository.dart';
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
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_performance/firebase_performance.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase FIRST (before any Firebase service)
  try {
    await Firebase.initializeApp().timeout(const Duration(seconds: 10));
    debugPrint('Firebase initialized');
  } catch (e) {
    debugPrint('Firebase init failed: $e');
  }

  // Initialize crash reporting — non-blocking, don't stall the app
  try {
    await CrashlyticsService.init().timeout(const Duration(seconds: 5));
  } catch (e) {
    debugPrint('CrashlyticsService.init failed: $e');
  }

  // Structured error widget — never expose stack traces in release mode
  ErrorWidget.builder = (FlutterErrorDetails details) {
    CrashlyticsService.recordError(
      details.exception,
      details.stack,
      reason: 'ErrorWidget: ${details.context}',
    );
    if (kDebugMode) {
      return Material(
        color: Colors.red.shade900,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Text(
              'DEBUG ERROR:\n${details.exceptionAsString()}',
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ),
      );
    }
    return const Material(
      color: Color(0xFF1A1A2E),
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 48),
              SizedBox(height: 16),
              Text(
                'Something went wrong.\nPlease restart the app.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ],
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

  PlatformDispatcher.instance.onError = (error, stack) {
    CrashlyticsService.recordError(error, stack, reason: 'PlatformDispatcher');
    return true;
  };

  AppConfig.validate();

  try {
    await Hive.initFlutter().timeout(const Duration(seconds: 10));
  } catch (e) {
    debugPrint('Hive init failed: $e');
  }

  try {
    await CacheService.init().timeout(const Duration(seconds: 10));
  } catch (e) {
    debugPrint('CacheService.init failed: $e');
  }

  bool supabaseReady = false;
  try {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      anonKey: AppConfig.supabaseAnonKey,
      accessToken: () async => FirebaseAuth.instance.currentUser?.getIdToken(),
    ).timeout(const Duration(seconds: 10));
    supabaseReady = true;
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      try {
        await CrashlyticsService.setUser(userId).timeout(const Duration(seconds: 5));
      } catch (e) {
        debugPrint('CrashlyticsService.setUser failed: $e');
      }
    }
  } catch (e) {
    debugPrint('Supabase init failed: $e');
    supabaseReady = false;
  }

  if (!supabaseReady) {
    debugPrint('CRITICAL: Supabase not available — app will show error state');
  }

  // Fire-and-forget: non-critical services — don't block runApp
  final featureFlagService = FeatureFlagService();
  unawaited(() async {
    try {
      await featureFlagService.init().timeout(const Duration(seconds: 8), onTimeout: () {
        debugPrint('FeatureFlagService.init timed out');
      });
    } catch (e) {
      debugPrint('FeatureFlagService.init failed: $e');
    }

    try {
      await NotificationService.instance.init().timeout(const Duration(seconds: 8), onTimeout: () {
        debugPrint('NotificationService.init timed out');
      });
    } catch (e) {
      debugPrint('NotificationService.init failed: $e');
    }

    try {
      await FirebaseAppCheck.instance.activate(
        androidProvider: kDebugMode
            ? AndroidProvider.debug
            : AndroidProvider.playIntegrity,
      ).timeout(const Duration(seconds: 10), onTimeout: () {
        debugPrint('App Check activation timed out');
      });
      debugPrint('Firebase App Check activated');
    } catch (e) {
      debugPrint('App Check init failed: $e');
    }

    try {
      await FirebasePerformance.instance
          .setPerformanceCollectionEnabled(!kDebugMode)
          .timeout(const Duration(seconds: 5), onTimeout: () {
        debugPrint('Performance Monitoring timed out');
      });
      if (!kDebugMode) debugPrint('Firebase Performance Monitoring activated');
    } catch (e) {
      debugPrint('Performance Monitoring init failed: $e');
    }
  }());

  runApp(
    ProviderScope(
      overrides: [
        if (supabaseReady) ...[
          authRepositoryProvider.overrideWithValue(
            SupabaseAuthRepository(supabase: Supabase.instance.client),
          ),
          postRepositoryProvider.overrideWithValue(
            SupabasePostRepository(supabase: Supabase.instance.client),
          ),
          pollRepositoryProvider.overrideWithValue(
            SupabasePollRepository(supabase: Supabase.instance.client),
          ),
        ],
      ],
      child: const HerzonApp(),
    ),
  );
}

class HerzonApp extends ConsumerWidget {
  const HerzonApp({super.key});

  static final Future<bool> _onboardingFuture = _checkOnboarding();

  static Future<bool> _checkOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('onboarding_complete') ?? false;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<bool>(
      future: _onboardingFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final showOnboarding = !snapshot.data!;
        final auth = ref.watch(authProvider);

        Widget home;
        if (auth.isLoading) {
          home = const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (showOnboarding) {
          home = const OnboardingScreen();
        } else if (auth.error != null) {
          home = Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 12),
                  const Text('Authentication error. Please try again.'),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => ref.invalidate(authProvider),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
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
              final userId =
                  ModalRoute.of(context)?.settings.arguments as String?;
              if (userId == null || userId.isEmpty) {
                return const LoginScreen();
              }
              return UserProfileScreen(userId: userId);
            },
            '/comments': (context) {
              final postId =
                  ModalRoute.of(context)?.settings.arguments as String?;
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
