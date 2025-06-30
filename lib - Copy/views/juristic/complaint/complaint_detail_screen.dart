// PATCH: complaint_detail_screen.dart (รูปแบบแกลเลอรี + cached_network_image + full screen)

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'complaint_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'finished_complaint_screen.dart';

class ComplaintDetailScreen extends StatefulWidget {
  final Complaint complaint;
  const ComplaintDetailScreen({Key? key, required this.complaint}) : super(key: key);

  @override
  State<ComplaintDetailScreen> createState() => _ComplaintDetailScreenState();
}

class _ComplaintDetailScreenState extends State<ComplaintDetailScreen> {
  List<String> _imageUrls = [];
  List<Map<String, dynamic>> _statusLogs = [];
  String? _finishedDesc;
  List<String> _finishedImages = [];

  @override
  void initState() {
    super.initState();
    _loadImages();
    _loadStatusLogs();
    _loadFinishedInfo();
  }

  Future<void> _loadImages() async {
    final client = Supabase.instance.client;
    final response = await client
        .from('image_complaint')
        .select('img_path')
        .eq('complaint_id', widget.complaint.complaintId);

    final urls = (response as List)
        .map((e) => e['img_path'] as String)
        .map((path) => client.storage.from('imagecomplain').getPublicUrl(path))
        .toList();

    setState(() => _imageUrls = urls);
  }

  Future<void> _loadFinishedInfo() async {
    final client = Supabase.instance.client;
    final complaintId = widget.complaint.complaintId;

    final detailRes = await client
        .from('finished_complaint')
        .select('description')
        .eq('complaint_id', complaintId)
        .maybeSingle();

    final imageRes = await client
        .from('image_finished')
        .select('img_path')
        .eq('complaint_id', complaintId);

    final imgUrls = (imageRes as List)
        .map((e) => client.storage.from('imagefinished').getPublicUrl(e['img_path'] as String))
        .toList();

    setState(() {
      _finishedDesc = detailRes?['description'];
      _finishedImages = imgUrls;
    });
  }

  Future<void> _loadStatusLogs() async {
    final client = Supabase.instance.client;
    final response = await client
        .from('status_complaint')
        .select('status_change, date, status_type, law_id')
        .eq('complaint_id', widget.complaint.complaintId)
        .order('date', ascending: true);

    setState(() {
      _statusLogs = List<Map<String, dynamic>>.from(response);
    });
  }

  String get statusText => widget.complaint.status ? '✅ เสร็จแล้ว' : '🕐 รอดำเนินการ';

  void _navigateToFinish() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FinishedComplaintScreen(complaint: widget.complaint),
      ),
    ).then((_) => _loadFinishedInfo());
  }

  void _showImageGallery(List<String> urls, int index) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: PageView.builder(
          controller: PageController(initialPage: index),
          itemCount: urls.length,
          itemBuilder: (ctx, i) => InteractiveViewer(
            child: CachedNetworkImage(
              imageUrl: urls[i],
              fit: BoxFit.contain,
              placeholder: (_, __) => const Center(child: CircularProgressIndicator()),
              errorWidget: (_, __, ___) => const Icon(Icons.broken_image),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageGrid(List<String> urls) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: urls.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemBuilder: (context, index) => GestureDetector(
        onTap: () => _showImageGallery(urls, index),
        child: CachedNetworkImage(
          imageUrl: urls[index],
          fit: BoxFit.cover,
          placeholder: (_, __) => const Center(child: CircularProgressIndicator()),
          errorWidget: (_, __, ___) => const Icon(Icons.broken_image),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('รายละเอียดคำร้อง')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.complaint.header, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 12),
              Text('คำอธิบาย: ${widget.complaint.description}'),
              Text('ประเภทคำร้อง: ${widget.complaint.typeName ?? widget.complaint.typeComplaintId}'),
              Text('ระดับความรุนแรง: ${widget.complaint.levelId}'),
              Text('วันที่แจ้ง: ${DateFormat('dd MMM yyyy').format(widget.complaint.date)}'),
              Text('สถานะ: $statusText'),
              const SizedBox(height: 12),
              if (!widget.complaint.status)
                ElevatedButton.icon(
                  icon: const Icon(Icons.check_circle),
                  label: const Text('แก้ไขสถานะ'),
                  onPressed: _navigateToFinish,
                ),
              const SizedBox(height: 16),
              if (_imageUrls.isNotEmpty) ...[
                const Text('รูปภาพประกอบ:'),
                const SizedBox(height: 8),
                _buildImageGrid(_imageUrls),
              ],
              const SizedBox(height: 16),
              if (_statusLogs.isNotEmpty) ...[
                const Text('ไทม์ไลน์สถานะ:'),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _statusLogs.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    final log = _statusLogs[index];
                    final date = DateTime.tryParse(log['date'] ?? '') ?? DateTime.now();
                    return ListTile(
                      leading: const Icon(Icons.update),
                      title: Text('${log['status_change']}'),
                      subtitle: Text('วันที่ ${DateFormat('dd MMM yyyy').format(date)} | โดยนิติ ${log['law_id']}'),
                    );
                  },
                ),
              ],
              const SizedBox(height: 16),
              if (widget.complaint.status && (_finishedDesc != null || _finishedImages.isNotEmpty)) ...[
                const Divider(),
                const Text('รายละเอียดหลังดำเนินการ:', style: TextStyle(fontWeight: FontWeight.bold)),
                if (_finishedDesc != null) Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(_finishedDesc!),
                ),
                const SizedBox(height: 8),
                if (_finishedImages.isNotEmpty) ...[
                  const Text('รูปภาพหลังดำเนินการ:'),
                  const SizedBox(height: 8),
                  _buildImageGrid(_finishedImages),
                ]
              ]
            ],
          ),
        ),
      ),
    );
  }
}
