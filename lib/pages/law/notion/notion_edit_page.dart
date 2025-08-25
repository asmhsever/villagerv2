import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:fullproject/domains/notion_domain.dart';
import 'package:fullproject/models/notion_model.dart';

class LawNotionEditPage extends StatefulWidget {
  final NotionModel notion;

  const LawNotionEditPage({super.key, required this.notion});

  @override
  State<LawNotionEditPage> createState() => _LawNotionEditPageState();
}

class _LawNotionEditPageState extends State<LawNotionEditPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _headerController;
  late TextEditingController _descController;
  bool _isSaving = false;
  late String _selectedType;

  // Image handling
  File? _selectedImageFile;
  Uint8List? _selectedImageBytes;
  bool _removeExistingImage = false;
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
    'GENERAL': Color(0xFFC7B9A5),
    'MAINTENANCE': Color(0xFFA3B18A),
    'SECURITY': Color(0xFFCC7748),
    'SOCIAL': Color(0xFFD48B5C),
  };

  @override
  void initState() {
    super.initState();
    _headerController = TextEditingController(text: widget.notion.header ?? '');
    _descController = TextEditingController(text: widget.notion.description ?? '');
    _selectedType = widget.notion.type ?? 'GENERAL';
  }

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
          final bytes = await image.readAsBytes();
          setState(() {
            _selectedImageBytes = bytes;
            _selectedImageFile = null;
            _removeExistingImage = false;
          });
        } else {
          setState(() {
            _selectedImageFile = File(image.path);
            _selectedImageBytes = null;
            _removeExistingImage = false;
          });
        }
      }
    } catch (e) {
      print('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ไม่สามารถเลือกรูปภาพได้: $e'),
            backgroundColor: const Color(0xFFCC7748),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImageFile = null;
      _selectedImageBytes = null;
      _removeExistingImage = true;
    });
  }

  Widget _buildCurrentImage() {
    // ถ้าเลือกรูปใหม่แล้ว
    if (_selectedImageFile != null || _selectedImageBytes != null) {
      return Container(
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
      );
    }

    // ถ้ามีรูปเดิมและไม่ได้ลบ
    if (widget.notion.img != null &&
        widget.notion.img!.isNotEmpty &&
        !_removeExistingImage) {
      return Container(
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
          child: Image.network(
            widget.notion.img!,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                color: const Color(0xFFF5F0E1),
                child: const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFA47551)),
                    strokeWidth: 2,
                  ),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: const Color(0xFFF5F0E1),
                child: const Center(
                  child: Icon(
                    Icons.broken_image_outlined,
                    color: Color(0xFFBFA18F),
                    size: 32,
                  ),
                ),
              );
            },
          ),
        ),
      );
    }

    // ไม่มีรูป - แสดง placeholder
    return SizedBox(
      height: 120,
      child: Material(
        color: const Color(0xFFF5F0E1),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: _pickImage,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFD8CAB8),
                style: BorderStyle.solid,
                width: 2,
              ),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_photo_alternate_outlined,
                  size: 32,
                  color: Color(0xFFBFA18F),
                ),
                SizedBox(height: 8),
                Text(
                  'แตะเพื่อเลือกรูปภาพ',
                  style: TextStyle(
                    color: Color(0xFFBFA18F),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    bool hasImage = (_selectedImageFile != null ||
        _selectedImageBytes != null ||
        (widget.notion.img != null &&
            widget.notion.img!.isNotEmpty &&
            !_removeExistingImage));

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD8CAB8), width: 1),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.image_outlined,
                  color: const Color(0xFFA47551),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'รูปภาพประกอบ',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFA47551),
                  ),
                ),
                const Spacer(),
                if (hasImage) ...[
                  TextButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('เปลี่ยน'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFA3B18A),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _removeImage,
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('ลบ'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFCC7748),
                    ),
                  ),
                ],
              ],
            ),
          ),

          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: _buildCurrentImage(),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD8CAB8), width: 1),
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
                  color: const Color(0xFFA47551),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'ประเภทข่าวสาร',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFA47551),
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
                final color = _typeColors[entry.key] ?? const Color(0xFFBFA18F);

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
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? color : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: color, width: 2),
                      ),
                      child: Text(
                        entry.value,
                        style: TextStyle(
                          color: isSelected ? Colors.white : color,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
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
      // เตรียม image file สำหรับอัปโหลด
      dynamic imageFile;
      if (kIsWeb && _selectedImageBytes != null) {
        imageFile = _selectedImageBytes;
      } else if (_selectedImageFile != null) {
        imageFile = _selectedImageFile;
      }

      await NotionDomain.update(
        notionId: widget.notion.notionId,
        lawId: widget.notion.lawId,
        villageId: widget.notion.villageId,
        header: _headerController.text.trim(),
        description: _descController.text.trim(),
        type: _selectedType,
        imageFile: imageFile,
        removeImage: _removeExistingImage,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('แก้ไขข่าวสารเรียบร้อยแล้ว'),
            backgroundColor: const Color(0xFFA3B18A),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      print("error can update notion $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('ไม่สามารถแก้ไขข่าวสารได้ กรุณาลองใหม่อีกครั้ง'),
            backgroundColor: const Color(0xFFCC7748),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
          500: Color(0xFFA47551),
          600: Color(0xFF9C6D4A),
          700: Color(0xFF926240),
          800: Color(0xFF885837),
          900: Color(0xFF764627),
        }),
        scaffoldBackgroundColor: const Color(0xFFFFFDF6),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFA47551),
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: Color(0xFFBFA18F),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFFBF9F3),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFD0C4B0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFD0C4B0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF916846), width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFCC7748), width: 2),
          ),
          labelStyle: const TextStyle(color: Color(0xFFBFA18F)),
          hintStyle: const TextStyle(color: Color(0xFFBFA18F)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE08E45),
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
            'แก้ไขข่าวสาร',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          centerTitle: true,
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFFFFDF6),
                Color(0xFFF5F0E1),
              ],
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
                      color: const Color(0xFFA47551),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _headerController,
                    decoration: const InputDecoration(
                      hintText: 'กรอกหัวข้อข่าวสาร...',
                      prefixIcon: Icon(Icons.title, color: Color(0xFFBFA18F)),
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
                      color: const Color(0xFFA47551),
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
                          : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.save, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'บันทึกการแก้ไข',
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