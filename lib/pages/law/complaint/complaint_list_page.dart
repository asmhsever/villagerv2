// lib/pages/law/complaint_list_page.dart

import 'package:flutter/material.dart';
import '../../../models/complaint_model.dart';
import '../../../services/law/complaint_service.dart';
import 'complaint_detail_page.dart';

class ComplaintListPage extends StatefulWidget {
  const ComplaintListPage({super.key});

  @override
  State<ComplaintListPage> createState() => _ComplaintListPageState();
}

class _ComplaintListPageState extends State<ComplaintListPage> {
  final ComplaintService _service = ComplaintService();
  late Future<List<ComplaintModel>> _complaintsFuture;

  @override
  void initState() {
    super.initState();
    _complaintsFuture = _service.getAllComplaints();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('รายการคำร้องเรียน')),
      body: FutureBuilder<List<ComplaintModel>>(
        future: _complaintsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'));
          }
          final complaints = snapshot.data ?? [];
          if (complaints.isEmpty) {
            return const Center(child: Text('ไม่มีคำร้องเรียนในระบบ'));
          }
          return ListView.builder(
            itemCount: complaints.length,
            itemBuilder: (context, index) {
              final c = complaints[index];
              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  title: Text(c.header),
                  subtitle: Text('สถานะ: ${c.status}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ComplaintDetailPage(complaint: c),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
