/// lib/views/juristic/complaint/finished_complaint_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'complaint_model.dart';

class FinishedComplaintScreen extends StatefulWidget {
  final Complaint complaint;

  const FinishedComplaintScreen({super.key, required this.complaint});

  @override
  State<FinishedComplaintScreen> createState() => _FinishedComplaintScreenState();
}

class _FinishedComplaintScreenState extends State<FinishedComplaintScreen> {
  final _descController = TextEditingController();
  final _picker = ImagePicker();
  File? _selectedImage;
  bool _loading = false;

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _selectedImage = File(picked.path));
    }
  }

  Future<void> _submit() async {
    if (_descController.text.isEmpty || _selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาใส่คำอธิบายและเลือกรูปภาพ')),
      );
      return;
    }

    setState(() => _loading = true);
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    final complaintId = widget.complaint.complaintId;

    // 1. upload image
    final imageName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final path = 'finished/$imageName';
    final bytes = await _selectedImage!.readAsBytes();
    await client.storage.from('imagefinished').uploadBinary(path, bytes);

    // 2. insert finished_complaint
    await client.from('finished_complaint').insert({
      'complaint_id': complaintId,
      'law_id': user?.id ?? 1, // fallback
      'description': _descController.text,
    });

    // 3. insert image_finished
    await client.from('image_finished').insert({
      'complaint_id': complaintId,
      'img_path': path,
    });

    // 4. update complaint.status
    await client.from('complaint')
        .update({'status': true})
        .eq('complaint_id', complaintId);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('อัปเดตสถานะเสร็จแล้ว')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('บันทึกการดำเนินการ')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('คำอธิบายผลการดำเนินการ:'),
            TextField(
              controller: _descController,
              maxLines: 3,
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            const Text('แนบรูปภาพหลังดำเนินการ:'),
            TextButton.icon(
              icon: const Icon(Icons.image),
              label: const Text('เลือกจากแกลเลอรี่'),
              onPressed: _pickImage,
            ),
            if (_selectedImage != null)
              Image.file(_selectedImage!, height: 200),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const CircularProgressIndicator()
                    : const Text('บันทึกสถานะเสร็จแล้ว'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}