// 📁 lib/views/juristic/fees/fees_bill_add_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FeesBillAddScreen extends StatefulWidget {
  final int houseId;
  const FeesBillAddScreen({super.key, required this.houseId});

  @override
  State<FeesBillAddScreen> createState() => _FeesBillAddScreenState();
}

class _FeesBillAddScreenState extends State<FeesBillAddScreen> {
  final _formKey = GlobalKey<FormState>();
  final amountCtrl = TextEditingController();
  final referenceCtrl = TextEditingController();
  int? selectedService;
  DateTime billDate = DateTime.now();
  DateTime dueDate = DateTime.now().add(const Duration(days: 14));
  bool isLoading = false;
  List<Map<String, dynamic>> _services = [];

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  Future<void> _loadServices() async {
    final data = await Supabase.instance.client.from('service').select();
    setState(() => _services = List<Map<String, dynamic>>.from(data));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => isLoading = true);

    final payload = {
      'house_id': widget.houseId,
      'bill_date': billDate.toIso8601String(),
      'amount': int.parse(amountCtrl.text.trim()),
      'paid_status': 0,
      'service': selectedService,
      'due_date': dueDate.toIso8601String(),
      'reference_no': referenceCtrl.text.trim(),
    };

    await Supabase.instance.client.from('bill_area').insert(payload);
    if (context.mounted) Navigator.pop(context, true);
  }

  @override
  void dispose() {
    amountCtrl.dispose();
    referenceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('yyyy-MM-dd');

    return Scaffold(
      appBar: AppBar(title: const Text('เพิ่มบิลใหม่')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: amountCtrl,
                decoration: const InputDecoration(labelText: 'จำนวนเงิน'),
                keyboardType: TextInputType.number,
                validator: (v) => v == null || v.isEmpty ? 'กรุณากรอกจำนวนเงิน' : null,
              ),
              TextFormField(
                controller: referenceCtrl,
                decoration: const InputDecoration(labelText: 'เลขอ้างอิง'),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: selectedService,
                decoration: const InputDecoration(labelText: 'เลือกบริการ'),
                items: _services.map((e) {
                  return DropdownMenuItem<int>(
                    value: e['service_id'],
                    child: Text(e['name']),
                  );
                }).toList(),
                onChanged: (v) => setState(() => selectedService = v),
                validator: (v) => v == null ? 'กรุณาเลือกบริการ' : null,
              ),
              const SizedBox(height: 16),
              Text('วันที่บิล: ${fmt.format(billDate)}'),
              ElevatedButton(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: billDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) setState(() => billDate = picked);
                },
                child: const Text('เลือกวันที่บิล'),
              ),
              const SizedBox(height: 8),
              Text('กำหนดชำระ: ${fmt.format(dueDate)}'),
              ElevatedButton(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: dueDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) setState(() => dueDate = picked);
                },
                child: const Text('เลือกวันครบกำหนด'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: isLoading ? null : _save,
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('บันทึก'),
              )
            ],
          ),
        ),
      ),
    );
  }
}
