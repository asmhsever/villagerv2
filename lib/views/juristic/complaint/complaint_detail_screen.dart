// lib/views/juristic/complaint/complaint_detail_screen.dart

import 'package:flutter/material.dart';
import 'complaint_service.dart';
import 'add_complaint_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';

class ComplaintDetailScreen extends StatefulWidget {
  final int complaintId;
  final bool isJuristic;

  const ComplaintDetailScreen({super.key, required this.complaintId, this.isJuristic = false});

  @override
  State<ComplaintDetailScreen> createState() => _ComplaintDetailScreenState();
}

class _ComplaintDetailScreenState extends State<ComplaintDetailScreen> {
  final _service = ComplaintService();
  Map<String, dynamic>? _complaint;
  bool _loading = true;

  Future<void> _load() async {
    final data = await _service.getComplaintById(widget.complaintId);

    if (data != null && data['house_id'] != null) {
      final house = await Supabase.instance.client
          .from('house')
          .select('house_number')
          .eq('house_id', data['house_id'])
          .maybeSingle();
      data['house_number'] = house?['house_number'];
    }

    if (data != null && data['type_complaint'] != null) {
      final type = await Supabase.instance.client
          .from('type_complaint')
          .select('type')
          .eq('type_id', data['type_complaint'])
          .maybeSingle();
      data['type_complaint_name'] = type?['type'];
    }

    setState(() {
      _complaint = data;
      _loading = false;
    });
  }

  String _urgencyLabel(int level) {
    switch (level) {
      case 1:
        return 'Low';
      case 2:
        return 'Moderate';
      case 3:
        return 'High';
      case 4:
        return 'Critical';
      case 5:
        return 'Emergency';
      default:
        return 'Unknown';
    }
  }

  Future<void> _changeStatus(String status) async {
    await _service.updateComplaintStatus(
      complaintId: widget.complaintId,
      status: status,
    );
    await _load();
  }

  Future<void> _confirmDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('ยืนยันการลบ'),
        content: const Text('คุณแน่ใจหรือไม่ว่าต้องการลบรายการนี้?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('ยกเลิก')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('ลบ')),
        ],
      ),
    );

    if (confirm == true) {
      await _service.deleteComplaint(widget.complaintId);
      if (mounted) Navigator.pop(context, true);
    }
  }

  Future<void> _editComplaint() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddComplaintScreen(houseId: _complaint!['house_id']),
      ),
    );
    if (result == true) _load();
  }

  Future<void> _exportToPDF() async {
    final pdf = pw.Document();
    final c = _complaint!;

    pw.ImageProvider? image;
    if (c['img'] != null && c['img'].toString().isNotEmpty) {
      final response = await http.get(Uri.parse(c['img']));
      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        image = pw.MemoryImage(bytes);
      }
    }

    pdf.addPage(
      pw.Page(
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Complaint Report', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 20),
            pw.Text('หัวข้อ: ${c['header'] ?? ''}'),
            pw.Text('รายละเอียด: ${c['description'] ?? ''}'),
            pw.Text('ประเภทเรื่อง: ${c['type_complaint_name'] ?? ''}'),
            pw.Text('ระดับ: ${_urgencyLabel(c['level'] ?? 0)}'),
            pw.Text('สถานะ: ${c['status_complaint'] ?? ''}'),
            pw.Text('บ้านเลขที่: ${c['house_number'] ?? ''}'),
            pw.Text('วันที่แจ้ง: ${c['date'] ?? ''}'),
            if (image != null) ...[
              pw.SizedBox(height: 20),
              pw.Text('แนบรูปภาพ:'),
              pw.SizedBox(height: 10),
              pw.Image(image, height: 200),
            ]
          ],
        ),
      ),
    );

    await Printing.layoutPdf(onLayout: (format) => pdf.save());
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('รายละเอียดร้องเรียน'),
        actions: widget.isJuristic
            ? [
          IconButton(icon: const Icon(Icons.picture_as_pdf), onPressed: _exportToPDF),
          IconButton(icon: const Icon(Icons.edit), onPressed: _editComplaint),
          IconButton(icon: const Icon(Icons.delete), onPressed: _confirmDelete),
        ]
            : null,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _complaint == null
          ? const Center(child: Text('ไม่พบข้อมูล'))
          : Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text('หัวข้อ: ${_complaint!['header'] ?? '-'}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('รายละเอียด: ${_complaint!['description'] ?? '-'}'),
            const SizedBox(height: 8),
            Text('ประเภทเรื่อง: ${_complaint!['type_complaint_name'] ?? '-'}'),
            const SizedBox(height: 8),
            Text('สถานะ: ${_complaint!['status_complaint'] ?? 'รอดำเนินการ'}'),
            const SizedBox(height: 8),
            Text('เลขที่บ้าน: ${_complaint!['house_number'] ?? '-'}'),
            const SizedBox(height: 8),
            Text('ระดับความเร่งด่วน: ${_urgencyLabel(_complaint!['level'] ?? 0)}'),
            const SizedBox(height: 8),
            Text('วันที่แจ้ง: ${_complaint!['date'] ?? '-'}'),
            if (_complaint!['img'] != null && _complaint!['img'].toString().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    _complaint!['img'],
                    fit: BoxFit.cover,
                    height: 200,
                    errorBuilder: (_, __, ___) => const Text('ไม่สามารถโหลดรูปภาพได้'),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            if (widget.isJuristic)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () => _changeStatus('in_progress'),
                    child: const Text('กำลังดำเนินการ'),
                  ),
                  ElevatedButton(
                    onPressed: () => _changeStatus('done'),
                    child: const Text('เสร็จสิ้น'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
