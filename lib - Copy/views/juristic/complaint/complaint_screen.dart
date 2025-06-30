// lib/views/juristic/complaint/complaint_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'complaint_service.dart';
import 'complaint_model.dart';
import 'complaint_detail_screen.dart';

class JuristicComplaintScreen extends StatefulWidget {
  const JuristicComplaintScreen({Key? key}) : super(key: key);

  @override
  State<JuristicComplaintScreen> createState() => _JuristicComplaintScreenState();
}

class _JuristicComplaintScreenState extends State<JuristicComplaintScreen> {
  final _service = ComplaintService();
  List<Complaint> _complaints = [];
  bool _loading = true;
  int? _villageId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final arg = ModalRoute.of(context)?.settings.arguments;
    if (arg is int) {
      _villageId = arg;
      _loadComplaints();
    } else {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadComplaints() async {
    if (_villageId == null) return;
    final list = await _service.fetchComplaints(_villageId!);
    setState(() {
      _complaints = list;
      _loading = false;
    });
  }

  String _statusText(bool status) => status ? '✅ เสร็จแล้ว' : '🕐 รอดำเนินการ';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('จัดการข้อร้องเรียน')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _complaints.isEmpty
          ? const Center(child: Text('ไม่มีข้อร้องเรียน'))
          : ListView.builder(
        itemCount: _complaints.length,
        itemBuilder: (context, index) {
          final c = _complaints[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              title: Text(c.header),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(c.description),
                  const SizedBox(height: 4),
                  Text('ประเภทคำร้อง: ${c.typeName ?? c.typeComplaintId}'),
                  Text('ระดับความรุนแรง: ${c.levelId}'),
                  Text('วันที่แจ้ง: ${DateFormat('dd MMM yyyy').format(c.date)}'),
                  Text('สถานะ: ${_statusText(c.status)}'),
                ],
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ComplaintDetailScreen(complaint: c),
                ),
              ).then((_) => _loadComplaints()),
            ),
          );
        },
      ),
    );
  }
}
