import 'package:flutter/material.dart';
import 'package:fullproject/domains/notion_domain.dart';
import 'package:fullproject/models/law_model.dart';
import 'package:fullproject/models/notion_model.dart';
import 'package:fullproject/services/auth_service.dart';

class LawNotionAddPage extends StatefulWidget {
  const LawNotionAddPage({super.key});

  @override
  State<LawNotionAddPage> createState() => _LawNotionAddPageState();
}

class _LawNotionAddPageState extends State<LawNotionAddPage> {
  final _formKey = GlobalKey<FormState>();
  final _headerController = TextEditingController();
  final _descController = TextEditingController();
  bool _isSaving = false;
  String _selectedType = 'GENERAL'; // เพิ่ม variable สำหรับเก็บ type

  // Map สำหรับแสดงชื่อ type เป็นภาษาไทย
  final Map<String, String> _typeLabels = {
    'GENERAL': 'ทั่วไป',
    'MAINTENANCE': 'การบำรุงรักษา',
    'SECURITY': 'ความปลอดภัย',
    'FINANCE': 'การเงิน',
    'SOCIAL': 'กิจกรรมสังคม',
  };

  Future<void> _submit() async {
    if (_isSaving || !_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final user = await AuthService.getCurrentUser();
      if (user is! LawModel) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('ไม่สามารถระบุผู้ใช้ได้')));
        return;
      }

      final createNotion = await NotionDomain.create(
        lawId: user.lawId,
        villageId: user.villageId,
        header: _headerController.text.trim(),
        description: _descController.text.trim(),
        type: _selectedType,
        imageFile: null, // ยังไม่มีการอัปโหลดรูป
      );

      if (createNotion == null) {
        print("error add notion");
        throw Exception('ไม่สามารถเพิ่มข่าวสารได้');
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      print("error add notion $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ไม่สามารถเพิ่มข่าวสารได้ กรุณาลองใหม่อีกครั้ง'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('เพิ่มข่าวสาร')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _headerController,
                decoration: const InputDecoration(
                  labelText: 'หัวข้อข่าว',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.isEmpty
                    ? 'กรุณากรอกหัวข้อข่าว'
                    : null,
              ),
              const SizedBox(height: 16),

              // Dropdown สำหรับเลือก type
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'ประเภทข่าวสาร',
                  border: OutlineInputBorder(),
                ),
                items: _typeLabels.entries.map((entry) {
                  return DropdownMenuItem<String>(
                    value: entry.key,
                    child: Text(entry.value),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedType = value!;
                  });
                },
                validator: (value) => value == null || value.isEmpty
                    ? 'กรุณาเลือกประเภทข่าวสาร'
                    : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _descController,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'เนื้อหาข่าว',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.isEmpty
                    ? 'กรุณากรอกรายละเอียดข่าว'
                    : null,
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _submit,
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('บันทึกข่าวสาร'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _headerController.dispose();
    _descController.dispose();
    super.dispose();
  }
}
