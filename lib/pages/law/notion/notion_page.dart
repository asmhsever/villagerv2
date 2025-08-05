import 'package:flutter/material.dart';
import 'package:fullproject/pages/law/notion/notion_edit_page.dart';
import 'package:intl/intl.dart';
import 'package:fullproject/models/notion_model.dart';
import 'package:fullproject/domains/notion_domain.dart';
import 'package:fullproject/services/auth_service.dart';
import 'package:fullproject/models/law_model.dart';
import 'package:fullproject/pages/law/notion/notion_add_page.dart';

class LawNotionPage extends StatefulWidget {
  const LawNotionPage({super.key});

  @override
  State<LawNotionPage> createState() => _LawNotionPageState();
}

class _LawNotionPageState extends State<LawNotionPage> {
  final NotionDomain _domain = NotionDomain();
  Future<List<NotionModel>>? _notions;
  LawModel? law;

  @override
  void initState() {
    super.initState();
    _loadNotions();
  }

  Future<void> _loadNotions() async {
    final user = await AuthService.getCurrentUser();
    if (user is LawModel) {
      setState(() => law = user);
      final results = await NotionDomain.getByVillage(user.villageId);
      setState(() {
        _notions = Future.value(results);
      });
    } else {
      _notions = Future.value([]);
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  Future<void> _navigateToAdd() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LawNotionAddPage()),
    );
    if (result == true) _loadNotions();
  }

  Future<void> _navigateToEdit(NotionModel notion) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => LawNotionEditPage(notion: notion)),
    );
    if (result == true) _loadNotions();
  }

  Future<void> _confirmDelete(NotionModel notion) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("ยืนยันการลบ"),
        content: Text("คุณต้องการลบข่าว '${notion.header}' ใช่หรือไม่?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("ยกเลิก"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("ลบ"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await NotionDomain.delete(notion.notionId);
      _loadNotions();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ข่าวสารหมู่บ้าน')),
      body: FutureBuilder<List<NotionModel>>(
        future: _notions,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('ไม่มีข่าวสารในขณะนี้'));
          }

          final notions = snapshot.data!;
          return ListView.builder(
            itemCount: notions.length,
            itemBuilder: (context, index) {
              final notion = notions[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  title: Text(
                    notion.header ?? '-',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(notion.description ?? ''),
                      const SizedBox(height: 4),
                      Text(
                        'วันที่: ${_formatDate(notion.createDate)}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.orange),
                        onPressed: () => _navigateToEdit(notion),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _confirmDelete(notion),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAdd,
        child: const Icon(Icons.add),
        tooltip: 'เพิ่มข่าวสาร',
      ),
    );
  }
}
