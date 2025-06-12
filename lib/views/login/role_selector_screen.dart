// lib/views/login/role_selector_screen.dart
import 'package:flutter/material.dart';
import 'law_login_screen.dart';
import 'resident_login_screen.dart';

class RoleSelectorScreen extends StatelessWidget {
  const RoleSelectorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('เลือกบทบาทเข้าสู่ระบบ')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.admin_panel_settings),
              label: const Text('ผู้ดูแลระบบ'),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LawLoginScreen()),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.account_balance),
              label: const Text('ผู้นิติ'),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LawLoginScreen()),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.house),
              label: const Text('ลูกบ้าน'),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ResidentLoginScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
