import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pwc_varanasi/screens/complaints_screen.dart';
import 'package:pwc_varanasi/screens/verify_complain_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../fragments/pending_complaints_verify_fragment.dart';

class ComplaintDetailScreen extends StatefulWidget {
  final Complaint complaint;
  ComplaintDetailScreen(this.complaint);

  @override
  _ComplaintDetailScreenState createState() => _ComplaintDetailScreenState();
}

class _ComplaintDetailScreenState extends State<ComplaintDetailScreen> {
  TextEditingController _textController = TextEditingController();
  List<File> _selectedImages = [];
  GoogleMapController? _mapController;
  LatLng? _pickedLocation;
  bool locationFetched = true;
  bool isRegistering = false;

  @override
  void dispose() {
    _mapController!.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // _locationPicker();
  }

  void _locationPicker() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return;
      }
    }
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    setState(() {
      locationFetched = false;
      _pickedLocation = LatLng(position.latitude, position.longitude);
    });
    await Future.delayed(Duration(milliseconds: 500));
    _mapController!.animateCamera(CameraUpdate.newLatLngZoom(
        LatLng(position.latitude, position.longitude), 15));
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  void _selectLocation(LatLng location) {
    setState(() {
      _pickedLocation = location;
    });
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
              },
            ),
          ],
        );
      },
    );
  }


  Future<void> _showMyDialogSuccess(String message, String title) async {
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
                Navigator.of(context)..pop()..pushReplacement(MaterialPageRoute(builder: (context)=>ComplaintsScreen(screen: 0,)));
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickImages() async {
    final List<XFile>? pickedImages = await ImagePicker().pickMultiImage(
      imageQuality: 80,
      maxWidth: 800,
    );
    if (pickedImages != null && pickedImages.isNotEmpty) {
      if (pickedImages.length > 5) {
        _showMyDialog(
            'You can select maximum 5 images. Please reselect images to proceed.',
            'Error');
        return;
      }
      setState(() {
        _selectedImages =
            pickedImages.map((XFile image) => File(image.path)).toList();
      });
    }
  }

  Future<void> uploadImagesToServer() async {
    setState(() {
      isRegistering = true;
    });
    final url = 'http://143.110.177.156:3000/mobile/complaints';
    var request = http.MultipartRequest('POST', Uri.parse(url));
    for (var i = 0; i < _selectedImages.length; i++) {
      final image = _selectedImages[i];
      final imageStream = http.ByteStream(Stream.castFrom(image.openRead()));
      final imageSize = await image.length();
      final multipartFile = http.MultipartFile(
        'images',
        imageStream,
        imageSize,
        filename: image.path.split('/').last,
      );
      request.files.add(multipartFile);
    }
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String userID = await prefs.getString('userID') ?? 'false';
    Map<String, String> params = {
      'user': userID,
      'title': '',
      'address': '',
      'latitude': _pickedLocation!.latitude.toString(),
      'longitude': _pickedLocation!.longitude.toString(),
      'description': _textController.text
    };
    params.forEach((key, value) {
      request.fields[key] = value;
    });
    try {
      final response = await request.send();
      if (response.statusCode == 201) {
        _showMyDialogSuccess(
            'Complaint log successfully. Please check my complaints section for updates.',
            'Success');
      } else {
        _showMyDialog(
            'Failed to upload images. Status code: ${response.statusCode}',
            'Error');
      }
    } catch (e) {
      _showMyDialog('Error occurred while uploading images: $e', 'Error');
    }
    setState(() {
      isRegistering = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Complaint Details'),
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Text(
                "Location",
                style: GoogleFonts.aBeeZee(
                    fontSize: 14,
                    color: Colors.black54,
                    fontWeight: FontWeight.bold
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: ClipRRect(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                ),
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.20,
                  width: MediaQuery.of(context).size.width * 0.90,
                  child: Material(
                    elevation: 5,
                    child: GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: LatLng(widget.complaint.latitude,widget.complaint.longitude),
                        zoom: 15,
                      ),
                      onMapCreated: _onMapCreated,
                      onTap: _selectLocation,
                      markers: LatLng(widget.complaint.latitude,widget.complaint.longitude) != null
                          ? {
                        Marker(
                          markerId: MarkerId('pickedLocation'),
                          position: LatLng(widget.complaint.latitude,widget.complaint.longitude)!,
                        )
                      }
                          : {},
                    ),
                  ),
                ),
              ),
            ),
            // Padding(
            //   padding: const EdgeInsets.all(16.0),
            //   child: _pickedLocation != null
            //       ? Text(
            //     'Picked Location: ${_pickedLocation!.latitude}, ${_pickedLocation!.longitude}',
            //     style: TextStyle(fontSize: 16.0),
            //   )
            //       : Text(
            //     'Tap on the map to pick a location',
            //     style: TextStyle(fontSize: 16.0),
            //   ),
            // ),
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Text(
                "Description",
                style: GoogleFonts.aBeeZee(
                    fontSize: 14,
                    color: Colors.black54,
                    fontWeight: FontWeight.bold
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 20),
              child: Material(
                borderRadius: BorderRadius.circular(20.0),
                child: Ink(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20.0),
                    color: Color(0xFFF1F1F1),
                  ),
                  child: Container(
                    width: double.maxFinite,
                    padding: EdgeInsets.all(10),
                    child: Text(
                      widget.complaint.description,
                      style: TextStyle(
                        color: Colors.black54,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Text(
                "Images",
                style: GoogleFonts.aBeeZee(
                    fontSize: 14,
                    color: Colors.black54,
                    fontWeight: FontWeight.bold
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(20.0),
              child: GridView.builder(
                shrinkWrap: true,
                itemCount: widget.complaint.images.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3, // Number of columns
                  mainAxisSpacing: 5.0, // Spacing between rows
                  crossAxisSpacing: 5.0, // Spacing between columns
                  childAspectRatio: 1.0, // Width to height ratio of grid items
                ),
                itemBuilder: (BuildContext context, int index) {
                  return  InkWell(
                  onTap: () async{
                  await launch('http://143.110.177.156:3000/${widget.complaint.images[index]}');
                  },
                  child: Container(
                    margin: EdgeInsets.symmetric(vertical: 8.0),
                    height: 50,
                    width: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8.0),
                      image: DecorationImage(
                        image: NetworkImage('http://143.110.177.156:3000/${widget.complaint.images[index]}'),
                        fit: BoxFit.contain,
                      ),
                    ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 20),
              child: Row(
                children: [
                  Expanded(
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
                                  onTap: () {
                                    Navigator.push(context, MaterialPageRoute(builder: (context)=>VerifyComplainScreen(widget.complaint)));
                                  },
                                  borderRadius: BorderRadius.circular(20.0),
                                  child: Container(
                                    padding: EdgeInsets.all(10.0),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          "Verify",
                                          style: GoogleFonts.aBeeZee(
                                            color: Colors.white,
                                          ),
                                        ),
                                        SizedBox(width: 10.0),
                                        Icon(
                                          Icons.send,
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
            SizedBox(
              height: 20,
            ),
          ],
        ),
      ),
    );
  }
}
