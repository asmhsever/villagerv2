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

class _HouseDetailPageState extends State<HouseDetailPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFD8CAB8),

      body: Column(
        children: [
          Expanded(
            child: FutureBuilder(
              future: HouseDomain.getById(widget.houseId!),
              builder: (context, snapshot) {
                // กำลังโหลด
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFFA47551),
                          ),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'กำลังโหลดข้อมูล...',
                          style: TextStyle(
                            color: Color(0xFFA47551),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // เกิดข้อผิดพลาด
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, color: Colors.red, size: 64),
                        SizedBox(height: 16),
                        Text(
                          'เกิดข้อผิดพลาด',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '${snapshot.error}',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {}); // รีโหลดข้อมูล
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFFA47551),
                            foregroundColor: Colors.white,
                          ),
                          child: Text('ลองใหม่'),
                        ),
                      ],
                    ),
                  );
                }

                // โหลดสำเร็จ
                if (snapshot.hasData) {
                  final data = snapshot.data!;

                  return SingleChildScrollView(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ข้อมูลพื้นฐานของบ้าน
                        _buildHouseBasicInfo(data),

                        SizedBox(height: 16),

                        // ข้อมูลรายละเอียดบ้าน
                        _buildHouseDetails(data),

                        SizedBox(height: 16),

                        // ข้อมูลเจ้าของบ้าน
                        _buildOwnerInfo(data),
                        LogoutButtom(),
                      ],
                    ),
                  );
                }

                return Center(
                  child: Text(
                    'ไม่มีข้อมูล',
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHouseBasicInfo(HouseModel house) {
    return _buildCard(
      title: 'ข้อมูลพื้นฐาน',
      icon: Icons.home,
      child: Column(
        children: [
          _buildInfoRow('หมายเลขบ้าน', house.houseNumber ?? 'ไม่ระบุ'),
          _buildInfoRow('ขนาด', house.size ?? 'ไม่ระบุ'),
          _buildInfoRow('พื้นที่ใช้สอย', house.usableArea ?? 'ไม่ระบุ'),
          _buildInfoRow('จำนวนชั้น', '${house.floors ?? 0} ชั้น'),
          _buildInfoRow('ประเภทบ้าน', _getHouseTypeText(house.houseType)),
          BuildImage(imagePath: house.img!, tablePath: "house"),
        ],
      ),
    );
  }

  Widget _buildHouseDetails(HouseModel house) {
    return _buildCard(
      title: 'รายละเอียด',
      icon: Icons.info_outline,
      child: Column(
        children: [
          _buildInfoRow('สถานะ', _getStatusText(house.status)),
          _buildInfoRow('ประเภทกรรมสิทธิ์', _getOwnershipTypeText(house.owner)),
          _buildInfoRow(
            'สถานะการใช้งาน',
            _getUsageStatusText(house.usageStatus),
          ),
          _buildInfoRow('เบอร์โทร', house.phone ?? 'ไม่ระบุ'),
        ],
      ),
    );
  }

  Widget _buildOwnerInfo(HouseModel house) {
    return _buildCard(
      title: 'ข้อมูลเจ้าของ',
      icon: Icons.person,
      child: Column(
        children: [
          _buildInfoRow('ชื่อเจ้าของ', house.owner ?? 'ไม่ระบุ'),
          _buildInfoRow('รหัสผู้ใช้', '${house.userId ?? 'ไม่ระบุ'}'),
        ],
      ),
    );
  }

  Widget _buildVillageInfo(VillageModel? village) {
    return _buildCard(
      title: 'ข้อมูลหมู่บ้าน',
      icon: Icons.location_city,
      child: village != null
          ? Column(
              children: [
                _buildInfoRow('ชื่อหมู่บ้าน', village.name ?? 'ไม่ระบุ'),
                _buildInfoRow('ที่อยู่', village.address ?? 'ไม่ระบุ'),
                _buildInfoRow('เบอร์โทรขาย', village.salePhone ?? 'ไม่ระบุ'),
                _buildInfoRow('รหัสไปรษณีย์', village.zipCode ?? 'ไม่ระบุ'),
                _buildInfoRow('รหัสจังหวัด', '${village.provinceId}'),
              ],
            )
          : Center(
              child: Text(
                'ไม่พบข้อมูลหมู่บ้าน',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
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
    return Card(
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Color(0xFFA47551), size: 24),
                SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFA47551),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: Colors.black87, fontSize: 14),
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
