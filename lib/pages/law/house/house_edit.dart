import 'package:flutter/material.dart';
import 'package:fullproject/models/house_model.dart';
import 'package:fullproject/domains/house_domain.dart';

class EditHousePage extends StatefulWidget {
  final HouseModel house;
  const EditHousePage({super.key, required this.house});

  @override
  State<EditHousePage> createState() => _EditHousePageState();
}

class _EditHousePageState extends State<EditHousePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _ownerController;
  late TextEditingController _phoneController;
  late TextEditingController _statusController;
  late TextEditingController _houseTypeController;
  late TextEditingController _floorsController;
  late TextEditingController _usableAreaController;
  late TextEditingController _sizeController;
  late TextEditingController _imgController;
  String? _usageStatus;

  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    _ownerController = TextEditingController(text: widget.house.owner);
    _phoneController = TextEditingController(text: widget.house.phone);
    _statusController = TextEditingController(text: widget.house.status);
    _houseTypeController = TextEditingController(text: widget.house.houseType);
    _floorsController = TextEditingController(text: widget.house.floors?.toString());
    _usableAreaController = TextEditingController(text: widget.house.usableArea);
    _sizeController = TextEditingController(text: widget.house.size);
    _imgController = TextEditingController(text: widget.house.img);
    _usageStatus = widget.house.usageStatus ?? 'active';
  }

  @override
  void dispose() {
    _ownerController.dispose();
    _phoneController.dispose();
    _statusController.dispose();
    _houseTypeController.dispose();
    _floorsController.dispose();
    _usableAreaController.dispose();
    _sizeController.dispose();
    _imgController.dispose();
    super.dispose();
  }

  Future<void> saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isSaving = true);

    final updatedHouse = widget.house.copyWith(
      owner: _ownerController.text.trim(),
      phone: _phoneController.text.trim(),
      status: _statusController.text.trim(),
      houseType: _houseTypeController.text.trim(),
      floors: int.tryParse(_floorsController.text.trim()),
      usableArea: _usableAreaController.text.trim(),
      usageStatus: _usageStatus,
      size: _sizeController.text.trim(),
      img: _imgController.text.trim(),
    );

    final result = await HouseDomain.update(
      houseId: updatedHouse.houseId,
      updatedHouse: updatedHouse,
    );

    setState(() => isSaving = false);

    if (result != null) {
      Navigator.pop(context, result);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('เกิดข้อผิดพลาดในการบันทึก')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('แก้ไขข้อมูลบ้าน')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _ownerController,
                decoration: const InputDecoration(labelText: 'เจ้าของบ้าน'),
                validator: (value) => value!.isEmpty ? 'กรุณาระบุชื่อเจ้าของ' : null,
              ),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'เบอร์โทร'),
              ),
              TextFormField(
                controller: _statusController,
                decoration: const InputDecoration(labelText: 'สถานะ'),
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
              DropdownButtonFormField<String>(
                value: _usageStatus,
                decoration: const InputDecoration(labelText: 'สถานะการใช้งาน'),
                items: ['active', 'inactive']
                    .map((value) => DropdownMenuItem(value: value, child: Text(value)))
                    .toList(),
                onChanged: (value) => setState(() => _usageStatus = value),
              ),
              TextFormField(
                controller: _sizeController,
                decoration: const InputDecoration(labelText: 'ขนาด'),
              ),
              TextFormField(
                controller: _imgController,
                decoration: const InputDecoration(labelText: 'ลิงก์รูปภาพ'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: isSaving ? null : saveChanges,
                child: isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('บันทึก'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
