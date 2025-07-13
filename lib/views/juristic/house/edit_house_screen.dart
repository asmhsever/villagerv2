// 📁 lib/views/juristic/house/edit_house_screen.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'house_model.dart';

class EditHouseScreen extends StatefulWidget {
  final House? house;
  final int? villageId;

  const EditHouseScreen({super.key, this.house, this.villageId});

  @override
  State<EditHouseScreen> createState() => _EditHouseScreenState();
}

class _EditHouseScreenState extends State<EditHouseScreen> {
  final _formKey = GlobalKey<FormState>();
  final usernameCtrl = TextEditingController();
  final sizeCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.house != null) {
      usernameCtrl.text = widget.house!.username ?? '';
      sizeCtrl.text = widget.house!.size ?? '';
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final payload = {
      'username': usernameCtrl.text.trim(),
      'size': sizeCtrl.text.trim(),
      if (widget.house == null && widget.villageId != null) 'village_id': widget.villageId,
    };

    final client = Supabase.instance.client;
    if (widget.house != null) {
      await client.from('house')
          .update(payload)
          .eq('house_id', widget.house!.houseId);
    } else {
      await client.from('house')
          .insert(payload);
    }

    if (context.mounted) Navigator.pop(context, true);
  }

  @override
  void dispose() {
    usernameCtrl.dispose();
    sizeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.house == null ? 'เพิ่มบ้าน' : 'แก้ไขบ้าน'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: usernameCtrl,
                decoration: const InputDecoration(labelText: 'เจ้าของบ้าน'),
                validator: (v) => v == null || v.isEmpty ? 'กรุณากรอกชื่อเจ้าของบ้าน' : null,
              ),
              TextFormField(
                controller: sizeCtrl,
                decoration: const InputDecoration(labelText: 'ขนาดบ้าน'),
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
