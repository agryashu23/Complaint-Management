import 'package:flutter/material.dart';
import 'package:pwc_varanasi/fragments/completed_complaints_fragment.dart';
import 'package:pwc_varanasi/fragments/pending_complaints_fragment.dart';

class ComplaintsScreen extends StatefulWidget {

  final int screen;

  const ComplaintsScreen({super.key, required this.screen});

  @override
  State<ComplaintsScreen> createState() => _ComplaintsScreenState();
}

class _ComplaintsScreenState extends State<ComplaintsScreen> with SingleTickerProviderStateMixin {
  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this,initialIndex: widget.screen);
  }

  @override
  void dispose() {
    _tabController!.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Complaints'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Pending'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      body: TabBarView(
        physics: NeverScrollableScrollPhysics(),
        controller: _tabController,
        children: [
          PendingComplaintsFragment(),
          CompletedComplaintsFragment(),
        ],
      ),
    );
  }
}