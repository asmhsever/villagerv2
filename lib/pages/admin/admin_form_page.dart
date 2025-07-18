import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:postgrest/postgrest.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fullproject/domains/admin_domain.dart';
import 'package:fullproject/models/admin_model.dart';

class AdminFormPage extends StatefulWidget {
  final AdminModel? admin; // null = สร้างใหม่, มีค่า = แก้ไข

  const AdminFormPage({Key? key, this.admin}) : super(key: key);

  @override
  State<AdminFormPage> createState() => _AdminFormPageState();
}

class _AdminFormPageState extends State<AdminFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  bool get _isEditing => widget.admin != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _usernameController.text = widget.admin!.username;
      // ไม่ใส่รหัสผ่านเดิม เพื่อความปลอดภัย
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // บันทึกข้อมูล
  Future<void> _saveAdmin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      Map<String, dynamic> result;

      if (_isEditing) {
        // แก้ไข admin
        result = await AdminDomain.updateAdmin(
          adminId: widget.admin!.adminId,
          username: _usernameController.text.trim(),
          password: _passwordController.text.isNotEmpty
              ? _passwordController.text
              : null,
        );
      } else {
        // สร้าง admin ใหม่
        result = await AdminDomain.createAdmin(
          username: _usernameController.text.trim(),
          password: _passwordController.text,
        );
      }

      if (result['success']) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message']),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(
            context,
          ).pop(true); // ส่งค่า true กลับไปเพื่อบอกว่าบันทึกสำเร็จ
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message']),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ตรวจสอบว่า username ซ้ำหรือไม่
  Future<String?> _validateUsername(String? value) async {
    if (value == null || value.trim().isEmpty) {
      return 'กรุณากรอกชื่อผู้ใช้';
    }

    if (value.trim().length < 3) {
      return 'ชื่อผู้ใช้ต้องมีอย่างน้อย 3 ตัวอักษร';
    }

    // ถ้าเป็นการแก้ไขและ username ไม่เปลี่ยน ไม่ต้องเช็ค
    if (_isEditing && value.trim() == widget.admin!.username) {
      return null;
    }

    try {
      final exists = await AdminDomain.isUsernameExists(
        value.trim(),
        excludeAdminId: _isEditing ? widget.admin!.adminId : null,
      );

      if (exists) {
        return 'ชื่อผู้ใช้นี้มีอยู่ในระบบแล้ว';
      }
    } catch (e) {
      return 'ไม่สามารถตรวจสอบชื่อผู้ใช้ได้';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'แก้ไขผู้ดูแลระบบ' : 'เพิ่มผู้ดูแลระบบ'),
        actions: [
          if (!_isLoading)
            TextButton(
              onPressed: _saveAdmin,
              child: const Text(
                'บันทึก',
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_isEditing) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ข้อมูลปัจจุบัน',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text('ID: ${widget.admin!.adminId}'),
                        Text('ชื่อผู้ใช้เดิม: ${widget.admin!.username}'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Username Field
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'ชื่อผู้ใช้',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                  helperText: 'ต้องมีอย่างน้อย 3 ตัวอักษร',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'กรุณากรอกชื่อผู้ใช้';
                  }
                  if (value.trim().length < 3) {
                    return 'ชื่อผู้ใช้ต้องมีอย่างน้อย 3 ตัวอักษร';
                  }
                  return null;
                },
                enabled: !_isLoading,
              ),

              const SizedBox(height: 16),

              // Password Field
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: _isEditing
                      ? 'รหัสผ่านใหม่ (เว้นว่างหากไม่ต้องการเปลี่ยน)'
                      : 'รหัสผ่าน',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  border: const OutlineInputBorder(),
                  helperText: _isEditing
                      ? 'เว้นว่างหากไม่ต้องการเปลี่ยนรหัสผ่าน'
                      : 'ต้องมีอย่างน้อย 6 ตัวอักษร',
                ),
                validator: (value) {
                  // สำหรับการแก้ไข ถ้าไม่ใส่รหัสผ่านใหม่ ไม่ต้อง validate
                  if (_isEditing && (value == null || value.isEmpty)) {
                    return null;
                  }

                  if (!_isEditing && (value == null || value.isEmpty)) {
                    return 'กรุณากรอกรหัสผ่าน';
                  }

                  if (value != null && value.isNotEmpty && value.length < 6) {
                    return 'รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร';
                  }

                  return null;
                },
                enabled: !_isLoading,
              ),

              const SizedBox(height: 16),

              // Confirm Password Field
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                decoration: InputDecoration(
                  labelText: 'ยืนยันรหัสผ่าน',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                  ),
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  // สำหรับการแก้ไข ถ้าไม่ได้ใส่รหัสผ่านใหม่ ไม่ต้อง validate confirm
                  if (_isEditing && _passwordController.text.isEmpty) {
                    return null;
                  }

                  if (value != _passwordController.text) {
                    return 'รหัสผ่านไม่ตรงกัน';
                  }

                  return null;
                },
                enabled: !_isLoading,
              ),

              const SizedBox(height: 30),

              // Save Button
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveAdmin,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          _isEditing ? 'อัปเดตข้อมูล' : 'สร้างผู้ดูแลระบบ',
                          style: const TextStyle(fontSize: 16),
                        ),
                ),
              ),

              const SizedBox(height: 20),

              // Cancel Button
              SizedBox(
                height: 50,
                child: OutlinedButton(
                  onPressed: _isLoading
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: const Text('ยกเลิก', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
