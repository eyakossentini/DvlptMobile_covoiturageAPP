import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/address.dart';

class RouteMapScreen extends StatefulWidget {
  const RouteMapScreen({super.key});

  @override
  State<RouteMapScreen> createState() => _RouteMapScreenState();
}

class _RouteMapScreenState extends State<RouteMapScreen> {
  LatLng _selected = const LatLng(36.8065, 10.1815); // Tunis par défaut

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choisir une localisation'),
        actions: [
          TextButton(
            onPressed: () {
              final address = Address(
                label:
                    'Lat: ${_selected.latitude.toStringAsFixed(6)} | '
                    'Lng: ${_selected.longitude.toStringAsFixed(6)}',
                lat: _selected.latitude,
                lng: _selected.longitude,
              );
              Navigator.pop(context, address); // ✅ renvoie l’adresse
            },
            child: const Text('Confirmer'),
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: _selected,
              initialZoom: 13,
              onTap: (tapPosition, latLng) {
                setState(() => _selected = latLng);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    duration: const Duration(milliseconds: 700),
                    content: Text(
                      'Sélection: ${latLng.latitude.toStringAsFixed(6)}, '
                      '${latLng.longitude.toStringAsFixed(6)}',
                    ),
                  ),
                );
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.carpooling_app',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _selected,
                    width: 50,
                    height: 50,
                    child: const Icon(Icons.location_pin, size: 50),
                  ),
                ],
              ),
            ],
          ),

          // bandeau info en bas
          Positioned(
            left: 12,
            right: 12,
            bottom: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Lat: ${_selected.latitude.toStringAsFixed(6)} | '
                'Lng: ${_selected.longitude.toStringAsFixed(6)}\n'
                'Tape sur la carte pour choisir, puis Confirmer.',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
