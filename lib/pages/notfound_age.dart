import 'package:flutter/material.dart';
import 'package:fullproject/navigation/app_navigation.dart';
import 'package:fullproject/routes/app_routes.dart';

class NotFoundPage extends StatelessWidget {
  const NotFoundPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("ไม่พบหน้า"),
        backgroundColor: Colors.red,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 32),
            const Text(
              "404 - ไม่พบหน้าที่ต้องการ",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                AppNavigation.navigateAndClearAll(AppRoutes.login);
              },
              child: const Text("กลับหน้าแรก"),
            ),
          ],
        ),
      ),
    );
  }
}
