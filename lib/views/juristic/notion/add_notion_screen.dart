// 📁 lib/views/juristic/notion/add_notion_screen.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddNotionScreen extends StatefulWidget {
  final int lawId;
  final int villageId;
  const AddNotionScreen({super.key, required this.lawId, required this.villageId});

  @override
  State<AddNotionScreen> createState() => _AddNotionScreenState();
}

class _AddNotionScreenState extends State<AddNotionScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _headerController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  bool _isLoading = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final header = _headerController.text.trim();
    final description = _descriptionController.text.trim();

    await Supabase.instance.client.from('notion').insert({
      'law_id': widget.lawId,
      'village_id': widget.villageId,
      'header': header,
      'description': description,
    });

    setState(() => _isLoading = false);
    if (context.mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('เพิ่มข่าวสาร')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _headerController,
                decoration: const InputDecoration(labelText: 'หัวข้อ'),
                validator: (value) => value!.isEmpty ? 'กรุณากรอกหัวข้อ' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'รายละเอียด'),
                maxLines: 5,
                validator: (value) => value!.isEmpty ? 'กรุณากรอกรายละเอียด' : null,
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
