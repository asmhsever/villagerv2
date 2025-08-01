import 'package:flutter/material.dart';
import 'package:fullproject/models/bill_model.dart';
import 'package:fullproject/config/supabase_config.dart';
import 'package:fullproject/services/auth_service.dart';
import 'package:fullproject/domains/bill_domain.dart';
import 'package:intl/intl.dart';

class BillAddPage extends StatefulWidget {
  const BillAddPage({super.key});

  @override
  State<BillAddPage> createState() => _BillAddPageState();
}

class _BillAddPageState extends State<BillAddPage> {
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
    _fetchHouses();
    _fetchServices();
  }

  Future<void> _fetchHouses() async {
    final law = await AuthService.getCurrentUser();
    final response = await SupabaseConfig.client
        .from('house')
        .select('house_id, house_number')
        .eq('village_id', law.villageId);

    setState(() {
      _houses = List<Map<String, dynamic>>.from(response);
    });
  }

  Future<void> _fetchServices() async {
    final response = await SupabaseConfig.client
        .from('service')
        .select('service_id, name');

    setState(() {
      _services = List<Map<String, dynamic>>.from(response);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _dueDate == null || _selectedHouseId == null || _selectedServiceId == null) return;

    final bill = BillModel(
      billId: 0,
      houseId: _selectedHouseId!,
      amount: int.parse(_amountController.text),
      dueDate: _dueDate!,
      paidStatus: 0,
      billDate: DateTime.now(),
      paidMethod: '',
      paidDate: null,
      service: _selectedServiceId, // ใส่ประเภทบริการที่เลือก
      referenceNo: 'REF${DateTime.now().millisecondsSinceEpoch}',
    );

    await BillDomain().create(bill);

    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = _houses.isEmpty || _services.isEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('เพิ่มค่าส่วนกลาง')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
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
                value: _services.any((s) => s['service_id'] == _selectedServiceId)
                    ? _selectedServiceId
                    : null,
                items: _services.map((service) {
                  return DropdownMenuItem<int>(
                    value: service['service_id'],
                    child: Text(service['name']),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedServiceId = val),
                decoration: const InputDecoration(labelText: 'ประเภทบริการ'),
                validator: (value) => value == null ? 'กรุณาเลือกประเภทบริการ' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'จำนวนเงิน'),
                validator: (value) => value == null || value.isEmpty ? 'กรุณากรอกจำนวนเงิน' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(_dueDate == null
                        ? 'เลือกวันครบกำหนด'
                        : 'ครบกำหนด: ${DateFormat('dd/MM/yyyy').format(_dueDate!)}'),
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
              ElevatedButton(
                onPressed: _submit,
                child: const Text('เพิ่มรายการ'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
