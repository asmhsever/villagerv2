// lib/views/login/law_login_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LawLoginScreen extends StatefulWidget {
  const LawLoginScreen({super.key});

  @override
  State<LawLoginScreen> createState() => _LawLoginScreenState();
}

class _LawLoginScreenState extends State<LawLoginScreen> {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  bool isLoading = false;

  Future<void> _login() async {
    final username = usernameController.text.trim();
    final password = passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      _showError('กรุณากรอกชื่อผู้ใช้และรหัสผ่าน');
      return;
    }

    setState(() => isLoading = true);

    try {
      final result = await Supabase.instance.client
          .from('law')
          .select('law_id')
          .eq('username', username)
          .eq('password', password)
          .maybeSingle();

      if (result == null) {
        _showError('ชื่อผู้ใช้หรือรหัสผ่านไม่ถูกต้อง');
        return;
      }

      final lawId = result['law_id'];

      Navigator.pushReplacementNamed(context, '/juristic', arguments: lawId);
    } catch (e) {
      _showError('เกิดข้อผิดพลาด: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('เข้าสู่ระบบ')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: usernameController,
              decoration: const InputDecoration(labelText: 'ชื่อผู้ใช้ (username)'),
            ),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(labelText: 'รหัสผ่าน'),
              obscureText: true,
            ),
            const SizedBox(height: 24),
            isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
              onPressed: _login,
              child: const Text('เข้าสู่ระบบ'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
