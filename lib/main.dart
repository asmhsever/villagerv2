import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:superprojectv2/views/juristic/house/house_main_screen.dart';

import 'views/login/role_selector_screen.dart';
import 'views/login/resident_login_screen.dart';
import 'dashboard/admin_dashboard.dart';
import 'dashboard/juristic_dashboard.dart';
import 'views/juristic/notion/notion_screen.dart';
import 'views/juristic/complaint/complaint_screen.dart';
import 'dashboard/resident_dashboard.dart';
import 'views/resident/complaint_screen.dart';
import 'views/juristic/bill/bill_screen.dart';
import 'views/resident/notion_screen.dart';
import 'views/juristic/fees/fees_screen.dart';
import 'views/juristic/profile/profile_screen.dart';
import 'views/juristic/profile/change_password_screen.dart';
import 'views/juristic/profile/edit_profile_screen.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('th_TH', null);
  await Supabase.initialize(
    url: 'https://rehsssptxuhahcfoxubc.supabase.co/',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJlaHNzc3B0eHVoYWhjZm94dWJjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDI1OTIwMzcsImV4cCI6MjA1ODE2ODAzN30.M1ueNssOTWHs6nQ3BQGWafIMPIs7kJfSmPDWIJ2VYBk',
  );
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smart Village',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const RoleSelectorScreen(),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('th', 'TH'),
        Locale('en', 'US'),
      ],
      routes: {
        '/admin': (context) => const AdminDashboard(),
        '/juristic': (context) => const JuristicDashboard(),
        '/juristic/notion': (context) => const NotionScreen(),
        '/juristic/complaints': (context) => const JuristicComplaintScreen(),
        '/juristic/fees': (context) {
          final args = ModalRoute.of(context)!.settings.arguments;
          if (args is int) {
            return JuristicFeesScreen(villageId: args);
          } else {
            return const Scaffold(
              body: Center(child: Text('❌ villageId not provided')),
            );
          }
        },

        '/resident': (context) => const ResidentDashboard(),
        '/resident/bill': (_) => const ResidentBillScreen(),
        '/resident/complaint': (_) => const ResidentComplaintScreen(),
        '/resident/login': (_) => const ResidentLoginScreen(),
        '/resident/notion': (context) => const ResidentNotionScreen(),
        '/juristic/profile': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as int;
          return JuristicProfileScreen(lawId: args);
        },
        '/change-password': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map;
          return ChangePasswordScreen(lawId: args['law_id']);
        },
        '/edit-profile': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map;
          return EditProfileScreen(lawId: args['law_id']);
        },
        '/juristic/houses': (context) {
          final villageId = ModalRoute.of(context)!.settings.arguments as int;
          return HouseMainScreen(villageId: villageId);
        },




      },
    );
  }
}
