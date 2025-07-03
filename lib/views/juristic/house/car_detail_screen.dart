// 📁 lib/views/juristic/house/car_detail_screen.dart

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'edit_car_screen.dart';

class CarDetailScreen extends StatefulWidget {
  final Map<String, dynamic>? car;

  const CarDetailScreen({super.key, this.car});

  @override
  State<CarDetailScreen> createState() => _CarDetailScreenState();
}

class _CarDetailScreenState extends State<CarDetailScreen> {
  Uint8List? imageBytes;
  bool loadingImage = true;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    final id = widget.car?['car_id'];
    if (id == null) return;
    final formats = ['jpg', 'png', 'webp'];
    for (final ext in formats) {
      final url = 'https://asmhsevers.supabase.co/storage/v1/object/public/car-images/$id.$ext';
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

  void _editCar(BuildContext context) {
    if (widget.car == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditCarScreen(car: widget.car!),
      ),
    );
  }

  Future<void> _deleteCar(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('ลบรถ'),
        content: const Text('คุณต้องการลบรถนี้ใช่หรือไม่?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('ยกเลิก')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('ลบ')),
        ],
      ),
    );

    if (confirm == true && widget.car != null) {
      final client = Supabase.instance.client;
      await client.from('car').delete().eq('car_id', widget.car!['car_id']);
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
    if (widget.car == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('รถ')),
        body: const Center(child: Text('ไม่พบข้อมูลรถ')),
      );
    }

    final car = widget.car!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('รายละเอียดรถ'),
        actions: [
          IconButton(icon: const Icon(Icons.edit), onPressed: () => _editCar(context)),
          IconButton(icon: const Icon(Icons.delete), onPressed: () => _deleteCar(context)),
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
              const Center(child: Icon(Icons.directions_car, size: 100)),

            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerLeft,
              child: Text('ยี่ห้อ: ${car['brand'] ?? '-'}', style: const TextStyle(fontSize: 18)),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text('รุ่น: ${car['model'] ?? '-'}', style: const TextStyle(fontSize: 18)),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text('ทะเบียน: ${car['number'] ?? '-'}', style: const TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}
