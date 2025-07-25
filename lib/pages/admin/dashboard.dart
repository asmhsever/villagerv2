import 'package:flutter/material.dart';
import 'package:fullproject/models/user_model.dart';
import 'package:fullproject/navigation/app_navigation.dart';
import 'package:fullproject/routes/app_routes.dart';
import 'package:fullproject/services/auth_service.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  UserModel? adminModel;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadCurrentUser();
  }

  Future<void> loadCurrentUser() async {
    try {
      final user = await AuthService.getCurrentUser();
      if (user is UserModel) {
        setState(() {
          adminModel = user;
          isLoading = false;
        });
      } else {
        // ไม่ใช่ admin หรือไม่มีข้อมูล
        AppNavigation.navigateTo(AppRoutes.login);
      }
    } catch (e) {
      AppNavigation.navigateTo(AppRoutes.login);
    }
  }

  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    } else {
      return Scaffold(
        body: Column(
          children: [
            Text("user id ${adminModel!.userId}"),
            Text("Username ${adminModel!.username}"),
            Text("role ${adminModel!.role}"),
          ],
        ),
      );
    }
  }
}
