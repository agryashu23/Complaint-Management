import 'package:flutter/material.dart';
import 'package:pwc_varanasi/fragments/completed_complaints_fragment.dart';
import 'package:pwc_varanasi/fragments/completed_complaints_verify_fragment.dart';
import 'package:pwc_varanasi/fragments/pending_complaints_fragment.dart';
import 'package:pwc_varanasi/fragments/pending_complaints_verify_fragment.dart';
import 'package:pwc_varanasi/screens/create_complain_screen.dart';

class ComplaintsVerifyFragment extends StatefulWidget {

  final int screen;

  const ComplaintsVerifyFragment({super.key, required this.screen});

  @override
  State<ComplaintsVerifyFragment> createState() => _ComplaintsVerifyFragmentState();
}

class _ComplaintsVerifyFragmentState extends State<ComplaintsVerifyFragment> with SingleTickerProviderStateMixin {
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
      body: Column(
        children: [
          Material(
            elevation: 5,
            color: Colors.blue,
            child: TabBar(
              controller: _tabController,
              tabs: [
                Tab(text: 'Pending'),
                Tab(text: 'Completed'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              physics: NeverScrollableScrollPhysics(),
              controller: _tabController,
              children: [
                PendingComplaintsVerifyFragment(),
                CompletedComplaintsVerifyFragment()
              ],
            ),
          ),
        ],
      ),
      // floatingActionButton: Padding(
      //   padding: const EdgeInsets.only(bottom: 75.0),
      //   child: FloatingActionButton(onPressed: () async {
      //     await Navigator.push(context, MaterialPageRoute(builder: (context)=>CreateComplainScreen()));
      //   },
      //     mini: false,
      //     child: Icon(Icons.edit),
      //   ),
      // ),
    );
  }
}