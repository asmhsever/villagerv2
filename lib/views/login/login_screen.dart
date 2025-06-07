// lib/views/login/law_login_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LawLoginScreen extends StatefulWidget {
  const LawLoginScreen({super.key});

  @override
  State<LawLoginScreen> createState() => _LawLoginScreenState();
}

class _LawLoginScreenState extends State<LawLoginScreen> {
  final idController = TextEditingController();
  final phoneController = TextEditingController();
  bool isLoading = false;

  Future<void> _login() async {
    final idText = idController.text.trim();
    final phone = phoneController.text.trim();
    final lawId = int.tryParse(idText);
    if (lawId == null || phone.isEmpty) return;

    setState(() => isLoading = true);

    final client = Supabase.instance.client;
    try {
      final result = await client
          .from('law')
          .select()
          .eq('law_id', lawId)
          .eq('phone', phone)
          .maybeSingle();

      if (result == null) {
        _showError('รหัสหรือเบอร์โทรศัพท์ไม่ถูกต้อง');
        setState(() => isLoading = false);
        return;
      }

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
      appBar: AppBar(title: const Text('เข้าสู่ระบบผู้นิติ')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: idController,
              decoration: const InputDecoration(labelText: 'รหัสประจำตัว (law_id)'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(labelText: 'เบอร์โทรศัพท์'),
              keyboardType: TextInputType.phone,
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
}
