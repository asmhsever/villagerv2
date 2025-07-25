import 'package:flutter/material.dart';
import 'package:fullproject/domains/notion_domain.dart';
import 'package:fullproject/extensions/context_extensions.dart';
import 'package:fullproject/models/house_model.dart';
import 'package:fullproject/models/notion_model.dart';
import 'package:fullproject/navigation/app_navigation.dart';
import 'package:fullproject/routes/app_routes.dart';
import 'package:fullproject/services/auth_service.dart';
import 'package:fullproject/services/image_service.dart';

class HouseDashboardPage extends StatefulWidget {
  const HouseDashboardPage({super.key});

  @override
  State<HouseDashboardPage> createState() => _HouseDashboardPageState();
}

class _HouseDashboardPageState extends State<HouseDashboardPage> {
  HouseModel? houseModel;
  bool isLoading = true;
  List<NotionModel> _recentNotions = [];

  @override
  void initState() {
    super.initState();
    loadCurrentUser();
  }

  Future<void> loadCurrentUser() async {
    try {
      final user = await AuthService.getCurrentUser();

      if (user is HouseModel) {
        setState(() {
          houseModel = user;
          isLoading = false;
        });
      } else {
        // ไม่ใช่ admin หรือไม่มีข้อมูล
        AppNavigation.navigateTo(AppRoutes.login);
      }
    } catch (e) {
      AppNavigation.navigateTo(AppRoutes.login);
    }
  }

  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    } else {
      return Scaffold(
        body: Column(
          children: [
            Text("user id ${houseModel!.userId}"),
            Text("house id : ${houseModel!.houseId}"),
            Text("viilage id : ${houseModel!.villageId}"),
            Text("onwer : ${houseModel!.owner}"),
            Expanded(child: HouseNotionsPage(villageId: houseModel!.villageId)),
          ],
        ),
      );
    }
  }
}

class HouseNotionsPage extends StatelessWidget {
  final int? villageId;

  const HouseNotionsPage({super.key, this.villageId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: NotionDomain.getRecentNotions(villageId: villageId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text("Error  ${snapshot.error}"));
        } else if (!snapshot.hasData) {
          return Center(child: Text("no data"));
        }
        final data = snapshot.data!;
        if (data['success'] != true) {
          return Center(child: Text("failed to load data"));
        }
        if (data['notions'] == null) {
          return Center(child: Text("no notions data"));
        }
        final List<NotionModel> notions = List<NotionModel>.from(
          data['notions'],
        );
        if (notions.isEmpty) {
          return Center(child: Text('no notion found'));
        }
        return ListView.builder(
          itemCount: notions.length,
          itemBuilder: (context, index) {
            return CardNotion(notion: notions[index]);
          },
        );
      },
    );
  }
}

class CardNotion extends StatelessWidget {
  final NotionModel notion;

  const CardNotion({super.key, required this.notion});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with profile info
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.blue.shade100,
                  child: Icon(
                    Icons.newspaper,
                    color: Colors.blue.shade700,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notion.header!,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(vertical: 15, horizontal: 30),
            height: context.heightPercent(0.3),
            width: double.infinity,
            child: BuildImage(imagePath: notion.img!, tablePath: 'notion'),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              notion.description!,
              style: const TextStyle(
                fontSize: 14,
                height: 1.4,
                color: Colors.black87,
              ),
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
