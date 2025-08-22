import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fullproject/models/house_model.dart';
import 'package:fullproject/services/auth_service.dart';
import 'package:fullproject/services/image_service.dart';
import 'package:image_picker/image_picker.dart';
import '../../../domains/house_domain.dart';
import 'dart:io';

class HouseCreatePage extends StatefulWidget {
  const HouseCreatePage({super.key});

  @override
  State<HouseCreatePage> createState() => _HouseCreatePageState();
}

class _HouseCreatePageState extends State<HouseCreatePage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _houseNumberController = TextEditingController();
  final _sizeController = TextEditingController();
  final _ownerController = TextEditingController();
  final _phoneController = TextEditingController();
  final _floorsController = TextEditingController();
  final _usableAreaController = TextEditingController();

  // Form values
  String? _status = 'owned';
  String? _houseType = 'detached';
  String? _usageStatus = 'active';
  File? _selectedImage;
  bool _hasUnsavedChanges = false;

  bool _isSubmitting = false;

  // Options for dropdowns
  final List<String> _statusOptions = [
    'owned',
    'vacant',
    'rented',
    'sold'
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
    // Listen for changes
    _houseNumberController.addListener(_onFieldChanged);
    _sizeController.addListener(_onFieldChanged);
    _ownerController.addListener(_onFieldChanged);
    _phoneController.addListener(_onFieldChanged);
    _floorsController.addListener(_onFieldChanged);
    _usableAreaController.addListener(_onFieldChanged);
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
    _sizeController.dispose();
    _ownerController.dispose();
    _phoneController.dispose();
    _floorsController.dispose();
    _usableAreaController.dispose();
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
            Icon(Icons.warning_amber_rounded, color: Colors.orange[600], size: 28),
            const SizedBox(width: 12),
            const Text('ยืนยันการออก'),
          ],
        ),
        content: const Text('คุณมีการเปลี่ยนแปลงที่ยังไม่ได้บันทึก ต้องการออกหรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
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
          decoration: const BoxDecoration(
            color: Colors.white,
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
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                const Text(
                  'เลือกรูปภาพ',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 20),

                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.photo_camera, color: Colors.blue),
                  ),
                  title: const Text('ถ่ายรูป'),
                  subtitle: const Text('ใช้กล้องถ่ายรูปใหม่'),
                  onTap: () => Navigator.pop(context, 'camera'),
                ),

                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.photo_library, color: Colors.green),
                  ),
                  title: const Text('เลือกจากแกลเลอรี่'),
                  subtitle: const Text('เลือกรูปจากคลังภาพ'),
                  onTap: () => Navigator.pop(context, 'gallery'),
                ),

                if (_selectedImage != null)
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.delete, color: Colors.red),
                    ),
                    title: const Text('ลบรูปภาพ', style: TextStyle(color: Colors.red)),
                    subtitle: const Text('ลบรูปภาพปัจจุบัน'),
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
          _hasUnsavedChanges = true;
        });
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('เกิดข้อผิดพลาดในการเลือกรูปภาพ: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
      _hasUnsavedChanges = true;
    });
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
      case 'owned': return 'มีเจ้าของ';
      case 'vacant': return 'ว่าง';
      case 'rented': return 'ให้เช่า';
      case 'sold': return 'ขายแล้ว';
      default: return status ?? '';
    }
  }

  String _getHouseTypeText(String? type) {
    switch (type) {
      case 'detached': return 'บ้านเดี่ยว';
      case 'townhouse': return 'ทาวน์เฮาส์';
      case 'apartment': return 'อพาร์ทเมนต์';
      case 'condo': return 'คอนโดมิเนียม';
      default: return type ?? '';
    }
  }

  String _getUsageStatusText(String? status) {
    switch (status) {
      case 'active': return 'ใช้งาน';
      case 'inactive': return 'ไม่ใช้งาน';
      case 'maintenance': return 'ปรับปรุง';
      default: return status ?? '';
    }
  }

  void _resetForm() {
    setState(() {
      _houseNumberController.clear();
      _sizeController.clear();
      _ownerController.clear();
      _phoneController.clear();
      _floorsController.clear();
      _usableAreaController.clear();
      _status = 'owned';
      _houseType = 'detached';
      _usageStatus = 'active';
      _selectedImage = null;
      _hasUnsavedChanges = false;
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final user = await AuthService.getCurrentUser();
      if (user == null || user.villageId == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.error, color: Colors.white),
                  SizedBox(width: 12),
                  Text('ไม่พบ village id'),
                ],
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      final house = HouseModel(
        houseId: 0, // จะถูกเซ็ตอัตโนมัติโดย Supabase
        villageId: user.villageId,
        userId: 0, // ยังไม่สร้าง user
        houseNumber: _houseNumberController.text.trim(),
        size: _sizeController.text.trim(),
        owner: _ownerController.text.trim(),
        phone: _phoneController.text.trim(),
        status: _status,
        houseType: _houseType,
        floors: int.tryParse(_floorsController.text.trim()),
        usableArea: _usableAreaController.text.trim(),
        usageStatus: _usageStatus,
        img: _selectedImage != null ? 'temp' : null,
      );

      final created = await HouseDomain.create(house: house);

      if (created != null) {
        // Upload image if selected
        if (_selectedImage != null) {
          await SupabaseImage().uploadImage(
            imageFile: _selectedImage!,
            tableName: "house",
            rowName: "house_id",
            rowImgName: "img",
            rowKey: created.houseId, bucketPath: '', imgName: '',
          );
        }

        if (context.mounted) {
          setState(() => _hasUnsavedChanges = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 12),
                  Text('เพิ่มบ้านสำเร็จ'),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.pop(context, created);
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.error, color: Colors.white),
                  SizedBox(width: 12),
                  Text('เกิดข้อผิดพลาดในการเพิ่มบ้าน'),
                ],
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('เกิดข้อผิดพลาด: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }

    setState(() => _isSubmitting = false);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text('เพิ่มลูกบ้าน'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 1,
          actions: [
            if (_hasUnsavedChanges)
              TextButton(
                onPressed: _resetForm,
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
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
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
                      color: Colors.green,
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
          ] else ...[
            // Placeholder เมื่อไม่มีรูป
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[300]!, width: 2, style: BorderStyle.values[1]),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.home,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'ยังไม่มีรูปภาพ',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'กดปุ่มด้านล่างเพื่อเพิ่มรูป',
                    style: TextStyle(
                      color: Colors.grey[500],
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
              icon: Icon(_selectedImage != null ? Icons.edit : Icons.add_photo_alternate),
              label: Text(_selectedImage != null ? 'เปลี่ยนรูปภาพ' : 'เพิ่มรูปภาพ'),
              style: OutlinedButton.styleFrom(
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
      icon: Icons.home,
      child: Column(
        children: [
          // บ้านเลขที่
          TextFormField(
            controller: _houseNumberController,
            decoration: InputDecoration(
              labelText: 'บ้านเลขที่ *',
              hintText: 'ระบุเลขที่บ้าน',
              prefixIcon: const Icon(Icons.home_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            validator: (value) =>
            value?.trim().isEmpty == true ? 'กรุณาระบุบ้านเลขที่' : null,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),

          // เจ้าของบ้าน
          TextFormField(
            controller: _ownerController,
            decoration: InputDecoration(
              labelText: 'เจ้าของบ้าน *',
              hintText: 'ระบุชื่อเจ้าของ',
              prefixIcon: const Icon(Icons.person),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            validator: (value) =>
            value?.trim().isEmpty == true ? 'กรุณาระบุชื่อเจ้าของ' : null,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),

          // เบอร์โทร
          TextFormField(
            controller: _phoneController,
            decoration: InputDecoration(
              labelText: 'เบอร์โทร',
              hintText: 'XXX-XXX-XXXX',
              prefixIcon: const Icon(Icons.phone),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            onChanged: (value) {
              final formatted = _formatPhoneNumber(value);
              if (formatted != value) {
                _phoneController.value = TextEditingValue(
                  text: formatted,
                  selection: TextSelection.collapsed(offset: formatted.length),
                );
              }
            },
            validator: (value) {
              if (value?.isNotEmpty == true) {
                final digits = value!.replaceAll(RegExp(r'[^\d]'), '');
                if (digits.length != 10) {
                  return 'เบอร์โทรต้องมี 10 หลัก';
                }
              }
              return null;
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
              prefixIcon: const Icon(Icons.apartment),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            items: _houseTypeOptions.map((type) {
              return DropdownMenuItem(
                value: type,
                child: Text(_getHouseTypeText(type)),
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
                    hintText: 'เช่น 1, 2',
                    prefixIcon: const Icon(Icons.layers),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
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
                    hintText: 'เช่น 100 ตร.ม.',
                    prefixIcon: const Icon(Icons.square_foot),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
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
              hintText: 'เช่น 80 ตร.ม.',
              prefixIcon: const Icon(Icons.area_chart),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.white,
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
              prefixIcon: const Icon(Icons.home_filled),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            items: _statusOptions.map((status) {
              return DropdownMenuItem(
                value: status,
                child: Text(_getStatusText(status)),
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

          // สถานะการใช้งาน
          DropdownButtonFormField<String>(
            value: _usageStatus,
            decoration: InputDecoration(
              labelText: 'สถานะการใช้งาน *',
              prefixIcon: const Icon(Icons.toggle_on),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            items: _usageStatusOptions.map((status) {
              return DropdownMenuItem(
                value: status,
                child: Text(_getUsageStatusText(status)),
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
            onPressed: _isSubmitting ? null : _submitForm,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isSubmitting
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
              'เพิ่มบ้าน',
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
            onPressed: _isSubmitting
                ? null
                : () async {
              if (_hasUnsavedChanges) {
                final shouldPop = await _onWillPop();
                if (shouldPop && context.mounted) {
                  Navigator.pop(context);
                }
              } else {
                Navigator.pop(context);
              }
            },
            style: OutlinedButton.styleFrom(
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                    color: Colors.blue[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: Colors.blue, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
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