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
  late TextEditingController _ownerController;
  late TextEditingController _phoneController;
  late TextEditingController _floorsController;
  late TextEditingController _usableAreaController;
  late TextEditingController _sizeController;

  // Form values
  String? _status;
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
    _ownerController = TextEditingController(text: widget.house.owner);
    _phoneController = TextEditingController(text: widget.house.phone);
    _floorsController = TextEditingController(text: widget.house.floors?.toString());
    _usableAreaController = TextEditingController(text: widget.house.usableArea);
    _sizeController = TextEditingController(text: widget.house.size);

    _status = widget.house.status;
    _houseType = widget.house.houseType;
    _usageStatus = widget.house.usageStatus ?? 'active';
    _currentImageUrl = widget.house.img;

    // Listen for changes
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
      builder: (context) => AlertDialog(
        title: const Text('ยืนยันการออก'),
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
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('ถ่ายรูป'),
                onTap: () {
                  Navigator.of(context).pop();
                  _getImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('เลือกจากแกลเลอรี่'),
                onTap: () {
                  Navigator.of(context).pop();
                  _getImage(ImageSource.gallery);
                },
              ),
              if (_selectedImage != null || (_currentImageUrl != null && !_removeCurrentImage))
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('ลบรูปภาพ', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.of(context).pop();
                    _removeImage();
                  },
                ),
            ],
          ),
        );
      },
    );
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
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาดในการเลือกรูปภาพ: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
      _ownerController.text = widget.house.owner ?? '';
      _phoneController.text = widget.house.phone ?? '';
      _floorsController.text = widget.house.floors?.toString() ?? '';
      _usableAreaController.text = widget.house.usableArea ?? '';
      _sizeController.text = widget.house.size ?? '';
      _status = widget.house.status;
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

    setState(() => _isSaving = true);

    try {
      String? finalImageUrl;

      // Handle image updates
      if (_selectedImage != null) {
        finalImageUrl = await SupabaseImage().uploadImage(
          imageFile: _selectedImage!,
          tableName: "house",
          rowName: "house_id",
          rowImgName: "img",
          rowKey: widget.house.houseId, bucketPath: '', imgName: '',
        );
      } else if (_removeCurrentImage) {
        finalImageUrl = null;
      } else {
        finalImageUrl = _currentImageUrl;
      }

      final updatedHouse = widget.house.copyWith(
        owner: _ownerController.text.trim(),
        phone: _phoneController.text.trim(),
        status: _status,
        houseType: _houseType,
        floors: int.tryParse(_floorsController.text.trim()),
        usableArea: _usableAreaController.text.trim(),
        usageStatus: _usageStatus,
        size: _sizeController.text.trim(),
        img: finalImageUrl,
      );

      final result = await HouseDomain.update(
        houseId: updatedHouse.houseId,
        updatedHouse: updatedHouse,
      );

      if (mounted) {
        setState(() => _isSaving = false);

        if (result != null) {
          setState(() => _hasUnsavedChanges = false);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('บันทึกข้อมูลสำเร็จ'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context, result);
          }
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('เกิดข้อผิดพลาดในการบันทึก'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('เกิดข้อผิดพลาด: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
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
          title: Text('แก้ไขบ้านเลขที่ ${widget.house.houseNumber}'),
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
                const SizedBox(height: 20),

                // ข้อมูลพื้นฐาน
                _buildBasicInfoSection(),
                const SizedBox(height: 20),

                // รายละเอียดบ้าน
                _buildHouseDetailsSection(),
                const SizedBox(height: 20),

                // สถานะต่างๆ
                _buildStatusSection(),
                const SizedBox(height: 30),

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
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    _selectedImage!,
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
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
              ],
            ),
          ] else if (_currentImageUrl != null && !_removeCurrentImage) ...[
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: BuildImage(
                    imagePath: _currentImageUrl!,
                    tablePath: 'house',
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                    errorWidget: Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Text('ไม่สามารถโหลดรูปภาพได้'),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue,
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
          ],

          const SizedBox(height: 16),

          // ปุ่มเลือกรูป
          InkWell(
            onTap: _pickImage,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              height: 60,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(12),
                color: Colors.white,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _selectedImage != null || (_currentImageUrl != null && !_removeCurrentImage)
                        ? Icons.edit
                        : Icons.add_photo_alternate,
                    color: Colors.blue,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _selectedImage != null || (_currentImageUrl != null && !_removeCurrentImage)
                        ? 'เปลี่ยนรูปภาพ'
                        : 'เพิ่มรูปภาพ',
                    style: const TextStyle(color: Colors.blue),
                  ),
                ],
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
          // เจ้าของบ้าน
          TextFormField(
            controller: _ownerController,
            decoration: const InputDecoration(
              labelText: 'เจ้าของบ้าน *',
              prefixIcon: Icon(Icons.person),
              border: OutlineInputBorder(),
            ),
            validator: (value) =>
            value?.trim().isEmpty == true ? 'กรุณาระบุชื่อเจ้าของ' : null,
          ),
          const SizedBox(height: 16),

          // เบอร์โทร
          TextFormField(
            controller: _phoneController,
            decoration: const InputDecoration(
              labelText: 'เบอร์โทร',
              prefixIcon: Icon(Icons.phone),
              border: OutlineInputBorder(),
              hintText: 'XXX-XXX-XXXX',
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
            decoration: const InputDecoration(
              labelText: 'ประเภทบ้าน',
              prefixIcon: Icon(Icons.apartment),
              border: OutlineInputBorder(),
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
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              // จำนวนชั้น
              Expanded(
                child: TextFormField(
                  controller: _floorsController,
                  decoration: const InputDecoration(
                    labelText: 'จำนวนชั้น',
                    prefixIcon: Icon(Icons.layers),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
              ),
              const SizedBox(width: 16),

              // ขนาด
              Expanded(
                child: TextFormField(
                  controller: _sizeController,
                  decoration: const InputDecoration(
                    labelText: 'ขนาด',
                    prefixIcon: Icon(Icons.square_foot),
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // พื้นที่ใช้สอย
          TextFormField(
            controller: _usableAreaController,
            decoration: const InputDecoration(
              labelText: 'พื้นที่ใช้สอย',
              prefixIcon: Icon(Icons.area_chart),
              border: OutlineInputBorder(),
            ),
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
            decoration: const InputDecoration(
              labelText: 'สถานะบ้าน',
              prefixIcon: Icon(Icons.home_filled),
              border: OutlineInputBorder(),
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
          ),
          const SizedBox(height: 16),

          // สถานะการใช้งาน
          DropdownButtonFormField<String>(
            value: _usageStatus,
            decoration: const InputDecoration(
              labelText: 'สถานะการใช้งาน',
              prefixIcon: Icon(Icons.toggle_on),
              border: OutlineInputBorder(),
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
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
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
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.blue, size: 24),
                const SizedBox(width: 8),
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