// lib/views/juristic/complaint/add_complaint_screen.dart

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'complaint_service.dart';

class AddComplaintScreen extends StatefulWidget {
  final int houseId;

  const AddComplaintScreen({super.key, required this.houseId});

  @override
  State<AddComplaintScreen> createState() => _AddComplaintScreenState();
}

class _AddComplaintScreenState extends State<AddComplaintScreen> {
  final _formKey = GlobalKey<FormState>();
  final _headerController = TextEditingController();
  final _descriptionController = TextEditingController();
  int? _typeComplaint;
  int? _level;
  bool _isPrivate = false;
  File? _imageFile;
  final _service = ComplaintService();

  bool _loading = false;
  List<Map<String, dynamic>> _complaintTypes = [];
  List<Map<String, dynamic>> _levels = [];

  Future<void> _loadData() async {
    final types = await Supabase.instance.client.from('type_complaint').select('*');
    final levels = await Supabase.instance.client.from('level_complaint').select('*');
    setState(() {
      _complaintTypes = List<Map<String, dynamic>>.from(types);
      _levels = List<Map<String, dynamic>>.from(levels);
      if (_complaintTypes.isNotEmpty) {
        _typeComplaint = _complaintTypes.first['type_id'];
      }
      if (_levels.isNotEmpty) {
        _level = _levels.first['level_id'];
      }
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source);
    if (picked != null) {
      setState(() => _imageFile = File(picked.path));
    }
  }

  Future<String?> _uploadImage(File file) async {
    final filename = 'complaints/${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
    final bytes = await file.readAsBytes();
    final response = await Supabase.instance.client.storage
        .from('complaints')
        .uploadBinary(filename, bytes, fileOptions: const FileOptions(upsert: true));
    if (response.isEmpty) return null;
    return Supabase.instance.client.storage.from('complaints').getPublicUrl(filename);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _typeComplaint == null || _level == null) return;
    setState(() => _loading = true);

    try {
      String? imageUrl;
      if (_imageFile != null) {
        imageUrl = await _uploadImage(_imageFile!);
      }

      await _service.addComplaint(
        houseId: widget.houseId,
        typeComplaint: _typeComplaint!,
        level: _level!,
        header: _headerController.text.trim(),
        description: _descriptionController.text.trim(),
        isPrivate: _isPrivate,
        img: imageUrl,
      );

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาด: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ร้องเรียนใหม่')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _headerController,
                decoration: const InputDecoration(labelText: 'หัวข้อ'),
                validator: (v) => v!.isEmpty ? 'กรุณากรอกหัวข้อ' : null,
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'รายละเอียด'),
                maxLines: 5,
                validator: (v) => v!.isEmpty ? 'กรุณากรอกรายละเอียด' : null,
              ),
              DropdownButtonFormField<int>(
                decoration: const InputDecoration(labelText: 'ประเภทเรื่อง'),
                value: _typeComplaint,
                onChanged: (v) => setState(() => _typeComplaint = v),
                items: _complaintTypes.map<DropdownMenuItem<int>>((item) {
                  return DropdownMenuItem<int>(
                    value: item['type_id'] as int,
                    child: Text(item['type'] ?? ''),
                  );
                }).toList(),
              ),
              DropdownButtonFormField<int>(
                decoration: const InputDecoration(labelText: 'ระดับความเร่งด่วน'),
                value: _level,
                onChanged: (v) => setState(() => _level = v),
                items: _levels.map<DropdownMenuItem<int>>((item) {
                  return DropdownMenuItem<int>(
                    value: item['level_id'] as int,
                    child: Text(item['level'] ?? ''),
                  );
                }).toList(),
              ),
              SwitchListTile(
                title: const Text('ร้องเรียนส่วนตัว'),
                value: _isPrivate,
                onChanged: (v) => setState(() => _isPrivate = v),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.image),
                    label: const Text('เลือกรูปจากแกลเลอรี'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('ถ่ายรูป'),
                  ),
                ],
              ),
              if (_imageFile != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Image.file(_imageFile!, height: 150),
                ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const CircularProgressIndicator()
                    : const Text('ส่งร้องเรียน'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
