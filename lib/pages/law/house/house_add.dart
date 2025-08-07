import 'package:flutter/material.dart';
import 'package:fullproject/models/house_model.dart';
import 'package:fullproject/services/auth_service.dart';
import '../../../domains/house_domain.dart';

class HouseCreatePage extends StatefulWidget {
  const HouseCreatePage({super.key});

  @override
  State<HouseCreatePage> createState() => _HouseCreatePageState();
}

class _HouseCreatePageState extends State<HouseCreatePage> {
  final _formKey = GlobalKey<FormState>();

  final _houseNumberController = TextEditingController();
  final _sizeController = TextEditingController();
  final _ownerController = TextEditingController();
  final _phoneController = TextEditingController();
  final _statusController = TextEditingController();
  final _houseTypeController = TextEditingController();
  final _floorsController = TextEditingController();
  final _usableAreaController = TextEditingController();
  final _usageStatusController = TextEditingController();

  bool _isSubmitting = false;

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final user = await AuthService.getCurrentUser();
    if (user == null || user.villageId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ไม่พบ village id')),
      );
      return;
    }

    final house = HouseModel(
      houseId: 0, // จะถูกเซ็ตอัตโนมัติโดย Supabase
      villageId: user.villageId,
      userId: 0, // ยังไม่สร้าง user
      houseNumber: _houseNumberController.text.trim(),
      size: _sizeController.text.trim(),
      owner: _ownerController.text.trim(),
      phone: _phoneController.text.trim(),
      status: _statusController.text.trim(),
      houseType: _houseTypeController.text.trim(),
      floors: int.tryParse(_floorsController.text.trim()),
      usableArea: _usableAreaController.text.trim(),
      usageStatus: _usageStatusController.text.trim(),
      img: null,
    );

    final created = await HouseDomain.create(house: house);

    if (created != null) {
      Navigator.pop(context, created);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('เกิดข้อผิดพลาดในการเพิ่มบ้าน')),
      );
    }

    setState(() => _isSubmitting = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('เพิ่มลูกบ้าน')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _houseNumberController,
                decoration: const InputDecoration(labelText: 'บ้านเลขที่'),
                validator: (val) => val == null || val.isEmpty ? 'กรอกบ้านเลขที่' : null,
              ),
              TextFormField(
                controller: _sizeController,
                decoration: const InputDecoration(labelText: 'ขนาด'),
              ),
              TextFormField(
                controller: _ownerController,
                decoration: const InputDecoration(labelText: 'เจ้าของบ้าน'),
              ),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'เบอร์โทร'),
              ),
              TextFormField(
                controller: _statusController,
                decoration: const InputDecoration(labelText: 'สถานะ (owned/vacant)'),
              ),
              TextFormField(
                controller: _houseTypeController,
                decoration: const InputDecoration(labelText: 'ประเภทบ้าน'),
              ),
              TextFormField(
                controller: _floorsController,
                decoration: const InputDecoration(labelText: 'จำนวนชั้น'),
                keyboardType: TextInputType.number,
              ),
              TextFormField(
                controller: _usableAreaController,
                decoration: const InputDecoration(labelText: 'พื้นที่ใช้สอย'),
              ),
              TextFormField(
                controller: _usageStatusController,
                decoration: const InputDecoration(labelText: 'สถานะการใช้งาน (active/inactive)'),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitForm,
                child: _isSubmitting
                    ? const CircularProgressIndicator()
                    : const Text('บันทึก'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
