// 📁 lib/views/juristic/fees/fees_bill_edit_screen.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class FeesBillEditScreen extends StatefulWidget {
  final int billId;
  const FeesBillEditScreen({super.key, required this.billId});

  @override
  State<FeesBillEditScreen> createState() => _FeesBillEditScreenState();
}

class _FeesBillEditScreenState extends State<FeesBillEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final amountCtrl = TextEditingController();
  final referenceCtrl = TextEditingController();

  DateTime? billDate;
  DateTime? dueDate;
  int? serviceId;

  List<Map<String, dynamic>> services = [];
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final client = Supabase.instance.client;
      final bill = await client
          .from('bill_area')
          .select()
          .eq('bill_id', widget.billId)
          .maybeSingle();

      final svcs = await client
          .from('service')
          .select('service_id, name')
          .order('name');

      if (bill != null) {
        amountCtrl.text = (bill['amount'] ?? '').toString();
        referenceCtrl.text = bill['reference_no'] ?? '';
        billDate = DateTime.tryParse(bill['bill_date'] ?? '');
        dueDate = DateTime.tryParse(bill['due_date'] ?? '');
        serviceId = bill['service_id'];
      }

      setState(() {
        services = List<Map<String, dynamic>>.from(svcs);
        _loading = false;
      });
    } catch (e) {
      debugPrint('❌ load error: $e');
      setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || serviceId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกข้อมูลให้ครบถ้วน')),
      );
      return;
    }

    if (billDate != null && dueDate != null && dueDate!.isBefore(billDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('วันครบกำหนดต้องไม่เร็วกว่าวันที่บิล')),
      );
      return;
    }

    if (_saving) return;
    setState(() => _saving = true);

    try {
      await Supabase.instance.client
          .from('bill_area')
          .update({
        'amount': double.tryParse(amountCtrl.text.trim()) ?? 0,
        'bill_date': billDate?.toIso8601String(),
        'due_date': dueDate?.toIso8601String(),
        'service_id': serviceId,
        'reference_no': referenceCtrl.text.trim(),
      })
          .eq('bill_id', widget.billId);

      if (context.mounted) Navigator.pop(context, true);
    } catch (e) {
      debugPrint('❌ Save error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('เกิดข้อผิดพลาดในการบันทึก')),
        );
      }
    } finally {
      setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    amountCtrl.dispose();
    referenceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(title: const Text('แก้ไขบิล')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'จำนวนเงิน'),
                validator: (v) => v == null || v.trim().isEmpty ? 'กรุณากรอกจำนวนเงิน' : null,
              ),
              const SizedBox(height: 12),
              Text('วันที่บิล: ${billDate != null ? fmt.format(billDate!) : '-'}'),
              ElevatedButton(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: billDate ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) setState(() => billDate = picked);
                },
                child: const Text('เลือกวันที่บิล'),
              ),
              const SizedBox(height: 12),
              Text('วันครบกำหนด: ${dueDate != null ? fmt.format(dueDate!) : '-'}'),
              ElevatedButton(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: dueDate ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) setState(() => dueDate = picked);
                },
                child: const Text('เลือกวันครบกำหนด'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                value: serviceId,
                items: services.map((s) => DropdownMenuItem<int>(
                  value: s['service_id'] as int,
                  child: Text(s['name'] ?? ''),
                )).toList(),
                onChanged: (v) => setState(() => serviceId = v),
                decoration: const InputDecoration(labelText: 'บริการ'),
                validator: (v) => v == null ? 'กรุณาเลือกบริการ' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: referenceCtrl,
                decoration: const InputDecoration(labelText: 'เลขอ้างอิง'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _save,
                child: const Text('บันทึก'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
