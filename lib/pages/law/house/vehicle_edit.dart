import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fullproject/models/vehicle_model.dart';
import 'package:fullproject/domains/vehicle_domain.dart';
import 'package:fullproject/services/image_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class VehicleManagePage extends StatefulWidget {
  final int houseId;
  const VehicleManagePage({super.key, required this.houseId});

  @override
  State<VehicleManagePage> createState() => _VehicleManagePageState();
}

class _VehicleManagePageState extends State<VehicleManagePage> {
  List<VehicleModel> vehicles = [];
  bool loading = true;
  String searchQuery = '';
  String selectedBrand = 'all';

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
    'อื่นๆ'
  ];

  @override
  void initState() {
    super.initState();
    loadVehicles();
  }

  Future<void> loadVehicles() async {
    setState(() => loading = true);
    try {
      final result = await VehicleDomain.getByHouse(houseId: widget.houseId);
      if (mounted) {
        setState(() {
          vehicles = result;
          loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาดในการโหลดข้อมูล: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<VehicleModel> get filteredVehicles {
    return vehicles.where((vehicle) {
      final matchesSearch = searchQuery.isEmpty ||
          (vehicle.brand?.toLowerCase().contains(searchQuery.toLowerCase()) ?? false) ||
          (vehicle.model?.toLowerCase().contains(searchQuery.toLowerCase()) ?? false) ||
          (vehicle.number?.toLowerCase().contains(searchQuery.toLowerCase()) ?? false);

      final matchesBrand = selectedBrand == 'all' ||
          vehicle.brand?.toLowerCase() == selectedBrand.toLowerCase();

      return matchesSearch && matchesBrand;
    }).toList();
  }

  Future<void> deleteVehicle(VehicleModel vehicle) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ยืนยันการลบ'),
        content: Text('คุณต้องการลบ ${vehicle.brand ?? ''} ${vehicle.model ?? ''} หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('ลบ', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await VehicleDomain.delete(vehicle.vehicleId);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('ลบยานพาหนะสำเร็จ'),
              backgroundColor: Colors.green,
            ),
          );
          loadVehicles();
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('เกิดข้อผิดพลาดในการลบ: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void showVehicleForm({VehicleModel? vehicle}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => VehicleFormSheet(
        houseId: widget.houseId,
        vehicle: vehicle,
        onSaved: () {
          Navigator.pop(context);
          loadVehicles();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = filteredVehicles;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('จัดการยานพาหนะ'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // Search & Filter Section
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                // Search Bar
                TextField(
                  decoration: InputDecoration(
                    hintText: 'ค้นหายี่ห้อ รุ่น หรือทะเบียน...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: searchQuery.isNotEmpty
                        ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() => searchQuery = '');
                      },
                    )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                  onChanged: (value) {
                    setState(() => searchQuery = value);
                  },
                ),
                const SizedBox(height: 12),

                // Brand Filter
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildFilterChip('ทั้งหมด', 'all'),
                      ...popularBrands.map((brand) => _buildFilterChip(brand, brand)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Results Count & Stats
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.white,
            child: Row(
              children: [
                Text(
                  'พบ ${filtered.length} คัน',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                if (vehicles.isNotEmpty)
                  Text(
                    'รวม ${vehicles.length} คันทั้งหมด',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),

          // Vehicles List
          Expanded(
            child: filtered.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
              onRefresh: loadVehicles,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final vehicle = filtered[index];
                  return _buildVehicleCard(vehicle);
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showVehicleForm(),
        icon: const Icon(Icons.add),
        label: const Text('เพิ่มยานพาหนะ'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = selectedBrand == value;
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            selectedBrand = value;
          });
        },
        backgroundColor: Colors.grey[100],
        selectedColor: Colors.blue[100],
        checkmarkColor: Colors.blue[700],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            searchQuery.isNotEmpty || selectedBrand != 'all'
                ? Icons.search_off
                : Icons.directions_car_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            searchQuery.isNotEmpty || selectedBrand != 'all'
                ? 'ไม่พบยานพาหนะที่ค้นหา'
                : 'ยังไม่มียานพาหนะในบ้านนี้',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            searchQuery.isNotEmpty || selectedBrand != 'all'
                ? 'ลองค้นหาด้วยคำอื่น'
                : 'กดปุ่ม + เพื่อเพิ่มยานพาหนะ',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleCard(VehicleModel vehicle) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => showVehicleForm(vehicle: vehicle),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Vehicle Image/Icon
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: vehicle.img != null && vehicle.img!.isNotEmpty
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: BuildImage(
                    imagePath: vehicle.img!,
                    tablePath: 'vehicle',
                    fit: BoxFit.cover,
                    errorWidget: const Icon(
                      Icons.directions_car,
                      size: 30,
                      color: Colors.blue,
                    ),
                  ),
                )
                    : const Icon(
                  Icons.directions_car,
                  size: 30,
                  color: Colors.blue,
                ),
              ),

              const SizedBox(width: 16),

              // Vehicle Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${vehicle.brand ?? ''} ${vehicle.model ?? ''}'.trim(),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (vehicle.number != null && vehicle.number!.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.amber[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.amber[300]!),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.confirmation_number,
                              size: 14,
                              color: Colors.amber,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              vehicle.number!,
                              style: TextStyle(
                                color: Colors.amber[800],
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              // Action Buttons
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () => showVehicleForm(vehicle: vehicle),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => deleteVehicle(vehicle),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class VehicleFormSheet extends StatefulWidget {
  final int houseId;
  final VehicleModel? vehicle;
  final VoidCallback onSaved;

  const VehicleFormSheet({
    super.key,
    required this.houseId,
    this.vehicle,
    required this.onSaved,
  });

  @override
  State<VehicleFormSheet> createState() => _VehicleFormSheetState();
}

class _VehicleFormSheetState extends State<VehicleFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _numberController = TextEditingController();

  File? _selectedImage;
  String? _currentImageUrl;
  bool _removeCurrentImage = false;
  bool _isSaving = false;

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
    'Daihatsu'
  ];

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (widget.vehicle != null) {
      _brandController.text = widget.vehicle!.brand ?? '';
      _modelController.text = widget.vehicle!.model ?? '';
      _numberController.text = widget.vehicle!.number ?? '';
      _currentImageUrl = widget.vehicle!.img;
    }
  }

  @override
  void dispose() {
    _brandController.dispose();
    _modelController.dispose();
    _numberController.dispose();
    super.dispose();
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
    });
  }

  Future<void> _saveVehicle() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      String? finalImageUrl;

      // Handle image updates
      if (_selectedImage != null) {
        if (widget.vehicle != null) {
          // Update existing vehicle
          finalImageUrl = await SupabaseImage().uploadImage(
            imageFile: _selectedImage!,
            tableName: "vehicle",
            rowName: "vehicle_id",
            rowImgName: "img",
            rowKey: widget.vehicle!.vehicleId,
          );
        }
      } else if (_removeCurrentImage) {
        finalImageUrl = null;
      } else {
        finalImageUrl = _currentImageUrl;
      }

      if (widget.vehicle != null) {
        // Update existing vehicle
        await VehicleDomain.update(
          vehicleId: widget.vehicle!.vehicleId,
          brand: _brandController.text.trim(),
          model: _modelController.text.trim(),
          number: _numberController.text.trim(),
          img: finalImageUrl,
        );
      } else {
        // Create new vehicle
        await VehicleDomain.create(
          houseId: widget.houseId,
          brand: _brandController.text.trim(),
          model: _modelController.text.trim(),
          number: _numberController.text.trim(),
          img: _selectedImage != null ? 'temp' : null, // Will be updated after creation
        );
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.vehicle != null ? 'แก้ไขยานพาหนะสำเร็จ' : 'เพิ่มยานพาหนะสำเร็จ'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onSaved();
      }
    } catch (e) {
      if (context.mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
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

          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text(
                  widget.vehicle != null ? 'แก้ไขยานพาหนะ' : 'เพิ่มยานพาหนะใหม่',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),

          const Divider(),

          // Form
          Expanded(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Image Section
                    _buildImageSection(),
                    const SizedBox(height: 20),

                    // Brand Field with Suggestions
                    Autocomplete<String>(
                      initialValue: TextEditingValue(text: _brandController.text),
                      optionsBuilder: (TextEditingValue textEditingValue) {
                        if (textEditingValue.text == '') {
                          return const Iterable<String>.empty();
                        }
                        return popularBrands.where((String option) {
                          return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                        });
                      },
                      onSelected: (String selection) {
                        _brandController.text = selection;
                      },
                      fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                        _brandController.text = controller.text;
                        return TextFormField(
                          controller: controller,
                          focusNode: focusNode,
                          onEditingComplete: onEditingComplete,
                          decoration: const InputDecoration(
                            labelText: 'ยี่ห้อ *',
                            prefixIcon: Icon(Icons.branding_watermark),
                            border: OutlineInputBorder(),
                            hintText: 'เช่น Toyota, Honda',
                          ),
                          validator: (value) =>
                          value?.trim().isEmpty == true ? 'กรุณาระบุยี่ห้อ' : null,
                        );
                      },
                    ),

                    const SizedBox(height: 16),

                    // Model Field
                    TextFormField(
                      controller: _modelController,
                      decoration: const InputDecoration(
                        labelText: 'รุ่น *',
                        prefixIcon: Icon(Icons.directions_car),
                        border: OutlineInputBorder(),
                        hintText: 'เช่น Corolla, Civic',
                      ),
                      validator: (value) =>
                      value?.trim().isEmpty == true ? 'กรุณาระบุรุ่น' : null,
                    ),

                    const SizedBox(height: 16),

                    // License Plate Field
                    TextFormField(
                      controller: _numberController,
                      decoration: const InputDecoration(
                        labelText: 'ทะเบียน',
                        prefixIcon: Icon(Icons.confirmation_number),
                        border: OutlineInputBorder(),
                        hintText: 'เช่น กข 1234',
                      ),
                      onChanged: (value) {
                        final formatted = _formatLicensePlate(value);
                        if (formatted != value) {
                          _numberController.value = TextEditingValue(
                            text: formatted,
                            selection: TextSelection.collapsed(offset: formatted.length),
                          );
                        }
                      },
                    ),

                    const SizedBox(height: 30),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveVehicle,
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
                            : Text(
                          widget.vehicle != null ? 'บันทึกการแก้ไข' : 'เพิ่มยานพาหนะ',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageSection() {
    return Column(
      children: [
        // Display current image
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
                      setState(() => _selectedImage = null);
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
                  tablePath: 'vehicle',
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

        // Image picker button
        InkWell(
          onTap: _pickImage,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            height: 60,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey[50],
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
    );
  }
}