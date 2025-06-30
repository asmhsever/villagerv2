// lib/views/juristic/car_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CarDetailScreen extends StatefulWidget {
  final Map<String, dynamic>? car;
  final int? houseId;

  const CarDetailScreen({super.key, this.car, this.houseId});

  @override
  State<CarDetailScreen> createState() => _CarDetailScreenState();
}

class _CarDetailScreenState extends State<CarDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  final plateCtrl = TextEditingController();
  final brandCtrl = TextEditingController();
  final colorCtrl = TextEditingController();
  String? selectedHouseId;

  @override
  void initState() {
    super.initState();
    if (widget.car != null) {
      final c = widget.car!;
      plateCtrl.text = c['license_plate'] ?? '';
      brandCtrl.text = c['brand'] ?? '';
      colorCtrl.text = c['color'] ?? '';
      selectedHouseId = c['house_id'].toString();
    } else if (widget.houseId != null) {
      selectedHouseId = widget.houseId.toString();
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final payload = {
      'license_plate': plateCtrl.text.trim(),
      'brand': brandCtrl.text.trim(),
      'color': colorCtrl.text.trim(),
      'house_id': int.tryParse(selectedHouseId ?? '0'),
    };

    final client = Supabase.instance.client;
    if (widget.car != null) {
      await client
          .from('car')
          .update(payload)
          .eq('car_id', widget.car!['car_id']);
    } else {
      await client.from('car').insert(payload);
    }

    if (context.mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    plateCtrl.dispose();
    brandCtrl.dispose();
    colorCtrl.dispose();
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
                controller: plateCtrl,
                decoration: const InputDecoration(labelText: 'ป้ายทะเบียน'),
                validator: (v) => v == null || v.isEmpty ? 'กรุณากรอกป้ายทะเบียน' : null,
              ),
              TextFormField(
                controller: brandCtrl,
                decoration: const InputDecoration(labelText: 'ยี่ห้อ'),
              ),
              TextFormField(
                controller: colorCtrl,
                decoration: const InputDecoration(labelText: 'สี'),
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
