// lib/views/login/resident_login_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ResidentLoginScreen extends StatefulWidget {
  const ResidentLoginScreen({super.key});

  @override
  State<ResidentLoginScreen> createState() => _ResidentLoginScreenState();
}

class _ResidentLoginScreenState extends State<ResidentLoginScreen> {
  final houseIdController = TextEditingController();
  final passwordController = TextEditingController();
  bool isLoading = false;

  Future<void> _login() async {
    final houseIdText = houseIdController.text.trim();
    final password = passwordController.text.trim();
    final houseId = int.tryParse(houseIdText);
    if (houseId == null || password.isEmpty) return;

    setState(() => isLoading = true);
    final client = Supabase.instance.client;

    try {
      final pass = await client
          .from('house_pass')
          .select()
          .eq('house_id', houseId)
          .eq('password', password)
          .maybeSingle();

      if (pass == null) {
        _showError('รหัสบ้านหรือรหัสผ่านไม่ถูกต้อง');
        setState(() => isLoading = false);
        return;
      }

      final villager = await client
          .from('villager')
          .select()
          .eq('house_id', houseId)
          .limit(1)
          .maybeSingle();

      if (villager == null) {
        _showError('ไม่พบลูกบ้านในบ้านนี้');
        setState(() => isLoading = false);
        return;
      }

      Navigator.pushReplacementNamed(context, '/resident', arguments: villager['villager_id']);
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
      appBar: AppBar(title: const Text('เข้าสู่ระบบลูกบ้าน')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: houseIdController,
              decoration: const InputDecoration(labelText: 'รหัสบ้าน'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(labelText: 'รหัสผ่านบ้าน'),
              obscureText: true,
            ),
            const SizedBox(height: 20),
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
}
