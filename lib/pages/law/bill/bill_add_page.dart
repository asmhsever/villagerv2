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
  int? _selectedServiceId; // เพิ่มสำหรับเลือกประเภทบริการ

  List<Map<String, dynamic>> _houses = [];
  List<Map<String, dynamic>> _services = []; // เพิ่มสำหรับเก็บประเภทบริการ
  bool _isLoading = false;

  // แมปประเภทบริการให้เป็นภาษาไทย
  final Map<String, String> _serviceTranslations = {
    'Area Fee': 'ค่าพื้นที่ส่วนกลาง',
    'Trash Fee': 'ค่าขยะ',
    'water Fee': 'ค่าน้ำ',
    'enegy Fee': 'ค่าไฟ',
  };

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    setState(() => _isLoading = true);

    try {
      final law = await AuthService.getCurrentUser();

      // ดึงข้อมูลบ้าน
      final housesResponse = await SupabaseConfig.client
          .from('house')
          .select('house_id, house_number')
          .eq('village_id', law.villageId);

      // ดึงข้อมูลประเภทบริการ
      final servicesResponse = await SupabaseConfig.client
          .from('service')
          .select('service_id, name');

      setState(() {
        _houses = List<Map<String, dynamic>>.from(housesResponse);
        _services = List<Map<String, dynamic>>.from(servicesResponse);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาดในการโหลดข้อมูล: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getServiceNameTh(String? englishName) {
    return _serviceTranslations[englishName] ?? englishName ?? 'ไม่ระบุ';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() ||
        _dueDate == null ||
        _selectedHouseId == null ||
        _selectedServiceId == null) { // เพิ่มเช็ค service
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณากรอกข้อมูลให้ครบถ้วน'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final bill = BillModel(
        billId: 0,
        houseId: _selectedHouseId!,
        amount: double.parse(_amountController.text),
        dueDate: _dueDate!,
        paidStatus: 0,
        billDate: DateTime.now(),
        paidMethod: null,
        paidDate: null,
        service: _selectedServiceId!, // ใช้ service ที่เลือก
        referenceNo: 'REF${DateTime.now().millisecondsSinceEpoch}',
      );

      final result = await BillDomain.create(bill: bill);

      if (result != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('เพิ่มบิลสำเร็จ'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        if (mounted) {
          Navigator.pop(context, true);
        }
      } else {
        throw Exception('ไม่สามารถเพิ่มบิลได้');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาด: เพิ่มบิลไม่สำเร็จ\n${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'ลองใหม่',
            textColor: Colors.white,
            onPressed: () => _submit(),
          ),
        ),
      );
      print('Error creating bill: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('เพิ่มค่าส่วนกลาง')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _houses.isEmpty || _services.isEmpty
          ? const Center(
        child: Text('ไม่พบข้อมูลบ้านหรือประเภทบริการ'),
      )
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView( // เพิ่มเพื่อป้องกัน overflow
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Dropdown เลือกบ้าน
                DropdownButtonFormField<int>(
                  value: _houses.any((h) => h['house_id'] == _selectedHouseId)
                      ? _selectedHouseId
                      : null,
                  items: _houses.map((house) {
                    return DropdownMenuItem<int>(
                      value: house['house_id'],
                      child: Text('บ้านเลขที่ ${house['house_number']}'),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedHouseId = val),
                  decoration: const InputDecoration(
                    labelText: 'บ้านเลขที่',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                  value == null ? 'กรุณาเลือกบ้าน' : null,
                ),

                const SizedBox(height: 16),

                // Dropdown เลือกประเภทบริการ
                DropdownButtonFormField<int>(
                  value: _selectedServiceId,
                  items: _services.map((service) {
                    return DropdownMenuItem<int>(
                      value: service['service_id'],
                      child: Text(_getServiceNameTh(service['name'])),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedServiceId = val),
                  decoration: const InputDecoration(
                    labelText: 'ประเภทบริการ',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                  value == null ? 'กรุณาเลือกประเภทบริการ' : null,
                ),

                const SizedBox(height: 16),

                // ช่องกรอกจำนวนเงิน
                TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'จำนวนเงิน (บาท)',
                    border: OutlineInputBorder(),
                    suffixText: 'บาท',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'กรุณากรอกจำนวนเงิน';
                    }
                    final amount = double.tryParse(value);
                    if (amount == null || amount <= 0) {
                      return 'กรุณากรอกจำนวนเงินที่ถูกต้อง';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // เลือกวันครบกำหนด
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'วันครบกำหนดชำระ',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _dueDate == null
                                    ? 'ยังไม่ได้เลือกวันที่'
                                    : DateFormat('dd/MM/yyyy').format(_dueDate!),
                                style: TextStyle(
                                  color: _dueDate == null ? Colors.red : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _dueDate ?? DateTime.now().add(const Duration(days: 30)),
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (picked != null) {
                              setState(() => _dueDate = picked);
                            }
                          },
                          icon: const Icon(Icons.calendar_today),
                          label: const Text('เลือกวันที่'),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // ปุ่มเพิ่มรายการ
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _submit,
                    icon: _isLoading
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                        : const Icon(Icons.add),
                    label: Text(_isLoading ? 'กำลังเพิ่มรายการ...' : 'เพิ่มรายการ'),
                    style: ElevatedButton.styleFrom(
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }
}