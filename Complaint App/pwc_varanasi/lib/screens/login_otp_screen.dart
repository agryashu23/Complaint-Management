import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_otp_text_field/flutter_otp_text_field.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:pwc_varanasi/screens/edit_profile_screen.dart';
import 'package:pwc_varanasi/screens/home_contract_screen.dart';
import 'package:pwc_varanasi/screens/home_screen.dart';
import 'package:pwc_varanasi/screens/home_verify_screen.dart';
import 'package:requests/requests.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'profile_screen.dart';

class LoginOTPScreen extends StatefulWidget {
  final String verificationId;
  final String phone;

  const LoginOTPScreen({super.key, required this.verificationId, required this.phone});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginOTPScreen> {
  final _formKey = GlobalKey<FormState>();
  bool? isLogging = false;
  String code = "";

  @override
  void initState() {
    super.initState();
  }

  void signInWithPhoneCredential(
       PhoneAuthCredential phoneCredential,  String phone) async {
    try {
      setState((){
        isLogging = true;
      });
      final authCredential =
      await FirebaseAuth.instance.signInWithCredential(phoneCredential);
      if (authCredential.user != null) {
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        var r = await Requests.post('http://143.110.177.156:3000/mobile/login',
            body: {
              'mobileNumber': '+91${phone}',
            },
            bodyEncoding: RequestBodyEncoding.FormURLEncoded);
        r.raiseForStatus();
        dynamic json = r.json();
        if (json['customer'].containsKey('_id')) {
          OneSignal.shared
              .setExternalUserId(json!['customer']['_id'])
              .then((results) {})
              .catchError((error) {});
          await prefs.setString('loggedIn', 'true');
          await prefs.setString('userID', json!['customer']['_id']);
          await prefs.setString('mobile', json!['customer']['mobileNumber']);
          await prefs.setString('name', json!['customer']['name']);
          await prefs.setString('type', json!['customer']['type']);
          // await prefs.setString('type', json!['customer']['firebaseUid']);
          if(json!['customer']['type'] == 'verify'){
            setState((){
              isLogging = false;
            });
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) {
              return HomeVerifyScreen();
            }));
          }
          else if(json!['customer']['type'] == 'contract') {
            setState((){
              isLogging = false;
            });
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) {
              return HomeContractScreen();
            }));
          }
          else{
            setState((){
              isLogging = false;
            });
            if(json!['customer']['name']==""){
              UserProfile userProfile = UserProfile.fromJson(json!['customer']);
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>EditProfileScreen(
                userProfile: userProfile!,
                fromLogin: true
              )));
            }else {
              Navigator.pushReplacement(
                  context, MaterialPageRoute(builder: (context) {
                return HomeScreen(screen:0);
              }));
            }
          }
        }
      }
    } on FirebaseException catch (e) {
      setState((){
        isLogging = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: Colors.tealAccent,
        duration: Duration(seconds: 2),
        content: Text("Enter Correct OTP"),
      ));
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(

      body: SafeArea(
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: Container(
                height: MediaQuery.of(context).size.height * 0.40,
                child: Stack(
                  children: [
                    Image.asset(
                      'images/login_back.jpg',
                      height: double.infinity,
                      fit: BoxFit.cover,
                    ),
                    Center(
                      child: Hero(tag: 'logo',
                        child: Image.asset(
                          'images/colored_logo.png',
                          width: MediaQuery.of(context).size.width * 0.75,
                          color: Colors.white,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Material(
                elevation: 5,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(30),topRight: Radius.circular(30)),
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.60,
                  padding: EdgeInsets.all(10),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: 25.0),
                      Padding(
                        padding: const EdgeInsets.only(left: 20),
                        child: Text(
                          "Please enter the OTP sent to your mobile.",
                          style: GoogleFonts.openSans(
                              color: Colors.black54, fontWeight: FontWeight.bold),
                        ),
                      ),
                      OtpTextField(
                        numberOfFields: 6,
                        enabledBorderColor: Color(0xFFF1F1F1),
                        textStyle:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        //set to true to show as box or false to show as dash
                        showFieldAsBox: true,
                        keyboardType: TextInputType.number,
                        filled: true,
                        fillColor: Color(0xFFF1F1F1),
                        borderRadius: BorderRadius.circular(20.0),
                        decoration: InputDecoration(
                          contentPadding:
                          EdgeInsets.symmetric(vertical: 2, horizontal: 2),
                        ),
                        onSubmit: (String verificationCode) {
                          setState(() {
                            code = verificationCode;
                          });
                        }, // end onSubmit
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 20, right: 20),
                        child:  isLogging!
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
                              color: Colors.blue,
                            ),
                            child: InkWell(
                              onTap: () async {

                                PhoneAuthCredential phoneCredential =
                                PhoneAuthProvider.credential(
                                  verificationId: widget.verificationId,
                                  smsCode: code,
                                );
                                signInWithPhoneCredential(phoneCredential, widget.phone);
                              },
                              borderRadius: BorderRadius.circular(20.0),
                              child: Container(
                                padding: EdgeInsets.all(10.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "Login",
                                      style: GoogleFonts.aBeeZee(
                                        color: Colors.white,
                                      ),
                                    ),
                                    SizedBox(width: 10.0),
                                    Icon(
                                      Icons.login_rounded,
                                      color: Colors.white,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 15.0),
                    ],
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

}
