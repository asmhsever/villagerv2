// 📁 lib/views/juristic/profile/edit_profile_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

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
  String? selectedGender;
  DateTime? birthDate;
  File? pickedImage;
  String? oldImageExt;

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
      selectedGender = data['gender'];
      if (data['birth_date'] != null) {
        birthDate = DateTime.tryParse(data['birth_date']);
      }

      for (final ext in ['jpg', 'png']) {
        final url = Supabase.instance.client.storage.from('images').getPublicUrl('law/law_${widget.lawId}.$ext');
        try {
          final response = await HttpClient().getUrl(Uri.parse(url)).then((r) => r.close());
          if (response.statusCode == 200) {
            oldImageExt = ext;
            break;
          }
        } catch (_) {}
      }
      setState(() {});
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('เลือกรูปภาพ'),
        content: const Text('เลือกวิธีการเลือกรูปภาพ'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, ImageSource.camera), child: const Text('กล้อง')),
          TextButton(onPressed: () => Navigator.pop(context, ImageSource.gallery), child: const Text('แกลเลอรี')),
        ],
      ),
    );
    if (source == null) return;

    final result = await picker.pickImage(source: source);
    if (result != null) {
      final file = File(result.path);
      final bytes = await file.length();
      if (bytes > 5 * 1024 * 1024) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ขนาดรูปภาพต้องไม่เกิน 5MB')));
        return;
      }
      setState(() => pickedImage = file);
    }
  }

  Future<void> _uploadImage(int lawId) async {
    if (pickedImage == null) return;
    final bucket = Supabase.instance.client.storage.from('images');
    final ext = pickedImage!.path.split('.').last;
    final path = 'law/law_$lawId.$ext';

    if (oldImageExt != null) {
      await bucket.remove(['law/law_$lawId.$oldImageExt']);
    }

    final bytes = await pickedImage!.readAsBytes();
    await bucket.uploadBinary(path, bytes, fileOptions: const FileOptions(upsert: true));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final payload = {
      'first_name': firstNameCtrl.text.trim(),
      'last_name': lastNameCtrl.text.trim(),
      'phone': phoneCtrl.text.trim(),
      'address': addressCtrl.text.trim(),
      'gender': selectedGender,
      'birth_date': birthDate?.toIso8601String(),
    };
    await Supabase.instance.client
        .from('law')
        .update(payload)
        .eq('law_id', widget.lawId);

    await _uploadImage(widget.lawId);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('บันทึกข้อมูลเรียบร้อย')));
      Navigator.pop(context, true);
    }
  }

  @override
  void dispose() {
    firstNameCtrl.dispose();
    lastNameCtrl.dispose();
    phoneCtrl.dispose();
    addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final result = await showDatePicker(
      context: context,
      initialDate: birthDate ?? DateTime(now.year - 20),
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (result != null) setState(() => birthDate = result);
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
                validator: (v) => v == null || v.isEmpty
                    ? 'กรุณากรอกเบอร์โทร'
                    : !RegExp(r'^\d{10}\$').hasMatch(v)
                    ? 'เบอร์โทรไม่ถูกต้อง'
                    : null,
              ),
              TextFormField(
                controller: addressCtrl,
                decoration: const InputDecoration(labelText: 'ที่อยู่'),
              ),
              DropdownButtonFormField<String>(
                value: selectedGender,
                decoration: const InputDecoration(labelText: 'เพศ'),
                items: const [
                  DropdownMenuItem(value: 'M', child: Text('ชาย')),
                  DropdownMenuItem(value: 'F', child: Text('หญิง')),
                ],
                onChanged: (v) => setState(() => selectedGender = v),
                validator: (v) => v == null ? 'กรุณาเลือกเพศ' : null,
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('วันเกิด'),
                subtitle: Text(birthDate != null
                    ? DateFormat('dd/MM/yyyy').format(birthDate!)
                    : 'ยังไม่เลือก'),
                trailing: const Icon(Icons.calendar_today),
                onTap: _pickBirthDate,
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
