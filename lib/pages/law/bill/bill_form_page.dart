// lib/pages/bill/bill_form_page.dart
import 'package:flutter/material.dart';
import 'package:fullproject/models/bill_model.dart';
import 'package:fullproject/config/supabase_config.dart';
import 'package:fullproject/services/auth_service.dart';
import 'package:fullproject/services/bill_service/bill_service.dart';
import 'package:intl/intl.dart';


class BillFormPage extends StatefulWidget {
  final BillModel? bill;

  const BillFormPage({super.key, this.bill});

  @override
  State<BillFormPage> createState() => _BillFormPageState();
}

class _BillFormPageState extends State<BillFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  DateTime? _dueDate;
  int? _selectedHouseId;
  List<Map<String, dynamic>> _houses = [];

  bool get isEdit => widget.bill != null;

  @override
  void initState() {
    super.initState();
    _fetchHouses();
    if (isEdit) {
      _amountController.text = widget.bill!.amount.toString();
      _dueDate = widget.bill!.dueDate;
      _selectedHouseId = widget.bill!.houseId;
    }
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _dueDate == null || _selectedHouseId == null) return;

    final bill = BillModel(
      billId: widget.bill?.billId ?? 0,
      houseId: _selectedHouseId!,
      amount: int.parse(_amountController.text),
      dueDate: _dueDate!,
      paidStatus: widget.bill?.paidStatus ?? 0,
      billDate: DateTime.now(),
      paidMethod: widget.bill?.paidMethod ?? '',
      paidDate: widget.bill?.paidDate,
      service: widget.bill?.service,
      referenceNo: widget.bill?.referenceNo ?? 'REF${DateTime.now().millisecondsSinceEpoch}',
    );

    final service = BillService();
    if (isEdit) {
      await service.updateBill(bill);
    } else {
      await service.addBill(bill);
    }

    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'แก้ไขบิล' : 'เพิ่มค่าส่วนกลาง')),
      body: _houses.isEmpty
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
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'จำนวนเงิน'),
                validator: (value) =>
                value == null || value.isEmpty ? 'กรุณากรอกจำนวนเงิน' : null,
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
                child: Text(isEdit ? 'บันทึกการแก้ไข' : 'เพิ่มรายการ'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
