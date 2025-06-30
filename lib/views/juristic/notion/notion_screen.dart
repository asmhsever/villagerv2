// lib/views/juristic/notion_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotionScreen extends StatefulWidget {
  const NotionScreen({super.key});

  @override
  State<NotionScreen> createState() => _NotionScreenState();
}

class _NotionScreenState extends State<NotionScreen> {
  int? lawId;
  int? villageId;
  bool isLoading = true;
  List<dynamic> notions = [];

  final _headerController = TextEditingController();
  final _descriptionController = TextEditingController();
  int? editId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    lawId = args?['law_id'];
    villageId = args?['village_id'];

    if (lawId != null && villageId != null) {
      _loadNotions();
    } else {
      setState(() => isLoading = false);
    }
  }

  Future<void> _loadNotions() async {
    final client = Supabase.instance.client;
    final result = await client
        .from('notion')
        .select()
        .order('notion_id', ascending: false);


    setState(() {
      notions = result;
      isLoading = false;
    });
  }

  Future<void> _insertOrUpdateNotion() async {
    final client = Supabase.instance.client;
    final header = _headerController.text.trim();
    final description = _descriptionController.text.trim();

    if (header.isEmpty || description.isEmpty || lawId == null || villageId == null) return;

    if (editId != null) {
      await client.from('notion').update({
        'header': header,
        'description': description,
      }).eq('notion_id', editId);
    } else {
      await client.from('notion').insert({
        'header': header,
        'description': description,
        'law_id': lawId,
        'village_id': villageId,
      });
    }

    _headerController.clear();
    _descriptionController.clear();
    editId = null;
    _loadNotions();
    Navigator.of(context).pop();
  }

  Future<void> _deleteNotion(int notionId) async {
    final client = Supabase.instance.client;
    await client.from('notion').delete().eq('notion_id', notionId);
    _loadNotions();
  }

  void _showAddDialog({Map? item}) {
    if (item != null) {
      _headerController.text = item['header'] ?? '';
      _descriptionController.text = item['description'] ?? '';
      editId = item['notion_id'];
    } else {
      _headerController.clear();
      _descriptionController.clear();
      editId = null;
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(editId != null ? 'แก้ไขประกาศ' : 'สร้างประกาศใหม่'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _headerController, decoration: const InputDecoration(labelText: 'หัวข้อ')),
            TextField(controller: _descriptionController, decoration: const InputDecoration(labelText: 'รายละเอียด')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('ยกเลิก')),
          ElevatedButton(onPressed: _insertOrUpdateNotion, child: const Text('บันทึก')),
        ],
      ),
    );
  }

  String _formatDate(String? isoDate) {
    if (isoDate == null) return '';
    final dt = DateTime.tryParse(isoDate);
    return dt != null ? '${dt.day}/${dt.month}/${dt.year}' : '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ประกาศข่าวสาร'),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: () => _showAddDialog()),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : notions.isEmpty
          ? const Center(child: Text('ไม่มีประกาศ'))
          : ListView.separated(
        itemCount: notions.length,
        separatorBuilder: (_, __) => const Divider(),
        itemBuilder: (context, index) {
          final item = notions[index];
          return ListTile(
            leading: const Icon(Icons.campaign),
            title: Text(item['header'] ?? '-'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['description'] ?? ''),
                Text('วันที่: ${_formatDate(item['created_at'])}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.orange),
                  onPressed: () => _showAddDialog(item: item),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteNotion(item['notion_id']),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
