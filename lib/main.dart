import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

import 'core/theme/app_theme.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/post_repository.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/screens/login_screen.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/screens/admin/admin_home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const supabaseUrl = 'https://xhjglurrmnmpqzbvctgn.supabase.co';
  const supabaseAnonKey = 'sb_publishable_2wfhoUBeSMqhEZYs0G0c4g_RQS8cnMq';

  await Supabase.initialize(url: supabaseUrl, publishableKey: supabaseAnonKey);

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
      child: const ProximiteApp(),
    ),
  );
}

class ProximiteApp extends ConsumerWidget {
  const ProximiteApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);

    Widget home;
    if (auth.isLoading) {
      home = const Scaffold(body: Center(child: CircularProgressIndicator()));
    } else if (auth.error != null) {
      home = Scaffold(body: Center(child: Text('Error: ${auth.error}')));
    } else if (auth.isAuthenticated) {
      home = const HomeScreen();
    } else {
      home = const LoginScreen();
    }

    return MaterialApp(
      title: 'Proximite',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: home,
      routes: {
        '/admin': (_) => const AdminHomeScreen(),
      },
    );
  }
}
