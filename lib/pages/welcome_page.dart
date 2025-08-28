import 'package:flutter/material.dart';
import 'package:fullproject/extensions/context_extensions.dart';
import 'package:fullproject/navigation/app_navigation.dart';
import 'package:fullproject/routes/app_routes.dart';
import 'package:fullproject/theme/Color.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/login/welcome_bg.png',
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: context.heightPercent(0.15),
            left: context.widthPercent(0.2),
            right: context.widthPercent(0.2),
            child: Text(
              "Nivilla",
              style: TextStyle(
                fontSize: 80,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Positioned(
            top: context.heightPercent(0.22),
            left: context.widthPercent(0.2),
            right: context.widthPercent(0.2),
            child: Image.asset("assets/images/shared/logo2.png"),
          ),
          Positioned(
            bottom: context.heightPercent(0.15),
            left: context.widthPercent(0.2),
            right: context.widthPercent(0.2),
            child: ElevatedButton(
              onPressed: () {
                AppNavigation.navigateTo(AppRoutes.login);
              },
              child: Text("เข้าสู่ระบบ", style: TextStyle(fontSize: 17)),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 5, vertical: 20),
                backgroundColor: ThemeColors.clayOrange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
