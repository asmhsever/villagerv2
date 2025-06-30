// lib/views/resident/complaint_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ResidentComplaintScreen extends StatefulWidget {
  const ResidentComplaintScreen({super.key});

  @override
  State<ResidentComplaintScreen> createState() => _ResidentComplaintScreenState();
}

class _ResidentComplaintScreenState extends State<ResidentComplaintScreen> {
  final _formKey = GlobalKey<FormState>();
  String? header;
  String? description;
  int? houseId;
  int? villagerId;
  int? villageId;
  bool isSubmitting = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      houseId = args['house_id'] as int?;
      villageId = args['village_id'] as int?;
      villagerId = args['villager_id'] as int?;
    }
  }

  Future<void> _submitComplaint() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    if (houseId == null || villageId == null) return;

    setState(() => isSubmitting = true);

    final client = Supabase.instance.client;
    try {
      await client.from('complaint').insert({
        'house_id': houseId,
        'type_complaint': 1, // กำหนดค่าเริ่มต้นหรือให้เลือกในอนาคต
        'date': DateTime.now().toIso8601String(),
        'header': header,
        'description': description,
        'status': false,
        'level': 1,
        'private': false,
      });
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      print('❌ Insert error: $e');
      setState(() => isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('แจ้งปัญหา')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'หัวข้อปัญหา'),
                onSaved: (val) => header = val,
                validator: (val) => val == null || val.isEmpty ? 'กรุณากรอกหัวข้อ' : null,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'รายละเอียด'),
                maxLines: 4,
                onSaved: (val) => description = val,
                validator: (val) => val == null || val.isEmpty ? 'กรุณากรอกรายละเอียด' : null,
              ),
              const SizedBox(height: 24),
              isSubmitting
                  ? const CircularProgressIndicator()
                  : ElevatedButton.icon(
                icon: const Icon(Icons.send),
                label: const Text('ส่งคำร้อง'),
                onPressed: _submitComplaint,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
