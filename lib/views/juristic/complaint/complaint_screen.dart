// lib/views/juristic/complaint/complaint_screen.dart

import 'package:flutter/material.dart';
import 'complaint_service.dart';
import 'complaint_detail_screen.dart';
import 'add_complaint_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ComplaintScreen extends StatefulWidget {
  final int houseId;

  const ComplaintScreen({super.key, required this.houseId});

  @override
  State<ComplaintScreen> createState() => _ComplaintScreenState();
}

class _ComplaintScreenState extends State<ComplaintScreen> {
  final _service = ComplaintService();
  late Future<List<Map<String, dynamic>>> _futureComplaints;
  List<Map<String, dynamic>> _complaints = [];
  String _search = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await _service.fetchComplaintsByHouse(widget.houseId);

    for (final item in data) {
      final house = await Supabase.instance.client
          .from('house')
          .select('house_number')
          .eq('house_id', item['house_id'])
          .maybeSingle();
      item['house_number'] = house?['house_number'];
    }

    setState(() {
      _complaints = data;
    });
  }

  List<Map<String, dynamic>> get _filteredComplaints {
    return _complaints.where((item) {
      final header = item['header']?.toString().toLowerCase() ?? '';
      final houseId = item['house_id']?.toString() ?? '';
      return header.contains(_search.toLowerCase()) || houseId.contains(_search);
    }).toList();
  }

  void _refresh() => _load();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('รายการร้องเรียน'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'ค้นหาหัวข้อหรือ house_id',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (v) => setState(() => _search = v),
            ),
          ),
        ),
      ),
      body: _complaints.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: () async => _refresh(),
        child: ListView.builder(
          itemCount: _filteredComplaints.length,
          itemBuilder: (context, index) {
            final item = _filteredComplaints[index];
            return ListTile(
              title: Text(item['header'] ?? '-'),
              subtitle: Text('บ้าน: ${item['house_number'] ?? '-'}\nวันที่: ${item['date'] ?? '-'}'),
              trailing: Text(item['status_complaint'] ?? 'รอดำเนินการ'),
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ComplaintDetailScreen(
                      complaintId: item['complaint_id'],
                      isJuristic: true,
                    ),
                  ),
                );
                _refresh();
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddComplaintScreen(houseId: widget.houseId),
            ),
          );
          if (result == true) _refresh();
        },
      ),
    );
  }
}
