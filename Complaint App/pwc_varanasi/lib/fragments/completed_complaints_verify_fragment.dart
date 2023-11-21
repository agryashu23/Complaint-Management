import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class Complaint {
  final String id;
  final String address;
  final double latitude;
  final double longitude;
  final String description;
  final List<String> images;
  final String status;

  Complaint({
    required this.id,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.description,
    required this.images,
    required this.status,
  });

  factory Complaint.fromJson(Map<String, dynamic> json) {
    return Complaint(
      id: json['_id'],
      address: json['address'],
      latitude: double.parse(json['latitude'].toString()),
      longitude: double.parse(json['longitude'].toString()),
      description: json['description'],
      images: List<String>.from(json['images']),
      status: json['status'],
    );
  }
}

class CompletedComplaintsVerifyFragment extends StatefulWidget {
  const CompletedComplaintsVerifyFragment({super.key});

  @override
  State<CompletedComplaintsVerifyFragment> createState() => _CompletedComplaintsVerifyFragmentState();
}

class _CompletedComplaintsVerifyFragmentState extends State<CompletedComplaintsVerifyFragment> {

  List<Complaint> complaints = [];
  bool isDataFetched = true;

  void fetchComplaints() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String userID = await prefs.getString('userID') ?? 'false';
    final response = await http.get(Uri.parse('http://143.110.177.156:3000/mobile/verify-complaints/${userID}'));
    if (response.statusCode == 200) {
      // final List<dynamic> jsonResponse = json.decode(response.body);
      final List<dynamic> jsonResponse = json.decode(response.body);
      final pendingComplaints = jsonResponse.where((item) => (item['status'] == 'resolved'||item['status'] == 'verified'));
      setState(() {
        complaints = pendingComplaints.map((item) => Complaint.fromJson(item)).toList();
      });
    } else {
      throw Exception('Failed to fetch complaints');
    }
    setState(() {
      isDataFetched = false;
    });
  }

  @override
  void initState() {
    super.initState();
    fetchComplaints();
  }

  IconData getIconForStatus(String status) {
    switch (status) {
      case 'pending':
        return Icons.warning;
      case 'inProgress':
        return Icons.timer;
      case 'resolved':
        return Icons.check_circle;
      default:
        return Icons.construction_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:  isDataFetched?Container(
          height: MediaQuery.of(context).size.height * 0.20,
          width: MediaQuery.of(context).size.width * 0.90,
          child: Center(child: CircularProgressIndicator())):ListView.builder(
        itemCount: complaints.length,
        itemBuilder: (BuildContext context, int index) {
          final complaint = complaints[index];
          return ListTile(
            leading: Icon(getIconForStatus(complaint.status),size: 30,),
            title: Container(
              margin: EdgeInsets.symmetric(vertical: 5),
              child: Text(complaint.id,style: GoogleFonts.aBeeZee(
                  color: Colors.black,
                  fontSize: 10
              ),),
            ),
            subtitle: Container(
                width: double.maxFinite,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(complaint.description,style: GoogleFonts.aBeeZee(
                      color: Colors.black,
                    ),),
                    SizedBox(height: 5,),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: GridView.builder(
                            itemCount: complaint.images.length,
                            shrinkWrap: true,
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                            ),
                            itemBuilder: (BuildContext context, int imageIndex) {
                              final imageUrl = complaint.images[imageIndex];
                              return Container(
                                height: 50,
                                width: 50,
                                margin: EdgeInsets.all(5) ,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(5),
                                    topRight: Radius.circular(5),
                                    bottomRight: Radius.circular(5),
                                    bottomLeft: Radius.circular(5),
                                  ),
                                  child: InkWell(
                                    onTap: () async{
                                      await launch('http://143.110.177.156:3000/${imageUrl}');
                                    },
                                    child: Image.network(
                                      'http://143.110.177.156:3000/${imageUrl}',
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                              );
                            },
                          ),
                        ),
                        SizedBox(width: 5,),
                        Expanded(
                          flex: 2,
                          child: ClipRRect(
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(20),
                              topRight: Radius.circular(20),
                              bottomRight: Radius.circular(20),
                              bottomLeft: Radius.circular(20),
                            ),
                            child: Container(
                              height: 100,
                              child: Material(
                                elevation: 5,
                                child: GoogleMap(
                                  liteModeEnabled: true,
                                  mapToolbarEnabled:false,
                                  compassEnabled:false,
                                  rotateGesturesEnabled:false,
                                  myLocationButtonEnabled:false,
                                  initialCameraPosition: CameraPosition(
                                    target: LatLng(complaint.latitude, complaint.longitude),
                                    zoom: 16,
                                  ),
                                  markers: LatLng(complaint.latitude, complaint.longitude) != null
                                      ? {
                                    Marker(
                                      markerId: MarkerId('pickedLocation'),
                                      position: LatLng(complaint.latitude, complaint.longitude)!,
                                    )
                                  }
                                      : {},
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Container(margin: EdgeInsets.symmetric(vertical: 5),child: Divider(height: 2,color: Colors.black54,)),
                  ],
                )),
            onTap: () {

            },
          );
        },
      ),
    );
  }
}
