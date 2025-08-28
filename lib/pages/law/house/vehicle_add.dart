import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:fullproject/domains/vehicle_domain.dart';
import 'package:fullproject/theme/Color.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class VehicleAddPage extends StatefulWidget {
  final int houseId;

  const VehicleAddPage({super.key, required this.houseId});

  @override
  State<VehicleAddPage> createState() => _VehicleAddPageState();
}

class _VehicleAddPageState extends State<VehicleAddPage> {
  final _formKey = GlobalKey<FormState>();
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _numberController = TextEditingController();
  final _yearController = TextEditingController();
  final _colorController = TextEditingController();
  final _notesController = TextEditingController();

  // ✨ รองรับทั้ง Web และ Mobile
  File? _selectedImage; // สำหรับ Mobile
  Uint8List? _webImage; // สำหรับ Web
  bool _isSaving = false;
  bool _hasUnsavedChanges = false;
  String? _selectedVehicleType = 'รถยนต์'; // Default

  final List<Map<String, dynamic>> vehicleTypes = [
    {
      'type': 'รถยนต์',
      'icon': Icons.directions_car,
      'color': ThemeColors.softBrown,
    },
    {
      'type': 'รถจักรยานยนต์',
      'icon': Icons.two_wheeler,
      'color': ThemeColors.clayOrange,
    },
    {
      'type': 'รถบรรทุก',
      'icon': Icons.local_shipping,
      'color': ThemeColors.oliveGreen,
    },
    {
      'type': 'รถตู้',
      'icon': Icons.airport_shuttle,
      'color': ThemeColors.softTerracotta,
    },
    {
      'type': 'รถสปอร์ต',
      'icon': Icons.sports_bar,
      'color': ThemeColors.burntOrange,
    },
    {
      'type': 'อื่นๆ',
      'icon': Icons.directions_car,
      'color': ThemeColors.warmAmber,
    },
  ];

  final List<String> popularBrands = [
    'Toyota',
    'Honda',
    'Mazda',
    'Nissan',
    'Mitsubishi',
    'Isuzu',
    'Ford',
    'Chevrolet',
    'BMW',
    'Mercedes-Benz',
    'Audi',
    'Volkswagen',
    'Hyundai',
    'Kia',
    'Subaru',
    'Suzuki',
    'Daihatsu',
    'Yamaha',
    'Kawasaki',
    'Ducati',
    'Harley-Davidson',
  ];

  final List<String> popularColors = [
    'ขาว',
    'ดำ',
    'เงิน',
    'เทา',
    'แดง',
    'น้ำเงิน',
    'เขียว',
    'เหลือง',
    'ทอง',
    'น้ำตาล',
    'ชมพู',
    'ม่วง',
    'ส้ม',
  ];

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // Listen for changes
    _brandController.addListener(_onFieldChanged);
    _modelController.addListener(_onFieldChanged);
    _numberController.addListener(_onFieldChanged);
    _yearController.addListener(_onFieldChanged);
    _colorController.addListener(_onFieldChanged);
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

                if (_hasImage())
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
      _brandController.clear();
      _modelController.clear();
      _numberController.clear();
      _yearController.clear();
      _colorController.clear();
      _notesController.clear();
      _selectedVehicleType = 'รถยนต์';
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
      if (kIsWeb && _webImage != null) {
        imageFile = _webImage;
      } else if (_selectedImage != null) {
        imageFile = _selectedImage;
      }

      // ✨ เรียกใช้ VehicleDomain.create ตามที่มีอยู่
      final createdVehicle = await VehicleDomain.create(
        houseId: widget.houseId,
        brand: _brandController.text.trim(),
        model: _modelController.text.trim(),
        number: _numberController.text.trim(),
        imageFile: imageFile,
      );

      if (!mounted) return;

      setState(() => _hasUnsavedChanges = false);

      if (createdVehicle != null) {
        _showSuccessSnackBar('เพิ่มยานพาหนะ "${createdVehicle}" สำเร็จแล้ว');
      } else {
        _showSuccessSnackBar('เพิ่มยานพาหนะสำเร็จแล้ว');
      }

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

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error, color: ThemeColors.ivoryWhite),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
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

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: ThemeColors.ivoryWhite),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
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

  bool _hasImage() => _selectedImage != null || _webImage != null;

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
            'เพิ่มยานพาหนะใหม่',
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
        color: ThemeColors.ivoryWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ThemeColors.softBorder),
        boxShadow: [
          BoxShadow(
            color: ThemeColors.warmStone.withValues(alpha: 0.1),
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
                  color: _getVehicleTypeColor(
                    _selectedVehicleType,
                  ).withOpacity(0.1),
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
                  color: ThemeColors.earthClay,
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
          // แสดงรูปปัจจุบัน
          if (_hasImage()) ...[
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
                    _getVehicleIcon(_selectedVehicleType),
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
                _hasImage() ? Icons.edit : Icons.add_photo_alternate,
                color: ThemeColors.burntOrange,
              ),
              label: Text(
                _hasImage() ? 'เปลี่ยนรูปภาพ' : 'เพิ่มรูปภาพ',
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
              color: ThemeColors.earthClay,
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
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        type['icon'],
                        color: isSelected
                            ? type['color']
                            : ThemeColors.warmStone,
                        size: 24,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        type['type'],
                        style: TextStyle(
                          color: isSelected
                              ? type['color']
                              : ThemeColors.earthClay,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
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
                  textEditingValue.text.toLowerCase(),
                );
              });
            },
            onSelected: (String selection) {
              _brandController.text = selection;
              _onFieldChanged();
            },
            fieldViewBuilder:
                (context, controller, focusNode, onEditingComplete) {
                  return TextFormField(
                    controller: controller,
                    focusNode: focusNode,
                    onEditingComplete: onEditingComplete,
                    decoration: InputDecoration(
                      labelText: 'ยี่ห้อ *',
                      labelStyle: TextStyle(color: ThemeColors.earthClay),
                      hintText: 'เช่น Toyota, Honda',
                      hintStyle: TextStyle(color: ThemeColors.warmStone),
                      prefixIcon: Icon(
                        Icons.branding_watermark,
                        color: ThemeColors.burntOrange,
                      ),
                      filled: true,
                      fillColor: ThemeColors.inputFill,
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
                        borderSide: BorderSide(
                          color: ThemeColors.clayOrange,
                          width: 2,
                        ),
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
                      color: ThemeColors.ivoryWhite,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: ThemeColors.softBorder),
                    ),
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: options.length,
                      itemBuilder: (context, index) {
                        final option = options.elementAt(index);
                        return ListTile(
                          title: Text(
                            option,
                            style: TextStyle(color: ThemeColors.earthClay),
                          ),
                          onTap: () => onSelected(option),
                          hoverColor: ThemeColors.beige,
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
              labelStyle: TextStyle(color: ThemeColors.earthClay),
              hintText: 'เช่น Camry, Civic',
              hintStyle: TextStyle(color: ThemeColors.warmStone),
              prefixIcon: Icon(
                Icons.model_training,
                color: ThemeColors.burntOrange,
              ),
              filled: true,
              fillColor: ThemeColors.inputFill,
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
              labelStyle: TextStyle(color: ThemeColors.earthClay),
              hintText: 'เช่น กข 1234 กรุงเทพฯ',
              hintStyle: TextStyle(color: ThemeColors.warmStone),
              prefixIcon: Icon(
                Icons.confirmation_number,
                color: ThemeColors.burntOrange,
              ),
              filled: true,
              fillColor: ThemeColors.inputFill,
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
              if (value != null &&
                  value.trim().isNotEmpty &&
                  value.trim().length < 2) {
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
              labelStyle: TextStyle(color: ThemeColors.earthClay),
              hintText: 'เช่น 2023',
              hintStyle: TextStyle(color: ThemeColors.warmStone),
              prefixIcon: Icon(
                Icons.calendar_today,
                color: ThemeColors.burntOrange,
              ),
              filled: true,
              fillColor: ThemeColors.inputFill,
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
                  textEditingValue.text.toLowerCase(),
                );
              });
            },
            onSelected: (String selection) {
              _colorController.text = selection;
              _onFieldChanged();
            },
            fieldViewBuilder:
                (context, controller, focusNode, onEditingComplete) {
                  return TextFormField(
                    controller: controller,
                    focusNode: focusNode,
                    onEditingComplete: onEditingComplete,
                    decoration: InputDecoration(
                      labelText: 'สี',
                      labelStyle: TextStyle(color: ThemeColors.earthClay),
                      hintText: 'เช่น ขาว, ดำ',
                      hintStyle: TextStyle(color: ThemeColors.warmStone),
                      prefixIcon: Icon(
                        Icons.palette,
                        color: ThemeColors.burntOrange,
                      ),
                      filled: true,
                      fillColor: ThemeColors.inputFill,
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
                        borderSide: BorderSide(
                          color: ThemeColors.clayOrange,
                          width: 2,
                        ),
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
                      color: ThemeColors.ivoryWhite,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: ThemeColors.softBorder),
                    ),
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: options.length,
                      itemBuilder: (context, index) {
                        final option = options.elementAt(index);
                        return ListTile(
                          title: Text(
                            option,
                            style: TextStyle(color: ThemeColors.earthClay),
                          ),
                          onTap: () => onSelected(option),
                          hoverColor: ThemeColors.beige,
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
          labelStyle: TextStyle(color: ThemeColors.earthClay),
          hintText: 'ระบุรายละเอียดเพิ่มเติมเกี่ยวกับยานพาหนะ...',
          hintStyle: TextStyle(color: ThemeColors.warmStone),
          prefixIcon: Icon(Icons.edit_note, color: ThemeColors.burntOrange),
          filled: true,
          fillColor: ThemeColors.inputFill,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: ThemeColors.softBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: ThemeColors.focusedBrown, width: 2),
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
              backgroundColor: ThemeColors.softBrown,
              foregroundColor: ThemeColors.ivoryWhite,
              disabledBackgroundColor: ThemeColors.disabledGrey,
              disabledForegroundColor: ThemeColors.warmStone,
              elevation: 2,
              shadowColor: ThemeColors.warmStone.withValues(alpha: 0.5),
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
                          valueColor: AlwaysStoppedAnimation<Color>(
                            ThemeColors.ivoryWhite,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'กำลังบันทึก...',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: ThemeColors.ivoryWhite,
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
                        'บันทึกยานพาหนะ',
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
            onPressed: _isSaving
                ? null
                : () async {
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
              foregroundColor: ThemeColors.earthClay,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.close, size: 18),
                const SizedBox(width: 8),
                const Text('ยกเลิก', style: TextStyle(fontSize: 16)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
