// lib/views/juristic/change_password_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChangePasswordScreen extends StatefulWidget {
  final int lawId;
  const ChangePasswordScreen({super.key, required this.lawId});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final oldPasswordCtrl = TextEditingController();
  final newPasswordCtrl = TextEditingController();
  final confirmPasswordCtrl = TextEditingController();
  bool isLoading = false;

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);
    try {
      final client = Supabase.instance.client;
      final user = await client
          .from('law')
          .select('password')
          .eq('law_id', widget.lawId)
          .maybeSingle();

      final currentPassword = user?['password']?.toString() ?? '';

      if (oldPasswordCtrl.text.trim() != currentPassword) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('รหัสผ่านเดิมไม่ถูกต้อง')),
        );
        setState(() => isLoading = false);
        return;
      }

      await client.from('law').update({
        'password': newPasswordCtrl.text.trim(),
      }).eq('law_id', widget.lawId);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('เปลี่ยนรหัสผ่านสำเร็จ')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('ERROR: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('เกิดข้อผิดพลาดในการเปลี่ยนรหัสผ่าน')),
      );
    }
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('เปลี่ยนรหัสผ่าน')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: oldPasswordCtrl,
                  decoration: const InputDecoration(labelText: 'รหัสผ่านเดิม'),
                  obscureText: true,
                  validator: (v) => v!.isEmpty ? 'กรุณากรอกรหัสผ่านเดิม' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: newPasswordCtrl,
                  decoration: const InputDecoration(labelText: 'รหัสผ่านใหม่'),
                  obscureText: true,
                  validator: (v) => v!.length < 4 ? 'รหัสผ่านใหม่ต้องมีอย่างน้อย 4 ตัวอักษร' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: confirmPasswordCtrl,
                  decoration: const InputDecoration(labelText: 'ยืนยันรหัสผ่านใหม่'),
                  obscureText: true,
                  validator: (v) => v != newPasswordCtrl.text ? 'รหัสผ่านไม่ตรงกัน' : null,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _changePassword,
                    child: isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('บันทึกรหัสผ่านใหม่'),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    oldPasswordCtrl.dispose();
    newPasswordCtrl.dispose();
    confirmPasswordCtrl.dispose();
    super.dispose();
  }
}
