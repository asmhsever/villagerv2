import 'package:flutter/material.dart';
import 'package:fullproject/domains/house_domain.dart';
import 'package:fullproject/domains/village_domain.dart';
import 'package:fullproject/models/village_model.dart';
import 'package:fullproject/pages/house/house_detail/village/committee.dart';
import 'package:fullproject/pages/house/house_detail/village/fund.dart';
import 'package:fullproject/pages/house/house_detail/village/guard.dart';
import 'package:fullproject/pages/house/house_detail/village/village_rule.dart';
import 'package:fullproject/services/image_service.dart';
import 'package:fullproject/theme/Color.dart';

class HouseVillageDetailPage extends StatefulWidget {
  final int? houseId;

  const HouseVillageDetailPage({super.key, this.houseId});

  @override
  State<HouseVillageDetailPage> createState() => _HouseVillageDetailPageState();
}

class _HouseVillageDetailPageState extends State<HouseVillageDetailPage> {
  // Theme Colors

  late Future<VillageModel> _villageFuture;

  Future<VillageModel> _loaddata() async {
    try {
      final house = await HouseDomain.getById(widget.houseId!);
      final village = await VillageDomain.getVillageById(house!.villageId);
      return village!;
    } catch (e) {
      throw Exception('Failed to load data: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _villageFuture = _loaddata();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeColors.ivoryWhite, // เปลี่ยนจาก Colors.grey[50]
      body: FutureBuilder<VillageModel>(
        future: _villageFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      ThemeColors.softBrown, // เปลี่ยนจาก Colors.teal[600]
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'กำลังโหลดข้อมูล...',
                    style: TextStyle(
                      color: ThemeColors.earthClay,
                      // เปลี่ยนจาก Colors.grey[600]
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    color: ThemeColors.mutedBurntSienna,
                    // เปลี่ยนจาก Colors.red[400]
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'เกิดข้อผิดพลาด',
                    style: TextStyle(
                      color: ThemeColors.clayOrange,
                      // เปลี่ยนจาก Colors.red[700]
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${snapshot.error}',
                    style: TextStyle(
                      color: ThemeColors.mutedBurntSienna,
                      // เปลี่ยนจาก Colors.red[600]
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {});
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('ลองใหม่'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ThemeColors.burntOrange,
                      // เปลี่ยนจาก Colors.red[600]
                      foregroundColor: ThemeColors.ivoryWhite,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData) {
            return Center(
              child: Text(
                'ไม่พบข้อมูล',
                style: TextStyle(
                  color: ThemeColors.earthClay, // เปลี่ยนจาก Colors.grey[600]
                  fontSize: 16,
                ),
              ),
            );
          }

          final data = snapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Village Section
                Card(
                  elevation: 6,
                  shadowColor: ThemeColors.softBrown.withOpacity(0.2),
                  // เปลี่ยน shadow color
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20), // เพิ่ม radius
                  ),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          ThemeColors.ivoryWhite,
                          ThemeColors.beige, // เปลี่ยนจาก Colors.teal[50]
                        ],
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(28.0), // เพิ่ม padding
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: BuildImage(
                              imagePath: data.logoImg!,
                              tablePath: "village/logo",
                            ),
                          ),
                          // Village Header
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(14),
                                // เพิ่ม padding
                                decoration: BoxDecoration(
                                  color: ThemeColors.softBrown,
                                  // เปลี่ยนจาก Colors.teal[600]
                                  borderRadius: BorderRadius.circular(16),
                                  // เพิ่ม radius
                                  boxShadow: [
                                    BoxShadow(
                                      color: ThemeColors.softBrown.withOpacity(
                                        0.3,
                                      ),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.location_city,
                                  color: Colors.white,
                                  size: 32, // เพิ่มขนาด
                                ),
                              ),
                              const SizedBox(width: 18),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '🏘️ หมู่บ้าน',
                                      style: TextStyle(
                                        color: ThemeColors.earthClay,
                                        // เปลี่ยนจาก Colors.grey[600]
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      data.name ?? 'ไม่ระบุชื่อ',
                                      style: const TextStyle(
                                        fontSize: 26, // เพิ่มขนาด
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 32), // เพิ่มระยะห่าง
                          // Village Details
                          _buildDetailRow(
                            icon: Icons.tag,
                            label: 'รหัสหมู่บ้าน',
                            value: data.villageId?.toString() ?? 'ไม่ระบุ',
                            color: ThemeColors.softBrown,
                          ),
                          const SizedBox(height: 20),

                          _buildDetailRow(
                            icon: Icons.location_on,
                            label: 'ที่อยู่',
                            value: data.address ?? 'ไม่ระบุที่อยู่',
                            color: ThemeColors.burntOrange,
                          ),
                          const SizedBox(height: 20),

                          _buildDetailRow(
                            icon: Icons.phone,
                            label: 'เบอร์โทรศัพท์',
                            value: data.salePhone ?? 'ไม่ระบุ',
                            color: ThemeColors.oliveGreen,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Action Buttons Section
                Card(
                  elevation: 6,
                  shadowColor: ThemeColors.softBrown.withOpacity(0.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          ThemeColors.ivoryWhite,
                          ThemeColors.sandyTan.withOpacity(0.3),
                        ],
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(28.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Section Header
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: ThemeColors.burntOrange,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: ThemeColors.burntOrange
                                          .withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.menu_open,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Text(
                                '🏢 บริการและข้อมูล',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Action Buttons Grid
                          Row(
                            children: [
                              // Guard Button
                              Expanded(
                                child: _buildActionButton(
                                  icon: Icons.security,
                                  title: 'เจ้าหน้าที่',
                                  subtitle: 'รักษาความปลอดภัย',
                                  color: ThemeColors.softBrown,
                                  onTap: () {
                                    print(data.villageId);
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            HouseGuardListPage(
                                              villageId: data.villageId,
                                            ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Fund Button
                              Expanded(
                                child: _buildActionButton(
                                  icon: Icons.account_balance_wallet,
                                  title: 'กองทุน',
                                  subtitle: 'ข้อมูลการเงิน',
                                  color: ThemeColors.oliveGreen,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => HouseFundPage(
                                          villageId: data.villageId,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          Row(
                            children: [
                              // Guard Button
                              Expanded(
                                child: _buildActionButton(
                                  icon: Icons.groups,
                                  title: 'คณะกรรมการ',
                                  subtitle: 'ข้อมูลคณะกรรมการหมู่บ้าน',
                                  color: ThemeColors.softTerracotta,
                                  isFullWidth: true,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => CommitteeListPage(
                                          villageId: data.villageId,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Fund Button
                              Expanded(
                                child: _buildActionButton(
                                  icon: Icons.rule,
                                  title: 'กฏหมู่บ้าน',
                                  subtitle: 'กฏของหมู่บ้านของท่าน',
                                  color: ThemeColors.oliveGreen,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            VillageRulesPage(village: data),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),

                          // Committee Button (Full Width)
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    bool isFullWidth = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: isFullWidth ? double.infinity : null,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: ThemeColors.earthClay,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios, color: color, size: 16),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16), // เพิ่ม padding รอบ row
      decoration: BoxDecoration(
        color: ThemeColors.sandyTan.withOpacity(0.3), // เพิ่มพื้นหลังแต่ละ row
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ThemeColors.warmStone.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10), // เพิ่ม padding icon
            decoration: BoxDecoration(
              color: color.withOpacity(0.15), // เพิ่มความเข้ม
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.2), width: 1),
            ),
            child: Icon(icon, color: color, size: 22), // เพิ่มขนาด icon
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: ThemeColors.earthClay,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 17, // เพิ่มขนาด
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
