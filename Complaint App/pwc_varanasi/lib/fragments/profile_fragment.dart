import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pwc_varanasi/screens/edit_profile_screen.dart';
import 'package:pwc_varanasi/screens/profile_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileFragment extends StatefulWidget {
  @override
  _ProfileFragmentState createState() => _ProfileFragmentState();
}

class _ProfileFragmentState extends State<ProfileFragment> {
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

  // void navigateToEditProfile() async{
  //   await Navigator.push(context, MaterialPageRoute(builder: (context)=>EditProfileFragment(
  //     userProfile: userProfile!,
  //   )));
  //   fetchUserProfile();
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 75.0),
        child: FloatingActionButton(onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (context)=>EditProfileScreen(
            userProfile: userProfile!,
            fromLogin: false,
          )));
          fetchUserProfile();
        },
          mini: false,
          child: Icon(Icons.edit),
        ),
      ),
      body: userProfile==null?Center(
        child: CircularProgressIndicator(),
      ):Padding(
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