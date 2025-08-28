import 'package:flutter/material.dart';
import 'package:fullproject/models/village_model.dart';
import 'package:fullproject/services/image_service.dart';
import 'package:fullproject/theme/Color.dart';

class VillageRulesPage extends StatefulWidget {
  final VillageModel village;

  const VillageRulesPage({Key? key, required this.village}) : super(key: key);

  @override
  State<VillageRulesPage> createState() => _VillageRulesPageState();
}

class _VillageRulesPageState extends State<VillageRulesPage> {
  List<String> ruleImages = [];

  @override
  void initState() {
    super.initState();
    _parseRuleImages();
  }

  // แปลง String "[1.jpg,2.jpg]" เป็น List<String>
  void _parseRuleImages() {
    if (widget.village.ruleImgs != null &&
        widget.village.ruleImgs!.isNotEmpty) {
      String cleanString = widget.village.ruleImgs!
          .replaceAll('[', '')
          .replaceAll(']', '')
          .replaceAll(' ', '');

      if (cleanString.isNotEmpty) {
        ruleImages = cleanString.split(',');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeColors.ivoryWhite, // Ivory White
      appBar: AppBar(
        title: Text(
          'กฎของ${widget.village.name}',
          style: const TextStyle(
            color: ThemeColors.ivoryWhite, // Ivory White
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: ThemeColors.softBrown, // Soft Brown
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: ThemeColors.ivoryWhite),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ruleImages.isEmpty ? _buildEmptyState() : _buildRulesList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.rule_outlined,
            size: 80,
            color: ThemeColors.earthClay, // Earth Clay
          ),
          const SizedBox(height: 16),
          Text(
            'ยังไม่มีกฎของหมู่บ้าน',
            style: TextStyle(
              fontSize: 18,
              color: ThemeColors.earthClay, // Earth Clay
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'กฎของหมู่บ้านจะปรากฏที่นี่เมื่อมีการเพิ่ม',
            style: TextStyle(
              fontSize: 14,
              color: ThemeColors.warmStone, // Warm Stone
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRulesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: ruleImages.length,
      itemBuilder: (context, index) {
        return _buildRuleCard(ruleImages[index], index + 1);
      },
    );
  }

  Widget _buildRuleCard(String imageName, int ruleNumber) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ThemeColors.softBorder, // Soft Border
          width: 1,
        ),
      ),
      child: GestureDetector(
        onTap: () => _showFullScreenImage(imageName, ruleNumber),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: BuildImage(imagePath: imageName, tablePath: "village/rule"),
        ),
      ),
    );
  }

  void _showFullScreenImage(String imageName, int ruleNumber) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: Stack(
            children: [
              Center(
                child: InteractiveViewer(
                  child: Container(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.8,
                      maxWidth: MediaQuery.of(context).size.width * 0.9,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: BuildImage(
                        imagePath: imageName,
                        tablePath: "village/rule",
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 40,
                right: 16,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 40,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'ข้อที่ $ruleNumber',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
