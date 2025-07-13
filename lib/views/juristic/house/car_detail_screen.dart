// lib/views/juristic/house/car_detail_screen.dart

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'edit_car_screen.dart';
import 'car_model.dart';

class CarDetailScreen extends StatefulWidget {
  final Car car;
  final int? houseId;

  const CarDetailScreen({super.key, required this.car, this.houseId});

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
    final id = widget.car.carId;
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
    final actualHouseId = widget.houseId ?? widget.car.houseId;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditCarScreen(car: widget.car, houseId: actualHouseId),
      ),
    );
  }

  Future<void> _deleteCar(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('ลบรถยนต์'),
        content: const Text('คุณต้องการลบรถยนต์นี้ใช่หรือไม่?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('ยกเลิก')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('ลบ')),
        ],
      ),
    );
    if (confirm != true) return;

    await Supabase.instance.client
        .from('car')
        .delete()
        .eq('car_id', widget.car.carId);

    if (context.mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('รายละเอียดรถยนต์'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _editCar(context),
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _deleteCar(context),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ยี่ห้อ: \${widget.car.brand ?? "-"}'),
            const SizedBox(height: 8),
            Text('รุ่น: \${widget.car.model ?? "-"}'),
            const SizedBox(height: 8),
            Text('ทะเบียน: \${widget.car.number ?? "-"}'),
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
