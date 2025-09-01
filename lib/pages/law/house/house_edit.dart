// lib/pages/edit_house_page.dart
// Production-hardened EditHousePage with ThemeColors integration

import 'dart:io' show File;
import 'dart:typed_data' show Uint8List;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:fullproject/domains/house_domain.dart';
import 'package:fullproject/models/house_model.dart';
import 'package:fullproject/services/image_service.dart';
import 'package:fullproject/theme/Color.dart';
import 'package:image_picker/image_picker.dart';

class EditHousePage extends StatefulWidget {
  final int villageId;
  final HouseModel? house; // null = create, not null = edit

  const EditHousePage({
    super.key,
    required this.villageId,
    this.house,
  });

  @override
  State<EditHousePage> createState() => _EditHousePageState();
}

class _EditHousePageState extends State<EditHousePage> {
  final _formKey = GlobalKey<FormState>();

  final _houseNumberController = TextEditingController();
  final _ownerController = TextEditingController();
  final _phoneController = TextEditingController();
  final _sizeController = TextEditingController();
  final _usableAreaController = TextEditingController();
  final _floorsController = TextEditingController();

  String? _selectedStatus;
  String? _selectedOwnershipType;
  String? _selectedHouseType;
  String? _selectedUsageStatus;

  // Image (web + mobile)
  File? _selectedImage; // mobile
  Uint8List? _webImage; // web
  String? _currentImageUrl;
  bool _removeCurrentImage = false;

  bool _isSaving = false;
  bool _hasUnsavedChanges = false;

  final ImagePicker _picker = ImagePicker();

  // Option definitions with ThemeColors
  final List<Map<String, dynamic>> houseStatuses = const [
    {'value': 'owned', 'label': 'มีคนอยู่อาศัย', 'icon': Icons.home, 'color': ThemeColors.successGreen},
    {'value': 'vacant', 'label': 'ว่าง', 'icon': Icons.home_outlined, 'color': ThemeColors.warningAmber},
    {'value': 'sold', 'label': 'ขายแล้ว', 'icon': Icons.home_work, 'color': ThemeColors.infoBlue},
    {'value': 'rented', 'label': 'ให้เช่าแล้ว', 'icon': Icons.key, 'color': ThemeColors.burntOrange},
  ];

  final List<Map<String, dynamic>> ownershipTypes = const [
    {'value': 'owner', 'label': 'เจ้าของบ้าน', 'icon': Icons.person, 'color': ThemeColors.softBrown},
    {'value': 'tenant', 'label': 'ผู้เช่า', 'icon': Icons.person_outline, 'color': ThemeColors.sageGreen},
  ];

  final List<Map<String, dynamic>> houseTypes = const [
    {'value': 'detached', 'label': 'บ้านเดี่ยว', 'icon': Icons.home, 'color': ThemeColors.infoBlue},
    {'value': 'duplex', 'label': 'บ้านแฝด', 'icon': Icons.home_work, 'color': ThemeColors.sageGreen},
    {'value': 'townhouse', 'label': 'ทาวน์เฮาส์', 'icon': Icons.apartment, 'color': ThemeColors.rustOrange},
    {'value': 'condo', 'label': 'คอนโด', 'icon': Icons.business, 'color': ThemeColors.terracottaRed},
  ];

  final List<Map<String, dynamic>> usageStatuses = const [
    {'value': 'active', 'label': 'ใช้งานปกติ', 'icon': Icons.check_circle, 'color': ThemeColors.successGreen},
    {'value': 'inactive', 'label': 'ไม่ใช้งาน', 'icon': Icons.cancel, 'color': ThemeColors.errorRust},
    {'value': 'maintenance', 'label': 'ซ่อมแซม', 'icon': Icons.build, 'color': ThemeColors.warningAmber},
  ];

  @override
  void initState() {
    super.initState();
    _initializeForm();
    _houseNumberController.addListener(_onFieldChanged);
    _ownerController.addListener(_onFieldChanged);
    _phoneController.addListener(_onFieldChanged);
    _sizeController.addListener(_onFieldChanged);
    _usableAreaController.addListener(_onFieldChanged);
    _floorsController.addListener(_onFieldChanged);
  }

  void _initializeForm() {
    final h = widget.house;
    if (h != null) {
      _houseNumberController.text = h.houseNumber ?? '';
      _ownerController.text = h.owner ?? '';
      _phoneController.text = h.phone ?? '';
      _sizeController.text = h.size ?? '';
      _usableAreaController.text = h.usableArea ?? '';
      _floorsController.text = (h.floors == null || h.floors! < 1) ? '' : h.floors!.toString();
      _selectedStatus = h.status;
      _selectedOwnershipType = h.ownershipType;
      _selectedHouseType = h.houseType;
      _selectedUsageStatus = h.usageStatus;
      _currentImageUrl = h.img;
    }
  }

  void _onFieldChanged() {
    if (!_hasUnsavedChanges) setState(() => _hasUnsavedChanges = true);
  }

  @override
  void dispose() {
    _houseNumberController.dispose();
    _ownerController.dispose();
    _phoneController.dispose();
    _sizeController.dispose();
    _usableAreaController.dispose();
    _floorsController.dispose();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    if (!_hasUnsavedChanges) return true;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: ThemeColors.ivoryWhite,
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: ThemeColors.warningAmber, size: 28),
            const SizedBox(width: 12),
            Text('ยืนยันการออก', style: TextStyle(color: ThemeColors.darkChocolate)),
          ],
        ),
        content: Text(
          'คุณมีการเปลี่ยนแปลงที่ยังไม่ได้บันทึก ต้องการออกหรือไม่?',
          style: TextStyle(color: ThemeColors.darkChocolate),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(foregroundColor: ThemeColors.softBrown),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: ThemeColors.errorRust),
            child: const Text('ออก'),
          ),
        ],
      ),
    );
    return confirm ?? false;
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
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: ThemeColors.dustyBrown.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Text(
                  'เลือกรูปภาพบ้าน',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: ThemeColors.darkChocolate,
                  ),
                ),
                const SizedBox(height: 20),
                if (!kIsWeb)
                  ListTile(
                    leading: _iconChip(Icons.photo_camera, ThemeColors.infoBlue),
                    title: Text('ถ่ายรูป', style: TextStyle(color: ThemeColors.darkChocolate)),
                    subtitle: Text('ใช้กล้องถ่ายรูปใหม่', style: TextStyle(color: ThemeColors.dustyBrown)),
                    onTap: () => Navigator.pop(context, 'camera'),
                  ),
                ListTile(
                  leading: _iconChip(Icons.photo_library, ThemeColors.sageGreen),
                  title: Text(
                    kIsWeb ? 'เลือกรูปภาพ' : 'เลือกจากแกลเลอรี่',
                    style: TextStyle(color: ThemeColors.darkChocolate),
                  ),
                  subtitle: Text(
                    kIsWeb ? 'เลือกรูปจากเครื่อง' : 'เลือกรูปจากคลังภาพ',
                    style: TextStyle(color: ThemeColors.dustyBrown),
                  ),
                  onTap: () => Navigator.pop(context, 'gallery'),
                ),
                if (_hasAnyImage())
                  ListTile(
                    leading: _iconChip(Icons.delete, ThemeColors.errorRust),
                    title: Text(
                      'ลบรูปภาพ',
                      style: TextStyle(color: ThemeColors.errorRust),
                    ),
                    subtitle: Text(
                      'ลบรูปภาพปัจจุบัน',
                      style: TextStyle(color: ThemeColors.dustyBrown),
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

    if (!mounted || result == null) return;
    switch (result) {
      case 'camera':
        if (!kIsWeb) await _getImage(ImageSource.camera);
        break;
      case 'gallery':
        await _getImage(ImageSource.gallery);
        break;
      case 'delete':
        _removeImage();
        break;
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
      if (image == null) return;

      if (kIsWeb) {
        final bytes = await image.readAsBytes();
        if (!mounted) return;
        setState(() {
          _webImage = bytes;
          _selectedImage = null;
          _removeCurrentImage = false;
          _hasUnsavedChanges = true;
        });
      } else {
        if (!mounted) return;
        setState(() {
          _selectedImage = File(image.path);
          _webImage = null;
          _removeCurrentImage = false;
          _hasUnsavedChanges = true;
        });
      }
    } catch (e) {
      _showSnack('เกิดข้อผิดพลาดในการเลือกรูปภาพ: $e', isError: true);
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
      _webImage = null;
      _removeCurrentImage = true;
      _hasUnsavedChanges = true;
    });
  }

  void _resetForm() {
    setState(() {
      _initializeForm();
      _selectedImage = null;
      _webImage = null;
      _removeCurrentImage = false;
      _hasUnsavedChanges = false;
    });
  }

  Future<void> _saveHouse() async {
    final form = _formKey.currentState;
    if (form == null) return;
    if (!form.validate()) return;

    // Required selections
    final missing = <String>[];
    if (_selectedStatus == null) missing.add('สถานะบ้าน');
    if (_selectedOwnershipType == null) missing.add('ประเภทความเป็นเจ้าของ');
    if (_selectedHouseType == null) missing.add('ประเภทบ้าน');
    if (_selectedUsageStatus == null) missing.add('สถานะการใช้งาน');

    if (missing.isNotEmpty) {
      _showSnack('กรุณาเลือก: ${missing.join(', ')}', isWarning: true);
      return;
    }

    setState(() => _isSaving = true);
    try {
      dynamic imageFile;
      if (kIsWeb && _webImage != null) {
        imageFile = _webImage;
      } else if (_selectedImage != null) {
        imageFile = _selectedImage;
      }

      HouseModel? result;
      if (widget.house != null) {
        result = await HouseDomain.update(
          houseId: widget.house!.houseId,
          villageId: widget.villageId,
          size: _sizeController.text.trim(),
          houseNumber: _houseNumberController.text.trim(),
          phone: _phoneController.text.trim(),
          owner: _ownerController.text.trim(),
          status: _selectedStatus!,
          userId: widget.house!.userId,
          ownershipType: _selectedOwnershipType!,
          houseType: _selectedHouseType!,
          floors: int.tryParse(_floorsController.text.trim()) ?? 1,
          usableArea: _usableAreaController.text.trim(),
          usageStatus: _selectedUsageStatus!,
          imageFile: imageFile,
          removeImage: _removeCurrentImage,
        );
      } else {
        // TODO: wire userId from auth/session instead of constant.
        result = await HouseDomain.create(
          villageId: widget.villageId,
          size: _sizeController.text.trim(),
          houseNumber: _houseNumberController.text.trim(),
          phone: _phoneController.text.trim(),
          owner: _ownerController.text.trim(),
          status: _selectedStatus!,
          userId: 1,
          ownershipType: _selectedOwnershipType!,
          houseType: _selectedHouseType!,
          floors: int.tryParse(_floorsController.text.trim()) ?? 1,
          usableArea: _usableAreaController.text.trim(),
          usageStatus: _selectedUsageStatus!,
          imageFile: imageFile,
        );
      }

      if (!mounted) return;
      if (result == null) throw Exception('ไม่สามารถบันทึกข้อมูลได้');

      _hasUnsavedChanges = false;
      _showSnack(
        widget.house != null
            ? 'แก้ไขข้อมูลบ้าน "${_houseNumberController.text}" สำเร็จแล้ว'
            : 'เพิ่มบ้าน "${_houseNumberController.text}" สำเร็จแล้ว',
      );
      Navigator.pop(context, result);
    } catch (e) {
      if (!mounted) return;
      _showSnack('เกิดข้อผิดพลาด: $e', isError: true);
      setState(() => _isSaving = false);
    }
  }

  // Helpers
  bool _hasNewImage() => _selectedImage != null || _webImage != null;
  bool _hasCurrentImage() => _currentImageUrl != null && !_removeCurrentImage;
  bool _hasAnyImage() => _hasNewImage() || _hasCurrentImage();

  void _showSnack(String message, {bool isError = false, bool isWarning = false}) {
    if (!mounted) return;
    final bg = isError
        ? ThemeColors.errorRust
        : isWarning
        ? ThemeColors.warningAmber
        : ThemeColors.successGreen;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error : (isWarning ? Icons.warning : Icons.check_circle),
              color: ThemeColors.ivoryWhite,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message, style: TextStyle(color: ThemeColors.ivoryWhite))),
          ],
        ),
        backgroundColor: bg,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.house != null;
    return PopScope(
      canPop: !_hasUnsavedChanges,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
        backgroundColor: ThemeColors.creamWhite,
        appBar: AppBar(
          title: Text(
            isEditing ? 'แก้ไขข้อมูลบ้าน' : 'เพิ่มบ้านใหม่',
            style: TextStyle(
              color: ThemeColors.darkChocolate,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: ThemeColors.ivoryWhite,
          foregroundColor: ThemeColors.darkChocolate,
          elevation: 2,
          shadowColor: ThemeColors.sandyTan.withValues(alpha: 0.3),
          actions: [
            if (_hasUnsavedChanges)
              TextButton(
                onPressed: _resetForm,
                style: TextButton.styleFrom(foregroundColor: ThemeColors.softBrown),
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
                _buildImageSection(),
                const SizedBox(height: 24),
                _buildBasicInfoCard(),
                const SizedBox(height: 24),
                _buildStatusCard(),
                const SizedBox(height: 24),
                _buildOwnershipCard(),
                const SizedBox(height: 24),
                _buildHouseTypeCard(),
                const SizedBox(height: 24),
                _buildUsageStatusCard(),
                const SizedBox(height: 24),
                _buildAdditionalInfoCard(),
                const SizedBox(height: 32),
                _buildActionButtons(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===== UI Sections =====

  Widget _buildImageSection() {
    return _buildCard(
      title: 'รูปภาพบ้าน',
      icon: Icons.photo,
      iconColor: ThemeColors.rustOrange,
      child: Column(
        children: [
          if (_hasNewImage())
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: kIsWeb && _webImage != null
                      ? Image.memory(_webImage!, width: double.infinity, height: 200, fit: BoxFit.cover)
                      : (_selectedImage != null
                      ? Image.file(_selectedImage!, width: double.infinity, height: 200, fit: BoxFit.cover)
                      : Container(width: double.infinity, height: 200, color: ThemeColors.lightTaupe)),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    decoration: BoxDecoration(
                      color: ThemeColors.darkChocolate.withValues(alpha: 0.7),
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
                _cornerTag('รูปใหม่', ThemeColors.successGreen),
              ],
            )
          else if (_hasCurrentImage())
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
                        color: ThemeColors.lightTaupe,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.broken_image, size: 48, color: ThemeColors.dustyBrown),
                            const SizedBox(height: 8),
                            Text(
                              'ไม่สามารถโหลดรูปภาพได้',
                              style: TextStyle(color: ThemeColors.dustyBrown),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                _cornerTag('รูปเดิม', ThemeColors.infoBlue),
              ],
            )
          else
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                color: ThemeColors.beige,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: ThemeColors.softBorder, width: 2),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.home_outlined, size: 64, color: ThemeColors.dustyBrown),
                  const SizedBox(height: 12),
                  Text(
                    'ยังไม่มีรูปภาพบ้าน',
                    style: TextStyle(color: ThemeColors.darkChocolate, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'กดปุ่มด้านล่างเพื่อเพิ่มรูป',
                    style: TextStyle(color: ThemeColors.dustyBrown, fontSize: 14),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: _pickImage,
              icon: Icon(
                _hasAnyImage() ? Icons.edit : Icons.add_photo_alternate,
                color: ThemeColors.softBrown,
              ),
              label: Text(
                _hasAnyImage() ? 'เปลี่ยนรูปภาพ' : 'เพิ่มรูปภาพ',
                style: TextStyle(color: ThemeColors.softBrown),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: ThemeColors.softBrown),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoCard() {
    return _buildCard(
      title: 'ข้อมูลพื้นฐาน',
      icon: Icons.info_outline,
      iconColor: ThemeColors.softBrown,
      child: Column(
        children: [
          TextFormField(
            controller: _houseNumberController,
            decoration: _inputDecoration(
              label: 'หมายเลขบ้าน *',
              hint: 'เช่น 123, A-45',
              icon: Icons.home,
            ),
            autovalidateMode: AutovalidateMode.onUserInteraction,
            validator: (value) => (value == null || value.trim().isEmpty) ? 'กรุณาระบุหมายเลขบ้าน' : null,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _ownerController,
            decoration: _inputDecoration(
              label: 'ชื่อเจ้าของ/ผู้อยู่อาศัย *',
              hint: 'ระบุชื่อเจ้าของบ้าน',
              icon: Icons.person,
            ),
            autovalidateMode: AutovalidateMode.onUserInteraction,
            validator: (value) => (value == null || value.trim().isEmpty) ? 'กรุณาระบุชื่อเจ้าของ' : null,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _phoneController,
            decoration: _inputDecoration(
              label: 'เบอร์โทรศัพท์ *',
              hint: '0812345678',
              icon: Icons.phone,
            ),
            keyboardType: TextInputType.phone,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(15)],
            autovalidateMode: AutovalidateMode.onUserInteraction,
            validator: (value) {
              final v = (value ?? '').trim();
              if (v.isEmpty) return 'กรุณาระบุเบอร์โทรศัพท์';
              if (v.length < 9) return 'กรุณาระบุเบอร์โทรศัพท์ให้ถูกต้อง';
              return null;
            },
            textInputAction: TextInputAction.next,
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalInfoCard() {
    return _buildCard(
      title: 'ข้อมูลเพิ่มเติม',
      icon: Icons.more_horiz,
      iconColor: ThemeColors.dustyBrown,
      child: Column(
        children: [
          TextFormField(
            controller: _sizeController,
            decoration: _inputDecoration(
              label: 'ขนาดบ้าน',
              hint: 'เช่น 150 ตร.ม.',
              icon: Icons.square_foot,
            ),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _usableAreaController,
            decoration: _inputDecoration(
              label: 'พื้นที่ใช้สอย',
              hint: 'เช่น 120 ตร.ม.',
              icon: Icons.space_dashboard,
            ),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _floorsController,
            decoration: _inputDecoration(
              label: 'จำนวนชั้น',
              hint: 'เช่น 2',
              icon: Icons.layers,
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(2)],
            validator: (value) {
              if (value?.trim().isEmpty ?? true) return null;
              final floors = int.tryParse(value!.trim());
              if (floors == null || floors < 1) return 'กรุณาระบุจำนวนชั้นที่ถูกต้อง (1-10)';
              if (floors > 10) return 'จำนวนชั้นไม่ควรเกิน 10 ชั้น';
              return null;
            },
            textInputAction: TextInputAction.done,
          ),
        ],
      ),
    );
  }

  Widget _buildOwnershipCard() => _buildCard(
    title: 'ประเภทความเป็นเจ้าของ',
    icon: Icons.person_outline,
    iconColor: ThemeColors.sageGreen,
    child: _buildGridSelector(
      options: ownershipTypes,
      selectedValue: _selectedOwnershipType,
      onSelect: (value) => setState(() {
        _selectedOwnershipType = value;
        _hasUnsavedChanges = true;
      }),
      validationMessage: 'กรุณาเลือกประเภทความเป็นเจ้าของ',
    ),
  );

  Widget _buildHouseTypeCard() => _buildCard(
    title: 'ประเภทบ้าน',
    icon: Icons.apartment,
    iconColor: ThemeColors.infoBlue,
    child: _buildGridSelector(
      options: houseTypes,
      selectedValue: _selectedHouseType,
      onSelect: (value) => setState(() {
        _selectedHouseType = value;
        _hasUnsavedChanges = true;
      }),
      validationMessage: 'กรุณาเลือกประเภทบ้าน',
    ),
  );

  Widget _buildUsageStatusCard() => _buildCard(
    title: 'สถานะการใช้งาน',
    icon: Icons.settings,
    iconColor: ThemeColors.warningAmber,
    child: _buildGridSelector(
      options: usageStatuses,
      selectedValue: _selectedUsageStatus,
      onSelect: (value) => setState(() {
        _selectedUsageStatus = value;
        _hasUnsavedChanges = true;
      }),
      validationMessage: 'กรุณาเลือกสถานะการใช้งาน',
    ),
  );

  Widget _buildStatusCard() => _buildCard(
    title: 'สถานะบ้าน',
    icon: Icons.home_outlined,
    iconColor: ThemeColors.successGreen,
    child: _buildGridSelector(
      options: houseStatuses,
      selectedValue: _selectedStatus,
      onSelect: (value) => setState(() {
        _selectedStatus = value;
        _hasUnsavedChanges = true;
      }),
      validationMessage: 'กรุณาเลือกสถานะบ้าน',
    ),
  );

  Widget _buildGridSelector({
    required List<Map<String, dynamic>> options,
    required String? selectedValue,
    required void Function(String) onSelect,
    required String validationMessage,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.6,
          ),
          itemCount: options.length,
          itemBuilder: (context, index) {
            final option = options[index];
            final Color color = option['color'] as Color;
            final bool isSelected = selectedValue == option['value'];
            return InkWell(
              onTap: () => onSelect(option['value'] as String),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected ? color.withValues(alpha: 0.15) : ThemeColors.ivoryWhite,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? color : ThemeColors.softBorder,
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: isSelected ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.2),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ] : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      option['icon'] as IconData,
                      color: isSelected ? color : ThemeColors.dustyBrown,
                      size: 24,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      option['label'] as String,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isSelected ? color : ThemeColors.darkChocolate,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        if (selectedValue == null) ...[
          const SizedBox(height: 8),
          Text(
            validationMessage,
            style: TextStyle(color: ThemeColors.errorRust, fontSize: 12),
          ),
        ],
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _isSaving ? null : _saveHouse,
            style: ElevatedButton.styleFrom(
              backgroundColor: ThemeColors.softBrown,
              foregroundColor: ThemeColors.ivoryWhite,
              disabledBackgroundColor: ThemeColors.disabledGrey,
              elevation: 4,
              shadowColor: ThemeColors.softBrown.withValues(alpha: 0.3),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
              widget.house != null ? 'บันทึกการแก้ไข' : 'เพิ่มบ้านใหม่',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: ThemeColors.ivoryWhite,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton(
            onPressed: _isSaving
                ? null
                : () async {
              if (_hasUnsavedChanges) {
                final shouldPop = await _onWillPop();
                if (shouldPop && mounted) Navigator.pop(context);
              } else {
                if (mounted) Navigator.pop(context);
              }
            },
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: ThemeColors.softBorder),
              foregroundColor: ThemeColors.softBrown,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('ยกเลิก'),
          ),
        ),
      ],
    );
  }

  // ===== Small UI utils =====

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: ThemeColors.dustyBrown),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: ThemeColors.softBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: ThemeColors.softBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: ThemeColors.focusedBrown, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: ThemeColors.errorRust),
      ),
      filled: true,
      fillColor: ThemeColors.inputFill,
      labelStyle: TextStyle(color: ThemeColors.dustyBrown),
      hintStyle: TextStyle(color: ThemeColors.dustyBrown.withValues(alpha: 0.7)),
    );
  }

  Widget _iconChip(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color),
    );
  }

  Widget _cornerTag(String text, Color color) {
    return Positioned(
      top: 12,
      left: 12,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          text,
          style: TextStyle(
            color: ThemeColors.ivoryWhite,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // Common card wrapper used across sections
  Widget _buildCard({
    required String title,
    required IconData icon,
    required Widget child,
    Color? iconColor,
  }) {
    return Card(
      elevation: 4,
      shadowColor: ThemeColors.sandyTan.withValues(alpha: 0.3),
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
                    color: (iconColor ?? ThemeColors.softBrown).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: (iconColor ?? ThemeColors.softBrown).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Icon(icon, color: iconColor ?? ThemeColors.softBrown, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: iconColor ?? ThemeColors.softBrown,
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