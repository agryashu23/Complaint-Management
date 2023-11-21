import 'package:flutter/material.dart';
import 'package:flutter_google_places/flutter_google_places.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_api_headers/google_api_headers.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:pwc_varanasi/location.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:google_api_headers/google_api_headers.dart';

class SelectLocation extends StatefulWidget {
  const SelectLocation({super.key});

  @override
  State<SelectLocation> createState() => _SelectLocationState();
}

class _SelectLocationState extends State<SelectLocation> {

  List<Locations> locations = [];
  String status = '';
  Prediction? place;
  Placemark? places;
  String? _currentAddress;
  LatLng? _currentPosition;
  // Position? _currentPosition;
  String googleApikey = "AIzaSyC1A7zM67k09UeHvPcf0DJo_OHcx9pdwQc";
  GoogleMapController? mapController; //contrller for Google map
  CameraPosition? cameraPosition;
  LatLng startLocation = LatLng(25.2620319, 82.9858812);
  String location = "Search Location";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select Location'),
      ),
        body: Stack(
            children:[
              GoogleMap(
                zoomControlsEnabled: false,
                zoomGesturesEnabled: true,
                compassEnabled: false,
                padding: EdgeInsets.only(bottom: 75),
                initialCameraPosition: CameraPosition(
                  target: startLocation,
                  zoom: 15.0,
                ),
                mapType: MapType.normal, //map type
                onMapCreated: (controller) { //method called when map is created
                  setState(() {
                    mapController = controller;
                  });
                },
              ),
              // Align(
              //     alignment: Alignment.topCenter,
              //     child: SearchMapPlaceWidget(
              //       hasClearButton: true,
              //       apiKey: googleApikey,
              //       bgColor: Colors.white,
              //       textColor: Colors.black,
              //       placeType: PlaceType.address,
              //       placeholder: "Enter the location",
              //       onSelected: (Place place)async{
              //         Geolocation? geolocation = await place.geolocation;
              //         mapController!.animateCamera(CameraUpdate.newLatLng(geolocation!.coordinates));
              //         mapController!.animateCamera(CameraUpdate.newLatLngBounds(geolocation.bounds,0));
              //
              //       },
              //
              //     )
              //
              // ),




              //search autoconplete input
              Positioned(  //search input bar
                  top:10,
                  child: InkWell(
                      onTap: () async {
                        place = await PlacesAutocomplete.show(
                            context: context,
                            apiKey: googleApikey,
                            mode: Mode.overlay,
                            language: 'en',
                            radius: 1000000,
                            types: [""],
                            strictbounds: false,
                            components: [Component(Component.country, 'in')],
                            //google_map_webservice package
                            onError: (err){
                              print(err);
                            }
                        );

                        if(place != null){
                          setState(() {
                            location = place!.description.toString();
                          });

                          //form google_maps_webservice package
                          GoogleMapsPlaces plist = GoogleMapsPlaces(apiKey:googleApikey,
                            apiHeaders: await GoogleApiHeaders().getHeaders(),
                            //from google_api_headers package
                          );
                          String placeid = place!.placeId ?? "0";
                          PlacesDetailsResponse detail = await plist.getDetailsByPlaceId(place!.placeId.toString());
                          final lat = detail.result.geometry!.location.lat;
                          final lang = detail.result.geometry!.location.lng;
                          _currentPosition = LatLng(lat, lang);
                          var newlatlang = LatLng(lat, lang);
                          await placemarkFromCoordinates(
                              lat, lang)
                              .then((List<Placemark> placemarks) {
                            places = placemarks[0];
                            setState(() async{
                              _currentAddress =
                              '${places!.name}, ${places!.street}, ${places!.subLocality},';
                              // joy.addDirections();
                            });
                          }).catchError((e) {
                            debugPrint(e);
                          });
                          setState(() {
                            mapController?.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(target: newlatlang, zoom: 18)));
                          });
                          //move map camera to selected place with animation
                        }

                      },
                      child:Padding(
                        padding: EdgeInsets.all(15),
                        child: Material(
                          elevation: 5,
                          borderRadius: BorderRadius.circular(20.0),
                          child: Ink(
                            width: MediaQuery.of(context).size.width-40,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20.0),
                                color: Colors.white,
                              ),
                              child: ListTile(
                              title:Text(location, style: TextStyle(fontSize: 18),),
                              trailing: Icon(Icons.search),
                              dense: true,
                            )
                          )
                        ),
                      )
                  )
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Material(
                    elevation: 5,
                    borderRadius: BorderRadius.circular(20.0),
                    child: Ink(
                      height: 45,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20.0),
                          color:Colors.green
                      ),
                      child: InkWell(
                        onTap: () {
                          Navigator.pop(context, {
                            'latitude':_currentPosition!.latitude,
                            'longitude':_currentPosition!.longitude,
                            'postalCode':places!.postalCode, 'address':_currentAddress,'area': places!.subAdministrativeArea,'aArea': places!.administrativeArea,
                          });
                        },
                        borderRadius: BorderRadius.circular(20.0),
                        child: Container(
                          padding: EdgeInsets.all(10.0),
                          child: Row(
                            mainAxisAlignment:
                            MainAxisAlignment.center,
                            children: [
                              Text(
                                "Select",
                                style: GoogleFonts.aBeeZee(
                                    color: Colors.white,
                                    fontSize: 12
                                ),
                              ),
                              SizedBox(width: 10.0),
                              Icon(
                                Icons.save,
                                color: Colors.white,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ]
        )
    );
  }
}
