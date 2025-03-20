import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:dio/dio.dart';

class MapScreen extends StatefulWidget {
  final String placeType;
  const MapScreen({super.key, required this.placeType});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? mapController;
  LatLng? _currentPosition;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  final String _apiKey = "AIzaSyA7qDSMl8SOjS_8-BHSRReewBXw_Um0sCw";
  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;
    // GPS yoqilganligini tekshiramiz
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint("Location services are disabled.");
      return;
    }
    // Ruxsatlarni tekshiramiz
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        debugPrint("User denied location permissions.");
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      debugPrint(
          "User permanently denied location permissions. Go to settings.");
      return;
    }
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    setState(() {
      _currentPosition = LatLng(position.latitude, position.longitude);
      _markers.add(
        Marker(
          markerId: const MarkerId("currentLocation"),
          position: _currentPosition!,
          infoWindow: const InfoWindow(title: "Sizning joylashuvingiz"),
        ),
      );
    });
    _goToCurrentLocation();
    _fetchNearbyCafes(); // Kafelarni yuklash
  }

  void _goToCurrentLocation() {
    if (_currentPosition != null && mapController != null) {
      mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(_currentPosition!, 15),
      );
    }
  }

  Future<void> _fetchNearbyCafes() async {
    if (_currentPosition == null) return;

    final url =
        "https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=${_currentPosition!.latitude},${_currentPosition!.longitude}&radius=5000&type=${widget.placeType}&key=$_apiKey";

    try {
      final response = await Dio().get(url);
      if (response.statusCode == 200) {
        final data = response.data;

        final results = data['results'] as List;
        for (var place in results) {
          print(place['photos']);
        }
        setState(() {
          _markers.addAll(results.map((place) {
            final location = place['geometry']['location'];
            final cafeLocation = LatLng(location['lat'], location['lng']);
            final rating = place.containsKey('rating')
                ? place['rating'].toString()
                : "No rating"; // Reytingni tekshiramiz
            // print(photos);

            return Marker(
              markerId: MarkerId(place['place_id']),
              position: cafeLocation,
              infoWindow: InfoWindow(
                title: place['name'],
                snippet: "⭐ $rating", // Reytingni infoWindow ichida chiqaramiz
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueOrange),
              onTap: () {
                _drawRoute(cafeLocation);
              },
            );
          }).toSet());
        });
      }
    } catch (e) {
      print("Error fetching cafes: $e");
    }
  }

  Future<void> _drawRoute(LatLng destination) async {
    if (_currentPosition == null) return;

    final String url = "https://maps.googleapis.com/maps/api/directions/json?"
        "origin=${_currentPosition!.latitude},${_currentPosition!.longitude}&"
        "destination=${destination.latitude},${destination.longitude}&"
        "key=$_apiKey";

    try {
      final response = await Dio().get(url);
      if (response.statusCode == 200) {
        final data = response.data;
        if (data['status'] == 'OK') {
          final points = data['routes'][0]['overview_polyline']['points'];
          final List<LatLng> routePoints = _decodePolyline(points);

          setState(() {
            _polylines.add(Polyline(
              polylineId: const PolylineId('route'),
              points: routePoints,
              color: Colors.blue,
              width: 5,
            ));
          });
        }
      }
    } catch (e) {
      // ignore: avoid_print
      print("Error drawing route: $e");
    }
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;
    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;
      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return points;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text("All ${widget.placeType}s in your near"),
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _currentPosition ?? const LatLng(0, 0),
              zoom: 15,
            ),
            mapType: MapType.normal,
            markers: _markers,
            polylines: _polylines,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            onMapCreated: (GoogleMapController controller) {
              mapController = controller;
              // Custom map style
              controller.setMapStyle('''
                [
                  {
                    "featureType": "poi",
                    "elementType": "labels.text.fill",
                    "stylers": [{"color": "#6A5ACD"}]
                  },
                  {
                    "featureType": "landscape",
                    "elementType": "geometry.fill",
                    "stylers": [{"color": "#F5F5F5"}]
                  }
                ]
              ''');
            },
          ),

          if (_currentPosition == null)
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        const Color(0xFF6A5ACD),
                      ),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      'Joylashuvni aniqlash...',
                      style: TextStyle(
                        color: const Color(0xFF6A5ACD),
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Location and Refresh Buttons
          Positioned(
            bottom: 20,
            right: 20,
            child: Column(
              children: [
                FloatingActionButton(
                  heroTag: 'locationBtn',
                  backgroundColor: const Color(0xFF6A5ACD),
                  onPressed: _goToCurrentLocation,
                  child: const Icon(
                    Icons.my_location,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                FloatingActionButton(
                  heroTag: 'refreshBtn',
                  backgroundColor: const Color(0xFF6A5ACD),
                  onPressed: _getCurrentLocation,
                  child: const Icon(
                    Icons.refresh,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
