import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:pwc_varanasi/screens/home_screen.dart';
import 'package:pwc_varanasi/screens/profile_screen.dart';


class EditProfileScreen extends StatefulWidget {
  final UserProfile userProfile;
  final bool fromLogin;
  EditProfileScreen({required this.userProfile, required this.fromLogin});

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController nameController;
  late TextEditingController emailController;
  late TextEditingController phoneController;
  bool isRegistering = false;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.userProfile.name);
    emailController = TextEditingController(text: widget.userProfile.email);
    phoneController = TextEditingController(text: widget.userProfile.mobileNumber);
  }


  Future<void> _showMyDialog(String message, String title) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            title,
            style: GoogleFonts.aBeeZee(
              color: Colors.black,
            ),
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                  message,
                  style: GoogleFonts.aBeeZee(color: Colors.black, fontSize: 14),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'Ok',
                style: GoogleFonts.aBeeZee(
                  color: Colors.black,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                if(widget.fromLogin == true) {
                  Navigator.pushReplacement(context, MaterialPageRoute(
                      builder: (context) => HomeScreen(screen: 0)));
                }
              },
            ),
          ],
        );
      },
    );
  }


  Future<void> updateProfile() async {
    final updatedProfile = UserProfile(
      id: widget.userProfile.id,
      mobileNumber: widget.userProfile.mobileNumber,
      firebaseUid: widget.userProfile.firebaseUid,
      name: nameController.text,
      email: emailController.text,
      phone: phoneController.text,
    );

    final apiUrl = 'http://143.110.177.156:3000/mobile/customers/${widget.userProfile.id}';
    final headers = {'Content-Type': 'application/json'};

    try {
      final response = await http.patch(
        Uri.parse(apiUrl),
        headers: headers,
        body: json.encode(updatedProfile.toJson()),
      );
      if (response.statusCode == 200) {
        _showMyDialog('Profile edited successfully','Success');
      } else {
        _showMyDialog('Failed to update profile. Status code: ${response.statusCode}','Error');
      }
    } catch (error) {
      // Handle network or decoding errors
      _showMyDialog('Failed to update profile. Error: $error','Error');
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Profile'),
      ),
      body: Padding(
        padding: EdgeInsets.only(top: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 20),
              child: Material(
                borderRadius: BorderRadius.circular(20.0),
                child: Ink(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20.0),
                    color: Color(0xFFF1F1F1),
                  ),
                  child: TextFormField(
                    controller: nameController,
                    keyboardType: TextInputType.name,
                    decoration: InputDecoration(
                      labelText: 'Enter Name',
                      prefixIcon: Icon(
                        Icons.person,
                        color: Colors.black54,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20.0),
                        borderSide: BorderSide.none,
                      ),
                      labelStyle: TextStyle(
                        color: Colors.black54,
                      ),
                    ),
                    style: TextStyle(
                      color: Colors.black54,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 16.0),

            Padding(
              padding: const EdgeInsets.only(left: 20, right: 20),
              child: Material(
                borderRadius: BorderRadius.circular(20.0),
                child: Ink(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20.0),
                    color: Color(0xFFF1F1F1),
                  ),
                  child: TextFormField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Enter Email Address',
                      prefixIcon: Icon(
                        Icons.email_rounded,
                        color: Colors.black54,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20.0),
                        borderSide: BorderSide.none,
                      ),
                      labelStyle: TextStyle(
                        color: Colors.black54,
                      ),
                    ),
                    style: TextStyle(
                      color: Colors.black54,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 16.0),
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 20),
              child: Material(
                borderRadius: BorderRadius.circular(20.0),
                child: Ink(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20.0),
                    color: Color(0xFFF1F1F1),
                  ),
                  child: TextFormField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'Enter Mobile Number',
                      prefixIcon: Icon(
                        Icons.phone,
                        color: Colors.black54,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20.0),
                        borderSide: BorderSide.none,
                      ),
                      labelStyle: TextStyle(
                        color: Colors.black54,
                      ),
                    ),
                    style: TextStyle(
                      color: Colors.black54,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 24.0),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: AnimatedSwitcher(
                duration: Duration(seconds: 1),
                child: isRegistering
                    ? Container(
                    height: 50,
                    child: Center(child: CircularProgressIndicator()))
                    : Material(
                  elevation: 5,
                  borderRadius: BorderRadius.circular(20.0),
                  child: Ink(
                    height: 45,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20.0),
                      color:Colors.green,
                    ),
                    child: InkWell(
                      onTap:updateProfile,
                      borderRadius: BorderRadius.circular(20.0),
                      child: Container(
                        padding: EdgeInsets.all(10.0),
                        child: Row(
                          mainAxisAlignment:
                          MainAxisAlignment.center,
                          children: [
                            Text(
                              "Save Changes",
                              style: GoogleFonts.aBeeZee(
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 10.0),
                            Icon(
                              Icons.save,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}