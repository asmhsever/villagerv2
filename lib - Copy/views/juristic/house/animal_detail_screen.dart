// 📁 lib/views/juristic/house/animal_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AnimalDetailScreen extends StatefulWidget {
  final Map<String, dynamic>? animal;
  final int? houseId;

  const AnimalDetailScreen({super.key, this.animal, this.houseId});

  @override
  State<AnimalDetailScreen> createState() => _AnimalDetailScreenState();
}

class _AnimalDetailScreenState extends State<AnimalDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  final nameCtrl = TextEditingController();
  final typeCtrl = TextEditingController();
  String? selectedHouseId;

  @override
  void initState() {
    super.initState();
    if (widget.animal != null) {
      final a = widget.animal!;
      nameCtrl.text = a['name'] ?? '';
      typeCtrl.text = a['type'] ?? '';
      selectedHouseId = a['house_id'].toString();
    } else if (widget.houseId != null) {
      selectedHouseId = widget.houseId.toString();
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final payload = {
      'name': nameCtrl.text.trim(),
      'type': typeCtrl.text.trim(),
      'house_id': int.tryParse(selectedHouseId ?? '0'),
    };

    final client = Supabase.instance.client;
    if (widget.animal != null) {
      await client
          .from('animal')
          .update(payload)
          .eq('animal_id', widget.animal!['animal_id']);
    } else {
      await client.from('animal').insert(payload);
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
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _save, child: const Text('บันทึก')),
            ],
          ),
        ),
      ),
    );
  }
}
