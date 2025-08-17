import 'package:flutter/material.dart';
import 'package:fullproject/domains/notion_domain.dart';
import 'package:fullproject/models/notion_model.dart';

class LawNotionEditPage extends StatefulWidget {
  final NotionModel notion;

  const LawNotionEditPage({super.key, required this.notion});

  @override
  State<LawNotionEditPage> createState() => _LawNotionEditPageState();
}

class _LawNotionEditPageState extends State<LawNotionEditPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _headerController;
  late TextEditingController _descController;
  bool _isSaving = false;
  late String _selectedType; // เพิ่ม variable สำหรับ type

  // Map สำหรับแสดงชื่อ type เป็นภาษาไทย
  final Map<String, String> _typeLabels = {
    'GENERAL': 'ทั่วไป',
    'MAINTENANCE': 'การบำรุงรักษา',
    'SECURITY': 'ความปลอดภัย',
    'FINANCE': 'การเงิน',
    'SOCIAL': 'กิจกรรมสังคม',
  };

  @override
  void initState() {
    super.initState();
    _headerController = TextEditingController(text: widget.notion.header ?? '');
    _descController = TextEditingController(
      text: widget.notion.description ?? '',
    );
    // ตั้งค่า type เริ่มต้นจาก notion ที่มีอยู่
    _selectedType = widget.notion.type ?? 'GENERAL';
  }

  Future<void> _submit() async {
    if (_isSaving || !_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      await NotionDomain.update(
        notionId: widget.notion.notionId,
        lawId: widget.notion.lawId,
        villageId: widget.notion.villageId,
        header: _headerController.text.trim(),
        description: _descController.text.trim(),
        type: _selectedType,
        imageFile: null,
        // ยังไม่มีการจัดการรูป
        removeImage: false, // ไม่ลบรูป
      );

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      print("error can update notion $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ไม่สามารถแก้ไขข่าวสารได้ กรุณาลองใหม่อีกครั้ง'),
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
      appBar: AppBar(title: const Text('แก้ไขข่าวสาร')),
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
                      : const Text('บันทึกการแก้ไข'),
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
