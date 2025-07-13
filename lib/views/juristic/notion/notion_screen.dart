// lib/views/juristic/notion/notion_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'edit_notion_screen.dart';
import 'add_notion_screen.dart';

class NotionScreen extends StatefulWidget {
  final int villageId;
  final int lawId;

  const NotionScreen({super.key, required this.villageId, required this.lawId});

  @override
  State<NotionScreen> createState() => _NotionScreenState();
}

class _NotionScreenState extends State<NotionScreen> {
  List<Map<String, dynamic>> _notices = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _loading = true;
  String _search = '';

  Future<void> _loadNotices() async {
    setState(() => _loading = true);
    final data = await Supabase.instance.client
        .from('notion')
        .select('*')
        .eq('village_id', widget.villageId)
        .order('created_at', ascending: false);

    setState(() {
      _notices = List<Map<String, dynamic>>.from(data);
      _filtered = _notices;
      _loading = false;
    });
  }

  void _filterNotices(String query) {
    setState(() {
      _search = query;
      _filtered = _notices.where((n) {
        final header = n['header']?.toLowerCase() ?? '';
        final desc = n['description']?.toLowerCase() ?? '';
        return header.contains(query.toLowerCase()) || desc.contains(query.toLowerCase());
      }).toList();
    });
  }

  Future<void> _deleteNotice(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('ยืนยันการลบ'),
        content: const Text('คุณแน่ใจหรือไม่ว่าต้องการลบประกาศนี้?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('ยกเลิก')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('ลบ')),
        ],
      ),
    );

    if (confirm == true) {
      await Supabase.instance.client
          .from('notion')
          .delete()
          .eq('notion_id', id);
      _loadNotices();
    }
  }

  @override
  void initState() {
    super.initState();
    _loadNotices();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ข่าวสาร/ประกาศ'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'ค้นหาประกาศ',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: _filterNotices,
            ),
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: () async => _loadNotices(),
        child: ListView.builder(
          itemCount: _filtered.length,
          itemBuilder: (context, index) {
            final notice = _filtered[index];
            final createdAt = notice['created_at'] != null
                ? DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(notice['created_at']))
                : '-';
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: ListTile(
                title: Text(notice['header'] ?? '-'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(notice['description'] ?? '-'),
                    const SizedBox(height: 4),
                    Text('วันที่: $createdAt', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EditNotionScreen(notionId: notice['notion_id']),
                          ),
                        );
                        if (result == true) _loadNotices();
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _deleteNotice(notice['notion_id']),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddNotionScreen(villageId: widget.villageId, lawId: widget.lawId),
            ),
          );
          if (result == true) _loadNotices();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
