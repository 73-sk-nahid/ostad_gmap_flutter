import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final GoogleMapController _googleMapController;

  final Location _location = Location();
  LatLng? _currentLocation;
  StreamSubscription? _streamLocation;

  late Marker _marker;
  final List<LatLng> _latLngList = [];
  final Set<Polyline> _polyLineSet = {};

  bool isFollowing = true;

  @override
  void initState() {
    listenToCurrentLocation();
    super.initState();
  }

  void listenToCurrentLocation() {
    _location.requestPermission();

    _location.hasPermission().then((value) {
      if(value == PermissionStatus.granted) {
        _location.changeSettings(interval: 10000);

        _streamLocation = _location.onLocationChanged.listen((LocationData locationData) {
          setState(() {
            _currentLocation = LatLng(locationData.latitude!, locationData.longitude!);

            updateMarker();
            updatePolyline();

            if(isFollowing) {
              _googleMapController.animateCamera(CameraUpdate.newLatLng(_currentLocation!));
            }
          });
        });
      }
    });
  }

  void updateMarker() {
    _marker = Marker(
      markerId: const MarkerId('current_location'),
      position: _currentLocation!,
      infoWindow: InfoWindow(
        title: 'My current location',
        snippet: 'Lat: ${_currentLocation!.latitude}, Lng: ${_currentLocation!.longitude}',
      ),
      onTap: () {
        _googleMapController
            .showMarkerInfoWindow(const MarkerId('current_location'));
      },
    );
  }

  void updatePolyline() {
    _latLngList.add(_currentLocation!);
    _polyLineSet.add(Polyline(
      polylineId: const PolylineId('polyline_list'),
      points: _latLngList,
      color: Colors.lightGreen,
      width: 6,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Map'),),
      body: _currentLocation == null ? loadingAndRefresh()
          : GoogleMap(
        onMapCreated: (GoogleMapController controller) {
          _googleMapController = controller;
        },
        initialCameraPosition: CameraPosition(
            zoom: 14,
            target: _currentLocation!
        ),
        markers: {_marker},
        polylines: _polyLineSet,
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: (){
          isFollowing = !isFollowing;
        },
        label: const Text('Follow Me'),
        backgroundColor: isFollowing ? Colors.lightGreen : Colors.blueGrey,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Center loadingAndRefresh() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          ElevatedButton(onPressed: (){
            setState(() {
              listenToCurrentLocation();
            });
          }, child: const Text('Refresh'))
        ],
      ),
    );
  }

  @override
  void dispose() {
    _streamLocation?.cancel();
    super.dispose();
  }
}