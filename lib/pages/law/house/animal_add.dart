import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:fullproject/domains/animal_domain.dart';
import 'package:fullproject/theme/Color.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class AnimalAddPage extends StatefulWidget {
  final int houseId;

  const AnimalAddPage({super.key, required this.houseId});

  @override
  State<AnimalAddPage> createState() => _AnimalAddPageState();
}

class _AnimalAddPageState extends State<AnimalAddPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _notesController = TextEditingController();

  String? _selectedType;

  // ✨ รองรับทั้ง Web และ Mobile
  File? _selectedImage; // สำหรับ Mobile
  Uint8List? _webImage; // สำหรับ Web
  bool _isSaving = false;
  bool _hasUnsavedChanges = false;

  final List<Map<String, dynamic>> animalTypes = [
    {'type': 'สุนัข', 'icon': Icons.pets, 'color': ThemeColors.softBrown},
    {'type': 'แมว', 'icon': Icons.pets, 'color': ThemeColors.clayOrange},
    {'type': 'นก', 'icon': Icons.flutter_dash, 'color': ThemeColors.oliveGreen},
    {'type': 'ปลา', 'icon': Icons.set_meal, 'color': ThemeColors.warmAmber},
    {
      'type': 'กระต่าย',
      'icon': Icons.cruelty_free,
      'color': ThemeColors.softTerracotta,
    },
    {'type': 'หนู', 'icon': Icons.mouse, 'color': ThemeColors.earthClay},
    {'type': 'อื่นๆ', 'icon': Icons.pets, 'color': ThemeColors.burntOrange},
  ];

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // Listen for changes
    _nameController.addListener(_onFieldChanged);
    _notesController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    if (!_hasUnsavedChanges) {
      setState(() {
        _hasUnsavedChanges = true;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    if (!_hasUnsavedChanges) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: ThemeColors.warmAmber,
              size: 28,
            ),
            const SizedBox(width: 12),
            Text(
              'ยืนยันการออก',
              style: TextStyle(color: ThemeColors.earthClay),
            ),
          ],
        ),
        content: Text(
          'คุณมีการเปลี่ยนแปลงที่ยังไม่ได้บันทึก ต้องการออกหรือไม่?',
          style: TextStyle(color: ThemeColors.earthClay),
        ),
        backgroundColor: ThemeColors.ivoryWhite,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(foregroundColor: ThemeColors.warmStone),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: ThemeColors.clayOrange,
            ),
            child: const Text('ออก'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  Future<void> _pickImage() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: ThemeColors.ivoryWhite,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: ThemeColors.warmStone.withValues(alpha: 0.3),
                spreadRadius: 1,
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: ThemeColors.softBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                Text(
                  'เลือกรูปภาพ',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: ThemeColors.softBrown,
                  ),
                ),

                const SizedBox(height: 20),

                // ✨ แสดงปุ่มถ่ายรูปเฉพาะบน Mobile
                if (!kIsWeb) ...[
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: ThemeColors.oliveGreen.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.photo_camera,
                        color: ThemeColors.oliveGreen,
                      ),
                    ),
                    title: Text(
                      'ถ่ายรูป',
                      style: TextStyle(color: ThemeColors.earthClay),
                    ),
                    subtitle: Text(
                      'ใช้กล้องถ่ายรูปใหม่',
                      style: TextStyle(color: ThemeColors.warmStone),
                    ),
                    onTap: () => Navigator.pop(context, 'camera'),
                  ),
                ],

                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: ThemeColors.burntOrange.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.photo_library,
                      color: ThemeColors.burntOrange,
                    ),
                  ),
                  title: Text(
                    kIsWeb ? 'เลือกรูปภาพ' : 'เลือกจากแกลเลอรี่',
                    style: TextStyle(color: ThemeColors.earthClay),
                  ),
                  subtitle: Text(
                    kIsWeb ? 'เลือกรูปจากเครื่อง' : 'เลือกรูปจากคลังภาพ',
                    style: TextStyle(color: ThemeColors.warmStone),
                  ),
                  onTap: () => Navigator.pop(context, 'gallery'),
                ),

                // แสดงปุ่มลบเมื่อมีรูปแล้ว
                if (_selectedImage != null || _webImage != null)
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: ThemeColors.clayOrange.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.delete, color: ThemeColors.clayOrange),
                    ),
                    title: Text(
                      'ลบรูปภาพ',
                      style: TextStyle(color: ThemeColors.clayOrange),
                    ),
                    subtitle: Text(
                      'ลบรูปภาพปัจจุบัน',
                      style: TextStyle(color: ThemeColors.warmStone),
                    ),
                    onTap: () => Navigator.pop(context, 'delete'),
                  ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );

    if (result != null) {
      switch (result) {
        case 'camera':
          if (!kIsWeb) _getImage(ImageSource.camera);
          break;
        case 'gallery':
          _getImage(ImageSource.gallery);
          break;
        case 'delete':
          _removeImage();
          break;
      }
    }
  }

  Future<void> _getImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        if (kIsWeb) {
          // ✨ Web: แปลงเป็น bytes
          final bytes = await image.readAsBytes();
          if (mounted) {
            setState(() {
              _webImage = bytes;
              _selectedImage = null;
              _hasUnsavedChanges = true;
            });
          }
        } else {
          // ✨ Mobile: ใช้ File
          if (mounted) {
            setState(() {
              _selectedImage = File(image.path);
              _webImage = null;
              _hasUnsavedChanges = true;
            });
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: ThemeColors.ivoryWhite),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'เกิดข้อผิดพลาดในการเลือกรูปภาพ: $e',
                    style: TextStyle(color: ThemeColors.ivoryWhite),
                  ),
                ),
              ],
            ),
            backgroundColor: ThemeColors.clayOrange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
      _webImage = null;
      _hasUnsavedChanges = true;
    });
  }

  void _resetForm() {
    setState(() {
      _nameController.clear();
      _notesController.clear();
      _selectedType = null;
      _selectedImage = null;
      _webImage = null;
      _hasUnsavedChanges = false;
    });
  }

  // ✨ ปรับปรุงให้ใช้ AnimalDomain.create ที่มีอยู่
  Future<void> _saveAnimal() async {
    if (!_formKey.currentState!.validate() || _selectedType == null) {
      if (_selectedType == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.warning, color: ThemeColors.ivoryWhite),
                const SizedBox(width: 12),
                const Text('กรุณาเลือกประเภทสัตว์เลี้ยง'),
              ],
            ),
            backgroundColor: ThemeColors.warmAmber,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    setState(() => _isSaving = true);

    try {
      // ✨ เตรียมข้อมูลรูปภาพ - รองรับทั้ง Web และ Mobile
      dynamic imageFile;
      if (kIsWeb && _webImage != null) {
        imageFile = _webImage;
      } else if (_selectedImage != null) {
        imageFile = _selectedImage;
      }

      // ✨ เรียกใช้ AnimalDomain.create ตามที่มีอยู่
      final createdAnimal = await AnimalDomain.create(
        houseId: widget.houseId,
        type: _selectedType!,
        name: _nameController.text.trim(),
        imageFile: imageFile, // ส่งรูปภาพไปด้วย
      );

      // ✨ ใช้ mounted check ก่อน async gap
      if (!mounted) return;

      setState(() => _hasUnsavedChanges = false);

      if (createdAnimal != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: ThemeColors.ivoryWhite),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'เพิ่มสัตว์เลี้ยง "${createdAnimal.name}" สำเร็จแล้ว',
                    style: TextStyle(color: ThemeColors.ivoryWhite),
                  ),
                ),
              ],
            ),
            backgroundColor: ThemeColors.oliveGreen,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: ThemeColors.ivoryWhite),
                const SizedBox(width: 12),
                Text(
                  'เพิ่มสัตว์เลี้ยงสำเร็จแล้ว',
                  style: TextStyle(color: ThemeColors.ivoryWhite),
                ),
              ],
            ),
            backgroundColor: ThemeColors.oliveGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      Navigator.pop(context, true); // ส่ง result กลับ
    } catch (e) {
      if (!mounted) return;

      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: ThemeColors.ivoryWhite),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'เกิดข้อผิดพลาด: $e',
                  style: TextStyle(color: ThemeColors.ivoryWhite),
                ),
              ),
            ],
          ),
          backgroundColor: ThemeColors.clayOrange,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Color _getAnimalTypeColor(String? type) {
    final animalType = animalTypes.firstWhere(
      (element) => element['type'] == type,
      orElse: () => animalTypes.last,
    );
    return animalType['color'];
  }

  IconData _getAnimalIcon(String? type) {
    final animalType = animalTypes.firstWhere(
      (element) => element['type'] == type,
      orElse: () => animalTypes.last,
    );
    return animalType['icon'];
  }

  // ✨ ตรวจสอบว่ามีรูปภาพหรือไม่
  bool get _hasImage => _selectedImage != null || _webImage != null;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final shouldPop = await _onWillPop();
        if (shouldPop && mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: ThemeColors.beige,
        appBar: AppBar(
          title: Text(
            'เพิ่มสัตว์เลี้ยงใหม่',
            style: TextStyle(
              color: ThemeColors.ivoryWhite,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: ThemeColors.softBrown,
          foregroundColor: ThemeColors.ivoryWhite,
          elevation: 2,
          shadowColor: ThemeColors.warmStone.withValues(alpha: 0.5),
          actions: [
            if (_hasUnsavedChanges)
              TextButton(
                onPressed: _resetForm,
                style: TextButton.styleFrom(
                  foregroundColor: ThemeColors.ivoryWhite,
                ),
                child: const Text('รีเซ็ต'),
              ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // รูปภาพสัตว์เลี้ยง
                _buildImageSection(),
                const SizedBox(height: 24),

                // ข้อมูลพื้นฐาน
                _buildBasicInfoSection(),
                const SizedBox(height: 24),

                // ประเภทสัตว์เลี้ยง
                _buildTypeSection(),
                const SizedBox(height: 24),

                // หมายเหตุเพิ่มเติม
                _buildNotesSection(),
                const SizedBox(height: 32),

                // ปุ่มบันทึก
                _buildActionButtons(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ✨ ปรับปรุง _buildImageSection ให้รองรับ Web
  Widget _buildImageSection() {
    return _buildCard(
      title: 'รูปภาพสัตว์เลี้ยง',
      icon: Icons.image,
      child: Column(
        children: [
          // แสดงรูปปัจจุบัน
          if (_hasImage) ...[
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: kIsWeb && _webImage != null
                      ? Image.memory(
                          _webImage!,
                          width: double.infinity,
                          height: 200,
                          fit: BoxFit.cover,
                        )
                      : _selectedImage != null
                      ? Image.file(
                          _selectedImage!,
                          width: double.infinity,
                          height: 200,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          width: double.infinity,
                          height: 200,
                          color: ThemeColors.warmStone,
                        ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    decoration: BoxDecoration(
                      color: ThemeColors.earthClay.withValues(alpha: 0.8),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(Icons.close, color: ThemeColors.ivoryWhite),
                      onPressed: () {
                        setState(() {
                          _selectedImage = null;
                          _webImage = null;
                          _hasUnsavedChanges = true;
                        });
                      },
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: ThemeColors.softerBurntOrange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'รูปใหม่',
                      style: TextStyle(
                        color: ThemeColors.ivoryWhite,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            // Placeholder เมื่อไม่มีรูป
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                color: ThemeColors.inputFill,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: ThemeColors.softBorder, width: 2),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _getAnimalIcon(_selectedType),
                    size: 64,
                    color: ThemeColors.warmStone,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'ยังไม่มีรูปภาพ',
                    style: TextStyle(
                      color: ThemeColors.earthClay,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'กดปุ่มด้านล่างเพื่อเพิ่มรูป',
                    style: TextStyle(
                      color: ThemeColors.warmStone,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),

          // ปุ่มเลือกรูป
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: _pickImage,
              icon: Icon(
                _hasImage ? Icons.edit : Icons.add_photo_alternate,
                color: ThemeColors.burntOrange,
              ),
              label: Text(
                _hasImage ? 'เปลี่ยนรูปภาพ' : 'เพิ่มรูปภาพ',
                style: TextStyle(color: ThemeColors.earthClay),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: ThemeColors.softBorder),
                backgroundColor: ThemeColors.ivoryWhite,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return _buildCard(
      title: 'ข้อมูลพื้นฐาน',
      icon: Icons.pets,
      child: Column(
        children: [
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'ชื่อสัตว์เลี้ยง *',
              labelStyle: TextStyle(color: ThemeColors.earthClay),
              hintText: 'ระบุชื่อสัตว์เลี้ยง',
              hintStyle: TextStyle(color: ThemeColors.warmStone),
              prefixIcon: Icon(Icons.pets, color: ThemeColors.burntOrange),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: ThemeColors.softBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: ThemeColors.focusedBrown,
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: ThemeColors.clayOrange),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: ThemeColors.clayOrange, width: 2),
              ),
              filled: true,
              fillColor: ThemeColors.inputFill,
            ),
            style: TextStyle(color: ThemeColors.earthClay),
            validator: (value) => value?.trim().isEmpty == true
                ? 'กรุณาระบุชื่อสัตว์เลี้ยง'
                : null,
            textInputAction: TextInputAction.next,
          ),
        ],
      ),
    );
  }

  Widget _buildTypeSection() {
    return _buildCard(
      title: 'ประเภทสัตว์เลี้ยง',
      icon: Icons.category,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'เลือกประเภทสัตว์เลี้ยง *',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: ThemeColors.earthClay,
            ),
          ),
          const SizedBox(height: 16),

          // Grid ของประเภทสัตว์
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 3,
            ),
            itemCount: animalTypes.length,
            itemBuilder: (context, index) {
              final type = animalTypes[index];
              final isSelected = _selectedType == type['type'];

              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedType = type['type'];
                    _hasUnsavedChanges = true;
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? type['color'].withValues(alpha: 0.1)
                        : ThemeColors.ivoryWhite,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? type['color']
                          : ThemeColors.softBorder,
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: type['color'].withValues(alpha: 0.2),
                              spreadRadius: 1,
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        type['icon'],
                        color: isSelected
                            ? type['color']
                            : ThemeColors.warmStone,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        type['type'],
                        style: TextStyle(
                          color: isSelected
                              ? type['color']
                              : ThemeColors.earthClay,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          if (_selectedType == null) ...[
            const SizedBox(height: 8),
            Text(
              'กรุณาเลือกประเภทสัตว์เลี้ยง',
              style: TextStyle(color: ThemeColors.clayOrange, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNotesSection() {
    return _buildCard(
      title: 'หมายเหตุเพิ่มเติม',
      icon: Icons.note_alt,
      child: TextFormField(
        controller: _notesController,
        decoration: InputDecoration(
          hintText: 'เช่น อาหารที่ชอบ, นิสัยพิเศษ, หรือข้อมูลอื่นๆ (ไม่บังคับ)',
          hintStyle: TextStyle(color: ThemeColors.warmStone),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: ThemeColors.softBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: ThemeColors.focusedBrown, width: 2),
          ),
          filled: true,
          fillColor: ThemeColors.inputFill,
        ),
        style: TextStyle(color: ThemeColors.earthClay),
        maxLines: 4,
        textInputAction: TextInputAction.done,
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // ปุ่มบันทึก
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _isSaving ? null : _saveAnimal,
            style: ElevatedButton.styleFrom(
              backgroundColor: _selectedType != null
                  ? _getAnimalTypeColor(_selectedType)
                  : ThemeColors.disabledGrey,
              foregroundColor: ThemeColors.ivoryWhite,
              disabledBackgroundColor: ThemeColors.disabledGrey,
              disabledForegroundColor: ThemeColors.warmStone,
              elevation: _selectedType != null ? 4 : 0,
              shadowColor: _selectedType != null
                  ? _getAnimalTypeColor(_selectedType).withValues(alpha: 0.4)
                  : null,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isSaving
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: ThemeColors.ivoryWhite,
                          strokeWidth: 2,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'กำลังบันทึก...',
                        style: TextStyle(color: ThemeColors.ivoryWhite),
                      ),
                    ],
                  )
                : Text(
                    'เพิ่มสัตว์เลี้ยง',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: ThemeColors.ivoryWhite,
                    ),
                  ),
          ),
        ),

        const SizedBox(height: 12),

        // ปุ่มยกเลิก
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton(
            onPressed: _isSaving
                ? null
                : () async {
                    if (_hasUnsavedChanges) {
                      final shouldPop = await _onWillPop();
                      if (shouldPop && mounted) {
                        Navigator.pop(context);
                      }
                    } else {
                      Navigator.pop(context);
                    }
                  },
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: ThemeColors.softBorder),
              backgroundColor: ThemeColors.ivoryWhite,
              foregroundColor: ThemeColors.earthClay,
              disabledForegroundColor: ThemeColors.warmStone,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'ยกเลิก',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Card(
      elevation: 3,
      shadowColor: ThemeColors.warmStone.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: ThemeColors.ivoryWhite,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: ThemeColors.burntOrange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: ThemeColors.burntOrange.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Icon(icon, color: ThemeColors.burntOrange, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: ThemeColors.softBrown,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}
