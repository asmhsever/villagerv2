// 📁 lib/views/juristic/edit_car_screen.dart

import 'package:flutter/material.dart';
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final payload = {
      'brand': brandCtrl.text.trim(),
      'model': modelCtrl.text.trim(),
      'number': numberCtrl.text.trim(),
      'house_id': int.tryParse(selectedHouseId ?? '0'),
    };

    final client = Supabase.instance.client;
    if (widget.car != null) {
      await client.from('car').update(payload).eq('car_id', widget.car!['car_id']);
    } else {
      await client.from('car').insert(payload);
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
              ),
              TextFormField(
                controller: numberCtrl,
                decoration: const InputDecoration(labelText: 'ทะเบียน'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _save, child: const Text('บันทึก')),
            ],
          ),
        ),
      ),
    );
  }
}
