import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fullproject/domains/vehicle_domain.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class VehicleAddPage extends StatefulWidget {
  final int houseId;

  const VehicleAddPage({
    super.key,
    required this.houseId,
  });

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

  File? _selectedImage;
  bool _isSaving = false;
  bool _hasUnsavedChanges = false;
  String? _selectedVehicleType = 'รถยนต์'; // Default

  final List<Map<String, dynamic>> vehicleTypes = [
    {'type': 'รถยนต์', 'icon': Icons.directions_car, 'color': Colors.blue},
    {
      'type': 'รถจักรยานยนต์',
      'icon': Icons.two_wheeler,
      'color': Colors.orange
    },
    {'type': 'รถบรรทุก', 'icon': Icons.local_shipping, 'color': Colors.green},
    {'type': 'รถตู้', 'icon': Icons.airport_shuttle, 'color': Colors.purple},
    {'type': 'รถสปอร์ต', 'icon': Icons.sports_bar, 'color': Colors.red},
    {'type': 'อื่นๆ', 'icon': Icons.directions_car, 'color': Colors.grey},
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
      builder: (context) =>
          AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.orange[600],
                    size: 28),
                const SizedBox(width: 12),
                const Text('ยืนยันการออก'),
              ],
            ),
            content: const Text(
                'คุณมีการเปลี่ยนแปลงที่ยังไม่ได้บันทึก ต้องการออกหรือไม่?'),
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

  String _formatLicensePlate(String input) {
    // Remove all non-alphanumeric characters
    String cleaned = input.replaceAll(RegExp(r'[^a-zA-Z0-9ก-ฮ]'), '');

    // Format as common Thai license plate patterns
    if (cleaned.length <= 2) {
      return cleaned;
    } else if (cleaned.length <= 4) {
      return '${cleaned.substring(0, 2)} ${cleaned.substring(2)}';
    } else if (cleaned.length <= 6) {
      return '${cleaned.substring(0, 2)} ${cleaned.substring(2, 4)} ${cleaned
          .substring(4)}';
    } else {
      return '${cleaned.substring(0, 2)} ${cleaned.substring(2, 4)} ${cleaned
          .substring(4, 6)}';
    }
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
                    title: const Text(
                        'ลบรูปภาพ', style: TextStyle(color: Colors.red)),
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
      _hasUnsavedChanges = false;
    });
  }

  Future<void> _saveVehicle() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      // Create new vehicle
      await VehicleDomain.create(
        houseId: widget.houseId,
        brand: _brandController.text.trim(),
        model: _modelController.text.trim(),
        number: _numberController.text.trim(),
        img: _selectedImage != null ? 'temp' : null,
      );

      // If there's an image, we need to handle the upload after creation
      // This would typically be done by getting the created vehicle ID and uploading the image
      // For now, we'll create with 'temp' and the image service will handle it

      if (context.mounted) {
        setState(() => _hasUnsavedChanges = false);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('เพิ่มยานพาหนะสำเร็จ'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );

        Navigator.pop(context, true); // ส่ง result กลับ
      }
    } catch (e) {
      if (context.mounted) {
        setState(() => _isSaving = false);
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
          title: const Text('เพิ่มยานพาหนะใหม่'),
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

  Widget _buildImageSection() {
    return _buildCard(
      title: 'รูปภาพยานพาหนะ',
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
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
          ] else
            ...[
              // Placeholder เมื่อไม่มีรูป
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[300]!,
                      width: 2,
                      style: BorderStyle.solid),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _getVehicleIcon(_selectedVehicleType),
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
              icon: Icon(
                _selectedImage != null ? Icons.edit : Icons.add_photo_alternate,
              ),
              label: Text(
                _selectedImage != null ? 'เปลี่ยนรูปภาพ' : 'เพิ่มรูปภาพ',
              ),
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

  Widget _buildVehicleTypeSection() {
    return _buildCard(
      title: 'ประเภทยานพาหนะ',
      icon: Icons.category,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'เลือกประเภทยานพาหนะ *',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
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
                        : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? type['color'] : Colors.grey[300]!,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        type['icon'],
                        color: isSelected ? type['color'] : Colors.grey[600],
                        size: 24,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        type['type'],
                        style: TextStyle(
                          color: isSelected ? type['color'] : Colors.grey[800],
                          fontWeight: isSelected ? FontWeight.bold : FontWeight
                              .normal,
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
            fieldViewBuilder: (context, controller, focusNode,
                onEditingComplete) {
              return TextFormField(
                controller: controller,
                focusNode: focusNode,
                onEditingComplete: onEditingComplete,
                decoration: InputDecoration(
                  labelText: 'ยี่ห้อ *',
                  hintText: 'เช่น Toyota, Honda',
                  prefixIcon: const Icon(Icons.branding_watermark),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (value) =>
                value
                    ?.trim()
                    .isEmpty == true ? 'กรุณาระบุยี่ห้อ' : null,
                textInputAction: TextInputAction.next,
                onChanged: (value) {
                  _brandController.text = value;
                  _onFieldChanged();
                },
              );
            },
          ),

          const SizedBox(height: 16),

          // รุ่น
          TextFormField(
            controller: _modelController,
            decoration: InputDecoration(
              labelText: 'รุ่น *',
              hintText: 'เช่น Corolla, Civic',
              prefixIcon: const Icon(Icons.directions_car),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            validator: (value) =>
            value
                ?.trim()
                .isEmpty == true ? 'กรุณาระบุรุ่น' : null,
            textInputAction: TextInputAction.next,
          ),

          const SizedBox(height: 16),

          // ทะเบียน
          TextFormField(
            controller: _numberController,
            decoration: InputDecoration(
              labelText: 'ทะเบียน',
              hintText: 'เช่น กข 1234',
              prefixIcon: const Icon(Icons.confirmation_number),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.white,
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
            textInputAction: TextInputAction.next,
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
          Row(
            children: [
              // ปี
              Expanded(
                child: TextFormField(
                  controller: _yearController,
                  decoration: InputDecoration(
                    labelText: 'ปี',
                    hintText: 'เช่น 2023',
                    prefixIcon: const Icon(Icons.calendar_today),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                  textInputAction: TextInputAction.next,
                ),
              ),

              const SizedBox(width: 16),

              // สี
              Expanded(
                child: Autocomplete<String>(
                  initialValue: TextEditingValue(text: _colorController.text),
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (textEditingValue.text == '') {
                      return const Iterable<String>.empty();
                    }
                    return popularColors.where((String option) {
                      return option.toLowerCase().contains(textEditingValue.text
                          .toLowerCase());
                    });
                  },
                  onSelected: (String selection) {
                    _colorController.text = selection;
                    _onFieldChanged();
                  },
                  fieldViewBuilder: (context, controller, focusNode,
                      onEditingComplete) {
                    return TextFormField(
                      controller: controller,
                      focusNode: focusNode,
                      onEditingComplete: onEditingComplete,
                      decoration: InputDecoration(
                        labelText: 'สี',
                        hintText: 'เช่น ขาว, ดำ',
                        prefixIcon: const Icon(Icons.palette),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      textInputAction: TextInputAction.next,
                      onChanged: (value) {
                        _colorController.text = value;
                        _onFieldChanged();
                      },
                    );
                  },
                ),
              ),
            ],
          ),
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
          hintText: 'เช่น ข้อมูลการประกัน, การดัดแปลง, หรือข้อมูลอื่นๆ (ไม่บังคับ)',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
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
            onPressed: _isSaving ? null : _saveVehicle,
            style: ElevatedButton.styleFrom(
              backgroundColor: _getVehicleTypeColor(_selectedVehicleType),
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
              'เพิ่มยานพาหนะ',
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