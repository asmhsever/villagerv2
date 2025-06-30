// lib/views/juristic/edit_profile_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

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
  final birthdateCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final genderCtrl = TextEditingController();
  final addressCtrl = TextEditingController();
  bool isLoading = true;
  final _genderOptions = ['ชาย', 'หญิง', 'อื่น ๆ'];
  File? _selectedImage;
  String? _imgName;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final result = await Supabase.instance.client
        .from('law')
        .select()
        .eq('law_id', widget.lawId)
        .maybeSingle();

    if (result != null) {
      firstNameCtrl.text = result['first_name']?.toString() ?? '';
      lastNameCtrl.text = result['last_name']?.toString() ?? '';
      birthdateCtrl.text = result['birth_date']?.toString() ?? '';
      phoneCtrl.text = result['phone']?.toString() ?? '';
      final genderCode = result['gender']?.toString();
      genderCtrl.text = switch (genderCode) {
        'M' => 'ชาย',
        'F' => 'หญิง',
        'O' => 'อื่น ๆ',
        _ => '',
      };
      addressCtrl.text = result['address']?.toString() ?? '';
      _imgName = result['img'];
    }

    setState(() => isLoading = false);
  }

  Future<void> _selectDate() async {
    final initialDate = birthdateCtrl.text.isNotEmpty
        ? DateFormat('yyyy-MM-dd').parse(birthdateCtrl.text)
        : DateTime(2000);

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      birthdateCtrl.text = DateFormat('yyyy-MM-dd').format(picked);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _selectedImage = File(pickedFile.path));
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final genderValue = switch (genderCtrl.text) {
      'ชาย' => 'M',
      'หญิง' => 'F',
      'อื่น ๆ' => 'O',
      _ => '',
    };

    String? imageName = _imgName;

    if (_selectedImage != null) {
      try {
        if (_imgName != null && _imgName!.isNotEmpty) {
          await Supabase.instance.client.storage.from('01').remove([_imgName!]);
        }
        imageName = '${const Uuid().v4()}.jpg';
        final bytes = await _selectedImage!.readAsBytes();
        await Supabase.instance.client.storage
            .from('01')
            .uploadBinary(imageName, bytes);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('อัปโหลดรูปภาพไม่สำเร็จ: $e'), backgroundColor: Colors.red),
          );
        }
        return;
      }
    }

    final payload = {
      'first_name': firstNameCtrl.text.trim(),
      'last_name': lastNameCtrl.text.trim(),
      'birth_date': birthdateCtrl.text.trim(),
      'phone': phoneCtrl.text.trim(),
      'gender': genderValue,
      'address': addressCtrl.text.trim(),
      if (imageName != null) 'img': imageName,
    };

    final response = await Supabase.instance.client
        .from('law')
        .update(payload)
        .eq('law_id', widget.lawId);

    debugPrint('UPDATE PAYLOAD: $payload');
    debugPrint('UPDATE RESPONSE: $response');

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('บันทึกข้อมูลเรียบร้อย')),
      );
      Navigator.pop(context, true);
    }
  }

  Widget _input(String label, TextEditingController ctrl,
      {bool readOnly = false, VoidCallback? onTap, String? Function(String?)? validator}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: ctrl,
        readOnly: readOnly,
        onTap: onTap,
        validator: validator,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    const Text('แก้ไขข้อมูลส่วนตัว', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView(
                    children: [
                      if (_selectedImage != null)
                        CircleAvatar(radius: 40, backgroundImage: FileImage(_selectedImage!)),
                      TextButton.icon(
                        onPressed: _pickImage,
                        icon: const Icon(Icons.image),
                        label: const Text('เลือกรูปโปรไฟล์'),
                      ),
                      _input('ชื่อ', firstNameCtrl, validator: (v) => v!.isEmpty ? 'กรุณากรอกชื่อ' : null),
                      _input('นามสกุล', lastNameCtrl, validator: (v) => v!.isEmpty ? 'กรุณากรอกนามสกุล' : null),
                      _input('วันเกิด', birthdateCtrl, readOnly: true, onTap: _selectDate, validator: (v) => v!.isEmpty ? 'กรุณาเลือกวันเกิด' : null),
                      _input('เบอร์โทร', phoneCtrl, validator: (v) => v!.length < 9 ? 'กรุณากรอกเบอร์โทรให้ถูกต้อง' : null),
                      DropdownButtonFormField<String>(
                        value: _genderOptions.contains(genderCtrl.text) ? genderCtrl.text : null,
                        items: _genderOptions.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                        onChanged: (val) => genderCtrl.text = val ?? '',
                        decoration: const InputDecoration(labelText: 'เพศ', border: OutlineInputBorder()),
                        validator: (v) => v == null || v.isEmpty ? 'กรุณาเลือกเพศ' : null,
                      ),
                      _input('ที่อยู่', addressCtrl, validator: (v) => v!.isEmpty ? 'กรุณากรอกที่อยู่' : null),
                    ],
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _save,
                    child: const Text('บันทึก'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    firstNameCtrl.dispose();
    lastNameCtrl.dispose();
    birthdateCtrl.dispose();
    phoneCtrl.dispose();
    genderCtrl.dispose();
    addressCtrl.dispose();
    super.dispose();
  }
}
