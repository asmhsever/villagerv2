// lib/pages/edit_house_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fullproject/models/house_model.dart';
import 'package:fullproject/domains/house_domain.dart';
import 'package:fullproject/services/image_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class EditHousePage extends StatefulWidget {
  final HouseModel house;
  const EditHousePage({super.key, required this.house});

  @override
  State<EditHousePage> createState() => _EditHousePageState();
}

class _EditHousePageState extends State<EditHousePage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  late TextEditingController _houseNumberController;
  late TextEditingController _ownerController;
  late TextEditingController _phoneController;
  late TextEditingController _floorsController;
  late TextEditingController _usableAreaController;
  late TextEditingController _sizeController;

  // Form values
  String? _status;
  String? _ownershipType;
  String? _houseType;
  String? _usageStatus;
  File? _selectedImage;
  String? _currentImageUrl;
  bool _removeCurrentImage = false;

  bool _isSaving = false;
  bool _hasUnsavedChanges = false;

  // Options for dropdowns
  final List<String> _statusOptions = [
    'owned',
    'vacant',
    'rented',
    'sold'
  ];

  final List<String> _ownershipTypeOptions = [
    'owned',
    'rented',
    'company'
  ];

  final List<String> _houseTypeOptions = [
    'detached',
    'townhouse',
    'apartment',
    'condo'
  ];

  final List<String> _usageStatusOptions = [
    'active',
    'inactive',
    'maintenance'
  ];

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    _houseNumberController = TextEditingController(text: widget.house.houseNumber);
    _ownerController = TextEditingController(text: widget.house.owner);
    _phoneController = TextEditingController(text: widget.house.phone);
    _floorsController = TextEditingController(text: widget.house.floors?.toString());
    _usableAreaController = TextEditingController(text: widget.house.usableArea);
    _sizeController = TextEditingController(text: widget.house.size);

    _status = widget.house.status;
    _ownershipType = 'owned'; // Default; adjust if model has this field
    _houseType = widget.house.houseType;
    _usageStatus = widget.house.usageStatus ?? 'active';
    _currentImageUrl = widget.house.img;

    // Listen for changes
    _houseNumberController.addListener(_onFieldChanged);
    _ownerController.addListener(_onFieldChanged);
    _phoneController.addListener(_onFieldChanged);
    _floorsController.addListener(_onFieldChanged);
    _usableAreaController.addListener(_onFieldChanged);
    _sizeController.addListener(_onFieldChanged);
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
    _houseNumberController.dispose();
    _ownerController.dispose();
    _phoneController.dispose();
    _floorsController.dispose();
    _usableAreaController.dispose();
    _sizeController.dispose();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    if (!_hasUnsavedChanges) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: const Color(0xFFE08E45), size: 28),
            const SizedBox(width: 12),
            const Text('ยืนยันการออก'),
          ],
        ),
        content: const Text('คุณมีการเปลี่ยนแปลงที่ยังไม่ได้บันทึก ต้องการออกหรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text('ยกเลิก', style: TextStyle(color: const Color(0xFFA47551))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFE08E45)),
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
      builder: (sheetContext) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFFFFDF6),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                    color: const Color(0xFFD8CAB8).withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                Text(
                  'เลือกรูปภาพ',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFA47551),
                  ),
                ),

                const SizedBox(height: 20),

                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD8CAB8).withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.photo_camera, color: const Color(0xFFA47551)),
                  ),
                  title: Text('ถ่ายรูป', style: TextStyle(color: const Color(0xFFA47551))),
                  subtitle: Text('ใช้กล้องถ่ายรูปใหม่', style: TextStyle(color: const Color(0xFFBFA18F))),
                  onTap: () => Navigator.pop(sheetContext, 'camera'),
                ),

                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFA3B18A).withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.photo_library, color: const Color(0xFFA3B18A)),
                  ),
                  title: Text('เลือกจากแกลเลอรี่', style: TextStyle(color: const Color(0xFFA47551))),
                  subtitle: Text('เลือกรูปจากคลังภาพ', style: TextStyle(color: const Color(0xFFBFA18F))),
                  onTap: () => Navigator.pop(sheetContext, 'gallery'),
                ),

                if (_selectedImage != null || (_currentImageUrl != null && !_removeCurrentImage))
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE08E45).withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.delete, color: const Color(0xFFE08E45)),
                    ),
                    title: Text('ลบรูปภาพ', style: TextStyle(color: const Color(0xFFE08E45))),
                    subtitle: Text('ลบรูปภาพปัจจุบัน', style: TextStyle(color: const Color(0xFFBFA18F))),
                    onTap: () => Navigator.pop(sheetContext, 'delete'),
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
          _getImage(ImageSource.camera);
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
        setState(() {
          _selectedImage = File(image.path);
          _removeCurrentImage = false;
          _hasUnsavedChanges = true;
        });
      }
    } catch (e) {
      if (!mounted) return; // why: avoid using context after dispose

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text('เกิดข้อผิดพลาดในการเลือกรูปภาพ: $e')),
            ],
          ),
          backgroundColor: const Color(0xFFE08E45),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
      _removeCurrentImage = true;
      _hasUnsavedChanges = true;
    });
  }

  void _resetForm() {
    setState(() {
      _houseNumberController.text = widget.house.houseNumber ?? '';
      _ownerController.text = widget.house.owner ?? '';
      _phoneController.text = widget.house.phone ?? '';
      _floorsController.text = widget.house.floors?.toString() ?? '';
      _usableAreaController.text = widget.house.usableArea ?? '';
      _sizeController.text = widget.house.size ?? '';
      _status = widget.house.status;
      _ownershipType = 'owned'; // Reset to default
      _houseType = widget.house.houseType;
      _usageStatus = widget.house.usageStatus ?? 'active';
      _selectedImage = null;
      _currentImageUrl = widget.house.img;
      _removeCurrentImage = false;
      _hasUnsavedChanges = false;
    });
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus(); // why: dismiss keyboard for better UX
    setState(() => _isSaving = true);

    try {
      final updatedHouse = await HouseDomain.update(
        houseId: widget.house.houseId,
        villageId: widget.house.villageId,
        size: _sizeController.text.trim(),
        houseNumber: _houseNumberController.text.trim(),
        phone: _phoneController.text.trim(),
        owner: _ownerController.text.trim(),
        status: _status!,
        userId: widget.house.userId,
        ownershipType: _ownershipType!,
        houseType: _houseType!,
        floors: int.tryParse(_floorsController.text.trim()) ?? 1,
        usableArea: _usableAreaController.text.trim(),
        usageStatus: _usageStatus!,
        imageFile: _selectedImage,
        removeImage: _removeCurrentImage,
      );

      if (!mounted) return; // why: context used below after await

      if (updatedHouse != null) {
        setState(() => _hasUnsavedChanges = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('บันทึกข้อมูลสำเร็จ'),
              ],
            ),
            backgroundColor: Color(0xFFA3B18A),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, updatedHouse);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 12),
                Text('เกิดข้อผิดพลาดในการบันทึก'),
              ],
            ),
            backgroundColor: Color(0xFFE08E45),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return; // why: context used below after await

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text('เกิดข้อผิดพลาด: $e')),
            ],
          ),
          backgroundColor: const Color(0xFFE08E45),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    if (mounted) {
      setState(() => _isSaving = false);
    }
  }

  String _formatPhoneNumber(String phone) {
    // Remove all non-digits
    String digits = phone.replaceAll(RegExp(r'[^\d]'), '');

    // Format as XXX-XXX-XXXX
    if (digits.length >= 10) {
      return '${digits.substring(0, 3)}-${digits.substring(3, 6)}-${digits.substring(6, 10)}';
    } else if (digits.length >= 6) {
      return '${digits.substring(0, 3)}-${digits.substring(3, 6)}-${digits.substring(6)}';
    } else if (digits.length >= 3) {
      return '${digits.substring(0, 3)}-${digits.substring(3)}';
    }
    return digits;
  }

  String _getStatusText(String? status) {
    switch (status) {
      case 'owned':
        return 'มีเจ้าของ';
      case 'vacant':
        return 'ว่าง';
      case 'rented':
        return 'ให้เช่า';
      case 'sold':
        return 'ขายแล้ว';
      default:
        return status ?? '';
    }
  }

  String _getOwnershipTypeText(String? type) {
    switch (type) {
      case 'owned':
        return 'เป็นเจ้าของ';
      case 'rented':
        return 'เช่า';
      case 'company':
        return 'นิติบุคคล';
      default:
        return type ?? '';
    }
  }

  String _getHouseTypeText(String? type) {
    switch (type) {
      case 'detached':
        return 'บ้านเดี่ยว';
      case 'townhouse':
        return 'ทาวน์เฮาส์';
      case 'apartment':
        return 'อพาร์ทเมนต์';
      case 'condo':
        return 'คอนโดมิเนียม';
      default:
        return type ?? '';
    }
  }

  String _getUsageStatusText(String? status) {
    switch (status) {
      case 'active':
        return 'ใช้งาน';
      case 'inactive':
        return 'ไม่ใช้งาน';
      case 'maintenance':
        return 'ปรับปรุง';
      default:
        return status ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final shouldPop = await _onWillPop();
        if (!mounted) return; // why: using context after await
        if (shouldPop) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFFFFDF6),
        appBar: AppBar(
          title: Text('แก้ไขบ้านเลขที่ ${widget.house.houseNumber}',
              style: TextStyle(color: const Color(0xFFA47551))),
          backgroundColor: const Color(0xFFFFFDF6),
          foregroundColor: const Color(0xFFA47551),
          elevation: 1,
          actions: [
            if (_hasUnsavedChanges)
              TextButton(
                onPressed: _resetForm,
                child: Text('รีเซ็ต', style: TextStyle(color: const Color(0xFFE08E45))),
              ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // รูปภาพบ้าน
                _buildImageSection(),
                const SizedBox(height: 24),

                // ข้อมูลพื้นฐาน
                _buildBasicInfoSection(),
                const SizedBox(height: 24),

                // รายละเอียดบ้าน
                _buildHouseDetailsSection(),
                const SizedBox(height: 24),

                // สถานะต่างๆ
                _buildStatusSection(),
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

  Widget _buildImageSection() {
    return _buildCard(
      title: 'รูปภาพบ้าน',
      icon: Icons.image,
      child: Column(
        children: [
          // แสดงรูปปัจจุบัน
          if (_selectedImage != null) ...[
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.file(
                    _selectedImage!,
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFA47551).withValues(alpha: 0.8),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Color(0xFFFFFDF6)),
                      onPressed: () {
                        setState(() {
                          _selectedImage = null;
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
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFA3B18A),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'รูปใหม่',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          ] else if (_currentImageUrl != null && !_removeCurrentImage) ...[
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: BuildImage(
                    imagePath: _currentImageUrl!,
                    tablePath: 'house',
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                    errorWidget: Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F0E1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFD8CAB8)),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline,
                              color: const Color(0xFFBFA18F), size: 48),
                          const SizedBox(height: 8),
                          Text('ไม่สามารถโหลดรูปภาพได้',
                              style: TextStyle(color: const Color(0xFFA47551))),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE08E45),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'รูปเดิม',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            // Placeholder เมื่อไม่มีรูปหรือถูกลบ
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F0E1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFD8CAB8), width: 2),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.home,
                    size: 64,
                    color: const Color(0xFFBFA18F),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'ไม่มีรูปภาพ',
                    style: TextStyle(
                      color: const Color(0xFFA47551),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'กดปุ่มด้านล่างเพื่อเพิ่มรูป',
                    style: TextStyle(
                      color: const Color(0xFFBFA18F),
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
              icon: Icon(_selectedImage != null || (_currentImageUrl != null && !_removeCurrentImage)
                  ? Icons.edit
                  : Icons.add_photo_alternate),
              label: Text(_selectedImage != null || (_currentImageUrl != null && !_removeCurrentImage)
                  ? 'เปลี่ยนรูปภาพ'
                  : 'เพิ่มรูปภาพ'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFA47551),
                side: BorderSide(color: const Color(0xFFD8CAB8)),
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
      icon: Icons.info_outline,
      child: Column(
        children: [
          // บ้านเลขที่
          TextFormField(
            controller: _houseNumberController,
            decoration: InputDecoration(
              labelText: 'บ้านเลขที่ *',
              labelStyle: TextStyle(color: const Color(0xFFA47551)),
              hintText: 'เช่น 123/45',
              hintStyle: TextStyle(color: const Color(0xFFBFA18F)),
              prefixIcon: Icon(Icons.confirmation_number, color: const Color(0xFFA47551)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: const Color(0xFFD0C4B0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: const Color(0xFFD0C4B0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: const Color(0xFF916846), width: 2),
              ),
              filled: true,
              fillColor: const Color(0xFFFBF9F3),
            ),
            textInputAction: TextInputAction.next,
            validator: (v) => (v == null || v.trim().isEmpty) ? 'กรุณากรอกบ้านเลขที่' : null,
          ),
          const SizedBox(height: 16),

          // เจ้าของบ้าน
          TextFormField(
            controller: _ownerController,
            decoration: InputDecoration(
              labelText: 'ชื่อเจ้าของบ้าน',
              labelStyle: TextStyle(color: const Color(0xFFA47551)),
              hintText: 'เช่น สมชาย ใจดี',
              hintStyle: TextStyle(color: const Color(0xFFBFA18F)),
              prefixIcon: Icon(Icons.person, color: const Color(0xFFA47551)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: const Color(0xFFD0C4B0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: const Color(0xFFD0C4B0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: const Color(0xFF916846), width: 2),
              ),
              filled: true,
              fillColor: const Color(0xFFFBF9F3),
            ),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),

          // เบอร์โทรศัพท์ (ใช้ formatter)
          TextFormField(
            controller: _phoneController,
            decoration: InputDecoration(
              labelText: 'เบอร์โทรศัพท์',
              labelStyle: TextStyle(color: const Color(0xFFA47551)),
              hintText: 'เช่น 081-234-5678',
              hintStyle: TextStyle(color: const Color(0xFFBFA18F)),
              prefixIcon: Icon(Icons.phone, color: const Color(0xFFA47551)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: const Color(0xFFD0C4B0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: const Color(0xFFD0C4B0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: const Color(0xFF916846), width: 2),
              ),
              filled: true,
              fillColor: const Color(0xFFFBF9F3),
            ),
            keyboardType: TextInputType.phone,
            // ไม่ใส่ digitsOnly เพื่อให้มีเครื่องหมาย - ได้
            onChanged: (value) {
              final formatted = _formatPhoneNumber(value);
              if (formatted != value) {
                final baseOffset = formatted.length;
                _phoneController
                  ..text = formatted
                  ..selection = TextSelection.collapsed(offset: baseOffset);
              }
            },
            textInputAction: TextInputAction.next,
          ),
        ],
      ),
    );
  }

  Widget _buildHouseDetailsSection() {
    return _buildCard(
      title: 'รายละเอียดบ้าน',
      icon: Icons.home_work,
      child: Column(
        children: [
          // ประเภทบ้าน
          DropdownButtonFormField<String>(
            value: _houseType,
            decoration: InputDecoration(
              labelText: 'ประเภทบ้าน *',
              labelStyle: TextStyle(color: const Color(0xFFA47551)),
              prefixIcon: Icon(Icons.apartment, color: const Color(0xFFA47551)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: const Color(0xFFD0C4B0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: const Color(0xFFD0C4B0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: const Color(0xFF916846), width: 2),
              ),
              filled: true,
              fillColor: const Color(0xFFFBF9F3),
            ),
            items: _houseTypeOptions.map((type) {
              return DropdownMenuItem(
                value: type,
                child: Text(_getHouseTypeText(type), style: TextStyle(color: const Color(0xFFA47551))),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _houseType = value;
                _hasUnsavedChanges = true;
              });
            },
            validator: (value) => value == null ? 'กรุณาเลือกประเภทบ้าน' : null,
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              // จำนวนชั้น
              Expanded(
                child: TextFormField(
                  controller: _floorsController,
                  decoration: InputDecoration(
                    labelText: 'จำนวนชั้น',
                    labelStyle: TextStyle(color: const Color(0xFFA47551)),
                    hintText: 'เช่น 1, 2',
                    hintStyle: TextStyle(color: const Color(0xFFBFA18F)),
                    prefixIcon: Icon(Icons.layers, color: const Color(0xFFA47551)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: const Color(0xFFD0C4B0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: const Color(0xFFD0C4B0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: const Color(0xFF916846), width: 2),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFFBF9F3),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  textInputAction: TextInputAction.next,
                ),
              ),
              const SizedBox(width: 16),

              // ขนาด
              Expanded(
                child: TextFormField(
                  controller: _sizeController,
                  decoration: InputDecoration(
                    labelText: 'ขนาด',
                    labelStyle: TextStyle(color: const Color(0xFFA47551)),
                    hintText: 'เช่น 100 ตร.ม.',
                    hintStyle: TextStyle(color: const Color(0xFFBFA18F)),
                    prefixIcon: Icon(Icons.square_foot, color: const Color(0xFFA47551)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: const Color(0xFFD0C4B0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: const Color(0xFFD0C4B0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: const Color(0xFF916846), width: 2),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFFBF9F3),
                  ),
                  textInputAction: TextInputAction.next,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // พื้นที่ใช้สอย
          TextFormField(
            controller: _usableAreaController,
            decoration: InputDecoration(
              labelText: 'พื้นที่ใช้สอย',
              labelStyle: TextStyle(color: const Color(0xFFA47551)),
              hintText: 'เช่น 80 ตร.ม.',
              hintStyle: TextStyle(color: const Color(0xFFBFA18F)),
              prefixIcon: Icon(Icons.area_chart, color: const Color(0xFFA47551)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: const Color(0xFFD0C4B0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: const Color(0xFFD0C4B0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: const Color(0xFF916846), width: 2),
              ),
              filled: true,
              fillColor: const Color(0xFFFBF9F3),
            ),
            textInputAction: TextInputAction.done,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSection() {
    return _buildCard(
      title: 'สถานะ',
      icon: Icons.info,
      child: Column(
        children: [
          // สถานะบ้าน
          DropdownButtonFormField<String>(
            value: _status,
            decoration: InputDecoration(
              labelText: 'สถานะบ้าน *',
              labelStyle: TextStyle(color: const Color(0xFFA47551)),
              prefixIcon: Icon(Icons.home_filled, color: const Color(0xFFA47551)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: const Color(0xFFD0C4B0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: const Color(0xFFD0C4B0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: const Color(0xFF916846), width: 2),
              ),
              filled: true,
              fillColor: const Color(0xFFFBF9F3),
            ),
            items: _statusOptions.map((status) {
              return DropdownMenuItem(
                value: status,
                child: Text(_getStatusText(status), style: TextStyle(color: const Color(0xFFA47551))),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _status = value;
                _hasUnsavedChanges = true;
              });
            },
            validator: (value) => value == null ? 'กรุณาเลือกสถานะบ้าน' : null,
          ),
          const SizedBox(height: 16),

          // ประเภทความเป็นเจ้าของ
          DropdownButtonFormField<String>(
            value: _ownershipType,
            decoration: InputDecoration(
              labelText: 'ประเภทความเป็นเจ้าของ *',
              labelStyle: TextStyle(color: const Color(0xFFA47551)),
              prefixIcon: Icon(Icons.account_balance, color: const Color(0xFFA47551)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: const Color(0xFFD0C4B0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: const Color(0xFFD0C4B0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: const Color(0xFF916846), width: 2),
              ),
              filled: true,
              fillColor: const Color(0xFFFBF9F3),
            ),
            items: _ownershipTypeOptions.map((type) {
              return DropdownMenuItem(
                value: type,
                child: Text(_getOwnershipTypeText(type), style: TextStyle(color: const Color(0xFFA47551))),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _ownershipType = value;
                _hasUnsavedChanges = true;
              });
            },
            validator: (value) => value == null ? 'กรุณาเลือกประเภทความเป็นเจ้าของ' : null,
          ),
          const SizedBox(height: 16),

          // สถานะการใช้งาน
          DropdownButtonFormField<String>(
            value: _usageStatus,
            decoration: InputDecoration(
              labelText: 'สถานะการใช้งาน *',
              labelStyle: TextStyle(color: const Color(0xFFA47551)),
              prefixIcon: Icon(Icons.toggle_on, color: const Color(0xFFA47551)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: const Color(0xFFD0C4B0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: const Color(0xFFD0C4B0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: const Color(0xFF916846), width: 2),
              ),
              filled: true,
              fillColor: const Color(0xFFFBF9F3),
            ),
            items: _usageStatusOptions.map((status) {
              return DropdownMenuItem(
                value: status,
                child: Text(_getUsageStatusText(status), style: TextStyle(color: const Color(0xFFA47551))),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _usageStatus = value;
                _hasUnsavedChanges = true;
              });
            },
            validator: (value) => value == null ? 'กรุณาเลือกสถานะการใช้งาน' : null,
          ),
        ],
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
            onPressed: _isSaving ? null : _saveChanges,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE08E45),
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(0xFFDCDCDC),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
            child: _isSaving
                ? const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
                SizedBox(width: 12),
                Text('กำลังบันทึก...'),
              ],
            )
                : const Text(
              'บันทึกการเปลี่ยนแปลง',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
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
                if (!mounted) return; // why: using context after await
                if (shouldPop) {
                  Navigator.pop(context);
                }
              } else {
                Navigator.pop(context);
              }
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFA47551),
              side: BorderSide(color: const Color(0xFFD8CAB8)),
              disabledForegroundColor: const Color(0xFFDCDCDC),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('ยกเลิก'),
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
      elevation: 2,
      color: const Color(0xFFFFFDF6),
      shadowColor: const Color(0xFFBFA18F).withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: const Color(0xFFD8CAB8).withValues(alpha: 0.3)),
      ),
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
                    color: const Color(0xFFE08E45).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: const Color(0xFFE08E45), size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFA47551),
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
