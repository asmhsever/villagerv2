// lib/services/complaint_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'complaint_model.dart';

class ComplaintService {
  final _client = Supabase.instance.client;

  Future<List<Complaint>> fetchComplaints(int villageId) async {
    final response = await _client
        .from('complaint')
        .select('*, house!inner(village_id)')
        .eq('house.village_id', villageId)
        .order('date', ascending: false);

    return (response as List)
        .map((item) => Complaint.fromMap(item))
        .toList();
  }

  Future<void> updateStatus({
    required int complaintId,
    required bool status,
  }) async {
    await _client
        .from('complaint')
        .update({'status': status})
        .eq('complaint_id', complaintId);
  }

  Future<void> addComplaint({
    required int houseId,
    required int typeComplaintId,
    required String header,
    required String description,
    required int levelId,
    required bool isPrivate,
  }) async {
    await _client.from('complaint').insert({
      'house_id': houseId,
      'type_complaint': typeComplaintId,
      'date': DateTime.now().toIso8601String(),
      'header': header,
      'description': description,
      'status': false,
      'level': levelId,
      'private': isPrivate,
    });
  }
}