import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:fullproject/config/supabase_config.dart';

class SupabaseImage {
  static final _client = SupabaseConfig.client;

  //upload to database and bucket
  Future<String?> uploadImage(
    File imageFile,
    String tableName,
    String rowName,
    dynamic rowKey,
  ) async {
    try {
      final filePath = '$tableName/$tableName' + '_' + '$rowKey.jpg';

      // เช็คและลบไฟล์เก่า (ถ้ามี)
      try {
        final oldFile = await _client
            .from(tableName)
            .select('img') // เปลี่ยนเป็น 'img'
            .eq(rowName, rowKey)
            .maybeSingle();

        if (oldFile != null && oldFile['img'] != null) {
          // เปลี่ยนเป็น 'img'
          await _client.storage.from('images').remove([
            oldFile['img'],
          ]); // ใช้ bucket 'images'
          print('Old file deleted: ${oldFile['img']}');
        }
      } catch (e) {
        print('Error deleting old file: $e');
      }

      // file to bucket
      await _client.storage
          .from('images')
          .upload(filePath, imageFile); // ใช้ bucket 'images'

      // file to database
      await _client // ใช้ _client แทน Supabase.instance.client
          .from(tableName)
          .upsert({
            rowName: rowKey, // primary key
            'img': filePath, // image path
          });

      return filePath;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  Future<String> getImageUrl(String imagePath, String tablePath) async {
    print('imagePath: $imagePath, bucketPath: $tablePath');
    final String path = tablePath + '/' + imagePath;
    final url = _client.storage
        .from('images') // ใช้ parameter
        .getPublicUrl(path); // ใช้ parameter

    print('Generated URL: $url');
    return url;
  }
}

class BuildImage extends StatefulWidget {
  final String imagePath;
  final String tablePath;

  const BuildImage({
    super.key,
    required this.imagePath,
    required this.tablePath,
  });

  @override
  State<BuildImage> createState() => _BuildImageState();
}

class _BuildImageState extends State<BuildImage> {
  final SupabaseImage supabaseImage = SupabaseImage(); // สร้าง instance
  String? imageUrl;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    loadImage();
  }

  Future<void> loadImage() async {
    print('loadImage() called');
    print('imagePath: ${widget.imagePath}');
    print('tablePath: ${widget.tablePath}');

    try {
      final url = await supabaseImage.getImageUrl(
        widget.imagePath,
        widget.tablePath,
      ); // เรียกใช้ method
      print('Got URL: $url');

      if (mounted) {
        setState(() {
          imageUrl = url;
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading image: $e');
      if (mounted) {
        setState(() {
          errorMessage = e.toString();
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, color: Colors.red),
            Text('Error: $errorMessage'),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  isLoading = true;
                  errorMessage = null;
                });
                loadImage();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (imageUrl != null) {
      return Image.network(
        imageUrl!,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const Center(child: CircularProgressIndicator());
        },
        errorBuilder: (context, error, stackTrace) {
          print('Image network error: $error');
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.broken_image, color: Colors.grey, size: 50),
                Text('Failed to load image'),
              ],
            ),
          );
        },
      );
    }

    return const Center(child: Text('No image available'));
  }
}
