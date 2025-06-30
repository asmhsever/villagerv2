// 📁 lib/views/juristic/edit_villager_screen.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditVillagerScreen extends StatefulWidget {
  final Map<String, dynamic>? villager;
  final int? houseId;

  const EditVillagerScreen({super.key, this.villager, this.houseId});

  @override
  State<EditVillagerScreen> createState() => _EditVillagerScreenState();
}

class _EditVillagerScreenState extends State<EditVillagerScreen> {
  final _formKey = GlobalKey<FormState>();
  final firstNameCtrl = TextEditingController();
  final lastNameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final birthdateCtrl = TextEditingController();
  final genderCtrl = TextEditingController();
  final cardNumberCtrl = TextEditingController();
  String? selectedHouseId;

  @override
  void initState() {
    super.initState();
    if (widget.villager != null) {
      final v = widget.villager!;
      firstNameCtrl.text = v['first_name'] ?? '';
      lastNameCtrl.text = v['last_name'] ?? '';
      phoneCtrl.text = v['phone'] ?? '';
      birthdateCtrl.text = v['birth_date'] ?? '';
      genderCtrl.text = v['gender'] ?? '';
      cardNumberCtrl.text = v['card_number'] ?? '';
      selectedHouseId = v['house_id'].toString();
    } else if (widget.houseId != null) {
      selectedHouseId = widget.houseId.toString();
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final payload = {
      'first_name': firstNameCtrl.text.trim(),
      'last_name': lastNameCtrl.text.trim(),
      'phone': phoneCtrl.text.trim(),
      'birth_date': birthdateCtrl.text.trim(),
      'gender': genderCtrl.text.trim(),
      'card_number': cardNumberCtrl.text.trim(),
      'house_id': int.tryParse(selectedHouseId ?? '0'),
    };

    final client = Supabase.instance.client;
    if (widget.villager != null) {
      await client
          .from('villager')
          .update(payload)
          .eq('villager_id', widget.villager!['villager_id']);
    } else {
      await client.from('villager').insert(payload);
    }

    if (context.mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    firstNameCtrl.dispose();
    lastNameCtrl.dispose();
    phoneCtrl.dispose();
    birthdateCtrl.dispose();
    genderCtrl.dispose();
    cardNumberCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.villager != null ? 'แก้ไขลูกบ้าน' : 'เพิ่มลูกบ้าน')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
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
                controller: birthdateCtrl,
                decoration: const InputDecoration(labelText: 'วันเกิด'),
              ),
              TextFormField(
                controller: genderCtrl,
                decoration: const InputDecoration(labelText: 'เพศ'),
              ),
              TextFormField(
                controller: phoneCtrl,
                decoration: const InputDecoration(labelText: 'เบอร์โทร'),
                keyboardType: TextInputType.phone,
                validator: (v) => v == null || v.length < 9 ? 'เบอร์ไม่ถูกต้อง' : null,
              ),
              TextFormField(
                controller: cardNumberCtrl,
                decoration: const InputDecoration(labelText: 'เลขบัตรประชาชน'),
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
