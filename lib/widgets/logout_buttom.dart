import 'package:flutter/material.dart';
import 'package:fullproject/navigation/app_navigation.dart';
import 'package:fullproject/routes/app_routes.dart';
import 'package:fullproject/services/auth_service.dart';
import 'package:fullproject/theme/Color.dart';

class LogoutButtom extends StatelessWidget {
  const LogoutButtom({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: _logoutSubmit,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            width: double.infinity,
            decoration: BoxDecoration(
              color: ThemeColors.warmStone,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                "ออกจากระบบ",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _logoutSubmit() {
    print("logout");
    AuthService.logout();
    AppNavigation.navigateAndClearAll(AppRoutes.login);
  }
}
