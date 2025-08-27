import 'package:flutter/material.dart';
import 'package:fullproject/domains/house_domain.dart';
import 'package:fullproject/domains/village_domain.dart';
import 'package:fullproject/models/house_model.dart';
import 'package:fullproject/models/village_model.dart';
import 'package:fullproject/services/image_service.dart';
import 'package:fullproject/widgets/logout_buttom.dart';

class HouseDetailPage extends StatefulWidget {
  final int? houseId;

  const HouseDetailPage({super.key, this.houseId});

  @override
  State<HouseDetailPage> createState() => _HouseDetailPageState();
}

class _HouseDetailPageState extends State<HouseDetailPage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Theme Colors
  static const Color softBrown = Color(0xFFA47551);
  static const Color ivoryWhite = Color(0xFFFFFDF6);
  static const Color beige = Color(0xFFF5F0E1);
  static const Color sandyTan = Color(0xFFD8CAB8);
  static const Color earthClay = Color(0xFFBFA18F);
  static const Color warmStone = Color(0xFFC7B9A5);
  static const Color oliveGreen = Color(0xFFA3B18A);
  static const Color burntOrange = Color(0xFFE08E45);
  static const Color softTerracotta = Color(0xFFD48B5C);
  static const Color clayOrange = Color(0xFFCC7748);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutQuart,
          ),
        );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: beige,
      body: FutureBuilder(
        future: HouseDomain.getById(widget.houseId!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingState();
          }

          if (snapshot.hasError) {
            return _buildErrorState(snapshot.error.toString());
          }

          if (snapshot.hasData) {
            final data = snapshot.data!;
            _animationController.forward();

            return FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: _buildHouseContent(data),
              ),
            );
          }

          return _buildNoDataState();
        },
      ),
    );
  }

  // Remove the custom app bar method since it's not needed

  Widget _buildLoadingState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: ivoryWhite,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: earthClay.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(softBrown),
              strokeWidth: 3,
            ),
            const SizedBox(height: 20),
            Text(
              'กำลังโหลดข้อมูลบ้าน...',
              style: TextStyle(
                color: earthClay,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: ivoryWhite,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: earthClay.withOpacity(0.1),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: clayOrange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.error_outline_rounded,
                color: clayOrange,
                size: 48,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'เกิดข้อผิดพลาด',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: softBrown,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(color: earthClay, fontSize: 14),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => setState(() {}),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('ลองใหม่'),
              style: ElevatedButton.styleFrom(
                backgroundColor: burntOrange,
                foregroundColor: ivoryWhite,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoDataState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: ivoryWhite,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: earthClay.withOpacity(0.1),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.home_outlined, size: 64, color: warmStone),
            const SizedBox(height: 16),
            Text(
              'ไม่พบข้อมูลบ้าน',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: softBrown,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHouseContent(HouseModel house) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // House Image Card
          _buildHouseImageCard(house),
          const SizedBox(height: 20),

          // Basic Info
          _buildHouseBasicInfo(house),
          const SizedBox(height: 16),

          // Details
          _buildHouseDetails(house),
          const SizedBox(height: 16),

          // Owner Info
          _buildOwnerInfo(house),
          const SizedBox(height: 24),

          // Logout Button
          Center(child: LogoutButtom()),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildHouseImageCard(HouseModel house) {
    return Container(
      decoration: BoxDecoration(
        color: ivoryWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: earthClay.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: burntOrange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.photo_camera_rounded,
                    color: burntOrange,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  'รูปภาพบ้าน',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: softBrown,
                  ),
                ),
              ],
            ),
          ),

          // Image
          if (house.img != null && house.img!.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
              width: double.infinity,
              constraints: const BoxConstraints(minHeight: 200),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: earthClay.withOpacity(0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: AspectRatio(
                  aspectRatio: 16 / 10,
                  child: BuildImage(imagePath: house.img!, tablePath: "house"),
                ),
              ),
            )
          else
            Container(
              margin: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
              height: 150,
              decoration: BoxDecoration(
                color: beige,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: warmStone.withOpacity(0.3)),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.image_not_supported_rounded,
                      size: 48,
                      color: warmStone,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'ไม่มีรูปภาพ',
                      style: TextStyle(color: earthClay, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHouseBasicInfo(HouseModel house) {
    return _buildCard(
      title: 'ข้อมูลพื้นฐาน',
      icon: Icons.home_rounded,
      iconColor: softBrown,
      children: [
        _buildInfoRow(
          'หมายเลขบ้าน',
          house.houseNumber ?? 'ไม่ระบุ',
          Icons.numbers_rounded,
        ),
        _buildInfoRow(
          'ขนาด',
          house.size ?? 'ไม่ระบุ',
          Icons.square_foot_rounded,
        ),
        _buildInfoRow(
          'พื้นที่ใช้สอย',
          house.usableArea ?? 'ไม่ระบุ',
          Icons.straighten_rounded,
        ),
        _buildInfoRow(
          'จำนวนชั้น',
          '${house.floors ?? 0} ชั้น',
          Icons.layers_rounded,
        ),
        _buildInfoRow(
          'ประเภทบ้าน',
          _getHouseTypeText(house.houseType),
          Icons.home_work_rounded,
        ),
      ],
    );
  }

  Widget _buildHouseDetails(HouseModel house) {
    return _buildCard(
      title: 'รายละเอียด',
      icon: Icons.info_rounded,
      iconColor: burntOrange,
      children: [
        _buildInfoRow(
          'สถานะ',
          _getStatusText(house.status),
          Icons.check_circle_rounded,
        ),
        _buildInfoRow(
          'ประเภทกรรมสิทธิ์',
          _getOwnershipTypeText(house.owner),
          Icons.verified_user_rounded,
        ),
        _buildInfoRow(
          'สถานะการใช้งาน',
          _getUsageStatusText(house.usageStatus),
          Icons.power_settings_new_rounded,
        ),
        _buildInfoRow(
          'เบอร์โทร',
          house.phone ?? 'ไม่ระบุ',
          Icons.phone_rounded,
        ),
      ],
    );
  }

  Widget _buildOwnerInfo(HouseModel house) {
    return _buildCard(
      title: 'ข้อมูลเจ้าของ',
      icon: Icons.person_rounded,
      iconColor: oliveGreen,
      children: [
        _buildInfoRow(
          'ชื่อเจ้าของ',
          house.owner ?? 'ไม่ระบุ',
          Icons.account_circle_rounded,
        ),
        _buildInfoRow(
          'รหัสผู้ใช้',
          '${house.userId ?? 'ไม่ระบุ'}',
          Icons.badge_rounded,
        ),
      ],
    );
  }

  Widget _buildCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: ivoryWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: earthClay.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                const SizedBox(width: 16),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: softBrown,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Content
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: beige.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: warmStone.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: earthClay),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: earthClay,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                color: softBrown,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  String _getHouseTypeText(String? houseType) {
    switch (houseType?.toLowerCase()) {
      case 'detached':
        return 'บ้านเดี่ยว';
      case 'townhouse':
        return 'ทาวน์เฮาส์';
      case 'apartment':
        return 'อพาร์ทเมนต์';
      case 'condo':
        return 'คอนโดมิเนียม';
      default:
        return houseType ?? 'ไม่ระบุ';
    }
  }

  String _getStatusText(String? status) {
    switch (status?.toLowerCase()) {
      case 'owned':
        return 'เป็นเจ้าของ';
      case 'rented':
        return 'เช่า';
      case 'vacant':
        return 'ว่าง';
      case 'sold':
        return 'ขายแล้ว';
      default:
        return status ?? 'ไม่ระบุ';
    }
  }

  String _getOwnershipTypeText(String? ownershipType) {
    switch (ownershipType?.toLowerCase()) {
      case 'owner':
        return 'เจ้าของ';
      case 'tenant':
        return 'ผู้เช่า';
      case 'relative':
        return 'ญาติ';
      default:
        return ownershipType ?? 'ไม่ระบุ';
    }
  }

  String _getUsageStatusText(String? usageStatus) {
    switch (usageStatus?.toLowerCase()) {
      case 'active':
        return 'ใช้งาน';
      case 'inactive':
        return 'ไม่ใช้งาน';
      case 'maintenance':
        return 'ปรับปรุง';
      default:
        return usageStatus ?? 'ไม่ระบุ';
    }
  }
}
