import 'package:flutter/material.dart';
import 'package:fullproject/navigation/app_navigation.dart';
import 'package:fullproject/routes/app_routes.dart';
import 'package:fullproject/services/auth_service.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    final session = await AuthService.isLoggedIn();
    if (session['is_logged_in'] != null) {
      switch (session['role']) {
        case 'admin':
          AppNavigation.navigateTo(AppRoutes.adminDashboard);
          break;
        case 'house':
          AppNavigation.navigateTo(AppRoutes.houseDashboard);
          break;
        case 'law':
          AppNavigation.navigateTo(AppRoutes.lawDashboard);
          break;
        default:
          AppNavigation.navigateTo(AppRoutes.notFound);
      }
    } else {
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(child: CircularProgressIndicator());
  }
}
