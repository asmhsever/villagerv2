import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:fullproject/domains/vehicle_domain.dart';
import 'package:fullproject/models/vehicle_model.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class VehicleEditPage extends StatefulWidget {
  final VehicleModel vehicle;

  const VehicleEditPage({
    super.key,
    required this.vehicle,
  });

  @override
  State<VehicleEditPage> createState() => _VehicleEditPageState();
}

class _VehicleEditPageState extends State<VehicleEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _numberController = TextEditingController();
  final _yearController = TextEditingController();
  final _colorController = TextEditingController();
  final _notesController = TextEditingController();

  // ✨ รองรับทั้ง Web และ Mobile
  File? _selectedImage;        // สำหรับ Mobile
  Uint8List? _webImage;        // สำหรับ Web
  bool _isSaving = false;
  bool _hasUnsavedChanges = false;
  String? _selectedVehicleType = 'รถยนต์'; // Default
  String? _originalImageUrl;   // เก็บ URL รูปเดิม

  // 🌾 ธีมสีใหม่ - แก้ไข withOpacity เป็น withValues
  static const Color _softBrown = Color(0xFFA47551);
  static const Color _ivoryWhite = Color(0xFFFFFDF6);
  static const Color _beige = Color(0xFFF5F0E1);
  static const Color _earthClay = Color(0xFFBFA18F);
  static const Color _warmStone = Color(0xFFC7B9A5);
  static const Color _oliveGreen = Color(0xFFA3B18A);
  static const Color _burntOrange = Color(0xFFE08E45);
  static const Color _softTerracotta = Color(0xFFD48B5C);
  static const Color _clayOrange = Color(0xFFCC7748);
  static const Color _warmAmber = Color(0xFFDA9856);
  static const Color _softerBurntOrange = Color(0xFFDB8142);
  static const Color _softBorder = Color(0xFFD0C4B0);
  static const Color _focusedBrown = Color(0xFF916846);
  static const Color _inputFill = Color(0xFFFBF9F3);
  static const Color _disabledGrey = Color(0xFFDCDCDC);

  final List<Map<String, dynamic>> vehicleTypes = [
    {'type': 'รถยนต์', 'icon': Icons.directions_car, 'color': _softBrown},
    {'type': 'รถจักรยานยนต์', 'icon': Icons.two_wheeler, 'color': _clayOrange},
    {'type': 'รถบรรทุก', 'icon': Icons.local_shipping, 'color': _oliveGreen},
    {'type': 'รถตู้', 'icon': Icons.airport_shuttle, 'color': _softTerracotta},
    {'type': 'รถสปอร์ต', 'icon': Icons.sports_bar, 'color': _burntOrange},
    {'type': 'อื่นๆ', 'icon': Icons.directions_car, 'color': _warmAmber},
  ];

  final List<String> popularBrands = [
    'Toyota', 'Honda', 'Mazda', 'Nissan', 'Mitsubishi', 'Isuzu',
    'Ford', 'Chevrolet', 'BMW', 'Mercedes-Benz', 'Audi', 'Volkswagen',
    'Hyundai', 'Kia', 'Subaru', 'Suzuki', 'Daihatsu', 'Yamaha',
    'Kawasaki', 'Ducati', 'Harley-Davidson'
  ];

  final List<String> popularColors = [
    'ขาว', 'ดำ', 'เงิน', 'เทา', 'แดง', 'น้ำเงิน', 'เขียว', 'เหลือง',
    'ทอง', 'น้ำตาล', 'ชมพู', 'ม่วง', 'ส้ม'
  ];

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadVehicleData();

    // Listen for changes
    _brandController.addListener(_onFieldChanged);
    _modelController.addListener(_onFieldChanged);
    _numberController.addListener(_onFieldChanged);
    _yearController.addListener(_onFieldChanged);
    _colorController.addListener(_onFieldChanged);
    _notesController.addListener(_onFieldChanged);
  }

  void _loadVehicleData() {
    // โหลดข้อมูลยานพาหนะเดิมลงในฟอร์ม - ใช้ properties จาก VehicleModel
    _brandController.text = widget.vehicle.brand ?? '';
    _modelController.text = widget.vehicle.model ?? '';
    _numberController.text = widget.vehicle.number ?? '';

    // VehicleModel ไม่มี year, color, notes, type fields ดังนั้นใช้ค่า default
    _yearController.text = '';
    _colorController.text = '';
    _notesController.text = '';
    _selectedVehicleType = 'รถยนต์'; // default

    // สำหรับ imageUrl - ใช้ img field จาก VehicleModel
    _originalImageUrl = widget.vehicle.img;
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
    _brandController.dispose();
    _modelController.dispose();
    _numberController.dispose();
    _yearController.dispose();
    _colorController.dispose();
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
            Icon(Icons.warning_amber_rounded, color: _warmAmber, size: 28),
            const SizedBox(width: 12),
            Text(
              'ยืนยันการออก',
              style: TextStyle(color: _earthClay),
            ),
          ],
        ),
        content: Text(
          'คุณมีการเปลี่ยนแปลงที่ยังไม่ได้บันทึก ต้องการออกหรือไม่?',
          style: TextStyle(color: _earthClay),
        ),
        backgroundColor: _ivoryWhite,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(foregroundColor: _warmStone),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: _clayOrange),
            child: const Text('ออก'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  String _formatLicensePlate(String input) {
    // Remove all non-alphanumeric characters
    String cleaned = input.replaceAll(RegExp(r'[^a-zA-Z0-9ก-ฮ]'), '');

    // Format as common Thai license plate patterns
    if (cleaned.length <= 2) {
      return cleaned;
    } else if (cleaned.length <= 4) {
      return '${cleaned.substring(0, 2)} ${cleaned.substring(2)}';
    } else if (cleaned.length <= 6) {
      return '${cleaned.substring(0, 2)} ${cleaned.substring(2, 4)} ${cleaned.substring(4)}';
    } else {
      return '${cleaned.substring(0, 2)} ${cleaned.substring(2, 4)} ${cleaned.substring(4, 6)}';
    }
  }

  Future<void> _pickImage() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: _ivoryWhite,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: _warmStone.withValues(alpha: 0.3),
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
                    color: _softBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                Text(
                  'เลือกรูปภาพ',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _softBrown,
                  ),
                ),

                const SizedBox(height: 20),

                // ✨ แสดงปุ่มถ่ายรูปเฉพาะบน Mobile
                if (!kIsWeb) ...[
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _oliveGreen.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.photo_camera, color: _oliveGreen),
                    ),
                    title: Text('ถ่ายรูป', style: TextStyle(color: _earthClay)),
                    subtitle: Text('ใช้กล้องถ่ายรูปใหม่', style: TextStyle(color: _warmStone)),
                    onTap: () => Navigator.pop(context, 'camera'),
                  ),
                ],

                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _burntOrange.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.photo_library, color: _burntOrange),
                  ),
                  title: Text(
                    kIsWeb ? 'เลือกรูปภาพ' : 'เลือกจากแกลเลอรี่',
                    style: TextStyle(color: _earthClay),
                  ),
                  subtitle: Text(
                    kIsWeb ? 'เลือกรูปจากเครื่อง' : 'เลือกรูปจากคลังภาพ',
                    style: TextStyle(color: _warmStone),
                  ),
                  onTap: () => Navigator.pop(context, 'gallery'),
                ),

                if (_hasImage())
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _clayOrange.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.delete, color: _clayOrange),
                    ),
                    title: Text('ลบรูปภาพ', style: TextStyle(color: _clayOrange)),
                    subtitle: Text('ลบรูปภาพปัจจุบัน', style: TextStyle(color: _warmStone)),
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
                Icon(Icons.error, color: _ivoryWhite),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'เกิดข้อผิดพลาดในการเลือกรูปภาพ: $e',
                    style: TextStyle(color: _ivoryWhite),
                  ),
                ),
              ],
            ),
            backgroundColor: _clayOrange,
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
      // ไม่ต้องเคลียร์ _originalImageUrl เพราะจะทำให้ _hasImage() return false
      _hasUnsavedChanges = true;
    });
  }

  void _resetForm() {
    setState(() {
      _loadVehicleData(); // โหลดข้อมูลเดิมกลับมา
      _selectedImage = null;
      _webImage = null;
      _hasUnsavedChanges = false;
    });
  }

  Future<void> _saveVehicle() async {
    if (!_formKey.currentState!.validate()) return;

    // ✅ เพิ่ม validation เพิ่มเติม
    if (_brandController.text.trim().isEmpty) {
      _showErrorSnackBar('กรุณาระบุยี่ห้อยานพาหนะ');
      return;
    }

    if (_modelController.text.trim().isEmpty) {
      _showErrorSnackBar('กรุณาระบุรุ่นยานพาหนะ');
      return;
    }

    setState(() => _isSaving = true);

    try {
      // ✨ เตรียมข้อมูลรูปภาพ - รองรับทั้ง Web และ Mobile
      dynamic imageFile;
      bool removeImage = false;

      if (_selectedImage != null || _webImage != null) {
        // มีรูปใหม่
        imageFile = kIsWeb ? _webImage : _selectedImage;
      } else if (_isImageRemoved()) {
        // ลบรูปเดิม
        removeImage = true;
      }

      // ✨ เรียกใช้ VehicleDomain.update ตาม method signature ที่มี
      await VehicleDomain.update(
        vehicleId: widget.vehicle.vehicleId,
        brand: _brandController.text.trim(),
        model: _modelController.text.trim(),
        number: _numberController.text.trim(),
        imageFile: imageFile,
        removeImage: removeImage,
      );

      if (!mounted) return;

      setState(() => _hasUnsavedChanges = false);
      _showSuccessSnackBar('อัปเดตยานพาหนะ "${widget.vehicle.displayName}" สำเร็จแล้ว');
      Navigator.pop(context, true); // ส่ง result กลับ
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackBar('เกิดข้อผิดพลาด: $e');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _deleteVehicle() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.delete_forever, color: _clayOrange, size: 28),
            const SizedBox(width: 12),
            Text(
              'ยืนยันการลบ',
              style: TextStyle(color: _earthClay),
            ),
          ],
        ),
        content: Text(
          'คุณต้องการลบยานพาหนะ "${widget.vehicle.displayName}" หรือไม่?\n\nการกระทำนี้ไม่สามารถย้อนกลับได้',
          style: TextStyle(color: _earthClay),
        ),
        backgroundColor: _ivoryWhite,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(foregroundColor: _warmStone),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: _clayOrange),
            child: const Text('ลบ'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isSaving = true);

    try {
      await VehicleDomain.delete(widget.vehicle.vehicleId);

      if (!mounted) return;

      _showSuccessSnackBar('ลบยานพาหนะ "${widget.vehicle.displayName}" สำเร็จแล้ว');
      Navigator.pop(context, 'deleted'); // ส่ง special result เพื่อบอกว่าลบแล้ว
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackBar('เกิดข้อผิดพลาดในการลบ: $e');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error, color: _ivoryWhite),
            const SizedBox(width: 12),
            Expanded(
              child: Text(message, style: TextStyle(color: _ivoryWhite)),
            ),
          ],
        ),
        backgroundColor: _clayOrange,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: _ivoryWhite),
            const SizedBox(width: 12),
            Expanded(
              child: Text(message, style: TextStyle(color: _ivoryWhite)),
            ),
          ],
        ),
        backgroundColor: _oliveGreen,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Color _getVehicleTypeColor(String? type) {
    final vehicleType = vehicleTypes.firstWhere(
          (element) => element['type'] == type,
      orElse: () => vehicleTypes.first,
    );
    return vehicleType['color'];
  }

  IconData _getVehicleIcon(String? type) {
    final vehicleType = vehicleTypes.firstWhere(
          (element) => element['type'] == type,
      orElse: () => vehicleTypes.first,
    );
    return vehicleType['icon'];
  }

  bool _hasImage() {
    // มีรูปใหม่
    if (_selectedImage != null || _webImage != null) return true;
    // มีรูปเดิม
    if (_originalImageUrl != null && _originalImageUrl!.isNotEmpty) return true;
    return false;
  }

  bool _isImageRemoved() {
    // รูปเดิมมีอยู่แต่ไม่มีรูปใหม่และไม่ได้แสดงรูปเดิม
    return _originalImageUrl != null &&
        _originalImageUrl!.isNotEmpty &&
        _selectedImage == null &&
        _webImage == null;
  }

  Widget _getCurrentImage() {
    if (kIsWeb && _webImage != null) {
      return Image.memory(
        _webImage!,
        width: double.infinity,
        height: 200,
        fit: BoxFit.cover,
      );
    } else if (_selectedImage != null) {
      return Image.file(
        _selectedImage!,
        width: double.infinity,
        height: 200,
        fit: BoxFit.cover,
      );
    } else if (_originalImageUrl != null && _originalImageUrl!.isNotEmpty) {
      return Image.network(
        _originalImageUrl!,
        width: double.infinity,
        height: 200,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: double.infinity,
            height: 200,
            color: _warmStone,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, color: _ivoryWhite, size: 48),
                const SizedBox(height: 8),
                Text(
                  'ไม่สามารถโหลดรูปภาพได้',
                  style: TextStyle(color: _ivoryWhite),
                ),
              ],
            ),
          );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: double.infinity,
            height: 200,
            color: _inputFill,
            child: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(_softBrown),
              ),
            ),
          );
        },
      );
    } else {
      return Container(
        width: double.infinity,
        height: 200,
        color: _warmStone,
      );
    }
  }

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
        backgroundColor: _beige,
        appBar: AppBar(
          title: Text(
            'แก้ไขยานพาหนะ',
            style: TextStyle(
              color: _ivoryWhite,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: _softBrown,
          foregroundColor: _ivoryWhite,
          elevation: 2,
          shadowColor: _warmStone.withValues(alpha: 0.5),
          actions: [
            // ปุ่มลบ
            IconButton(
              onPressed: _isSaving ? null : _deleteVehicle,
              icon: const Icon(Icons.delete),
              tooltip: 'ลบยานพาหนะ',
            ),
            if (_hasUnsavedChanges)
              TextButton(
                onPressed: _resetForm,
                style: TextButton.styleFrom(foregroundColor: _ivoryWhite),
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
                // รูปภาพยานพาหนะ
                _buildImageSection(),
                const SizedBox(height: 24),

                // ประเภทยานพาหนะ
                _buildVehicleTypeSection(),
                const SizedBox(height: 24),

                // ข้อมูลพื้นฐาน
                _buildBasicInfoSection(),
                const SizedBox(height: 24),

                // ข้อมูลเพิ่มเติม
                _buildAdditionalInfoSection(),
                const SizedBox(height: 24),

                // หมายเหตุ
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

  Widget _buildCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _ivoryWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _softBorder),
        boxShadow: [
          BoxShadow(
            color: _warmStone.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getVehicleTypeColor(_selectedVehicleType).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: _getVehicleTypeColor(_selectedVehicleType),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _earthClay,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildImageSection() {
    return _buildCard(
      title: 'รูปภาพยานพาหนะ',
      icon: Icons.image,
      child: Column(
        children: [
          // แสดงรูปปัจจุบัน (รูปใหม่หรือรูปเดิม)
          if (_hasImage() && !_isImageRemoved()) ...[
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: _getCurrentImage(),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    decoration: BoxDecoration(
                      color: _earthClay.withValues(alpha: 0.8),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(Icons.close, color: _ivoryWhite),
                      onPressed: () {
                        _removeImage();
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
                      color: _selectedImage != null || _webImage != null
                          ? _softerBurntOrange
                          : _oliveGreen,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _selectedImage != null || _webImage != null ? 'รูปใหม่' : 'รูปเดิม',
                      style: TextStyle(color: _ivoryWhite, fontSize: 12),
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
                color: _inputFill,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _softBorder, width: 2),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _getVehicleIcon(_selectedVehicleType),
                    size: 64,
                    color: _warmStone,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'ไม่มีรูปภาพ',
                    style: TextStyle(
                      color: _earthClay,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'กดปุ่มด้านล่างเพื่อเพิ่มรูป',
                    style: TextStyle(
                      color: _warmStone,
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
                _hasImage() ? Icons.edit : Icons.add_photo_alternate,
                color: _burntOrange,
              ),
              label: Text(
                _hasImage() ? 'เปลี่ยนรูปภาพ' : 'เพิ่มรูปภาพ',
                style: TextStyle(color: _earthClay),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: _softBorder),
                backgroundColor: _ivoryWhite,
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

  Widget _buildVehicleTypeSection() {
    return _buildCard(
      title: 'ประเภทยานพาหนะ',
      icon: Icons.category,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'เลือกประเภทยานพาหนะ *',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: _earthClay,
            ),
          ),
          const SizedBox(height: 16),

          // Grid ของประเภทยานพาหนะ
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2.5,
            ),
            itemCount: vehicleTypes.length,
            itemBuilder: (context, index) {
              final type = vehicleTypes[index];
              final isSelected = _selectedVehicleType == type['type'];

              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedVehicleType = type['type'];
                    _hasUnsavedChanges = true;
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected ? type['color'].withValues(alpha: 0.1) : _ivoryWhite,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? type['color'] : _softBorder,
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected ? [
                      BoxShadow(
                        color: type['color'].withValues(alpha: 0.2),
                        spreadRadius: 1,
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ] : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        type['icon'],
                        color: isSelected ? type['color'] : _warmStone,
                        size: 24,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        type['type'],
                        style: TextStyle(
                          color: isSelected ? type['color'] : _earthClay,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return _buildCard(
      title: 'ข้อมูลพื้นฐาน',
      icon: Icons.directions_car,
      child: Column(
        children: [
          // ยี่ห้อ
          Autocomplete<String>(
            initialValue: TextEditingValue(text: _brandController.text),
            optionsBuilder: (TextEditingValue textEditingValue) {
              if (textEditingValue.text == '') {
                return const Iterable<String>.empty();
              }
              return popularBrands.where((String option) {
                return option.toLowerCase().contains(
                    textEditingValue.text.toLowerCase());
              });
            },
            onSelected: (String selection) {
              _brandController.text = selection;
              _onFieldChanged();
            },
            fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
              return TextFormField(
                controller: controller,
                focusNode: focusNode,
                onEditingComplete: onEditingComplete,
                decoration: InputDecoration(
                  labelText: 'ยี่ห้อ *',
                  labelStyle: TextStyle(color: _earthClay),
                  hintText: 'เช่น Toyota, Honda',
                  hintStyle: TextStyle(color: _warmStone),
                  prefixIcon: Icon(Icons.branding_watermark, color: _burntOrange),
                  filled: true,
                  fillColor: _inputFill,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: _softBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: _focusedBrown, width: 2),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: _clayOrange),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: _clayOrange, width: 2),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'กรุณาใส่ยี่ห้อยานพาหนะ';
                  }
                  return null;
                },
                onChanged: (value) => _onFieldChanged(),
              );
            },
            optionsViewBuilder: (context, onSelected, options) {
              return Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: MediaQuery.of(context).size.width - 32,
                    constraints: const BoxConstraints(maxHeight: 200),
                    decoration: BoxDecoration(
                      color: _ivoryWhite,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _softBorder),
                    ),
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: options.length,
                      itemBuilder: (context, index) {
                        final option = options.elementAt(index);
                        return ListTile(
                          title: Text(option, style: TextStyle(color: _earthClay)),
                          onTap: () => onSelected(option),
                          hoverColor: _beige,
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 16),

          // รุ่น
          TextFormField(
            controller: _modelController,
            decoration: InputDecoration(
              labelText: 'รุ่น *',
              labelStyle: TextStyle(color: _earthClay),
              hintText: 'เช่น Camry, Civic',
              hintStyle: TextStyle(color: _warmStone),
              prefixIcon: Icon(Icons.model_training, color: _burntOrange),
              filled: true,
              fillColor: _inputFill,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: _softBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: _focusedBrown, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: _clayOrange),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: _clayOrange, width: 2),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'กรุณาใส่รุ่นยานพาหนะ';
              }
              return null;
            },
            onChanged: (value) => _onFieldChanged(),
          ),

          const SizedBox(height: 16),

          // หมายเลขทะเบียน
          TextFormField(
            controller: _numberController,
            decoration: InputDecoration(
              labelText: 'หมายเลขทะเบียน',
              labelStyle: TextStyle(color: _earthClay),
              hintText: 'เช่น กข 1234 กรุงเทพฯ',
              hintStyle: TextStyle(color: _warmStone),
              prefixIcon: Icon(Icons.confirmation_number, color: _burntOrange),
              filled: true,
              fillColor: _inputFill,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: _softBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: _focusedBrown, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: _clayOrange),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: _clayOrange, width: 2),
              ),
            ),
            onChanged: (value) {
              final formatted = _formatLicensePlate(value);
              if (formatted != value) {
                _numberController.value = TextEditingValue(
                  text: formatted,
                  selection: TextSelection.collapsed(offset: formatted.length),
                );
              }
              _onFieldChanged();
            },
            validator: (value) {
              if (value != null && value.trim().isNotEmpty && value.trim().length < 2) {
                return 'หมายเลขทะเบียนต้องมีอย่างน้อย 2 ตัวอักษร';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalInfoSection() {
    return _buildCard(
      title: 'ข้อมูลเพิ่มเติม',
      icon: Icons.info_outline,
      child: Column(
        children: [
          // ปี
          TextFormField(
            controller: _yearController,
            decoration: InputDecoration(
              labelText: 'ปี',
              labelStyle: TextStyle(color: _earthClay),
              hintText: 'เช่น 2023',
              hintStyle: TextStyle(color: _warmStone),
              prefixIcon: Icon(Icons.calendar_today, color: _burntOrange),
              filled: true,
              fillColor: _inputFill,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: _softBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: _focusedBrown, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: _clayOrange),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: _clayOrange, width: 2),
              ),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(4),
            ],
            validator: (value) {
              if (value != null && value.isNotEmpty) {
                final year = int.tryParse(value);
                final currentYear = DateTime.now().year;
                if (year == null || year < 1900 || year > currentYear + 1) {
                  return 'กรุณาใส่ปีที่ถูกต้อง (1900-${currentYear + 1})';
                }
              }
              return null;
            },
            onChanged: (value) => _onFieldChanged(),
          ),

          const SizedBox(height: 16),

          // สี
          Autocomplete<String>(
            initialValue: TextEditingValue(text: _colorController.text),
            optionsBuilder: (TextEditingValue textEditingValue) {
              if (textEditingValue.text == '') {
                return popularColors;
              }
              return popularColors.where((String option) {
                return option.toLowerCase().contains(
                    textEditingValue.text.toLowerCase());
              });
            },
            onSelected: (String selection) {
              _colorController.text = selection;
              _onFieldChanged();
            },
            fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
              return TextFormField(
                controller: controller,
                focusNode: focusNode,
                onEditingComplete: onEditingComplete,
                decoration: InputDecoration(
                  labelText: 'สี',
                  labelStyle: TextStyle(color: _earthClay),
                  hintText: 'เช่น ขาว, ดำ',
                  hintStyle: TextStyle(color: _warmStone),
                  prefixIcon: Icon(Icons.palette, color: _burntOrange),
                  filled: true,
                  fillColor: _inputFill,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: _softBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: _focusedBrown, width: 2),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: _clayOrange),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: _clayOrange, width: 2),
                  ),
                ),
                onChanged: (value) => _onFieldChanged(),
              );
            },
            optionsViewBuilder: (context, onSelected, options) {
              return Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: MediaQuery.of(context).size.width - 32,
                    constraints: const BoxConstraints(maxHeight: 200),
                    decoration: BoxDecoration(
                      color: _ivoryWhite,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _softBorder),
                    ),
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: options.length,
                      itemBuilder: (context, index) {
                        final option = options.elementAt(index);
                        return ListTile(
                          title: Text(option, style: TextStyle(color: _earthClay)),
                          onTap: () => onSelected(option),
                          hoverColor: _beige,
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNotesSection() {
    return _buildCard(
      title: 'หมายเหตุ',
      icon: Icons.note,
      child: TextFormField(
        controller: _notesController,
        decoration: InputDecoration(
          labelText: 'หมายเหตุเพิ่มเติม',
          labelStyle: TextStyle(color: _earthClay),
          hintText: 'ระบุรายละเอียดเพิ่มเติมเกี่ยวกับยานพาหนะ...',
          hintStyle: TextStyle(color: _warmStone),
          prefixIcon: Icon(Icons.edit_note, color: _burntOrange),
          filled: true,
          fillColor: _inputFill,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: _softBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: _focusedBrown, width: 2),
          ),
          alignLabelWithHint: true,
        ),
        maxLines: 3,
        onChanged: (value) => _onFieldChanged(),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // ปุ่มบันทึก
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isSaving ? null : _saveVehicle,
            style: ElevatedButton.styleFrom(
              backgroundColor: _softBrown,
              foregroundColor: _ivoryWhite,
              disabledBackgroundColor: _disabledGrey,
              disabledForegroundColor: _warmStone,
              elevation: 2,
              shadowColor: _warmStone.withValues(alpha: 0.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
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
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(_ivoryWhite),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'กำลังบันทึก...',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _ivoryWhite,
                  ),
                ),
              ],
            )
                : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.save, size: 20),
                const SizedBox(width: 8),
                Text(
                  'บันทึกการเปลี่ยนแปลง',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        // ปุ่มยกเลิก
        SizedBox(
          width: double.infinity,
          height: 48,
          child: TextButton(
            onPressed: _isSaving ? null : () async {
              if (_hasUnsavedChanges) {
                final shouldExit = await _onWillPop();
                if (shouldExit && mounted) {
                  Navigator.of(context).pop();
                }
              } else {
                Navigator.of(context).pop();
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: _earthClay,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.close, size: 18),
                const SizedBox(width: 8),
                const Text(
                  'ยกเลิก',
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}