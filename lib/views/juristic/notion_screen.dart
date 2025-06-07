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
        .eq('law_id', lawId)
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
          ? const Center(child: Text('ไม่มีประกาศ'))
          : ListView.builder(
        itemCount: notions.length,
        itemBuilder: (context, index) {
          final item = notions[index];
          return ListTile(
            title: Text(item['header'] ?? '-'),
            subtitle: Text(item['description'] ?? ''),
          );
        },
      ),
    );
  }
}
