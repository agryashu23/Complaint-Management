import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pwc_varanasi/screens/faq_screen.dart';
import 'package:pwc_varanasi/screens/home_screen.dart';
import 'package:pwc_varanasi/screens/login_otp_screen.dart';
import 'package:requests/requests.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController _mobileController = TextEditingController();
  String? verifiId;
  bool? isLogging = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.black, // Change this to the desired color
    ));
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
                        padding: const EdgeInsets.all(20.0),
                        child: Text(
                          "Please enter your mobile.",
                          style: GoogleFonts.openSans(
                              color: Colors.black54, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 20, right: 20),
                        child: Material(
                          borderRadius: BorderRadius.circular(20.0),
                          child: Ink(
                            height: 50,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20.0),
                              color: Color(0xFFF1F1F1),
                            ),
                            child: TextFormField(
                              controller: _mobileController,
                              keyboardType: TextInputType.phone,
                              decoration: InputDecoration(
                                labelText: 'Mobile Number',
                                prefixIcon: Icon(
                                  Icons.phone_android,
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
                      SizedBox(height: 15.0),
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
                                  if (_mobileController.text.length == 10) {
                                    setState((){
                                      isLogging = true;
                                    });
                                    await FirebaseAuth.instance.signOut();
                                    await FirebaseAuth.instance.verifyPhoneNumber(
                                      phoneNumber:
                                      '+91${_mobileController.text.trimRight()}',
                                      verificationCompleted:
                                          (PhoneAuthCredential credential) {},
                                      verificationFailed:
                                          (FirebaseAuthException e) {
                                            setState((){
                                              isLogging = false;
                                            });
                                        ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                                content: Text(
                                                    'Enter Correct Mobile Number')));
                                      },
                                      codeSent: (String verificationId,
                                          int? resendToken) {
                                        verifiId = verificationId;

                                        setState((){
                                          isLogging = false;
                                        });
                                        Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) => LoginOTPScreen(
                                                verificationId:
                                                verifiId.toString(),
                                                phone: _mobileController.text,
                                              )),
                                        );
                                      },
                                      codeAutoRetrievalTimeout: (String verId) {
                                        verifiId = verId;
                                      },
                                    );
                                  } else {
                                    setState((){
                                      isLogging = false;
                                    });
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                        content: Text(
                                            'Please Enter Correct Mobile Number')));
                                  }
                              },
                              borderRadius: BorderRadius.circular(20.0),
                              child: Container(
                                padding: EdgeInsets.all(10.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "Send OTP",
                                      style: GoogleFonts.aBeeZee(
                                        color: Colors.white,
                                      ),
                                    ),
                                    SizedBox(width: 10.0),
                                    Icon(
                                      Icons.send_rounded,
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
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: Row(
                          children: [
                            Expanded(
                              child: Divider(
                                color: Colors.black54,
                                thickness: 1.0,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0),
                              child: Text(
                                'OR',
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  color: Colors.black54,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Divider(
                                color: Colors.black54,
                                thickness: 1.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 15.0),
                      // Padding(
                      //   padding: const EdgeInsets.only(left: 20, right: 20),
                      //   child: Material(
                      //     elevation: 5,
                      //     borderRadius: BorderRadius.circular(20.0),
                      //     child: Ink(
                      //       height: 45,
                      //       decoration: BoxDecoration(
                      //         borderRadius: BorderRadius.circular(20.0),
                      //         color: Color(0xFF7A7A7A),
                      //       ),
                      //       child: InkWell(
                      //         onTap: () async {
                      //           if (_formKey.currentState!.validate()) {
                      //             if (_mobileController.text.length == 10) {
                      //               await FirebaseAuth.instance.signOut();
                      //               await FirebaseAuth.instance.verifyPhoneNumber(
                      //                 phoneNumber:
                      //                 '+91${_mobileController.text.trimRight()}',
                      //                 verificationCompleted:
                      //                     (PhoneAuthCredential credential) {},
                      //                 verificationFailed:
                      //                     (FirebaseAuthException e) {
                      //                   ScaffoldMessenger.of(context).showSnackBar(
                      //                       SnackBar(
                      //                           content: Text(
                      //                               'Enter Correct Mobile Number')));
                      //                 },
                      //                 codeSent: (String verificationId,
                      //                     int? resendToken) {
                      //                   verifiId = verificationId;
                      //                   Navigator.pushReplacement(
                      //                     context,
                      //                     MaterialPageRoute(
                      //                         builder: (context) => LoginOTPScreen(
                      //                           verificationId:
                      //                           verifiId.toString(),
                      //                           phone: _mobileController.text,
                      //                         )),
                      //                   );
                      //                 },
                      //                 codeAutoRetrievalTimeout: (String verId) {
                      //                   verifiId = verId;
                      //                 },
                      //               );
                      //             } else {
                      //               ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      //                   content: Text(
                      //                       'Please Enter Correct Mobile Number')));
                      //             }
                      //           }
                      //         },
                      //         borderRadius: BorderRadius.circular(20.0),
                      //         child: Container(
                      //           padding: EdgeInsets.all(10.0),
                      //           child: Row(
                      //             mainAxisAlignment: MainAxisAlignment.center,
                      //             children: [
                      //               Text(
                      //                 "Verification Officer Login",
                      //                 style: GoogleFonts.aBeeZee(
                      //                   color: Colors.white,
                      //                 ),
                      //               ),
                      //               SizedBox(width: 10.0),
                      //               Icon(
                      //                 Icons.verified_user_rounded,
                      //                 color: Colors.white,
                      //               ),
                      //             ],
                      //           ),
                      //         ),
                      //       ),
                      //     ),
                      //   ),
                      // ),
                      // SizedBox(height: 10.0),
                      // Padding(
                      //   padding: const EdgeInsets.only(left: 20, right: 20),
                      //   child: Material(
                      //     elevation: 5,
                      //     borderRadius: BorderRadius.circular(20.0),
                      //     child: Ink(
                      //       height: 45,
                      //       decoration: BoxDecoration(
                      //         borderRadius: BorderRadius.circular(20.0),
                      //         color: Colors.green,
                      //       ),
                      //       child: InkWell(
                      //         onTap: () async {
                      //           if (_formKey.currentState!.validate()) {
                      //             if (_mobileController.text.length == 10) {
                      //               await FirebaseAuth.instance.signOut();
                      //               await FirebaseAuth.instance.verifyPhoneNumber(
                      //                 phoneNumber:
                      //                 '+91${_mobileController.text.trimRight()}',
                      //                 verificationCompleted:
                      //                     (PhoneAuthCredential credential) {},
                      //                 verificationFailed:
                      //                     (FirebaseAuthException e) {
                      //                   ScaffoldMessenger.of(context).showSnackBar(
                      //                       SnackBar(
                      //                           content: Text(
                      //                               'Enter Correct Mobile Number')));
                      //                 },
                      //                 codeSent: (String verificationId,
                      //                     int? resendToken) {
                      //                   verifiId = verificationId;
                      //                   Navigator.pushReplacement(
                      //                     context,
                      //                     MaterialPageRoute(
                      //                         builder: (context) => LoginOTPScreen(
                      //                           verificationId:
                      //                           verifiId.toString(),
                      //                           phone: _mobileController.text,
                      //                         )),
                      //                   );
                      //                 },
                      //                 codeAutoRetrievalTimeout: (String verId) {
                      //                   verifiId = verId;
                      //                 },
                      //               );
                      //             } else {
                      //               ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      //                   content: Text(
                      //                       'Please Enter Correct Mobile Number')));
                      //             }
                      //           }
                      //         },
                      //         borderRadius: BorderRadius.circular(20.0),
                      //         child: Container(
                      //           padding: EdgeInsets.all(10.0),
                      //           child: Row(
                      //             mainAxisAlignment: MainAxisAlignment.center,
                      //             children: [
                      //               Text(
                      //             "Contract Officer Login",
                      //                 style: GoogleFonts.aBeeZee(
                      //                   color: Colors.white,
                      //                 ),
                      //               ),
                      //               SizedBox(width: 10.0),
                      //               Icon(
                      //                 Icons.handyman_rounded,
                      //                 color: Colors.white,
                      //               ),
                      //             ],
                      //           ),
                      //         ),
                      //       ),
                      //     ),
                      //   ),
                      // ),
                      // SizedBox(height: 10.0),
                      Padding(
                        padding: const EdgeInsets.only(left: 20, right: 20),
                        child: Material(
                          elevation: 5,
                          borderRadius: BorderRadius.circular(20.0),
                          child: Ink(
                            height: 45,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20.0),
                              color: Colors.orange,
                            ),
                            child: InkWell(
                              onTap: () async {
                                Navigator.push(context, MaterialPageRoute(builder: (context)=>FAQScreen()));
                              },
                              borderRadius: BorderRadius.circular(20.0),
                              child: Container(
                                padding: EdgeInsets.all(10.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "Frequently Asked Questions",
                                      style: GoogleFonts.aBeeZee(
                                        color: Colors.white,
                                      ),
                                    ),
                                    SizedBox(width: 10.0),
                                    Icon(
                                      Icons.question_answer_rounded,
                                      color: Colors.white,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Spacer(),
                      Padding(
                        padding: const EdgeInsets.all(5.0),
                        child: Center(
                          child: Text(
                            "Version: 1.0.1 Updated On: 24/08/2023",
                            style: GoogleFonts.openSans(
                              fontSize: 12,
                                color: Colors.black),
                          ),
                        ),
                      ),
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
