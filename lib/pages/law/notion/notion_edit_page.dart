import 'package:flutter/material.dart';
import 'package:fullproject/domains/notion_domain.dart';
import 'package:fullproject/models/notion_model.dart';

class NotionEditPage extends StatefulWidget {
  final NotionModel notion;

  const NotionEditPage({super.key, required this.notion});

  @override
  State<NotionEditPage> createState() => _NotionEditPageState();
}

class _NotionEditPageState extends State<NotionEditPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _headerController;
  late TextEditingController _descController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _headerController = TextEditingController(text: widget.notion.header ?? '');
    _descController = TextEditingController(text: widget.notion.description ?? '');
  }

  Future<void> _submit() async {
    if (_isSaving || !_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final updatedNotion = NotionModel(
      notionId: widget.notion.notionId,
      lawId: widget.notion.lawId,
      villageId: widget.notion.villageId,
      header: _headerController.text.trim(),
      description: _descController.text.trim(),
      createDate: widget.notion.createDate,
      img: widget.notion.img,
    );

    await NotionDomain().update(updatedNotion);

    if (mounted) Navigator.pop(context, true);
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
                decoration: const InputDecoration(labelText: 'หัวข้อข่าว'),
                validator: (value) => value == null || value.isEmpty ? 'กรุณากรอกหัวข้อข่าว' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descController,
                maxLines: 5,
                decoration: const InputDecoration(labelText: 'เนื้อหาข่าว'),
                validator: (value) => value == null || value.isEmpty ? 'กรุณากรอกรายละเอียดข่าว' : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isSaving ? null : _submit,
                child: _isSaving
                    ? const CircularProgressIndicator()
                    : const Text('บันทึกการแก้ไข'),
              )
            ],
          ),
        ),
      ),
    );
  }
}
