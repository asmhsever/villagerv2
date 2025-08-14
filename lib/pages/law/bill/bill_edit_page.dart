import 'package:flutter/material.dart';
import 'package:fullproject/domains/bill_domain.dart';
import 'package:fullproject/models/bill_model.dart';
import 'package:fullproject/config/supabase_config.dart';
import 'package:fullproject/services/auth_service.dart';
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
  bool _isLoading = false;
  bool _isInitialLoading = true;

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
    _initializeData();
  }

  Future<void> _initializeData() async {
    // ตั้งค่าเริ่มต้นจากบิลที่มีอยู่
    _amountController.text = widget.bill.amount.toString();
    _dueDate = widget.bill.dueDate;
    _selectedHouseId = widget.bill.houseId;
    _selectedServiceId = widget.bill.service;

    await _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    setState(() => _isInitialLoading = true);

    try {
      final law = await AuthService.getCurrentUser();

      // ดึงข้อมูลบ้านเฉพาะในหมู่บ้านนี้
      final houses = await SupabaseConfig.client
          .from('house')
          .select('house_id, house_number')
          .eq('village_id', law.villageId)
          .order('house_number');

      // ดึงข้อมูลประเภทบริการ
      final services = await SupabaseConfig.client
          .from('service')
          .select('service_id, name')
          .order('service_id');

      setState(() {
        _houses = List<Map<String, dynamic>>.from(houses);
        _services = List<Map<String, dynamic>>.from(services);
        _isInitialLoading = false;
      });
    } catch (e) {
      setState(() => _isInitialLoading = false);
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
        _selectedServiceId == null) {
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
      final updatedBill = widget.bill.copyWith(
        houseId: _selectedHouseId!,
        amount: double.parse(_amountController.text),
        dueDate: _dueDate,
        service: _selectedServiceId,
      );

      final result = await BillDomain.update(
        billId: updatedBill.billId,
        updatedBill: updatedBill,
      );

      if (result != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('อัพเดทบิลสำเร็จ'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        if (mounted) Navigator.pop(context, true);
      } else {
        throw Exception('ไม่สามารถอัพเดทบิลได้');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาด: อัพเดทบิลไม่สำเร็จ\n${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'ลองใหม่',
            textColor: Colors.white,
            onPressed: () => _submit(),
          ),
        ),
      );
      print('Error updating bill: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _confirmCancel() async {
    final hasChanges = _hasUnsavedChanges();

    if (!hasChanges) {
      Navigator.pop(context);
      return;
    }

    final shouldLeave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ยกเลิกการแก้ไข'),
        content: const Text('คุณมีการเปลี่ยนแปลงที่ยังไม่ได้บันทึก\nต้องการออกจากหน้านี้หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('ออกจากหน้านี้'),
          ),
        ],
      ),
    );

    if (shouldLeave == true && mounted) {
      Navigator.pop(context);
    }
  }

  bool _hasUnsavedChanges() {
    return _amountController.text != widget.bill.amount.toString() ||
        _dueDate != widget.bill.dueDate ||
        _selectedHouseId != widget.bill.houseId ||
        _selectedServiceId != widget.bill.service;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasUnsavedChanges(),
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop && _hasUnsavedChanges()) {
          await _confirmCancel();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('แก้ไขบิล #${widget.bill.billId}'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _confirmCancel,
          ),
          actions: [
            if (_hasUnsavedChanges())
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  setState(() {
                    _amountController.text = widget.bill.amount.toString();
                    _dueDate = widget.bill.dueDate;
                    _selectedHouseId = widget.bill.houseId;
                    _selectedServiceId = widget.bill.service;
                  });
                },
                tooltip: 'รีเซ็ตการเปลี่ยนแปลง',
              ),
          ],
        ),
        body: _isInitialLoading
            ? const Center(child: CircularProgressIndicator())
            : _houses.isEmpty || _services.isEmpty
            ? const Center(
          child: Text('ไม่พบข้อมูลบ้านหรือประเภทบริการ'),
        )
            : SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // แสดงข้อมูลบิลเดิม
                Card(
                  color: Colors.blue.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ข้อมูลบิลเดิม',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text('รหัสบิล: ${widget.bill.billId}'),
                        Text('จำนวนเงินเดิม: ${widget.bill.amount} บาท'),
                        Text('วันครบกำหนดเดิม: ${DateFormat('dd/MM/yyyy').format(widget.bill.dueDate)}'),
                        Text('สถานะ: ${widget.bill.paidStatus == 1 ? 'ชำระแล้ว' : 'ยังไม่ชำระ'}'),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

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
                  decoration: const InputDecoration(
                    labelText: 'ประเภทบริการ',
                    border: OutlineInputBorder(),
                  ),
                  items: _services.map((service) {
                    return DropdownMenuItem<int>(
                      value: service['service_id'],
                      child: Text(_getServiceNameTh(service['name'])),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedServiceId = val),
                  validator: (val) =>
                  val == null ? 'กรุณาเลือกประเภทบริการ' : null,
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
                          icon: const Icon(Icons.calendar_today),
                          label: const Text('เลือกวันที่'),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // ปุ่มบันทึก
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
                        : const Icon(Icons.save),
                    label: Text(_isLoading ? 'กำลังบันทึก...' : 'บันทึกการแก้ไข'),
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