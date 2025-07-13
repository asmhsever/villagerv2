// 📁 lib/views/juristic/profile/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'edit_profile_screen.dart';
import 'change_password_screen.dart';
import 'package:intl/intl.dart';

class JuristicProfileScreen extends StatefulWidget {
  final int lawId;
  const JuristicProfileScreen({super.key, required this.lawId});

  @override
  State<JuristicProfileScreen> createState() => _JuristicProfileScreenState();
}

class _JuristicProfileScreenState extends State<JuristicProfileScreen> {
  Map<String, dynamic>? userData;
  bool isLoading = true;
  ImageProvider? profileImage;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final data = await Supabase.instance.client
        .from('law')
        .select()
        .eq('law_id', widget.lawId)
        .maybeSingle();

    if (data != null) {
      profileImage = await _resolveProfileImage(widget.lawId);
    }

    setState(() {
      userData = data;
      isLoading = false;
    });
  }

  Future<ImageProvider> _resolveProfileImage(int lawId) async {
    final bucket = Supabase.instance.client.storage.from('images');
    final basePath = 'law/law_$lawId';

    for (final ext in ['jpg', 'png']) {
      final path = '$basePath.$ext';
      try {
        final signedUrl = await bucket.createSignedUrl(path, 60);
        if (signedUrl.isNotEmpty) {
          return NetworkImage(bucket.getPublicUrl(path));
        }
      } catch (_) {}
    }
    return const AssetImage('lib/images/test1.png');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ข้อมูลส่วนตัว')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : userData == null
          ? const Center(child: Text('ไม่พบข้อมูล'))
          : Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: CircleAvatar(radius: 50, backgroundImage: profileImage),
            ),
            const SizedBox(height: 16),
            Text('ชื่อ: ${userData!['first_name'] ?? '-'}'),
            Text('นามสกุล: ${userData!['last_name'] ?? '-'}'),
            Text('วันเกิด: ${userData!['birth_date'] != null ? DateFormat('dd/MM/yyyy').format(DateTime.parse(userData!['birth_date'])) : '-'}'),
            Text('เบอร์โทร: ${userData!['phone'] ?? '-'}'),
            Text('เพศ: ${userData!['gender'] ?? '-'}'),
            Text('ที่อยู่: ${userData!['address'] ?? '-'}'),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.edit),
                  onPressed: () async {
                    final updated = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditProfileScreen(lawId: widget.lawId),
                      ),
                    );
                    if (updated == true) _loadProfile();
                  },
                  label: const Text('แก้ไขข้อมูล'),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.lock),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChangePasswordScreen(lawId: widget.lawId),
                      ),
                    );
                  },
                  label: const Text('เปลี่ยนรหัสผ่าน'),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
