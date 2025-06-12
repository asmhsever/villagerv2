// lib/views/juristic/complaint_screen.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class ComplaintScreen extends StatefulWidget {
  const ComplaintScreen({super.key});

  @override
  State<ComplaintScreen> createState() => _ComplaintScreenState();
}

class _ComplaintScreenState extends State<ComplaintScreen> {
  List<Map<String, dynamic>> complaints = [];
  bool isLoading = true;
  int? villageId;
  String statusFilter = 'all';
  String? severityFilter;
  String searchText = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is int) {
      villageId = args;
      _loadComplaints();
    }
  }

  Future<void> _loadComplaints() async {
    setState(() => isLoading = true);
    final client = Supabase.instance.client;

    final raw = await client.rpc('get_complaints_with_details', params: {'village_id': villageId});
    complaints = List<Map<String, dynamic>>.from(raw);
    setState(() => isLoading = false);
  }

  void _showActionDialog(Map<String, dynamic> complaint) async {
    final TextEditingController controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('ดำเนินการคำร้อง'),
          content: TextField(
            controller: controller,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'รายละเอียดผลดำเนินการ'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('ยกเลิก')),
            ElevatedButton(
              onPressed: () async {
                await Supabase.instance.client.from('finished_complaint').insert({
                  'complaint_id': complaint['complaint_id'],
                  'law_id': complaint['law_id'] ?? 1,
                  'description': controller.text,
                });
                await Supabase.instance.client
                    .from('complaint')
                    .update({'status': true})
                    .eq('complaint_id', complaint['complaint_id']);
                Navigator.pop(context);
                _loadComplaints();
              },
              child: const Text('บันทึก'),
            )
          ],
        );
      },
    );
  }

  List<Map<String, dynamic>> _filteredComplaints() {
    return complaints.where((c) {
      final matchesStatus = statusFilter == 'all' ||
          (statusFilter == 'resolved' && c['status'] == true) ||
          (statusFilter == 'pending' && c['status'] != true);
      final matchesLevel = severityFilter == null || c['level_name'] == severityFilter;
      final matchesSearch = searchText.isEmpty ||
          c['header'].toString().toLowerCase().contains(searchText.toLowerCase()) ||
          c['description'].toString().toLowerCase().contains(searchText.toLowerCase());
      return matchesStatus && matchesLevel && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final f = DateFormat('yyyy-MM-dd');
    final filtered = _filteredComplaints();

    return Scaffold(
      appBar: AppBar(title: const Text('คำร้องเรียนลูกบ้าน')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                DropdownButton<String>(
                  value: statusFilter,
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('ทั้งหมด')),
                    DropdownMenuItem(value: 'pending', child: Text('รอดำเนินการ')),
                    DropdownMenuItem(value: 'resolved', child: Text('ดำเนินการแล้ว')),
                  ],
                  onChanged: (value) => setState(() => statusFilter = value!),
                ),
                const SizedBox(width: 16),
                DropdownButton<String?>(
                  hint: const Text('ระดับ'),
                  value: severityFilter,
                  items: [
                    const DropdownMenuItem(value: null, child: Text('ทั้งหมด')),
                    ...{'Low', 'Moderate', 'High', 'Critical', 'Emergency'}.map(
                          (e) => DropdownMenuItem(value: e, child: Text(e)),
                    )
                  ],
                  onChanged: (v) => setState(() => severityFilter = v),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(hintText: 'ค้นหา...'),
                    onChanged: (value) => setState(() => searchText = value),
                  ),
                )
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Text('รวม: ${filtered.length} รายการ'),
                const Spacer(),
                Text('รอดำเนินการ: ${complaints.where((c) => c['status'] != true).length}'),
                const SizedBox(width: 16),
                Text('ดำเนินการแล้ว: ${complaints.where((c) => c['status'] == true).length}'),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              children: filtered.map((c) {
                return Card(
                  margin: const EdgeInsets.all(8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c['header'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text(c['description']),
                        Text('หมวดหมู่: ${c['type_name'] ?? '-'}'),
                        Text('ระดับ: ${c['level_name'] ?? '-'}'),
                        Text('วันที่: ${c['date'] ?? '-'}'),
                        Text('สถานะ: ${c['status'] == true ? '✅ ดำเนินการแล้ว' : '⏳ รอดำเนินการ'}'),
                        const SizedBox(height: 8),
                        if (c['status'] != true)
                          Align(
                            alignment: Alignment.centerRight,
                            child: ElevatedButton(
                              onPressed: () => _showActionDialog(c),
                              child: const Text('ดำเนินการ'),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
