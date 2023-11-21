import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:requests/requests.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Notification {

  final String time;
  final String message;
  final String title;
  const Notification(this.time, this.message, this.title);
}

class NotificationScreen extends StatefulWidget {
  @override
  _NotificationScreenState createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {

  List<Notification> notifications = [];


  @override
  void initState() {
    super.initState();
    handleProfile();
  }

  void handleProfile() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String userID = await prefs.getString('userID')??'';
    print(userID);
    var response =
    await Requests.get('http://143.110.177.156:3000/mobile/notifications/'+userID,
        bodyEncoding: RequestBodyEncoding.FormURLEncoded);
    response.raiseForStatus();
    dynamic json = response.json();
    // if(json['success']==true){
      for(int i =0; i<json.length;i++ ){
        notifications.add(Notification(json[i]['time'], json[i]['message'], json[i]['title']));
      }
    // }
    setState(() {

    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: Text(
          'Notifications',
          style: GoogleFonts.aBeeZee(
              fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: ListView.builder(
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          return Container(
            color: index%2==0?Color(0XFFE2FAFF) :Colors.white,
            child: ListTile(
              leading: Icon(Icons.notifications,color:Colors.black),
              title: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 5,),
                  Text(notifications[index].title,style: GoogleFonts.aBeeZee(
                      fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),),
                  SizedBox(height: 5,),
                  Text(notifications[index].message,style: GoogleFonts.aBeeZee(
                      fontSize: 14, fontWeight: FontWeight.normal, color: Colors.black),),
                  SizedBox(height: 5,),
                ],
              ),
              onTap: () {
                // Handle notification tap
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(notifications[index].title,style: GoogleFonts.aBeeZee(
                    fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),),
                    content: Text(notifications[index].message,style: GoogleFonts.aBeeZee(
                        fontSize: 14, fontWeight: FontWeight.normal, color: Colors.black),),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: Text('OK',style: GoogleFonts.aBeeZee(
                            fontSize: 12, fontWeight: FontWeight.normal, color: Colors.black),),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
