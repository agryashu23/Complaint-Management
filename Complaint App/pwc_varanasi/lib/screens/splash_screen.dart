import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pwc_varanasi/screens/home_contract_screen.dart';
import 'package:pwc_varanasi/screens/home_screen.dart';
import 'package:pwc_varanasi/screens/home_verify_screen.dart';
import 'package:pwc_varanasi/screens/login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  @override
  void initState() {
    super.initState();
    Timer(Duration(seconds: 2),() async {
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        String loginStatus = await prefs.getString('loggedIn')??'false';
        String admin = await prefs.getString('type')??'user';
        print(admin);
        if(loginStatus =='true'){
          if(admin == 'verify') {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) {
              return HomeVerifyScreen();
            }));
          }
          else if(admin == 'contract') {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) {
              return HomeContractScreen();
            }));
          }
          else {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) {
              return HomeScreen(screen: 0,);
            }));
          }
        }else{
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (context) => LoginScreen()));
        }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Center(child: Hero(tag: 'logo',
      child: Image.asset('images/colored_logo.png',height: 150,width: MediaQuery.of(context).size.width*0.60,)),),
    );
  }
}