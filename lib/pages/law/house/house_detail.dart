import 'package:flutter/material.dart';
import 'package:fullproject/models/house_model.dart';
import 'package:fullproject/domains/house_domain.dart';
import 'house_edit.dart';

class HouseDetailPage extends StatefulWidget {
  final int houseId;
  const HouseDetailPage({super.key, required this.houseId});

  @override
  State<HouseDetailPage> createState() => _HouseDetailPageState();
}

class _HouseDetailPageState extends State<HouseDetailPage> {
  HouseModel? house;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadHouse();
  }

  Future<void> loadHouse() async {
    final result = await HouseDomain.getById(widget.houseId);
    setState(() {
      house = result;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('รายละเอียดบ้าน'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EditHousePage(house: house!),
                ),
              );

              if (result is HouseModel) {
                setState(() => house = result); // อัปเดตข้อมูลในหน้าปัจจุบัน
              }
            },
          )
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : house == null
          ? const Center(child: Text('ไม่พบข้อมูล'))
          : Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            if (house!.img != null && house!.img!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  house!.img!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                  const Center(
                      child: Text('ไม่สามารถโหลดรูปภาพได้')),
                ),
              ),
            const SizedBox(height: 16),
            detailTile('บ้านเลขที่', house!.houseNumber),
            detailTile('เจ้าของ', house!.owner),
            detailTile('เบอร์โทร', house!.phone),
            detailTile('สถานะ', house!.status),
            detailTile('ประเภทบ้าน', house!.houseType),
            detailTile('จำนวนชั้น', house!.floors?.toString()),
            detailTile('พื้นที่ใช้สอย', house!.usableArea),
            detailTile('สถานะการใช้งาน', house!.usageStatus),
            detailTile('ขนาด', house!.size),
          ],
        ),
      ),
    );
  }

  Widget detailTile(String label, String? value) {
    return Card(
      child: ListTile(
        title: Text(label),
        subtitle: Text(value ?? '-'),
      ),
    );
  }
}
