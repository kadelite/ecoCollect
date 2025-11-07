import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'waste_report_screen.dart';
import 'track_trucks_screen.dart';
import 'rewards_screen.dart';

class HomeScreen extends StatefulWidget {
  final String userId;
  const HomeScreen({super.key, required this.userId});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('EcoCollect'),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.report), text: 'Report'),
            Tab(icon: Icon(Icons.local_shipping), text: 'Track Trucks'),
            Tab(icon: Icon(Icons.stars), text: 'Rewards'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          WasteReportScreen(userId: widget.userId),
          const TrackTrucksScreen(),
          RewardsScreen(userId: widget.userId),
        ],
      ),
    );
  }
}
