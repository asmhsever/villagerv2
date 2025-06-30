// 📁 lib/views/juristic/house/edit_animal_screen.dart

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'animal_service.dart';

class EditAnimalScreen extends StatefulWidget {
  final Map<String, dynamic>? animal;
  final int houseId;

  const EditAnimalScreen({super.key, this.animal, required this.houseId});

  @override
  State<EditAnimalScreen> createState() => _EditAnimalScreenState();
}

class _EditAnimalScreenState extends State<EditAnimalScreen> {
  final _formKey = GlobalKey<FormState>();
  final nameCtrl = TextEditingController();
  final typeCtrl = TextEditingController();
  XFile? imageFile;
  final picker = ImagePicker();
  final service = AnimalService();

  @override
  void initState() {
    super.initState();
    if (widget.animal != null) {
      final a = widget.animal!;
      nameCtrl.text = a['name'] ?? '';
      typeCtrl.text = a['type'] ?? '';
    }
  }

  Future<void> _pickImage() async {
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => imageFile = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final name = nameCtrl.text.trim();
    final type = typeCtrl.text.trim();

    if (widget.animal != null) {
      await service.updateAnimalWithImage(
        animalId: widget.animal!['animal_id'],
        houseId: widget.houseId,
        name: name,
        type: type,
        imageFile: imageFile,
      );
    } else {
      if (imageFile == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('กรุณาเลือกรูปภาพสัตว์เลี้ยง'),
        ));
        return;
      }
      await service.addAnimalWithImage(
        houseId: widget.houseId,
        name: name,
        type: type,
        imageFile: imageFile!,
      );
    }

    if (context.mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    typeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.animal != null ? 'แก้ไขสัตว์เลี้ยง' : 'เพิ่มสัตว์เลี้ยง')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'ชื่อ'),
                validator: (v) => v == null || v.isEmpty ? 'กรุณากรอกชื่อ' : null,
              ),
              TextFormField(
                controller: typeCtrl,
                decoration: const InputDecoration(labelText: 'ประเภท'),
                validator: (v) => v == null || v.isEmpty ? 'กรุณากรอกประเภท' : null,
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.image),
                label: const Text('เลือกรูปสัตว์เลี้ยง'),
              ),
              if (imageFile != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Image.file(File(imageFile!.path), height: 150),
                ),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: _save, child: const Text('บันทึก')),
            ],
          ),
        ),
      ),
    );
  }
}
