import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fullproject/domains/funds_domain.dart';
import 'package:fullproject/models/funds_model.dart';
import 'package:fullproject/services/image_service.dart';
import 'package:fullproject/theme/Color.dart';
import 'package:image_picker/image_picker.dart';

class LawFundEditPage extends StatefulWidget {
  final FundModel fund;

  const LawFundEditPage({Key? key, required this.fund}) : super(key: key);

  @override
  State<LawFundEditPage> createState() => _LawFundEditPageState();
}

class _LawFundEditPageState extends State<LawFundEditPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  String _selectedType = 'income';

  // Receipt Image
  File? _newReceiptImageFile;
  Uint8List? _newReceiptImageBytes;
  bool _removeReceiptImage = false;
  String? _currentReceiptUrl;

  // Approval Image
  File? _newApprovImageFile;
  Uint8List? _newApprovImageBytes;
  bool _removeApprovImage = false;
  String? _currentApprovUrl;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    _descriptionController.text = widget.fund.description;
    _amountController.text = widget.fund.amount.toString();
    _selectedType = widget.fund.type;
    _currentReceiptUrl = widget.fund.receiptImg;
    _currentApprovUrl = widget.fund.approvImg;
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  bool _hasSelectedImage(String imageType) {
    if (imageType == 'receipt') {
      return (kIsWeb && _newReceiptImageBytes != null) ||
          (!kIsWeb && _newReceiptImageFile != null);
    } else {
      return (kIsWeb && _newApprovImageBytes != null) ||
          (!kIsWeb && _newApprovImageFile != null);
    }
  }

  Future<void> _pickImage(String imageType) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (image != null) {
        if (kIsWeb) {
          final bytes = await image.readAsBytes();
          setState(() {
            if (imageType == 'receipt') {
              _newReceiptImageBytes = bytes;
              _newReceiptImageFile = null;
              _removeReceiptImage = false;
            } else {
              _newApprovImageBytes = bytes;
              _newApprovImageFile = null;
              _removeApprovImage = false;
            }
          });
        } else {
          setState(() {
            if (imageType == 'receipt') {
              _newReceiptImageFile = File(image.path);
              _newReceiptImageBytes = null;
              _removeReceiptImage = false;
            } else {
              _newApprovImageFile = File(image.path);
              _newApprovImageBytes = null;
              _removeApprovImage = false;
            }
          });
        }
      }
    } catch (e) {
      _showErrorSnackBar('เกิดข้อผิดพลาดในการเลือกรูปภาพ: $e');
    }
  }

  Future<void> _pickImageFromCamera(String imageType) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (image != null) {
        if (kIsWeb) {
          final bytes = await image.readAsBytes();
          setState(() {
            if (imageType == 'receipt') {
              _newReceiptImageBytes = bytes;
              _newReceiptImageFile = null;
              _removeReceiptImage = false;
            } else {
              _newApprovImageBytes = bytes;
              _newApprovImageFile = null;
              _removeApprovImage = false;
            }
          });
        } else {
          setState(() {
            if (imageType == 'receipt') {
              _newReceiptImageFile = File(image.path);
              _newReceiptImageBytes = null;
              _removeReceiptImage = false;
            } else {
              _newApprovImageFile = File(image.path);
              _newApprovImageBytes = null;
              _removeApprovImage = false;
            }
          });
        }
      }
    } catch (e) {
      _showErrorSnackBar('เกิดข้อผิดพลาดในการถ่ายภาพ: $e');
    }
  }

  void _removeImage(String imageType) {
    setState(() {
      if (imageType == 'receipt') {
        _newReceiptImageFile = null;
        _newReceiptImageBytes = null;
        _removeReceiptImage = true;
      } else {
        _newApprovImageFile = null;
        _newApprovImageBytes = null;
        _removeApprovImage = true;
      }
    });
  }

  void _showImagePicker(String imageType) {
    final title = imageType == 'receipt' ? 'รูปใบเสร็จ' : 'รูปอนุมัติ';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: ThemeColors.beige,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: ThemeColors.warmStone,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 16),
            Text(
              'เลือก$title',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: ThemeColors.softBrown,
              ),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildImageOption(
                  icon: Icons.camera_alt_outlined,
                  label: 'ถ่ายรูป',
                  onTap: () {
                    Navigator.pop(context);
                    _pickImageFromCamera(imageType);
                  },
                ),
                _buildImageOption(
                  icon: Icons.photo_library_outlined,
                  label: 'แกลลอรี่',
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(imageType);
                  },
                ),
                if (_hasImageToShow(imageType))
                  _buildImageOption(
                    icon: Icons.delete_outline,
                    label: 'ลบรูป',
                    color: ThemeColors.burntOrange,
                    onTap: () {
                      Navigator.pop(context);
                      _removeImage(imageType);
                    },
                  ),
              ],
            ),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildImageOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    final optionColor = color ?? ThemeColors.softBrown;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: optionColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: optionColor.withOpacity(0.3)),
            ),
            child: Icon(icon, color: optionColor, size: 24),
          ),
          SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: optionColor,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  bool _hasImageToShow(String imageType) {
    if (imageType == 'receipt') {
      return (_currentReceiptUrl != null && !_removeReceiptImage) ||
          _hasSelectedImage(imageType);
    } else {
      return (_currentApprovUrl != null && !_removeApprovImage) ||
          _hasSelectedImage(imageType);
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final amount = double.parse(_amountController.text);

      // เตรียม imageFile สำหรับรูปใบเสร็จ
      dynamic receiptImageFile;
      if (_hasSelectedImage('receipt')) {
        if (kIsWeb && _newReceiptImageBytes != null) {
          receiptImageFile = _newReceiptImageBytes!;
        } else if (!kIsWeb && _newReceiptImageFile != null) {
          receiptImageFile = _newReceiptImageFile!;
        }
      }

      // เตรียม imageFile สำหรับรูปอนุมัติ
      dynamic approvImageFile;
      if (_hasSelectedImage('approv')) {
        if (kIsWeb && _newApprovImageBytes != null) {
          approvImageFile = _newApprovImageBytes!;
        } else if (!kIsWeb && _newApprovImageFile != null) {
          approvImageFile = _newApprovImageFile!;
        }
      }

      await FundDomain.update(
        fundId: widget.fund.fundId,
        villageId: widget.fund.villageId,
        type: _selectedType,
        amount: amount,
        description: _descriptionController.text,
        receiptImageFile: receiptImageFile,
        approvImageFile: approvImageFile,
        removeReceiptImage: _removeReceiptImage,
        removeApprovImage: _removeApprovImage,
      );

      _showSuccessSnackBar('บันทึกข้อมูลเรียบร้อยแล้ว');
      Navigator.pop(context, true);
    } catch (e) {
      _showErrorSnackBar('เกิดข้อผิดพลาดในการบันทึกข้อมูล: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle_outline, color: ThemeColors.ivoryWhite),
            SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: ThemeColors.oliveGreen,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: ThemeColors.ivoryWhite),
            SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: ThemeColors.burntOrange,
        duration: Duration(seconds: 3),
      ),
    );
  }

  Widget _buildImageCard(String imageType) {
    final title = imageType == 'receipt' ? 'ใบเสร็จ' : 'หลักฐานอนุมัติ';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: ThemeColors.softBrown,
          ),
        ),
        SizedBox(height: 8),
        Container(
          height: 120,
          decoration: BoxDecoration(
            color: ThemeColors.beige,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: ThemeColors.sandyTan),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _showImagePicker(imageType),
              child: _buildImageContent(imageType),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageContent(String imageType) {
    // Check if image should be removed
    if ((imageType == 'receipt' && _removeReceiptImage) ||
        (imageType == 'approv' && _removeApprovImage)) {
      return _buildEmptyImageState(imageType);
    }

    // Show new selected image
    if (_hasSelectedImage(imageType)) {
      return _buildSelectedImagePreview(imageType);
    }

    // Show current image from server
    final currentUrl = imageType == 'receipt'
        ? _currentReceiptUrl
        : _currentApprovUrl;
    if (currentUrl != null && currentUrl.isNotEmpty) {
      return _buildCurrentImagePreview(currentUrl, "funds/${imageType}");
    }

    // Show empty state
    return _buildEmptyImageState(imageType);
  }

  Widget _buildEmptyImageState(String imageType) {
    final title = imageType == 'receipt'
        ? 'เพิ่มรูปใบเสร็จ'
        : 'เพิ่มรูปหลักฐานอนุมัติ';

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.add_photo_alternate_outlined,
          size: 48,
          color: ThemeColors.warmStone,
        ),
        SizedBox(height: 12),
        Text(
          title,
          style: TextStyle(
            color: ThemeColors.warmStone,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'แตะเพื่อเลือกรูปภาพ',
          style: TextStyle(color: ThemeColors.earthClay, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildSelectedImagePreview(String imageType) {
    Widget imageWidget;

    if (kIsWeb) {
      final bytes = imageType == 'receipt'
          ? _newReceiptImageBytes
          : _newApprovImageBytes;
      imageWidget = bytes != null
          ? Image.memory(
              bytes,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            )
          : _buildEmptyImageState(imageType);
    } else {
      final file = imageType == 'receipt'
          ? _newReceiptImageFile
          : _newApprovImageFile;
      imageWidget = file != null
          ? Image.file(
              file,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            )
          : _buildEmptyImageState(imageType);
    }

    return Stack(
      children: [
        ClipRRect(borderRadius: BorderRadius.circular(11), child: imageWidget),
        Positioned(
          top: 8,
          right: 8,
          child: GestureDetector(
            onTap: () => _removeImage(imageType),
            child: Container(
              padding: EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: ThemeColors.burntOrange,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.close, color: ThemeColors.ivoryWhite, size: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentImagePreview(String imageUrl, String bucketPath) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(11),
          child: BuildImage(imagePath: imageUrl, tablePath: bucketPath),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: Container(
            padding: EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.edit, color: Colors.white, size: 16),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeColors.ivoryWhite,
      appBar: AppBar(
        title: Text('แก้ไขรายการกองทุน'),
        backgroundColor: ThemeColors.softBrown,
        foregroundColor: ThemeColors.ivoryWhite,
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Type Selector
              Container(
                padding: EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: ThemeColors.beige,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: ThemeColors.sandyTan),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedType = 'income'),
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _selectedType == 'income'
                                ? ThemeColors.oliveGreen.withOpacity(0.15)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: _selectedType == 'income'
                                ? Border.all(color: ThemeColors.oliveGreen)
                                : null,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.trending_up_rounded,
                                size: 18,
                                color: _selectedType == 'income'
                                    ? ThemeColors.oliveGreen
                                    : ThemeColors.warmStone,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'รายรับ',
                                style: TextStyle(
                                  color: _selectedType == 'income'
                                      ? ThemeColors.oliveGreen
                                      : ThemeColors.warmStone,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedType = 'outcome'),
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _selectedType == 'outcome'
                                ? ThemeColors.burntOrange.withOpacity(0.15)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: _selectedType == 'outcome'
                                ? Border.all(color: ThemeColors.burntOrange)
                                : null,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.trending_down_rounded,
                                size: 18,
                                color: _selectedType == 'outcome'
                                    ? ThemeColors.burntOrange
                                    : ThemeColors.warmStone,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'รายจ่าย',
                                style: TextStyle(
                                  color: _selectedType == 'outcome'
                                      ? ThemeColors.burntOrange
                                      : ThemeColors.warmStone,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),

              // Amount Field
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
                decoration: InputDecoration(
                  labelText: 'จำนวนเงิน',
                  prefixText: '฿ ',
                  filled: true,
                  fillColor: ThemeColors.beige,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: ThemeColors.sandyTan),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: ThemeColors.sandyTan),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: ThemeColors.softBrown,
                      width: 2,
                    ),
                  ),
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'กรุณากรอกจำนวนเงิน';
                  final amount = double.tryParse(value!);
                  if (amount == null) return 'กรุณากรอกตัวเลขที่ถูกต้อง';
                  if (amount <= 0) return 'จำนวนเงินต้องมากกว่า 0';
                  return null;
                },
              ),
              SizedBox(height: 16),

              // Description Field
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'คำอธิบาย',
                  filled: true,
                  fillColor: ThemeColors.beige,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: ThemeColors.sandyTan),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: ThemeColors.sandyTan),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: ThemeColors.softBrown,
                      width: 2,
                    ),
                  ),
                ),
                validator: (value) {
                  if (value?.trim().isEmpty ?? true) return 'กรุณากรอกคำอธิบาย';
                  if (value!.trim().length < 3)
                    return 'คำอธิบายต้องมีอย่างน้อย 3 ตัวอักษร';
                  return null;
                },
              ),
              SizedBox(height: 20),

              // Images Section
              Text(
                'รูปภาพ',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: ThemeColors.softBrown,
                ),
              ),
              SizedBox(height: 12),

              // Receipt Image - Full Width
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'รูปใบเสร็จ',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: ThemeColors.softTerracotta,
                    ),
                  ),
                  SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    height: 160,
                    decoration: BoxDecoration(
                      color: ThemeColors.beige,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: ThemeColors.sandyTan),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => _showImagePicker('receipt'),
                        child: _buildImageContent('receipt'),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),

              // Approval Image - Full Width
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'รูปหลักฐานอนุมัติ',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: ThemeColors.softTerracotta,
                    ),
                  ),
                  SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    height: 160,
                    decoration: BoxDecoration(
                      color: ThemeColors.beige,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: ThemeColors.sandyTan),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => _showImagePicker('approv'),
                        child: _buildImageContent('approv'),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedType == 'income'
                        ? ThemeColors.oliveGreen
                        : ThemeColors.burntOrange,
                    foregroundColor: ThemeColors.ivoryWhite,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              ThemeColors.ivoryWhite,
                            ),
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'บันทึกการเปลี่ยนแปลง',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
