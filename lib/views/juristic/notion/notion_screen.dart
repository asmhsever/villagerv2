// 📁 lib/views/juristic/notion/notion_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'add_notion_screen.dart';
import 'edit_notion_screen.dart';

class NotionScreen extends StatefulWidget {
  final int lawId;
  final int villageId;
  const NotionScreen({super.key, required this.lawId, required this.villageId});

  @override
  State<NotionScreen> createState() => _NotionScreenState();
}

class _NotionScreenState extends State<NotionScreen> {
  List<Map<String, dynamic>> data = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final response = await Supabase.instance.client
        .from('notion')
        .select()
        .eq('law_id', widget.lawId)
        .eq('village_id', widget.villageId)
        .order('created_at', ascending: false);

    setState(() {
      data = List<Map<String, dynamic>>.from(response);
      isLoading = false;
    });
  }

  Future<void> _deleteNotion(int id) async {
    await Supabase.instance.client.from('notion').delete().eq('notion_id', id);
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ข่าวสาร'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final added = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddNotionScreen(
                    lawId: widget.lawId,
                    villageId: widget.villageId,
                  ),
                ),
              );
              if (added == true) _loadData();
            },
          )
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: data.length,
        separatorBuilder: (_, __) => const Divider(),
        itemBuilder: (_, index) {
          final item = data[index];
          return ListTile(
            title: Text(
              item['header'] ?? '',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['description'] ?? ''),
                const SizedBox(height: 8),
                Text(
                  DateFormat('yyyy-MM-dd').format(DateTime.parse(item['created_at'])),
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'edit') {
                  final updated = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EditNotionScreen(
                        notionId: item['notion_id'],
                        lawId: widget.lawId,
                        villageId: widget.villageId,
                      ),
                    ),
                  );
                  if (updated == true) _loadData();
                } else if (value == 'delete') {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('ยืนยันการลบ'),
                      content: const Text('คุณต้องการลบรายการนี้ใช่หรือไม่?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('ยกเลิก')),
                        TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('ลบ')),
                      ],
                    ),
                  );
                  if (confirmed == true) {
                    await _deleteNotion(item['notion_id']);
                  }
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'edit', child: Text('แก้ไข')),
                const PopupMenuItem(value: 'delete', child: Text('ลบ')),
              ],
            ),
          );
        },
      ),
    );
  }
}

