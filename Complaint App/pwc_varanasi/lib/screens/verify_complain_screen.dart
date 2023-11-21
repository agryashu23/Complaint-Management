import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pwc_varanasi/fragments/pending_complaints_verify_fragment.dart';
import 'package:pwc_varanasi/screens/complaints_screen.dart';
import 'package:pwc_varanasi/screens/create_complain_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:image/image.dart' as img; // Import the image package
import 'package:path_provider/path_provider.dart';

class VerifyComplainScreen extends StatefulWidget {
  final Complaint complaint;

  VerifyComplainScreen(this.complaint);

  @override
  _VerifyComplainScreenState createState() => _VerifyComplainScreenState();
}

class _VerifyComplainScreenState extends State<VerifyComplainScreen> {
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
    _locationPicker();
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
                Navigator.of(context)..pop()..pop()..pop();
              },
            ),
          ],
        );
      },
    );
  }


  Future<Address> getAddressFromLatLng(double latitude, double longitude) async {
    final apiKey = 'AIzaSyC1A7zM67k09UeHvPcf0DJo_OHcx9pdwQc';
    final url = 'https://maps.googleapis.com/maps/api/geocode/json?latlng=$latitude,$longitude&key=$apiKey';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final jsonResult = json.decode(response.body);
      if (jsonResult['status'] == 'OK') {
        final components = jsonResult['results'][0]['address_components'];
        String formattedAddress = jsonResult['results'][0]['formatted_address'];
        String city = '';
        String state = '';

        for (var component in components) {
          List<String> types = List<String>.from(component['types']);
          if (types.contains('locality')) {
            city = component['long_name'];
          }
          if (types.contains('administrative_area_level_1')) {
            state = component['short_name'];
          }
        }

        return Address(
          formattedAddress: formattedAddress,
          city: city,
          state: state,
        );
      } else {
        throw Exception('Error: ${jsonResult['status']}');
      }
    } else {
      throw Exception('Failed to fetch address');
    }
  }

  Future<void> _pickImages() async {
    if (_selectedImages.length > 5) {
      _showMyDialog(
          'You can select maximum 5 images. Please reselect images to proceed.',
          'Error');
      return;
    }
    final XFile? pickedImages = await ImagePicker().pickImage(
      imageQuality: 80, source: ImageSource.camera,
    );
    if (pickedImages != null) {
      File originalImageFile = File(pickedImages.path);
      img.Image originalImage = img.decodeImage(originalImageFile.readAsBytesSync())!;

      Address address = await getAddressFromLatLng(double.parse(_pickedLocation!.latitude.toString()), double.parse(_pickedLocation!.longitude.toString()));
      img.drawString(originalImage, "${address.city}, ${address.state}\n${address.formattedAddress}\n${_pickedLocation!.latitude.toString()},${_pickedLocation!.longitude.toString()}\n${DateTime.now().toString()}", font: img.arial24,y: originalImage.height - 120,);

      // Save the modified image
      Directory appDocDir = await getApplicationDocumentsDirectory();
      String imagePath = "${appDocDir.path}/image_${DateTime.now().millisecondsSinceEpoch}.jpg";
      File modifiedImageFile = File(imagePath);
      modifiedImageFile.writeAsBytesSync(img.encodeJpg(originalImage));

      setState(() {
        _selectedImages.add(modifiedImageFile);//.map((XFile image) => File(image.path)).toList();
      });
    }
  }


  Future<void> uploadImagesToServer() async {
    setState(() {
      isRegistering = true;
    });
    final url = 'http://143.110.177.156:3000/mobile/verify-complaints';
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
      'complaint':widget.complaint.id,
      'description': _textController.text
    };
    params.forEach((key, value) {
      request.fields[key] = value;
    });
    try {
      final response = await request.send();
      if (response.statusCode == 200) {
        _showMyDialogSuccess(
            'Verification was done successfully.',
            'Success');
      } else {
        _showMyDialog(
            'Failed to upload images. Status code: ${response.statusCode}',
            'Error');
      }
    } catch (e) {
      _showMyDialog('Error occurred while uploading images: $e', 'Error');
    }
    isRegistering = true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Verify Complaint'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // AnimatedSwitcher(
            //   duration: Duration(seconds: 1),
            //   child: locationFetched
            //       ? Container(
            //           height: MediaQuery.of(context).size.height * 0.20,
            //           width: MediaQuery.of(context).size.width * 0.90,
            //           child: Center(child: CircularProgressIndicator()))
            //       : Padding(
            //           padding: const EdgeInsets.all(10.0),
            //           child: ClipRRect(
            //             borderRadius: BorderRadius.only(
            //               topLeft: Radius.circular(20),
            //               topRight: Radius.circular(20),
            //               bottomRight: Radius.circular(20),
            //               bottomLeft: Radius.circular(20),
            //             ),
            //             child: Container(
            //               height: MediaQuery.of(context).size.height * 0.20,
            //               width: MediaQuery.of(context).size.width * 0.90,
            //               child: Material(
            //                 elevation: 5,
            //                 child: GoogleMap(
            //                   initialCameraPosition: CameraPosition(
            //                     target: LatLng(20.5937, 78.9629),
            //                     zoom: 3,
            //                   ),
            //                   onMapCreated: _onMapCreated,
            //                   onTap: _selectLocation,
            //                   markers: _pickedLocation != null
            //                       ? {
            //                           Marker(
            //                             markerId: MarkerId('pickedLocation'),
            //                             position: _pickedLocation!,
            //                           )
            //                         }
            //                       : {},
            //                 ),
            //               ),
            //             ),
            //           ),
            //         ),
            // ),
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
              padding: const EdgeInsets.only(left: 20, right: 20),
              child: Material(
                borderRadius: BorderRadius.circular(20.0),
                child: Ink(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20.0),
                    color: Color(0xFFF1F1F1),
                  ),
                  child: TextFormField(
                    controller: _textController,
                    keyboardType: TextInputType.text,
                    maxLines: 10,
                    decoration: InputDecoration(
                      labelText: 'Please explain the verification in details.',
                      prefixIcon: Icon(
                        Icons.edit_note_rounded,
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
            Padding(
              padding: EdgeInsets.all(20.0),
              child: GridView.builder(
                shrinkWrap: true,
                itemCount: _selectedImages.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3, // Number of columns
                  mainAxisSpacing: 5.0, // Spacing between rows
                  crossAxisSpacing: 5.0, // Spacing between columns
                  childAspectRatio: 1.0, // Width to height ratio of grid items
                ),
                itemBuilder: (BuildContext context, int index) {
                  return Container(
                    margin: EdgeInsets.symmetric(vertical: 8.0),
                    height: 50,
                    width: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8.0),
                      image: DecorationImage(
                        image: FileImage(_selectedImages[index]),
                        fit: BoxFit.cover,
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
                    child: Material(
                      elevation: 5,
                      borderRadius: BorderRadius.circular(20.0),
                      child: Ink(
                        height: 45,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20.0),
                          color: Colors.blue,
                        ),
                        child: InkWell(
                          onTap: _pickImages,
                          borderRadius: BorderRadius.circular(20.0),
                          child: Container(
                            padding: EdgeInsets.all(10.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Select Images",
                                  style: GoogleFonts.aBeeZee(
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(width: 10.0),
                                Icon(
                                  Icons.image_search_rounded,
                                  color: Colors.white,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 10,
                  ),
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
                                  color: _selectedImages.length > 0 &&
                                          _textController.text.isNotEmpty
                                      ? Colors.green
                                      : Colors.grey,
                                ),
                                child: InkWell(
                                  onTap: () {
                                    if (_selectedImages.length >2 &&
                                        _textController.text.isNotEmpty) {
                                      uploadImagesToServer();
                                    }
                                    else{
                                      _showMyDialog('Please select minimum 3 images and add description about the project.', 'Error');
                                    }
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
                                          Icons.verified,
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
