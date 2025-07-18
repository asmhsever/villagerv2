// lib/pages/law/complaint_detail_page.dart

import 'package:flutter/material.dart';
import '../../../models/complaint_model.dart';
import '../../../services/law/complaint_service.dart';

class ComplaintDetailPage extends StatefulWidget {
  final ComplaintModel complaint;

  const ComplaintDetailPage({super.key, required this.complaint});

  @override
  State<ComplaintDetailPage> createState() => _ComplaintDetailPageState();
}

class _ComplaintDetailPageState extends State<ComplaintDetailPage> {
  final ComplaintService _service = ComplaintService();
  late String _status;

  final List<String> statusOptions = [
    'รอดำเนินการ',
    'กำลังดำเนินการ',
    'เสร็จสิ้น'
  ];

  @override
  void initState() {
    super.initState();
    _status = statusOptions.contains(widget.complaint.status)
        ? widget.complaint.status
        : statusOptions.first;
  }

  Future<void> _updateStatus() async {
    await _service.updateStatus(widget.complaint.id, _status);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('อัปเดตสถานะเรียบร้อย')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.complaint;
    return Scaffold(
      appBar: AppBar(title: Text('คำร้อง: ${c.header}')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('วันที่แจ้ง: ${c.date.toLocal().toIso8601String().substring(0, 10)}'),
            const SizedBox(height: 8),
            Text('รายละเอียด:', style: Theme.of(context).textTheme.titleMedium),
            Text(c.description),
            const SizedBox(height: 16),
            if (c.img != null && c.img!.isNotEmpty) Image.network(c.img!),
            const SizedBox(height: 24),
            DropdownButtonFormField<String>(
              value: _status,
              decoration: const InputDecoration(labelText: 'สถานะ'),
              items: statusOptions
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (val) => setState(() => _status = val ?? statusOptions.first),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _updateStatus,
              icon: const Icon(Icons.save),
              label: const Text('บันทึกสถานะ'),
            ),
          ],
        ),
      ),
    );
  }
}
