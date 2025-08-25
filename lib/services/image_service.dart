import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fullproject/config/supabase_config.dart';
import 'package:image/image.dart' as img;
import 'dart:typed_data';
import 'dart:io';

class SupabaseImage {
  static final _client = SupabaseConfig.client;

  /// Resize and convert image to WebP format
  Future<Uint8List?> _processImage({
    required dynamic imageFile,
    int maxWidth = 800,
    int maxHeight = 600,
    int quality = 85,
  }) async {
    try {
      Uint8List imageBytes;

      // Handle different input types
      if (imageFile is File) {
        imageBytes = await imageFile.readAsBytes();
      } else if (imageFile is Uint8List) {
        imageBytes = imageFile;
      } else {
        print('Unsupported image file type');
        return null;
      }

      // Decode the image
      img.Image? originalImage = img.decodeImage(imageBytes);
      if (originalImage == null) {
        print('Failed to decode image');
        return null;
      }

      // Calculate new dimensions while maintaining aspect ratio
      int newWidth = originalImage.width;
      int newHeight = originalImage.height;

      if (newWidth > maxWidth || newHeight > maxHeight) {
        double aspectRatio = newWidth / newHeight;

        if (aspectRatio > 1) {
          // Landscape
          newWidth = maxWidth;
          newHeight = (maxWidth / aspectRatio).round();
        } else {
          // Portrait or square
          newHeight = maxHeight;
          newWidth = (maxHeight * aspectRatio).round();
        }
      }

      // Resize the image
      img.Image resizedImage = img.copyResize(
        originalImage,
        width: newWidth,
        height: newHeight,
        interpolation: img.Interpolation.cubic,
      );

      // Convert to JPEG format with specified quality (WebP alternative)
      Uint8List processedBytes = img.encodeJpg(resizedImage, quality: quality);

      print('Original size: ${imageBytes.length} bytes');
      print('Processed size: ${processedBytes.length} bytes');
      print(
        'Compression ratio: ${(processedBytes.length / imageBytes.length * 100).toStringAsFixed(1)}%',
      );

      return processedBytes;
    } catch (e) {
      print('Error processing image: $e');
      return null;
    }
  }

  //delete
  Future<bool> deleteImage({
    required String bucketPath,
    required String imageUrl,
  }) async {
    try {
      // ลบไฟล์จาก storage bucket
      final response = await _client.storage.from('images').remove([imageUrl]);

      print('Image deleted from bucket: $imageUrl');
      return true;
    } catch (e) {
      print('Error deleting image from bucket: $e');
      return false;
    }
  }

  /// Upload processed image to database and bucket

  Future<String?> uploadImage({
    dynamic imageFile,
    required String tableName,
    required String bucketPath,
    required String imgName,
    required String rowName,
    required String rowImgName,

    dynamic rowKey,
    int maxWidth = 800,
    int maxHeight = 600,
    int quality = 85,
  }) async {
    try {
      // Process the image (resize and convert to WebP)
      final processedImageBytes = await _processImage(
        imageFile: imageFile,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        quality: quality,
      );

      if (processedImageBytes == null) {
        print('Failed to process image');
        return null;
      }

      final filePath = '$bucketPath/${imgName}_$rowKey.jpg';

      // Check and delete old file if exists
      try {
        final oldFile = await _client
            .from(tableName)
            .select(rowImgName)
            .eq(rowName, rowKey)
            .maybeSingle();

        if (oldFile != null && oldFile[rowImgName] != null) {
          await _client.storage.from('images').remove([oldFile[rowImgName]]);
          print('Old file deleted: ${oldFile[rowImgName]}');
        }
      } catch (e) {
        print('Error deleting old file: $e');
      }

      // Upload processed image to bucket
      await _client.storage
          .from('images')
          .uploadBinary(filePath, processedImageBytes);

      return "${imgName}_${rowKey}.jpg";
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  /// Upload image with custom processing options
  Future<String?> uploadImageWithOptions({
    dynamic imageFile,
    required String tableName,
    required String rowName,
    required String rowImgName,
    required String imgName,
    required String bucketPath,
    dynamic rowKey,
    ImageProcessingOptions? options,
  }) async {
    final opts = options ?? ImageProcessingOptions();

    return uploadImage(
      imageFile: imageFile,
      tableName: tableName,
      rowName: rowName,
      rowImgName: rowImgName,
      rowKey: rowKey,
      bucketPath: bucketPath,
      imgName: imgName,
      maxWidth: opts.maxWidth,
      maxHeight: opts.maxHeight,
      quality: opts.quality,
    );
  }

  /// Get image URL from storage
  Future<String> getImageUrl(String imagePath, String tablePath) async {
    final String path = '$tablePath/$imagePath';
    final url = _client.storage.from('images').getPublicUrl(path);

    return url;
  }

  /// Create thumbnail version of image
  Future<String?> uploadThumbnail({
    dynamic imageFile,
    required String tableName,
    required String rowName,
    required String rowImgName,
    dynamic rowKey,
    int thumbnailSize = 150,
    int quality = 70,
  }) async {
    try {
      final processedImageBytes = await _processImage(
        imageFile: imageFile,
        maxWidth: thumbnailSize,
        maxHeight: thumbnailSize,
        quality: quality,
      );

      if (processedImageBytes == null) {
        return null;
      }

      final filePath = '$tableName/thumbnails/${tableName}_${rowKey}_thumb.jpg';

      await _client.storage
          .from('images')
          .uploadBinary(filePath, processedImageBytes);

      return "${tableName}_${rowKey}_thumb.jpg";
    } catch (e) {
      print('Error uploading thumbnail: $e');
      return null;
    }
  }
}

/// Configuration class for image processing options
class ImageProcessingOptions {
  final int maxWidth;
  final int maxHeight;
  final int quality;

  const ImageProcessingOptions({
    this.maxWidth = 800,
    this.maxHeight = 600,
    this.quality = 85,
  });

  // Predefined options
  static const ImageProcessingOptions thumbnail = ImageProcessingOptions(
    maxWidth: 150,
    maxHeight: 150,
    quality: 70,
  );

  static const ImageProcessingOptions medium = ImageProcessingOptions(
    maxWidth: 600,
    maxHeight: 400,
    quality: 80,
  );

  static const ImageProcessingOptions large = ImageProcessingOptions(
    maxWidth: 1200,
    maxHeight: 800,
    quality: 85,
  );

  static const ImageProcessingOptions highQuality = ImageProcessingOptions(
    maxWidth: 1920,
    maxHeight: 1080,
    quality: 95,
  );
}

class BuildImage extends StatefulWidget {
  final String imagePath;
  final String tablePath;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget? placeholder;
  final Widget? errorWidget;

  const BuildImage({
    super.key,
    required this.imagePath,
    required this.tablePath,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.placeholder,
    this.errorWidget,
  });

  @override
  State<BuildImage> createState() => _BuildImageState();
}

class _BuildImageState extends State<BuildImage> {
  final SupabaseImage supabaseImage = SupabaseImage();
  String? imageUrl;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    loadImage();
  }

  @override
  void didUpdateWidget(BuildImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imagePath != widget.imagePath ||
        oldWidget.tablePath != widget.tablePath) {
      loadImage();
    }
  }

  Future<void> loadImage() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final url = await supabaseImage.getImageUrl(
        widget.imagePath,
        widget.tablePath,
      );

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
      return widget.placeholder ??
          const Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null) {
      return widget.errorWidget ??
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, color: Colors.red),
                Text('Error: $errorMessage'),
                ElevatedButton(
                  onPressed: loadImage,
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
    }

    if (imageUrl != null) {
      return Image.network(
        imageUrl!,
        fit: widget.fit,
        width: widget.width,
        height: widget.height,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return widget.placeholder ??
              const Center(child: CircularProgressIndicator());
        },
        errorBuilder: (context, error, stackTrace) {
          print('Image network error: $error');
          return widget.errorWidget ??
              const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.broken_image, color: Colors.grey, size: 20),
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
