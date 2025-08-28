import 'package:flutter/material.dart';
import 'package:fullproject/theme/Color.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:fullproject/domains/notion_domain.dart';
import 'package:fullproject/models/law_model.dart';
import 'package:fullproject/services/auth_service.dart';

class LawNotionAddPage extends StatefulWidget {
  const LawNotionAddPage({super.key});

  @override
  State<LawNotionAddPage> createState() => _LawNotionAddPageState();
}

class _LawNotionAddPageState extends State<LawNotionAddPage> {
  final _formKey = GlobalKey<FormState>();
  final _headerController = TextEditingController();
  final _descController = TextEditingController();
  bool _isSaving = false;
  String _selectedType = 'GENERAL';

  // Image handling
  File? _selectedImageFile;
  Uint8List? _selectedImageBytes;
  final ImagePicker _picker = ImagePicker();

  // Map สำหรับแสดงชื่อ type เป็นภาษาไทย
  final Map<String, String> _typeLabels = {
    'GENERAL': 'ข้อมูลทั่วไป',
    'MAINTENANCE': 'ซ่อมบำรุง',
    'SECURITY': 'ความปลอดภัย',
    'SOCIAL': 'กิจกรรมสังคม',
  };

  // Map สำหรับสี type
  final Map<String, Color> _typeColors = {
    'GENERAL': ThemeColors.warmStone,
    'MAINTENANCE': ThemeColors.oliveGreen,
    'SECURITY': ThemeColors.clayOrange,
    'SOCIAL': ThemeColors.softTerracotta,
  };

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        if (kIsWeb) {
          // สำหรับ Web ใช้ bytes
          final bytes = await image.readAsBytes();
          setState(() {
            _selectedImageBytes = bytes;
            _selectedImageFile = null;
          });
        } else {
          // สำหรับ Mobile ใช้ File
          setState(() {
            _selectedImageFile = File(image.path);
            _selectedImageBytes = null;
          });
        }
      }
    } catch (e) {
      print('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ไม่สามารถเลือกรูปภาพได้: $e'),
            backgroundColor: ThemeColors.clayOrange,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImageFile = null;
      _selectedImageBytes = null;
    });
  }

  Widget _buildImageSection() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: ThemeColors.ivoryWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ThemeColors.sandyTan, width: 1),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.image_outlined,
                  color: ThemeColors.softBrown,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'รูปภาพประกอบ',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: ThemeColors.softBrown,
                  ),
                ),
                const Spacer(),
                if (_selectedImageFile != null || _selectedImageBytes != null)
                  TextButton.icon(
                    onPressed: _removeImage,
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('ลบ'),
                    style: TextButton.styleFrom(
                      foregroundColor: ThemeColors.clayOrange,
                    ),
                  ),
              ],
            ),
          ),

          if (_selectedImageFile != null || _selectedImageBytes != null) ...[
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0x1A000000),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: kIsWeb && _selectedImageBytes != null
                    ? Image.memory(_selectedImageBytes!, fit: BoxFit.cover)
                    : _selectedImageFile != null
                    ? Image.file(_selectedImageFile!, fit: BoxFit.cover)
                    : const SizedBox.shrink(),
              ),
            ),
            const SizedBox(height: 16),
          ] else ...[
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              height: 120,
              child: Material(
                color: ThemeColors.beige,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: _pickImage,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: ThemeColors.sandyTan,
                        style: BorderStyle.solid,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_photo_alternate_outlined,
                          size: 32,
                          color: ThemeColors.earthClay,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'แตะเพื่อเลือกรูปภาพ',
                          style: TextStyle(
                            color: ThemeColors.earthClay,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Container(
      decoration: BoxDecoration(
        color: ThemeColors.ivoryWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ThemeColors.sandyTan, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.category_outlined,
                  color: ThemeColors.softBrown,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'ประเภทข่าวสาร',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: ThemeColors.softBrown,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _typeLabels.entries.map((entry) {
                final isSelected = _selectedType == entry.key;
                final color = _typeColors[entry.key] ?? ThemeColors.earthClay;

                return Material(
                  borderRadius: BorderRadius.circular(20),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      setState(() {
                        _selectedType = entry.key;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? color : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: color, width: 2),
                      ),
                      child: Text(
                        entry.value,
                        style: TextStyle(
                          color: isSelected ? Colors.white : color,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (_isSaving || !_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final user = await AuthService.getCurrentUser();
      if (user is! LawModel) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('ไม่สามารถระบุผู้ใช้ได้'),
            backgroundColor: ThemeColors.clayOrange,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
        return;
      }

      // เตรียม image file สำหรับอัปโหลด
      dynamic imageFile;
      if (kIsWeb && _selectedImageBytes != null) {
        imageFile = _selectedImageBytes;
      } else if (_selectedImageFile != null) {
        imageFile = _selectedImageFile;
      }

      final createNotion = await NotionDomain.create(
        lawId: user.lawId,
        villageId: user.villageId,
        header: _headerController.text.trim(),
        description: _descController.text.trim(),
        type: _selectedType,
        imageFile: imageFile,
      );

      if (createNotion == null) {
        throw Exception('ไม่สามารถเพิ่มข่าวสารได้');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('เพิ่มข่าวสารเรียบร้อยแล้ว'),
            backgroundColor: ThemeColors.oliveGreen,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      print("error add notion $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'ไม่สามารถเพิ่มข่าวสารได้ กรุณาลองใหม่อีกครั้ง',
            ),
            backgroundColor: ThemeColors.clayOrange,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        primarySwatch: MaterialColor(0xFFA47551, const {
          50: Color(0xFFF5F2EF),
          100: Color(0xFFE5DDD6),
          200: Color(0xFFD4C5BB),
          300: Color(0xFFC2ADA0),
          400: Color(0xFFB5998B),
          500: ThemeColors.softBrown,
          600: Color(0xFF9C6D4A),
          700: Color(0xFF926240),
          800: Color(0xFF885837),
          900: Color(0xFF764627),
        }),
        scaffoldBackgroundColor: ThemeColors.ivoryWhite,
        appBarTheme: const AppBarTheme(
          backgroundColor: ThemeColors.softBrown,
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: ThemeColors.earthClay,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: ThemeColors.inputFill,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: ThemeColors.softBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: ThemeColors.softBorder),
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
              color: ThemeColors.clayOrange,
              width: 2,
            ),
          ),
          labelStyle: const TextStyle(color: ThemeColors.earthClay),
          hintStyle: const TextStyle(color: ThemeColors.earthClay),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: ThemeColors.burntOrange,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 3,
          ),
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'เพิ่มข่าวสาร',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          centerTitle: true,
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [ThemeColors.ivoryWhite, ThemeColors.beige],
            ),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // หัวข้อข่าว
                  Text(
                    'หัวข้อข่าวสาร',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: ThemeColors.softBrown,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _headerController,
                    decoration: const InputDecoration(
                      hintText: 'กรอกหัวข้อข่าวสาร...',
                      prefixIcon: Icon(
                        Icons.title,
                        color: ThemeColors.earthClay,
                      ),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'กรุณากรอกหัวข้อข่าว'
                        : null,
                  ),
                  const SizedBox(height: 24),

                  // ประเภทข่าวสาร
                  _buildTypeSelector(),
                  const SizedBox(height: 24),

                  // รูปภาพประกอบ
                  _buildImageSection(),
                  const SizedBox(height: 24),

                  // เนื้อหาข่าว
                  Text(
                    'เนื้อหาข่าวสาร',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: ThemeColors.softBrown,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _descController,
                    maxLines: 6,
                    decoration: const InputDecoration(
                      hintText: 'กรอกรายละเอียดข่าวสาร...',
                      alignLabelWithHint: true,
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'กรุณากรอกรายละเอียดข่าว'
                        : null,
                  ),
                  const SizedBox(height: 32),

                  // ปุ่มบันทึก
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _submit,
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.save, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'บันทึกข่าวสาร',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _headerController.dispose();
    _descController.dispose();
    super.dispose();
  }
}
