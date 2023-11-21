import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pwc_varanasi/screens/edit_profile_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserProfile {
  final String id;
  final String mobileNumber;
  final String firebaseUid;
  final String name;
  final String email;
  final String phone;

  UserProfile({
    required this.id,
    required this.mobileNumber,
    required this.firebaseUid,
    required this.name,
    required this.email,
    required this.phone,
  });


  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'mobileNumber': mobileNumber,
      'firebaseUid': firebaseUid,
      'name': name,
      'email': email,
      'phone': phone,
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['_id'],
      mobileNumber: json['mobileNumber'],
      firebaseUid: json['firebaseUid'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
    );
  }
}

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserProfile? userProfile;

  @override
  void initState() {
    super.initState();
    fetchUserProfile();
  }

  Future<void> fetchUserProfile() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      String userID = await prefs.getString('userID') ?? 'false';
      final response = await http.get(Uri.parse('http://143.110.177.156:3000/mobile/customers/${userID}'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          userProfile = UserProfile.fromJson(data);
        });
      } else {
        // Handle error response
        print('Failed to fetch user profile. Status code: ${response.statusCode}');
      }
    } catch (error) {
      // Handle network or decoding errors
      print('Failed to fetch user profile. Error: $error');
    }
  }

  void navigateToEditProfile() async{
    await Navigator.push(context, MaterialPageRoute(builder: (context)=>EditProfileScreen(
      userProfile: userProfile!,
      fromLogin: false,
    )));
    fetchUserProfile();
  }

  @override
  Widget build(BuildContext context) {
    if (userProfile == null) {
      // Show loading indicator or empty state while fetching data
      return Scaffold(
        appBar: AppBar(
          title: Text('Profile'),
        ),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
        actions: [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: navigateToEditProfile,
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              title: Text(
                'Name',
                style: TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                userProfile!.name,
                style: TextStyle(fontSize: 16.0),
              ),
            ),
            ListTile(
              title: Text(
                'Email',
                style: TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                userProfile!.email,
                style: TextStyle(fontSize: 16.0),
              ),
            ),
            ListTile(
              title: Text(
                'Phone',
                style: TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                userProfile!.mobileNumber,
                style: TextStyle(fontSize: 16.0),
              ),
            ),
          ],
        ),
      ),
    );
  }
}