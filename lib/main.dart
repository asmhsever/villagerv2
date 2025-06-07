import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'views/login/role_selector_screen.dart';
import 'views/login/login_screen.dart';
import 'views/admin/admin_dashboard.dart';
import 'views/juristic/juristic_dashboard.dart';
import 'views/juristic/notion_screen.dart';
import 'views/resident/resident_dashboard.dart';
import 'views/resident/complaint_screen.dart';
import 'views/resident/bill_screen.dart';
import 'views/resident/notion_screen.dart';
import 'views/login/resident_login_screen.dart';
import 'views/login/role_selector_screen.dart';



Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
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

      routes: {
        '/admin': (context) => const AdminDashboard(),
        '/juristic': (context) => const JuristicDashboard(),
        '/juristic/notion': (context) => const NotionScreen(),
        '/resident': (context) => const ResidentDashboard(),
        '/resident/bill': (_) => const ResidentBillScreen(),
        '/resident/complaint': (_) => const ResidentComplaintScreen(),
        '/resident/login': (_) => const ResidentLoginScreen(),
        '/resident/notion': (context) => const ResidentNotionScreen(),

      },
    );
  }
}
