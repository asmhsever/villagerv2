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
      final notion = NotionModel(
        notionId: 0,
        lawId: user.lawId,
        villageId: user.villageId,
        header: _headerController.text.trim(),
        description: _descController.text.trim(),
        createDate: DateTime.now(),
        img: null,
      );
      print(notion.toJson());
      final createNotion = await NotionDomain.create(notion);
      if (createNotion == null) {
        print("error add notion");
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
                decoration: const InputDecoration(labelText: 'หัวข้อข่าว'),
                validator: (value) => value == null || value.isEmpty
                    ? 'กรุณากรอกหัวข้อข่าว'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descController,
                maxLines: 5,
                decoration: const InputDecoration(labelText: 'เนื้อหาข่าว'),
                validator: (value) => value == null || value.isEmpty
                    ? 'กรุณากรอกรายละเอียดข่าว'
                    : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isSaving ? null : _submit,
                child: _isSaving
                    ? const CircularProgressIndicator()
                    : const Text('บันทึกข่าวสาร'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
