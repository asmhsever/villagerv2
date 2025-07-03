// 📁 lib/views/juristic/house/edit_car_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditCarScreen extends StatefulWidget {
  final Map<String, dynamic>? car;
  final int? houseId;

  const EditCarScreen({super.key, this.car, this.houseId});

  @override
  State<EditCarScreen> createState() => _EditCarScreenState();
}

class _EditCarScreenState extends State<EditCarScreen> {
  final _formKey = GlobalKey<FormState>();
  final brandCtrl = TextEditingController();
  final modelCtrl = TextEditingController();
  final numberCtrl = TextEditingController();
  String? selectedHouseId;
  File? selectedImage;

  @override
  void initState() {
    super.initState();
    if (widget.car != null) {
      final c = widget.car!;
      brandCtrl.text = c['brand'] ?? '';
      modelCtrl.text = c['model'] ?? '';
      numberCtrl.text = c['number'] ?? '';
      selectedHouseId = c['house_id'].toString();
    } else if (widget.houseId != null) {
      selectedHouseId = widget.houseId.toString();
    }
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => selectedImage = File(picked.path));
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final payload = {
      'brand': brandCtrl.text.trim(),
      'model': modelCtrl.text.trim(),
      'number': numberCtrl.text.trim(),
      'house_id': int.tryParse(selectedHouseId ?? '0'),
    };

    final client = Supabase.instance.client;
    int carId;

    if (widget.car != null) {
      await client.from('car').update(payload).eq('car_id', widget.car!['car_id']);
      carId = widget.car!['car_id'];
    } else {
      final inserted = await client.from('car').insert(payload).select().maybeSingle();
      if (inserted == null) return;
      carId = inserted['car_id'];
    }

    if (selectedImage != null) {
      final bytes = await selectedImage!.readAsBytes();
      final ext = selectedImage!.path.split('.').last;
      final fileName = '$carId.$ext';

      await client.storage
          .from('car-images')
          .uploadBinary(fileName, bytes, fileOptions: const FileOptions(upsert: true));
    }

    if (context.mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    brandCtrl.dispose();
    modelCtrl.dispose();
    numberCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.car != null ? 'แก้ไขรถ' : 'เพิ่มรถ')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: brandCtrl,
                decoration: const InputDecoration(labelText: 'ยี่ห้อ'),
                validator: (v) => v == null || v.isEmpty ? 'กรุณากรอกยี่ห้อ' : null,
              ),
              TextFormField(
                controller: modelCtrl,
                decoration: const InputDecoration(labelText: 'รุ่น'),
                validator: (v) => v == null || v.isEmpty ? 'กรุณากรอกรุ่น' : null,
              ),
              TextFormField(
                controller: numberCtrl,
                decoration: const InputDecoration(labelText: 'ทะเบียน'),
                validator: (v) => v == null || v.isEmpty ? 'กรุณากรอกทะเบียน' : null,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.image),
                label: const Text('เลือกรูปภาพ'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _save,
                child: const Text('บันทึก'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
