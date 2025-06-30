// 📁 lib/views/juristic/house/animal_detail_screen.dart

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'edit_animal_screen.dart';

class AnimalDetailScreen extends StatefulWidget {
  final Map<String, dynamic>? animal;
  final int? houseId;

  const AnimalDetailScreen({super.key, this.animal, this.houseId});

  @override
  State<AnimalDetailScreen> createState() => _AnimalDetailScreenState();
}

class _AnimalDetailScreenState extends State<AnimalDetailScreen> {
  Uint8List? imageBytes;
  bool loadingImage = true;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    final id = widget.animal?['animal_id'];
    if (id == null) return;
    final formats = ['jpg', 'png', 'webp'];
    for (final ext in formats) {
      final url = 'https://asmhsevers.supabase.co/storage/v1/object/public/animal-images/$id.$ext';
      try {
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          setState(() {
            imageBytes = response.bodyBytes;
            loadingImage = false;
          });
          return;
        }
      } catch (_) {}
    }
    setState(() => loadingImage = false);
  }

  void _editAnimal(BuildContext context) {
    final actualHouseId = widget.houseId ?? widget.animal?['house_id'] as int;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditAnimalScreen(animal: widget.animal!, houseId: actualHouseId),
      ),
    );
  }

  Future<void> _deleteAnimal(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('ลบสัตว์เลี้ยง'),
        content: const Text('คุณต้องการลบสัตว์เลี้ยงนี้ใช่หรือไม่?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('ยกเลิก')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('ลบ')),
        ],
      ),
    );

    if (confirm == true && widget.animal != null) {
      final client = Supabase.instance.client;
      await client.from('animal').delete().eq('animal_id', widget.animal!['animal_id']);
      if (context.mounted) Navigator.pop(context);
    }
  }

  void _showFullImage() {
    if (imageBytes == null) return;
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: InteractiveViewer(
            child: Image.memory(imageBytes!),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.animal == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('สัตว์เลี้ยง')),
        body: const Center(child: Text('ไม่พบข้อมูลสัตว์เลี้ยง')),
      );
    }

    final animal = widget.animal!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('รายละเอียดสัตว์เลี้ยง'),
        actions: [
          IconButton(icon: const Icon(Icons.edit), onPressed: () => _editAnimal(context)),
          IconButton(icon: const Icon(Icons.delete), onPressed: () => _deleteAnimal(context)),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (loadingImage)
              const Center(child: CircularProgressIndicator())
            else if (imageBytes != null)
              Center(
                child: GestureDetector(
                  onTap: _showFullImage,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(
                      imageBytes!,
                      width: 150,
                      height: 150,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              )
            else
              const Center(child: Icon(Icons.pets, size: 100)),

            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerLeft,
              child: Text('ชื่อ: ${animal['name'] ?? '-'}', style: const TextStyle(fontSize: 18)),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text('ประเภท: ${animal['type'] ?? '-'}', style: const TextStyle(fontSize: 18)),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text('บ้านเลขที่: ${animal['house_id'] ?? '-'}', style: const TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}