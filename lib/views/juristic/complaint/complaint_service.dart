// lib/views/juristic/complaint/complaint_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';

class ComplaintService {
  final _client = Supabase.instance.client;

  // ดึง complaint ทั้งหมดของบ้านใดบ้านหนึ่ง
  Future<List<Map<String, dynamic>>> fetchComplaintsByHouse(int houseId) async {
    final response = await _client
        .from('complaint')
        .select('*')
        .eq('house_id', houseId)
        .order('date', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  // เพิ่ม complaint ใหม่
  Future<void> addComplaint({
    required int houseId,
    required int typeComplaint,
    required int level,
    required String header,
    required String description,
    String? img,
    bool isPrivate = false,
  }) async {
    await _client.from('complaint').insert({
      'house_id': houseId,
      'type_complaint': typeComplaint,
      'level': level,
      'header': header,
      'description': description,
      'private': isPrivate,
      'img': img,
      'status_complaint': 'waiting',
      'date': DateTime.now().toIso8601String(),
    });
  }

  // อัปเดตสถานะ complaint (ใช้โดย juristic)
  Future<void> updateComplaintStatus({
    required int complaintId,
    required String status,
  }) async {
    await _client
        .from('complaint')
        .update({ 'status_complaint': status })
        .eq('complaint_id', complaintId);
  }

  // ดึงรายละเอียดร้องเรียนเฉพาะรายการ
  Future<Map<String, dynamic>?> getComplaintById(int id) async {
    final response = await _client
        .from('complaint')
        .select('*')
        .eq('complaint_id', id)
        .maybeSingle();

    return response;
  }

  // ลบ complaint (อาจจะมีสิทธิ์เฉพาะผู้ร้องหรือนิติ)
  Future<void> deleteComplaint(int id) async {
    await _client
        .from('complaint')
        .delete()
        .eq('complaint_id', id);
  }
}
