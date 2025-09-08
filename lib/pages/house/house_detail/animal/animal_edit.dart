import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fullproject/services/image_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'package:fullproject/domains/animal_domain.dart';
import 'package:fullproject/models/animal_model.dart';
import 'package:fullproject/theme/Color.dart';

class HouseEditAnimalPage extends StatefulWidget {
  final int animalId;

  const HouseEditAnimalPage({super.key, required this.animalId});

  @override
  State<HouseEditAnimalPage> createState() => _HouseEditAnimalPageState();
}

class _HouseEditAnimalPageState extends State<HouseEditAnimalPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _typeController = TextEditingController();

  // Image - Updated variables
  File? _selectedImageFile;
  Uint8List? _selectedImageBytes;
  bool _removeImage = false;
  bool _isLoading = false;
  bool _isLoadingData = true;
  String? _selectedStatus; // เพิ่มตัวแปรสำหรับสถานะ
  AnimalModel? _animal;

  final ImagePicker _picker = ImagePicker();

  // เพิ่มรายการสถานะ
  final List<Map<String, dynamic>> animalStatuses = [
    {
      'status': 'active',
      'label': 'มีชีวิต',
      'icon': Icons.favorite,
      'color': ThemeColors.oliveGreen,
      'description': 'สัตว์เลี้ยงมีสุขภาพดี',
    },
    {
      'status': 'inactive',
      'label': 'ไม่ได้ดูแล',
      'icon': Icons.pause_circle,
      'color': ThemeColors.burntOrange,
      'description': 'ชั่วคราวไม่ได้ดูแล',
    },
    {
      'status': 'dead',
      'label': 'เสียชีวิต',
      'icon': Icons.sentiment_very_dissatisfied,
      'color': ThemeColors.clayOrange,
      'description': 'สัตว์เลี้ยงเสียชีวิตแล้ว',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadAnimalData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _typeController.dispose();
    super.dispose();
  }

  // โหลดข้อมูลสัตว์เลี้ยงจาก animalId
  Future<void> _loadAnimalData() async {
    try {
      setState(() {
        _isLoadingData = true;
      });

      final animal = await AnimalDomain.getById(animalId: widget.animalId);

      if (animal != null && mounted) {
        setState(() {
          _animal = animal;
          _nameController.text = animal.name?.toString() ?? '';
          _typeController.text = animal.type?.toString() ?? '';
          _selectedStatus = animal.status ?? 'active'; // โหลดสถานะ
          _isLoadingData = false;
        });
      } else {
        if (mounted) {
          setState(() {
            _isLoadingData = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('ไม่พบข้อมูลสัตว์เลี้ยงที่ต้องการแก้ไข'),
              backgroundColor: ThemeColors.clayOrange,
            ),
          );
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingData = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาดในการโหลดข้อมูล: $e'),
            backgroundColor: ThemeColors.clayOrange,
          ),
        );
        Navigator.of(context).pop();
      }
    }
  }

  // Updated Image Functions
  bool _hasSelectedImage() {
    return (kIsWeb && _selectedImageBytes != null) ||
        (!kIsWeb && _selectedImageFile != null);
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (image != null) {
        if (kIsWeb) {
          final bytes = await image.readAsBytes();
          setState(() {
            _selectedImageBytes = bytes;
            _selectedImageFile = null;
            _removeImage = false;
          });
        } else {
          setState(() {
            _selectedImageFile = File(image.path);
            _selectedImageBytes = null;
            _removeImage = false;
          });
        }
      }
    } catch (e) {
      _showErrorSnackBar('เกิดข้อผิดพลาดในการเลือกรูปภาพ: $e');
    }
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (image != null) {
        if (kIsWeb) {
          final bytes = await image.readAsBytes();
          setState(() {
            _selectedImageBytes = bytes;
            _selectedImageFile = null;
            _removeImage = false;
          });
        } else {
          setState(() {
            _selectedImageFile = File(image.path);
            _selectedImageBytes = null;
            _removeImage = false;
          });
        }
      }
    } catch (e) {
      _showErrorSnackBar('เกิดข้อผิดพลาดในการถ่ายภาพ: $e');
    }
  }

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: ThemeColors.ivoryWhite,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'เลือกรูปภาพ',
            style: TextStyle(
              color: ThemeColors.softBrown,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: ThemeColors.oliveGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.photo_library_rounded,
                    color: ThemeColors.oliveGreen,
                  ),
                ),
                title: Text(
                  'เลือกจากแกลเลอรี่',
                  style: TextStyle(color: ThemeColors.earthClay),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage();
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: ThemeColors.burntOrange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.camera_alt_rounded,
                    color: ThemeColors.burntOrange,
                  ),
                ),
                title: Text(
                  'ถ่ายภาพ',
                  style: TextStyle(color: ThemeColors.earthClay),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromCamera();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // ลบรูปภาพ
  void _removeImageAction() {
    setState(() {
      _selectedImageFile = null;
      _selectedImageBytes = null;
      _removeImage = true;
    });
  }

  // บันทึกข้อมูล - เพิ่มส่ง status
  Future<void> _saveAnimal() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // ตรวจสอบสถานะ
    if (_selectedStatus == null) {
      _showErrorSnackBar('กรุณาเลือกสถานะสัตว์เลี้ยง');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      dynamic imageFile;

      // เตรียม imageFile สำหรับส่งไปยัง function
      if (_hasSelectedImage()) {
        if (kIsWeb && _selectedImageBytes != null) {
          imageFile = _selectedImageBytes!;
        } else if (!kIsWeb && _selectedImageFile != null) {
          imageFile = _selectedImageFile!;
        }
      }

      await AnimalDomain.update(
        animalId: widget.animalId,
        type: _typeController.text.trim(),
        name: _nameController.text.trim(),
        status: _selectedStatus!,
        // เพิ่มส่งสถานะ
        imageFile: imageFile,
        removeImage: _removeImage,
      );

      if (mounted) {
        _showSuccessSnackBar('บันทึกข้อมูลสำเร็จ');
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('เกิดข้อผิดพลาด: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // เพิ่ม method สำหรับ build status section
  Widget _buildStatusSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ThemeColors.ivoryWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ThemeColors.sandyTan, width: 1),
        boxShadow: [
          BoxShadow(
            color: ThemeColors.warmStone.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'สถานะสัตว์เลี้ยง',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: ThemeColors.softBrown,
            ),
          ),
          const SizedBox(height: 16),

          // แสดงสถานะเป็น Radio Tiles
          Column(
            children: animalStatuses.map((status) {
              final isSelected = _selectedStatus == status['status'];

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? status['color'].withOpacity(0.1)
                      : ThemeColors.beige.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? status['color'] : ThemeColors.sandyTan,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: RadioListTile<String>(
                  value: status['status'],
                  groupValue: _selectedStatus,
                  onChanged: (value) {
                    setState(() {
                      _selectedStatus = value;
                    });
                  },
                  title: Row(
                    children: [
                      Icon(
                        status['icon'],
                        color: isSelected
                            ? status['color']
                            : ThemeColors.warmStone,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        status['label'],
                        style: TextStyle(
                          color: isSelected
                              ? status['color']
                              : ThemeColors.earthClay,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  subtitle: Text(
                    status['description'],
                    style: TextStyle(
                      color: ThemeColors.warmStone,
                      fontSize: 12,
                    ),
                  ),
                  activeColor: status['color'],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            }).toList(),
          ),

          if (_selectedStatus == null) ...[
            const SizedBox(height: 8),
            Text(
              'กรุณาเลือกสถานะสัตว์เลี้ยง',
              style: TextStyle(color: Colors.red[700], fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // แสดง loading ระหว่างโหลดข้อมูล
    if (_isLoadingData) {
      return Scaffold(
        backgroundColor: ThemeColors.ivoryWhite,
        appBar: AppBar(
          backgroundColor: ThemeColors.softBrown,
          foregroundColor: ThemeColors.ivoryWhite,
          title: const Text(
            'แก้ไขข้อมูลสัตว์เลี้ยง',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: ThemeColors.ivoryWhite,
            ),
          ),
          elevation: 0,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  ThemeColors.softBrown,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'กำลังโหลดข้อมูลสัตว์เลี้ยง...',
                style: TextStyle(color: ThemeColors.earthClay, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    // แสดงข้อผิดพลาดหากไม่มีข้อมูล
    if (_animal == null) {
      return Scaffold(
        backgroundColor: ThemeColors.ivoryWhite,
        appBar: AppBar(
          backgroundColor: ThemeColors.softBrown,
          foregroundColor: ThemeColors.ivoryWhite,
          title: const Text(
            'แก้ไขข้อมูลสัตว์เลี้ยง',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: ThemeColors.ivoryWhite,
            ),
          ),
          elevation: 0,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                color: ThemeColors.clayOrange,
                size: 64,
              ),
              SizedBox(height: 16),
              Text(
                'ไม่พบข้อมูลสัตว์เลี้ยงที่ต้องการแก้ไข',
                style: TextStyle(
                  color: ThemeColors.clayOrange,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: ThemeColors.ivoryWhite,
      appBar: AppBar(
        backgroundColor: ThemeColors.softBrown,
        foregroundColor: ThemeColors.ivoryWhite,
        title: Text(
          'แก้ไขข้อมูล ${_animal!.name}',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: ThemeColors.ivoryWhite,
          ),
        ),
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_ios),
        ),
        actions: [
          // Save Button
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: IconButton(
              onPressed: _isLoading ? null : _saveAnimal,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          ThemeColors.ivoryWhite,
                        ),
                      ),
                    )
                  : const Icon(Icons.save),
              tooltip: 'บันทึก',
              style: IconButton.styleFrom(
                backgroundColor: ThemeColors.oliveGreen,
                foregroundColor: ThemeColors.ivoryWhite,
                shape: const CircleBorder(),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: ThemeColors.beige,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: ThemeColors.sandyTan, width: 1),
                ),
                child: Row(
                  children: [
                    Icon(Icons.edit, color: ThemeColors.softBrown, size: 28),
                    const SizedBox(width: 12),
                    const Text(
                      'แก้ไขข้อมูลสัตว์เลี้ยง',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: ThemeColors.softBrown,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: ThemeColors.warmStone,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'ID: ${_animal!.animalId}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: ThemeColors.ivoryWhite,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Animal Name Field
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: ThemeColors.ivoryWhite,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: ThemeColors.sandyTan, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: ThemeColors.warmStone.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ชื่อสัตว์เลี้ยง',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: ThemeColors.softBrown,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _nameController,
                      style: const TextStyle(
                        color: ThemeColors.softBrown,
                        fontSize: 16,
                      ),
                      decoration: InputDecoration(
                        hintText: 'กรอกชื่อสัตว์เลี้ยง',
                        hintStyle: TextStyle(color: ThemeColors.warmStone),
                        filled: true,
                        fillColor: ThemeColors.inputFill,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: ThemeColors.softBorder,
                            width: 1,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: ThemeColors.softBorder,
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: ThemeColors.focusedBrown,
                            width: 2,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Colors.red,
                            width: 1,
                          ),
                        ),
                        prefixIcon: Icon(
                          Icons.pets,
                          color: ThemeColors.warmStone,
                        ),
                        contentPadding: const EdgeInsets.all(16),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'กรุณากรอกชื่อสัตว์เลี้ยง';
                        }
                        if (value.trim().length < 2) {
                          return 'ชื่อต้องมีอย่างน้อย 2 ตัวอักษร';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Animal Type Field
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: ThemeColors.ivoryWhite,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: ThemeColors.sandyTan, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: ThemeColors.warmStone.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ประเภทสัตว์เลี้ยง',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: ThemeColors.softBrown,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _typeController,
                      style: const TextStyle(
                        color: ThemeColors.softBrown,
                        fontSize: 16,
                      ),
                      decoration: InputDecoration(
                        hintText: 'กรอกประเภทสัตว์เลี้ยง (เช่น สุนัข, แมว, นก)',
                        hintStyle: TextStyle(color: ThemeColors.warmStone),
                        filled: true,
                        fillColor: ThemeColors.inputFill,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: ThemeColors.softBorder,
                            width: 1,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: ThemeColors.softBorder,
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: ThemeColors.focusedBrown,
                            width: 2,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Colors.red,
                            width: 1,
                          ),
                        ),
                        prefixIcon: Icon(
                          Icons.category_rounded,
                          color: ThemeColors.warmStone,
                        ),
                        contentPadding: const EdgeInsets.all(16),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'กรุณากรอกประเภทสัตว์เลี้ยง';
                        }
                        if (value.trim().length < 2) {
                          return 'ประเภทต้องมีอย่างน้อย 2 ตัวอักษร';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Status Section - เพิ่มใหม่
              _buildStatusSection(),

              const SizedBox(height: 24),

              // Image Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: ThemeColors.ivoryWhite,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: ThemeColors.sandyTan, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: ThemeColors.warmStone.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      'รูปภาพสัตว์เลี้ยง',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: ThemeColors.softBrown,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Image Display
                    Container(
                      width: double.infinity,
                      height: 200,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: ThemeColors.sandyTan,
                          width: 2,
                        ),
                      ),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: _hasSelectedImage()
                                ? _buildImagePreview()
                                : BuildImage(
                                    imagePath: _animal!.img!,
                                    tablePath: "animal",
                                  ),
                          ),
                          Positioned(
                            top: 8,
                            left: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _hasSelectedImage()
                                    ? ThemeColors.oliveGreen
                                    : ThemeColors.burntOrange,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _hasSelectedImage() ? 'รูปใหม่' : 'รูปเดิม',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 8,
                            left: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: TextButton.icon(
                                onPressed: _showImageSourceDialog,
                                icon: const Icon(
                                  Icons.edit_rounded,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                label: const Text(
                                  'เปลี่ยนรูปภาพ',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Image Action Button
                    ElevatedButton.icon(
                      onPressed: _removeImageAction,
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: const Text('ลบรูป'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ThemeColors.clayOrange,
                        foregroundColor: ThemeColors.ivoryWhite,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Save Button (Bottom)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveAnimal,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ThemeColors.oliveGreen,
                    foregroundColor: ThemeColors.ivoryWhite,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    elevation: 3,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              ThemeColors.ivoryWhite,
                            ),
                          ),
                        )
                      : const Text(
                          'บันทึกการแก้ไข',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    if (kIsWeb && _selectedImageBytes != null) {
      return Image.memory(
        _selectedImageBytes!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    } else if (!kIsWeb && _selectedImageFile != null) {
      return Image.file(
        _selectedImageFile!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    }
    return Container();
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 12),
            Text(message),
          ],
        ),
        backgroundColor: ThemeColors.oliveGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
