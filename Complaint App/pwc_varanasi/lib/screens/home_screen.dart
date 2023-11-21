import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pwc_varanasi/fragments/complaints_fragment.dart';
import 'package:pwc_varanasi/fragments/dashboard_fragment.dart';
import 'package:pwc_varanasi/fragments/profile_fragment.dart';
import 'package:pwc_varanasi/screens/notification_screen.dart';
import 'package:pwc_varanasi/screens/splash_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import 'package'

class HomeScreen extends StatefulWidget {
  final int screen;
  const HomeScreen({super.key, required this.screen});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;


  @override
  void initState() {
    super.initState();
    setState(() {
      _currentIndex = widget.screen;
    });
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
        statusBarColor: Colors.black,
        systemNavigationBarColor: Colors.white
    ));
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Hero(tag: 'logo',
          child: Image.asset(
            'images/colored_logo.png',
            color: Colors.white,
            height: 100,
            fit: BoxFit.fill,
          ),
        ),
        actions: [
          // IconButton(onPressed: (){}, icon: Icon(Icons.language)),
          IconButton(onPressed: () async {
            Navigator.push(context, MaterialPageRoute(builder: (context)=>NotificationScreen()));
          }, icon: Icon(Icons.notifications_active_rounded)),
          IconButton(onPressed: () async {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Text("Warning!"),
                  content: Text("Do you really want to logout?"),
                  actions: <Widget>[
                    TextButton(
                      child: Text("Cancel"),
                      onPressed: () async {
                        Navigator.of(context)..pop();
                      },
                    ),
                    TextButton(
                      child: Text("Proceed"),
                      onPressed: () async {
                        final SharedPreferences prefs = await SharedPreferences.getInstance();
                        await prefs.remove('loggedIn');
                        await prefs.remove('userID');
                        await prefs.remove('mobile');
                        await prefs.remove('name');
                        await prefs.remove('type');
                        Navigator.of(context)..pop()..pushReplacement(MaterialPageRoute(builder: (context)=>SplashScreen()));
                      },
                    ),
                  ],
                );
              },
            );
          }, icon: Icon(Icons.logout))
        ],
      ),
      body: Stack(
        children: [
          Container(child: [
            DashboardFragment(),
            ComplaintsFragment(screen: 0,),
            ProfileFragment(),
          ][_currentIndex]),
          Align(
            alignment: Alignment.bottomCenter,
            child: CurvedNavigationBar(
              index: _currentIndex,
              backgroundColor: Colors.transparent,
              color: Theme.of(context).primaryColor,
              items: <Widget>[
                Icon(Icons.home_rounded, size: 30,color: Colors.white,),
                Icon(Icons.edit_note_rounded, size: 30,color: Colors.white,),
                Icon(Icons.manage_accounts, size: 30,color: Colors.white,),
              ],
              onTap: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
            ),
          )
        ],
      ),
    );
  }
}
