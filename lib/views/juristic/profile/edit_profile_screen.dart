// 📁 lib/views/juristic/profile/edit_profile_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditProfileScreen extends StatefulWidget {
  final int lawId;
  const EditProfileScreen({super.key, required this.lawId});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final firstNameCtrl = TextEditingController();
  final lastNameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final addressCtrl = TextEditingController();
  final genderCtrl = TextEditingController();
  File? pickedImage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final data = await Supabase.instance.client
        .from('law')
        .select()
        .eq('law_id', widget.lawId)
        .maybeSingle();
    if (data != null) {
      firstNameCtrl.text = data['first_name'] ?? '';
      lastNameCtrl.text = data['last_name'] ?? '';
      phoneCtrl.text = data['phone'] ?? '';
      addressCtrl.text = data['address'] ?? '';
      genderCtrl.text = data['gender'] ?? '';
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final result = await picker.pickImage(source: ImageSource.gallery);
    if (result != null) {
      setState(() => pickedImage = File(result.path));
    }
  }

  Future<void> _uploadImage(int lawId) async {
    if (pickedImage == null) return;
    final bucket = Supabase.instance.client.storage.from('images');
    final filePath = 'law/law_$lawId.jpg';
    final bytes = await pickedImage!.readAsBytes();
    await bucket.remove([filePath]);
    await bucket.uploadBinary(filePath, bytes);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final payload = {
      'first_name': firstNameCtrl.text.trim(),
      'last_name': lastNameCtrl.text.trim(),
      'phone': phoneCtrl.text.trim(),
      'address': addressCtrl.text.trim(),
      'gender': genderCtrl.text.trim(),
    };
    await Supabase.instance.client
        .from('law')
        .update(payload)
        .eq('law_id', widget.lawId);

    await _uploadImage(widget.lawId);

    if (context.mounted) Navigator.pop(context, true);
  }

  @override
  void dispose() {
    firstNameCtrl.dispose();
    lastNameCtrl.dispose();
    phoneCtrl.dispose();
    addressCtrl.dispose();
    genderCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('แก้ไขข้อมูล')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.image),
                    label: const Text('เลือกรูปโปรไฟล์'),
                  ),
                  const SizedBox(width: 16),
                  if (pickedImage != null)
                    ClipOval(
                      child: Image.file(
                        pickedImage!,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: firstNameCtrl,
                decoration: const InputDecoration(labelText: 'ชื่อ'),
                validator: (v) => v == null || v.isEmpty ? 'กรุณากรอกชื่อ' : null,
              ),
              TextFormField(
                controller: lastNameCtrl,
                decoration: const InputDecoration(labelText: 'นามสกุล'),
                validator: (v) => v == null || v.isEmpty ? 'กรุณากรอกนามสกุล' : null,
              ),
              TextFormField(
                controller: phoneCtrl,
                decoration: const InputDecoration(labelText: 'เบอร์โทร'),
              ),
              TextFormField(
                controller: addressCtrl,
                decoration: const InputDecoration(labelText: 'ที่อยู่'),
              ),
              TextFormField(
                controller: genderCtrl,
                decoration: const InputDecoration(labelText: 'เพศ'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _save,
                child: const Text('บันทึก'),
              )
            ],
          ),
        ),
      ),
    );
  }
}
