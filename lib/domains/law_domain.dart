import 'package:fullproject/config/supabase_config.dart';
import 'package:fullproject/models/law_model.dart';
import 'package:fullproject/services/image_service.dart';

class LawDomain {
  static final _client = SupabaseConfig.client;
  static const String _table = 'law';

  // Create - เพิ่มข้อมูลผู้ที่เกี่ยวข้องกับกฎหมายใหม่
  static Future<LawModel?> create({
    required int villageId,
    required String firstName,
    required String lastName,
    required String birthDate,
    required String phone,
    required String gender,
    required String address,
    required int userId,
    dynamic imageFile, // รองรับทั้ง File และ Uint8List
  }) async {
    try {
      // 1. สร้าง law ก่อน (ยังไม่มีรูป)
      final response = await _client
          .from(_table)
          .insert({
        'village_id': villageId,
        'first_name': firstName,
        'last_name': lastName,
        'birth_date': birthDate,
        'phone': phone,
        'gender': gender,
        'address': address,
        'user_id': userId,
        'img': null,
      })
          .select()
          .single();

      final createdLaw = LawModel.fromJson(response);

      // 2. อัปโหลดรูป (ถ้ามี)
      if (imageFile != null && createdLaw.lawId != 0) {
        final imageUrl = await SupabaseImage().uploadImage(
          bucketPath: "law",
          imgName: "law",
          imageFile: imageFile,
          tableName: "law",
          rowName: "law_id",
          rowImgName: "img",
          rowKey: createdLaw.lawId,
        );

        // 3. อัปเดต law ด้วย imageUrl
        if (imageUrl != null) {
          await _client
              .from(_table)
              .update({'img': imageUrl})
              .eq('law_id', createdLaw.lawId);

          // Return law ที่มี imageUrl
          return LawModel(
            lawId: createdLaw.lawId,
            villageId: createdLaw.villageId,
            firstName: createdLaw.firstName,
            lastName: createdLaw.lastName,
            birthDate: createdLaw.birthDate,
            phone: createdLaw.phone,
            gender: createdLaw.gender,
            address: createdLaw.address,
            userId: createdLaw.userId,
            img: imageUrl,
          );
        }
      }

      return createdLaw;
    } catch (e) {
      print('Error creating law: $e');
      return null;
    }
  }

  // Update - อัพเดทข้อมูลผู้ที่เกี่ยวข้องกับกฎหมาย
  static Future<LawModel?> update({
    required int lawId,
    required int villageId,
    required String firstName,
    required String lastName,
    required String birthDate,
    required String phone,
    required String gender,
    required String address,
    required int userId,
    dynamic imageFile, // รองรับทั้ง File และ Uint8List
    bool removeImage = false, // flag สำหรับลบรูป
  }) async {
    try {
      String? finalImageUrl;

      if (removeImage) {
        // ลบรูปภาพ
        finalImageUrl = null;
      } else if (imageFile != null) {
        // อัปโหลดรูปใหม่
        finalImageUrl = await SupabaseImage().uploadImage(
          imageFile: imageFile,
          tableName: "law",
          rowName: "law_id",
          rowImgName: "img",
          rowKey: lawId,
          bucketPath: "law",
          imgName: "law",
        );
      }
      // ถ้า imageFile เป็น null และ removeImage เป็น false = ไม่แก้ไขรูป

      // อัปเดตข้อมูล
      final Map<String, dynamic> updateData = {
        'village_id': villageId,
        'first_name': firstName,
        'last_name': lastName,
        'birth_date': birthDate,
        'phone': phone,
        'gender': gender,
        'address': address,
        'user_id': userId,
      };

      // เพิ่ม img field เฉพาะเมื่อต้องการเปลี่ยนรูป
      if (removeImage || imageFile != null) {
        updateData['img'] = finalImageUrl;
      }

      final response = await _client
          .from(_table)
          .update(updateData)
          .eq('law_id', lawId)
          .select()
          .single();

      return LawModel.fromJson(response);
    } catch (e) {
      print('Error updating law: $e');
      return null;
    }
  }

  // Delete - ลบข้อมูลผู้ที่เกี่ยวข้องกับกฎหมาย
  static Future<bool> delete(int lawId) async {
    try {
      // 1. ดึงข้อมูล law เพื่อเช็ค imageUrl ก่อน
      final response = await _client
          .from(_table)
          .select('img')
          .eq('law_id', lawId)
          .single();

      final imageUrl = response['img'] as String?;

      // 2. ลบรูปภาพออกจาก storage ก่อน (ถ้ามี)
      if (imageUrl != null && imageUrl.isNotEmpty) {
        await SupabaseImage().deleteImage(
          bucketPath: "law",
          imageUrl: imageUrl,
        );
      }

      // 3. ลบข้อมูล law จากฐานข้อมูล
      await _client.from(_table).delete().eq('law_id', lawId);

      return true;
    } catch (e) {
      print('Error deleting law: $e');
      return false;
    }
  }

  // Read - อ่านข้อมูลทั้งหมดในระบบ (Admin only)
  static Future<List<LawModel>> getAll() async {
    try {
      final response = await _client
          .from(_table)
          .select()
          .order('first_name', ascending: true);

      return response
          .map<LawModel>((json) => LawModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error getting all law records: $e');
      return [];
    }
  }

  // Read - อ่านข้อมูลทั้งหมดในหมู่บ้าน
  static Future<List<LawModel>> getAllInVillage({
    required int villageId,
  }) async {
    try {
      final response = await _client
          .from(_table)
          .select()
          .eq('village_id', villageId)
          .order('first_name', ascending: true);

      return response
          .map<LawModel>((json) => LawModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error getting law records in village: $e');
      return [];
    }
  }

  // Read - อ่านข้อมูลตาม ID
  static Future<LawModel?> getById(int lawId) async {
    try {
      final response = await _client
          .from(_table)
          .select()
          .eq('law_id', lawId)
          .single();

      return LawModel.fromJson(response);
    } catch (e) {
      print('Error getting law by ID: $e');
      return null;
    }
  }

  // Read - อ่านข้อมูลตาม User ID
  static Future<List<LawModel>> getByUserId(int userId) async {
    try {
      final response = await _client
          .from(_table)
          .select()
          .eq('user_id', userId)
          .order('first_name', ascending: true);

      return response
          .map<LawModel>((json) => LawModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error getting law records by user ID: $e');
      return [];
    }
  }

  // Read - อ่านข้อมูลตามเพศ
  static Future<List<LawModel>> getByGender({
    required int villageId,
    required String gender,
  }) async {
    try {
      final response = await _client
          .from(_table)
          .select()
          .eq('village_id', villageId)
          .eq('gender', gender)
          .order('first_name', ascending: true);

      return response
          .map<LawModel>((json) => LawModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error getting law records by gender: $e');
      return [];
    }
  }

  // Read - ค้นหาตามชื่อ
  static Future<List<LawModel>> searchByName({
    required int villageId,
    required String name,
  }) async {
    try {
      final response = await _client
          .from(_table)
          .select()
          .eq('village_id', villageId)
          .or('first_name.ilike.%$name%,last_name.ilike.%$name%')
          .order('first_name', ascending: true);

      return response
          .map<LawModel>((json) => LawModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error searching law records by name: $e');
      return [];
    }
  }

  // Read - ค้นหาตามเบอร์โทร
  static Future<List<LawModel>> searchByPhone({
    required int villageId,
    required String phone,
  }) async {
    try {
      final response = await _client
          .from(_table)
          .select()
          .eq('village_id', villageId)
          .ilike('phone', '%$phone%')
          .order('first_name', ascending: true);

      return response
          .map<LawModel>((json) => LawModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error searching law records by phone: $e');
      return [];
    }
  }

  // Read - ค้นหาตามที่อยู่
  static Future<List<LawModel>> searchByAddress({
    required int villageId,
    required String address,
  }) async {
    try {
      final response = await _client
          .from(_table)
          .select()
          .eq('village_id', villageId)
          .ilike('address', '%$address%')
          .order('first_name', ascending: true);

      return response
          .map<LawModel>((json) => LawModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error searching law records by address: $e');
      return [];
    }
  }

  // Read - ค้นหาตามช่วงอายุ (ตามปีเกิด)
  static Future<List<LawModel>> getByBirthDateRange({
    required int villageId,
    required String startDate,
    required String endDate,
  }) async {
    try {
      final response = await _client
          .from(_table)
          .select()
          .eq('village_id', villageId)
          .gte('birth_date', startDate)
          .lte('birth_date', endDate)
          .order('birth_date', ascending: true);

      return response
          .map<LawModel>((json) => LawModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error getting law records by birth date range: $e');
      return [];
    }
  }

  // Utility - นับจำนวนคนในหมู่บ้าน
  static Future<int> countPeopleInVillage(int villageId) async {
    try {
      final response = await _client
          .from(_table)
          .select('law_id')
          .eq('village_id', villageId);

      return response.length;
    } catch (e) {
      print('Error counting people in village: $e');
      return 0;
    }
  }

  // Utility - นับจำนวนคนตามเพศ
  static Future<Map<String, int>> getCountByGender(int villageId) async {
    try {
      final response = await _client
          .from(_table)
          .select('gender')
          .eq('village_id', villageId);

      Map<String, int> genderCount = {};
      for (var person in response) {
        String gender = person['gender'] ?? 'unknown';
        genderCount[gender] = (genderCount[gender] ?? 0) + 1;
      }

      return genderCount;
    } catch (e) {
      print('Error getting count by gender: $e');
      return {};
    }
  }

  // Utility - สถิติภาพรวมของหมู่บ้าน
  static Future<Map<String, dynamic>> getVillageStats(int villageId) async {
    try {
      final response = await _client
          .from(_table)
          .select('gender, birth_date')
          .eq('village_id', villageId);

      int totalPeople = response.length;
      int maleCount = 0;
      int femaleCount = 0;
      int otherCount = 0;
      Map<int, int> ageGroups = {
        0: 0, // 0-17
        18: 0, // 18-30
        31: 0, // 31-50
        51: 0, // 51-65
        66: 0, // 66+
      };

      DateTime now = DateTime.now();

      for (var person in response) {
        // นับเพศ
        String gender = person['gender'] ?? 'other';
        if (gender == 'M') {
          maleCount++;
        } else if (gender == 'F') {
          femaleCount++;
        } else {
          otherCount++;
        }

        // นับช่วงอายุ
        String? birthDateStr = person['birth_date'];
        if (birthDateStr != null) {
          try {
            DateTime birthDate = DateTime.parse(birthDateStr);
            int age = now.year - birthDate.year;
            if (now.month < birthDate.month ||
                (now.month == birthDate.month && now.day < birthDate.day)) {
              age--;
            }

            if (age < 18) {
              ageGroups[0] = (ageGroups[0] ?? 0) + 1;
            } else if (age <= 30) {
              ageGroups[18] = (ageGroups[18] ?? 0) + 1;
            } else if (age <= 50) {
              ageGroups[31] = (ageGroups[31] ?? 0) + 1;
            } else if (age <= 65) {
              ageGroups[51] = (ageGroups[51] ?? 0) + 1;
            } else {
              ageGroups[66] = (ageGroups[66] ?? 0) + 1;
            }
          } catch (e) {
            // ถ้า parse วันที่ไม่ได้ ข้ามไป
            continue;
          }
        }
      }

      return {
        'total_people': totalPeople,
        'male_count': maleCount,
        'female_count': femaleCount,
        'other_count': otherCount,
        'gender_ratio': totalPeople > 0
            ? {
          'male_percentage': (maleCount / totalPeople * 100),
          'female_percentage': (femaleCount / totalPeople * 100),
          'other_percentage': (otherCount / totalPeople * 100),
        }
            : {'male_percentage': 0, 'female_percentage': 0, 'other_percentage': 0},
        'age_groups': {
          'children_teens': ageGroups[0], // 0-17
          'young_adults': ageGroups[18], // 18-30
          'adults': ageGroups[31], // 31-50
          'middle_aged': ageGroups[51], // 51-65
          'elderly': ageGroups[66], // 66+
        },
      };
    } catch (e) {
      print('Error getting village stats: $e');
      return {};
    }
  }
}