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
  List<Map<String, dynamic>> _houses = [];

  @override
  void initState() {
    super.initState();
    _fetchHouses();
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
    print("ลองเพิ่ม1");
    if (!_formKey.currentState!.validate() ||
        _dueDate == null ||
        _selectedHouseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณากรอกข้อมูลให้ครบถ้วน'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    print("ลองเพิ่ม");
    try {
      final bill = BillModel(
        billId: 0,
        houseId: _selectedHouseId!,
        amount: double.parse(_amountController.text),
        dueDate: _dueDate!,
        paidStatus: 0,
        billDate: DateTime.now(),
        paidMethod: null,
        // เปลี่ยนเป็น null แทน empty string
        paidDate: null,
        service: 0,
        referenceNo: 'REF${DateTime.now().millisecondsSinceEpoch}',
      );

      final result = await BillDomain.create(bill: bill);

      if (result != null) {
        // สำเร็จ
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('เพิ่มบิลสำเร็จ'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        if (mounted) {
          Navigator.pop(context, true); // ส่งค่า true กลับไปเพื่อ refresh
        }
      } else {
        // Domain return null แปลว่าเกิดข้อผิดพลาด
        throw Exception('ไม่สามารถเพิ่มบิลได้');
      }
    } catch (e) {
      // แสดงข้อความ error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาด: เพิ่มบิลไม่สำเร็จ\n${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'ลองใหม่',
            textColor: Colors.white,
            onPressed: () => _submit(), // ลองส่งใหม่
          ),
        ),
      );
      print('Error creating bill: $e');
    } finally {
      // ซ่อน loading เสมอ
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('เพิ่มค่าส่วนกลาง')),
      body: _houses.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    DropdownButtonFormField<int>(
                      value:
                          _houses.any((h) => h['house_id'] == _selectedHouseId)
                          ? _selectedHouseId
                          : null,
                      items: _houses.map((house) {
                        return DropdownMenuItem<int>(
                          value: house['house_id'],
                          child: Text(house['house_number']),
                        );
                      }).toList(),
                      onChanged: (val) =>
                          setState(() => _selectedHouseId = val),
                      decoration: const InputDecoration(
                        labelText: 'บ้านเลขที่',
                      ),
                      validator: (value) =>
                          value == null ? 'กรุณาเลือกบ้าน' : null,
                    ),
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
                              firstDate: DateTime.now().subtract(
                                const Duration(days: 365),
                              ),
                              lastDate: DateTime.now().add(
                                const Duration(days: 365),
                              ),
                            );
                            if (picked != null) {
                              setState(() => _dueDate = picked);
                            }
                          },
                          child: const Text('เลือกวันที่'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        print("ปุ่มถูกกด!"); // ✅ เพิ่ม debug นี้ก่อน
                        _submit();
                      },
                      child: const Text('เพิ่มรายการ'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
