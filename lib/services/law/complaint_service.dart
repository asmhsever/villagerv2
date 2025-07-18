// lib/services/complaint_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/complaint_model.dart';

class ComplaintService {
  final SupabaseClient _client = Supabase.instance.client;
  final String _table = 'complaint';

  Future<List<ComplaintModel>> getAllComplaints() async {
    final res = await _client.from(_table).select();
    return res.map<ComplaintModel>((e) => ComplaintModel.fromMap(e)).toList();
  }

  Future<ComplaintModel?> getComplaintById(int id) async {
    final res = await _client.from(_table).select().eq('complaint_id', id).single();
    return ComplaintModel.fromMap(res);
  }

  Future<void> updateStatus(int id, String status) async {
    await _client.from(_table)
        .update({'status_complaint': status})
        .eq('complaint_id', id);
  }

  Future<void> deleteComplaint(int id) async {
    await _client.from(_table).delete().eq('complaint_id', id);
  }

  Future<void> createComplaint(ComplaintModel complaint) async {
    final data = complaint.toMap();
    data.remove('complaint_id'); // Let Supabase auto-generate
    await _client.from(_table).insert(data);
  }
}
