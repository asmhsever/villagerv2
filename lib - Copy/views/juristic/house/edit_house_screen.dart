// 📁 lib/views/juristic/edit_house_screen.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditHouseScreen extends StatefulWidget {
  final Map<String, dynamic>? house;
  final int? villageId;
  const EditHouseScreen({super.key, this.house, this.villageId});

  @override
  State<EditHouseScreen> createState() => _EditHouseScreenState();
}

class _EditHouseScreenState extends State<EditHouseScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController usernameCtrl;
  late TextEditingController sizeCtrl;

  @override
  void initState() {
    super.initState();
    usernameCtrl = TextEditingController(text: widget.house?['username'] ?? '');
    sizeCtrl = TextEditingController(text: widget.house?['size'] ?? '');
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final payload = {
      'username': usernameCtrl.text.trim(),
      'size': sizeCtrl.text.trim(),
      if (widget.house == null && widget.villageId != null) 'village_id': widget.villageId,
    };

    final client = Supabase.instance.client;
    if (widget.house != null && widget.house!['house_id'] != null) {
      await client.from('house').update(payload).eq('house_id', widget.house!['house_id']);
    } else {
      await client.from('house').insert(payload);
    }

    if (context.mounted) Navigator.pop(context, true);
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
              const SizedBox(height: 16),
              TextFormField(
                controller: sizeCtrl,
                decoration: const InputDecoration(labelText: 'ขนาดบ้าน'),
                validator: (v) => v == null || v.isEmpty ? 'กรุณากรอกขนาดบ้าน' : null,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _save,
                  child: Text(widget.house == null ? 'เพิ่มบ้าน' : 'บันทึกการแก้ไข'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
