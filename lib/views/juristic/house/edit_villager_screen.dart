// 📁 lib/views/juristic/house/edit_villager_screen.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'villager_model.dart';
import 'villager_service.dart';

class EditVillagerScreen extends StatefulWidget {
  final Villager? villager;
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
  final villagerService = VillagerService();

  int? get currentHouseId => widget.villager?.houseId ?? widget.houseId;

  @override
  void initState() {
    super.initState();
    if (widget.villager != null) {
      firstNameCtrl.text = widget.villager!.firstName ?? '';
      lastNameCtrl.text = widget.villager!.lastName ?? '';
      phoneCtrl.text = widget.villager!.phone ?? '';
      birthdateCtrl.text = widget.villager!.birthDate ?? '';
      genderCtrl.text = widget.villager!.gender ?? '';
      cardNumberCtrl.text = widget.villager!.cardNumber ?? '';
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || currentHouseId == null) return;

    final newVillager = Villager(
      villagerId: widget.villager?.villagerId ?? 0,
      houseId: currentHouseId!,
      firstName: firstNameCtrl.text.trim(),
      lastName: lastNameCtrl.text.trim(),
      birthDate: birthdateCtrl.text.trim(),
      gender: genderCtrl.text.trim(),
      phone: phoneCtrl.text.trim(),
      cardNumber: cardNumberCtrl.text.trim(),
    );

    if (widget.villager != null) {
      await villagerService.updateVillager(newVillager);
    } else {
      await villagerService.insertVillager(newVillager);
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
      appBar: AppBar(title: const Text('เพิ่ม/แก้ไขผู้อยู่อาศัย')),
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
              ),
              TextFormField(
                controller: phoneCtrl,
                decoration: const InputDecoration(labelText: 'เบอร์โทร'),
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
                controller: cardNumberCtrl,
                decoration: const InputDecoration(labelText: 'เลขบัตรประชาชน'),
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
