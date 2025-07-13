// 📁 lib/views/juristic/house/edit_car_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'car_model.dart';

class EditCarScreen extends StatefulWidget {
  final Car? car;
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
  File? selectedImage;
  final picker = ImagePicker();

  int? get currentHouseId => widget.car?.houseId ?? widget.houseId;

  @override
  void initState() {
    super.initState();
    if (widget.car != null) {
      brandCtrl.text = widget.car!.brand ?? '';
      modelCtrl.text = widget.car!.model ?? '';
      numberCtrl.text = widget.car!.number ?? '';
    }
  }

  Future<void> _pickImage() async {
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => selectedImage = File(picked.path));
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || currentHouseId == null) return;

    final brand = brandCtrl.text.trim();
    final model = modelCtrl.text.trim();
    final number = numberCtrl.text.trim();
    final client = Supabase.instance.client;

    int carId;
    if (widget.car != null) {
      await client.from('car').update({
        'brand': brand,
        'model': model,
        'number': number,
      }).eq('car_id', widget.car!.carId);
      carId = widget.car!.carId;
    } else {
      final inserted = await client.from('car')
          .insert({
        'house_id': currentHouseId,
        'brand': brand,
        'model': model,
        'number': number,
      })
          .select()
          .maybeSingle();
      if (inserted == null) return;
      carId = inserted['car_id'];
    }

    if (selectedImage != null) {
      final ext = selectedImage!.path.split('.').last;
      await client.storage
          .from('car-images')
          .uploadBinary('$carId.$ext', await selectedImage!.readAsBytes(), fileOptions: const FileOptions(upsert: true));
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
      appBar: AppBar(title: const Text('รถยนต์')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: brandCtrl,
                decoration: const InputDecoration(labelText: 'ยี่ห้อ'),
              ),
              TextFormField(
                controller: modelCtrl,
                decoration: const InputDecoration(labelText: 'รุ่น'),
              ),
              TextFormField(
                controller: numberCtrl,
                decoration: const InputDecoration(labelText: 'ทะเบียน'),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.image),
                label: const Text('เลือกรูปภาพ'),
              ),
              const Spacer(),
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
