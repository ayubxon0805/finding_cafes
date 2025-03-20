import 'package:finding_cafes/google_maps_flutter.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class SpashScreen extends StatefulWidget {
  const SpashScreen({super.key});

  @override
  State<SpashScreen> createState() => _SpashScreenState();
}

class _SpashScreenState extends State<SpashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isHovered = false;

  final List<Map<String, dynamic>> places = [
    {
      'name': 'Café',
      'icon': Icons.coffee,
      'type': 'cafe',
      'color': const Color(0xFFE94B3C),
      'description': 'Find the perfect spot for your coffee break',
    },
    {
      'name': 'Mosque',
      'icon': Icons.mosque,
      'type': 'mosque',
      'color': const Color(0xFF2E86C1),
      'description': 'Discover nearby places of worship',
    },
    {
      'name': 'Park',
      'icon': Icons.park,
      'type': 'park',
      'color': const Color(0xFF2ECC71),
      'description': 'Find green spaces for relaxation',
    },
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void navigateToMap(String placeType) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            GoogleMapScreen(placeType: placeType),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20.0, vertical: 30),
              child: Column(
                children: [
                  ScaleTransition(
                    scale: _animation,
                    child: Text(
                      'Discover Your City',
                      style: GoogleFonts.poppins(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2C3E50),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 10),
                  FadeTransition(
                    opacity: _animation,
                    child: Text(
                      'What would you like to find?',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: const Color(0xFF7F8C8D),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(20),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 15,
                  childAspectRatio: 1,
                ),
                itemCount: places.length,
                itemBuilder: (context, index) {
                  final place = places[index];
                  return _buildPlaceCard(place);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceCard(Map<String, dynamic> place) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            place['color'].withOpacity(0.1),
            place['color'].withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: place['color'].withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.push(context, MaterialPageRoute(
              builder: (context) {
                return MapScreen(
                  placeType: place['type'],
                );
              },
            ));
          },
          onHover: (hovering) {
            setState(() {
              _isHovered = hovering;
            });
          },
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: place['color'].withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    place['icon'],
                    size: 36,
                    color: place['color'],
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  place['name'],
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2C3E50),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  place['description'],
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: const Color(0xFF7F8C8D),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class GoogleMapScreen extends StatelessWidget {
  final String placeType;

  const GoogleMapScreen({super.key, required this.placeType});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2C3E50),
        elevation: 0,
        title: Text(
          'Find $placeType',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: LatLng(41.311081, 69.240562),
              zoom: 12,
            ),
            markers: {
              Marker(
                markerId: const MarkerId('marker'),
                position: const LatLng(41.311081, 69.240562),
              ),
            },
          ),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    placeType == 'cafe'
                        ? Icons.coffee
                        : placeType == 'mosque'
                            ? Icons.mosque
                            : Icons.park,
                    color: placeType == 'cafe'
                        ? const Color(0xFFE94B3C)
                        : placeType == 'mosque'
                            ? const Color(0xFF2E86C1)
                            : const Color(0xFF2ECC71),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Searching for nearby $placeType locations...',
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF2C3E50),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
