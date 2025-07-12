// lib/views/juristic/notion/edit_notion_screen.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditNotionScreen extends StatefulWidget {
  final int notionId;

  const EditNotionScreen({super.key, required this.notionId});

  @override
  State<EditNotionScreen> createState() => _EditNotionScreenState();
}

class _EditNotionScreenState extends State<EditNotionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _headerController = TextEditingController();
  final _descController = TextEditingController();
  bool _loading = false;

  Future<void> _loadNotion() async {
    setState(() => _loading = true);
    final data = await Supabase.instance.client
        .from('notion')
        .select('*')
        .eq('notion_id', widget.notionId)
        .maybeSingle();

    if (data != null) {
      _headerController.text = data['header'] ?? '';
      _descController.text = data['description'] ?? '';
    }
    setState(() => _loading = false);
  }

  Future<void> _updateNotion() async {
    if (!_formKey.currentState!.validate()) return;

    await Supabase.instance.client.from('notion').update({
      'header': _headerController.text,
      'description': _descController.text,
    }).eq('notion_id', widget.notionId);

    if (mounted) Navigator.pop(context, true);
  }

  @override
  void initState() {
    super.initState();
    _loadNotion();
  }

  @override
  void dispose() {
    _headerController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('แก้ไขประกาศ')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _headerController,
                decoration: const InputDecoration(labelText: 'หัวข้อ'),
                validator: (v) => v == null || v.isEmpty ? 'กรุณากรอกหัวข้อ' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(labelText: 'รายละเอียด'),
                maxLines: 4,
                validator: (v) => v == null || v.isEmpty ? 'กรุณากรอกรายละเอียด' : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _updateNotion,
                child: const Text('บันทึกการแก้ไข'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
