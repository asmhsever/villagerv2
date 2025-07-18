// lib/main.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fullproject/extensions/context_extensions.dart';
import 'package:fullproject/navigation/app_navigation.dart';
import 'package:fullproject/pages/notfound_age.dart';
import 'package:fullproject/routes/app_routes.dart';
import 'package:fullproject/routes/route_generator.dart';
import 'config/supabase_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Nivilla",
      navigatorKey: AppNavigation.navigatorKey,
      onGenerateRoute: RouteGenerator.generateRoute,
      initialRoute: AppRoutes.login,
      onUnknownRoute: (settings) {
        return MaterialPageRoute(builder: (context) => NotFoundPage());
      },
    );
  }
}
