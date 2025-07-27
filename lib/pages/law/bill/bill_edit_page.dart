import 'package:flutter/material.dart';
import 'package:fullproject/models/bill_model.dart';
import 'package:fullproject/config/supabase_config.dart';
import 'package:fullproject/services/bill_service/bill_service.dart';
import 'package:intl/intl.dart';

class BillEditPage extends StatefulWidget {
  final BillModel bill;

  const BillEditPage({super.key, required this.bill});

  @override
  State<BillEditPage> createState() => _BillEditPageState();
}

class _BillEditPageState extends State<BillEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  DateTime? _dueDate;
  int? _selectedHouseId;
  int? _selectedServiceId;

  List<Map<String, dynamic>> _houses = [];
  List<Map<String, dynamic>> _services = [];

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
    _amountController.text = widget.bill.amount.toString();
    _dueDate = widget.bill.dueDate;
    _selectedHouseId = widget.bill.houseId;
    _selectedServiceId = widget.bill.service;
  }

  Future<void> _fetchInitialData() async {
    final houses = await SupabaseConfig.client
        .from('house')
        .select('house_id, house_number');

    final services = await SupabaseConfig.client
        .from('service')
        .select('service_id, name');

    setState(() {
      _houses = List<Map<String, dynamic>>.from(houses);
      _services = List<Map<String, dynamic>>.from(services);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _dueDate == null || _selectedHouseId == null || _selectedServiceId == null) return;

    final bill = widget.bill.copyWith(
      houseId: _selectedHouseId!,
      amount: int.parse(_amountController.text),
      dueDate: _dueDate,
      service: _selectedServiceId,
    );

    final service = BillService();
    await service.updateBill(bill);

    if (mounted) Navigator.pop(context, true);
  }

  String _getServiceNameTh(String? eng) {
    switch (eng) {
      case 'Area Fee':
        return 'ค่าพื้นที่ส่วนกลาง';
      case 'Trash Fee':
        return 'ค่าขยะ';
      case 'water Fee':
        return 'ค่าน้ำ';
      case 'enegy Fee':
        return 'ค่าไฟ';
      default:
        return eng ?? 'ไม่ระบุ';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('แก้ไขค่าส่วนกลาง')),
      body: _houses.isEmpty || _services.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<int>(
                value: _houses.any((h) => h['house_id'] == _selectedHouseId)
                    ? _selectedHouseId
                    : null,
                items: _houses.map((house) {
                  return DropdownMenuItem<int>(
                    value: house['house_id'],
                    child: Text(house['house_number']),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedHouseId = val),
                decoration: const InputDecoration(labelText: 'บ้านเลขที่'),
                validator: (value) => value == null ? 'กรุณาเลือกบ้าน' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                value: _selectedServiceId,
                decoration: const InputDecoration(labelText: 'ประเภทบริการ'),
                items: _services.map((s) {
                  return DropdownMenuItem<int>(
                    value: s['service_id'],
                    child: Text(_getServiceNameTh(s['name'])),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedServiceId = val),
                validator: (val) => val == null ? 'กรุณาเลือกประเภท' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'จำนวนเงิน'),
                validator: (value) => value == null || value.isEmpty
                    ? 'กรุณากรอกจำนวนเงิน'
                    : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _dueDate == null
                          ? 'เลือกวันครบกำหนด'
                          : 'ครบกำหนด: ${DateFormat('dd/MM/yyyy').format(_dueDate!)}',
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _dueDate ?? DateTime.now(),
                        firstDate: DateTime.now().subtract(const Duration(days: 365)),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        setState(() => _dueDate = picked);
                      }
                    },
                    child: const Text('เลือกวันที่'),
                  )
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submit,
                  child: const Text('บันทึกการแก้ไข'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}