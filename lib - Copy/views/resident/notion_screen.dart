// lib/views/resident/notion_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ResidentNotionScreen extends StatefulWidget {
  const ResidentNotionScreen({super.key});

  @override
  State<ResidentNotionScreen> createState() => _ResidentNotionScreenState();
}

class _ResidentNotionScreenState extends State<ResidentNotionScreen> {
  int? villageId;
  bool isLoading = true;
  List<dynamic> notions = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is int) {
      villageId = args;
      _loadNotions(args);
    } else {
      setState(() => isLoading = false);
    }
  }

  Future<void> _loadNotions(int villageId) async {
    final client = Supabase.instance.client;
    final result = await client
        .from('notion')
        .select()
        .eq('village_id', villageId)
        .order('notion_id', ascending: false);

    setState(() {
      notions = result;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ประกาศข่าวสาร')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : notions.isEmpty
          ? const Center(child: Text('ยังไม่มีประกาศ'))
          : ListView.separated(
        itemCount: notions.length,
        separatorBuilder: (_, __) => const Divider(),
        itemBuilder: (context, index) {
          final item = notions[index];
          return ListTile(
            leading: const Icon(Icons.announcement),
            title: Text(item['header'] ?? '-'),
            subtitle: Text(item['description'] ?? ''),
          );
        },
      ),
    );
  }
}
