// 📁 lib/views/juristic/notion/edit_notion_screen.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditNotionScreen extends StatefulWidget {
  final int notionId;
  final int lawId;
  final int villageId;

  const EditNotionScreen({
    super.key,
    required this.notionId,
    required this.lawId,
    required this.villageId,
  });

  @override
  State<EditNotionScreen> createState() => _EditNotionScreenState();
}

class _EditNotionScreenState extends State<EditNotionScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _headerController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotion();
  }

  Future<void> _loadNotion() async {
    final notion = await Supabase.instance.client
        .from('notion')
        .select()
        .eq('notion_id', widget.notionId)
        .maybeSingle();

    if (notion != null) {
      _headerController.text = notion['header'] ?? '';
      _descriptionController.text = notion['description'] ?? '';
    }

    setState(() => _isLoading = false);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    await Supabase.instance.client.from('notion').update({
      'header': _headerController.text.trim(),
      'description': _descriptionController.text.trim(),
    }).eq('notion_id', widget.notionId);

    setState(() => _isLoading = false);

    if (context.mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('แก้ไขข่าวสาร')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _headerController,
                decoration: const InputDecoration(labelText: 'หัวข้อ'),
                validator: (value) =>
                value!.isEmpty ? 'กรุณากรอกหัวข้อ' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration:
                const InputDecoration(labelText: 'รายละเอียด'),
                maxLines: 5,
                validator: (value) =>
                value!.isEmpty ? 'กรุณากรอกรายละเอียด' : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                child: _isLoading
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
