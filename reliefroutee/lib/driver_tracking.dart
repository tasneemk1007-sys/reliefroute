import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class DriverLocationPublisher {
  DriverLocationPublisher({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  StreamSubscription<Position>? _subscription;

  Future<void> start(String orderId) async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw StateError('Location services are disabled.');
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw StateError('Location permission is required for driver tracking.');
    }
    await stop();
    final driverId = _auth.currentUser?.uid;
    if (driverId == null) throw StateError('A signed-in driver is required.');
    _subscription =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 20,
          ),
        ).listen((position) {
          _firestore.collection('deliveries').doc(orderId).set({
            'driverId': driverId,
            'latitude': position.latitude,
            'longitude': position.longitude,
            'heading': position.heading,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        });
  }

  Future<void> stop() async => _subscription?.cancel();
}

class OpenStreetMapTracking extends StatelessWidget {
  const OpenStreetMapTracking({super.key, required this.orderId});
  final String orderId;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('deliveries')
          .doc(orderId)
          .snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data();
        final latitude = (data?['latitude'] as num?)?.toDouble();
        final longitude = (data?['longitude'] as num?)?.toDouble();
        if (latitude == null || longitude == null) {
          return const Card(
            child: ListTile(
              leading: Icon(Icons.location_searching),
              title: Text('Waiting for driver location'),
              subtitle: Text(
                'The map will appear when the driver starts sharing location.',
              ),
            ),
          );
        }
        final point = LatLng(latitude, longitude);
        return SizedBox(
          height: 280,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: FlutterMap(
              options: MapOptions(initialCenter: point, initialZoom: 15),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'za.co.reliefroute.app',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: point,
                      width: 48,
                      height: 48,
                      child: const Icon(
                        Icons.local_shipping,
                        color: Colors.teal,
                        size: 38,
                      ),
                    ),
                  ],
                ),
                const RichAttributionWidget(
                  attributions: [
                    TextSourceAttribution('OpenStreetMap contributors'),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
