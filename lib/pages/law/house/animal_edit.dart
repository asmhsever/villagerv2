import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fullproject/models/animal_model.dart';
import 'package:fullproject/domains/animal_domain.dart';
import 'package:fullproject/services/image_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class AnimalManagePage extends StatefulWidget {
  final int houseId;
  const AnimalManagePage({super.key, required this.houseId});

  @override
  State<AnimalManagePage> createState() => _AnimalManagePageState();
}

class _AnimalManagePageState extends State<AnimalManagePage> {
  List<AnimalModel> animals = [];
  bool loading = true;
  String searchQuery = '';
  String selectedType = 'all';

  final List<String> animalTypes = [
    'สุนัข',
    'แมว',
    'นก',
    'ปลา',
    'กระต่าย',
    'หนู',
    'อื่นๆ'
  ];

  @override
  void initState() {
    super.initState();
    loadAnimals();
  }

  Future<void> loadAnimals() async {
    setState(() => loading = true);
    try {
      final result = await AnimalDomain.getByHouse(houseId: widget.houseId);
      if (mounted) {
        setState(() {
          animals = result;
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

  List<AnimalModel> get filteredAnimals {
    return animals.where((animal) {
      final matchesSearch = searchQuery.isEmpty ||
          (animal.name?.toLowerCase().contains(searchQuery.toLowerCase()) ?? false) ||
          (animal.type?.toLowerCase().contains(searchQuery.toLowerCase()) ?? false);

      final matchesType = selectedType == 'all' ||
          animal.type?.toLowerCase() == selectedType.toLowerCase();

      return matchesSearch && matchesType;
    }).toList();
  }

  Future<void> deleteAnimal(AnimalModel animal) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ยืนยันการลบ'),
        content: Text('คุณต้องการลบ ${animal.name ?? 'สัตว์เลี้ยง'} หรือไม่?'),
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
        await AnimalDomain.delete(animal.animalId);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('ลบสัตว์เลี้ยงสำเร็จ'),
              backgroundColor: Colors.green,
            ),
          );
          loadAnimals();
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

  void showAnimalForm({AnimalModel? animal}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AnimalFormSheet(
        houseId: widget.houseId,
        animal: animal,
        onSaved: () {
          Navigator.pop(context);
          loadAnimals();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = filteredAnimals;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('จัดการสัตว์เลี้ยง'),
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
                    hintText: 'ค้นหาชื่อหรือประเภทสัตว์เลี้ยง...',
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

                // Type Filter
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildFilterChip('ทั้งหมด', 'all'),
                      ...animalTypes.map((type) => _buildFilterChip(type, type)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Results Count
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.white,
            child: Row(
              children: [
                Text(
                  'พบ ${filtered.length} รายการ',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // Animals List
          Expanded(
            child: filtered.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
              onRefresh: loadAnimals,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final animal = filtered[index];
                  return _buildAnimalCard(animal);
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showAnimalForm(),
        icon: const Icon(Icons.add),
        label: const Text('เพิ่มสัตว์เลี้ยง'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = selectedType == value;
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            selectedType = value;
          });
        },
        backgroundColor: Colors.grey[100],
        selectedColor: Colors.green[100],
        checkmarkColor: Colors.green[700],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            searchQuery.isNotEmpty || selectedType != 'all'
                ? Icons.search_off
                : Icons.pets_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            searchQuery.isNotEmpty || selectedType != 'all'
                ? 'ไม่พบสัตว์เลี้ยงที่ค้นหา'
                : 'ยังไม่มีสัตว์เลี้ยงในบ้านนี้',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            searchQuery.isNotEmpty || selectedType != 'all'
                ? 'ลองค้นหาด้วยคำอื่น'
                : 'กดปุ่ม + เพื่อเพิ่มสัตว์เลี้ยง',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimalCard(AnimalModel animal) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => showAnimalForm(animal: animal),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Animal Image/Icon
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: _getAnimalTypeColor(animal.type).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: animal.img != null && animal.img!.isNotEmpty
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: BuildImage(
                    imagePath: animal.img!,
                    tablePath: 'animal',
                    fit: BoxFit.cover,
                    errorWidget: Icon(
                      _getAnimalIcon(animal.type),
                      size: 30,
                      color: _getAnimalTypeColor(animal.type),
                    ),
                  ),
                )
                    : Icon(
                  _getAnimalIcon(animal.type),
                  size: 30,
                  color: _getAnimalTypeColor(animal.type),
                ),
              ),

              const SizedBox(width: 16),

              // Animal Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      animal.name ?? 'ไม่มีชื่อ',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          _getAnimalIcon(animal.type),
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          animal.type ?? 'ไม่ระบุประเภท',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
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
                    onPressed: () => showAnimalForm(animal: animal),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => deleteAnimal(animal),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getAnimalIcon(String? type) {
    switch (type?.toLowerCase()) {
      case 'สุนัข':
      case 'dog':
        return Icons.pets;
      case 'แมว':
      case 'cat':
        return Icons.pets;
      case 'นก':
      case 'bird':
        return Icons.flutter_dash;
      case 'ปลา':
      case 'fish':
        return Icons.set_meal;
      case 'กระต่าย':
      case 'rabbit':
        return Icons.cruelty_free;
      case 'หนู':
      case 'mouse':
        return Icons.mouse;
      default:
        return Icons.pets;
    }
  }

  Color _getAnimalTypeColor(String? type) {
    switch (type?.toLowerCase()) {
      case 'สุนัข':
      case 'dog':
        return Colors.brown;
      case 'แมว':
      case 'cat':
        return Colors.purple;
      case 'นก':
      case 'bird':
        return Colors.blue;
      case 'ปลา':
      case 'fish':
        return Colors.cyan;
      case 'กระต่าย':
      case 'rabbit':
        return Colors.pink;
      case 'หนู':
      case 'mouse':
        return Colors.grey;
      default:
        return Colors.orange;
    }
  }
}

class AnimalFormSheet extends StatefulWidget {
  final int houseId;
  final AnimalModel? animal;
  final VoidCallback onSaved;

  const AnimalFormSheet({
    super.key,
    required this.houseId,
    this.animal,
    required this.onSaved,
  });

  @override
  State<AnimalFormSheet> createState() => _AnimalFormSheetState();
}

class _AnimalFormSheetState extends State<AnimalFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String? _selectedType;
  File? _selectedImage;
  String? _currentImageUrl;
  bool _removeCurrentImage = false;
  bool _isSaving = false;

  final List<String> animalTypes = [
    'สุนัข',
    'แมว',
    'นก',
    'ปลา',
    'กระต่าย',
    'หนู',
    'อื่นๆ'
  ];

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (widget.animal != null) {
      _nameController.text = widget.animal!.name ?? '';
      _selectedType = widget.animal!.type;
      _currentImageUrl = widget.animal!.img;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
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

  Future<void> _saveAnimal() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      String? finalImageUrl;

      // Handle image updates
      if (_selectedImage != null) {
        if (widget.animal != null) {
          // Update existing animal
          finalImageUrl = await SupabaseImage().uploadImage(
            imageFile: _selectedImage!,
            tableName: "animal",
            rowName: "animal_id",
            rowImgName: "img",
            rowKey: widget.animal!.animalId,
          );
        }
      } else if (_removeCurrentImage) {
        finalImageUrl = null;
      } else {
        finalImageUrl = _currentImageUrl;
      }

      if (widget.animal != null) {
        // Update existing animal
        await AnimalDomain.update(
          animalId: widget.animal!.animalId,
          type: _selectedType!,
          name: _nameController.text.trim(),
          img: finalImageUrl,
        );
      } else {
        // Create new animal
        await AnimalDomain.create(
          houseId: widget.houseId,
          type: _selectedType!,
          name: _nameController.text.trim(),
          img: _selectedImage != null ? 'temp' : null, // Will be updated after creation
        );

        // If there's an image, we need to get the new animal ID and upload
        if (_selectedImage != null) {
          // Note: You might need to modify AnimalDomain.create to return the created animal
          // For now, we'll handle this in the UI refresh
        }
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.animal != null ? 'แก้ไขสัตว์เลี้ยงสำเร็จ' : 'เพิ่มสัตว์เลี้ยงสำเร็จ'),
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
                  widget.animal != null ? 'แก้ไขสัตว์เลี้ยง' : 'เพิ่มสัตว์เลี้ยงใหม่',
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

                    // Name Field
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'ชื่อสัตว์เลี้ยง *',
                        prefixIcon: Icon(Icons.pets),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                      value?.trim().isEmpty == true ? 'กรุณาระบุชื่อสัตว์เลี้ยง' : null,
                    ),

                    const SizedBox(height: 20),

                    // Type Dropdown
                    DropdownButtonFormField<String>(
                      value: _selectedType,
                      decoration: const InputDecoration(
                        labelText: 'ประเภทสัตว์เลี้ยง *',
                        prefixIcon: Icon(Icons.category),
                        border: OutlineInputBorder(),
                      ),
                      items: animalTypes.map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(type),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _selectedType = value);
                      },
                      validator: (value) => value == null ? 'กรุณาเลือกประเภทสัตว์เลี้ยง' : null,
                    ),

                    const SizedBox(height: 30),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveAnimal,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
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
                          widget.animal != null ? 'บันทึกการแก้ไข' : 'เพิ่มสัตว์เลี้ยง',
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
                  tablePath: 'animal',
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
                  color: Colors.green,
                ),
                const SizedBox(width: 8),
                Text(
                  _selectedImage != null || (_currentImageUrl != null && !_removeCurrentImage)
                      ? 'เปลี่ยนรูปภาพ'
                      : 'เพิ่มรูปภาพ',
                  style: const TextStyle(color: Colors.green),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}