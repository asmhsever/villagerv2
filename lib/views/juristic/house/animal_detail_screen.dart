// lib/views/juristic/house/animal_detail_screen.dart

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'edit_animal_screen.dart';
import 'animal_model.dart';

class AnimalDetailScreen extends StatefulWidget {
  final Animal animal;
  final int? houseId;

  const AnimalDetailScreen({super.key, required this.animal, this.houseId});

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
    final id = widget.animal.animalId;
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
    final actualHouseId = widget.houseId ?? widget.animal.houseId;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditAnimalScreen(animal: widget.animal, houseId: actualHouseId),
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
    if (confirm != true) return;

    await Supabase.instance.client
        .from('animal')
        .delete()
        .eq('animal_id', widget.animal.animalId);

    if (context.mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('รายละเอียดสัตว์เลี้ยง'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _editAnimal(context),
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _deleteAnimal(context),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ชื่อ: \${widget.animal.name ?? "-"}'),
            const SizedBox(height: 8),
            Text('ประเภท: \${widget.animal.type ?? "-"}'),
            const SizedBox(height: 16),
            loadingImage
                ? const CircularProgressIndicator()
                : imageBytes != null
                ? Image.memory(imageBytes!, height: 200)
                : const Text('ไม่พบรูปภาพ'),
          ],
        ),
      ),
    );
  }
}
