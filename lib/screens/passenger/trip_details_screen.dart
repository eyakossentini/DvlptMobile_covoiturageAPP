import 'package:carpooling_app/screens/auth/login_screen.dart';
import 'package:carpooling_app/providers/ride_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../models/ride_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/reservation_provider.dart';

class TripDetailsScreen extends StatelessWidget {
  final Ride ride;

  const TripDetailsScreen({super.key, required this.ride});

  @override
  Widget build(BuildContext context) {
    final fromLatLng = LatLng(ride.from.lat, ride.from.lng);
    final toLatLng = LatLng(ride.to.lat, ride.to.lng);

    // centre entre les deux points
    final center = LatLng(
      (ride.from.lat + ride.to.lat) / 2,
      (ride.from.lng + ride.to.lng) / 2,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails du trajet'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Provider.of<AuthProvider>(context, listen: false).logout();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            '${ride.from.label} → ${ride.to.label}',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),

          _InfoRow(label: 'Date', value: ride.date),
          _InfoRow(label: 'Prix', value: '${ride.price} TND'),
          _InfoRow(label: 'Places', value: '${ride.seats}'),
          const SizedBox(height: 16),

          Text('Carte', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),

          SizedBox(
            height: 280,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: FlutterMap(
                options: MapOptions(initialCenter: center, initialZoom: 10),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.carpooling_app',
                  ),

                  PolylineLayer(
                    polylines: [
                      Polyline(points: [fromLatLng, toLatLng], strokeWidth: 4),
                    ],
                  ),

                  MarkerLayer(
                    markers: [
                      Marker(
                        point: fromLatLng,
                        width: 44,
                        height: 44,
                        child: GestureDetector(
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Départ : ${ride.from.label}'),
                              ),
                            );
                          },
                          child: const Icon(Icons.location_pin, size: 44),
                        ),
                      ),
                      Marker(
                        point: toLatLng,
                        width: 44,
                        height: 44,
                        child: GestureDetector(
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Arrivée : ${ride.to.label}'),
                              ),
                            );
                          },
                          child: const Icon(Icons.flag, size: 36),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          ExpansionTile(
            title: const Text('Coordonnées'),
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('FROM: ${ride.from.lat}, ${ride.from.lng}'),
                    Text('TO:   ${ride.to.lat}, ${ride.to.lng}'),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ✅ Bouton Réserver + refresh rides
          ElevatedButton.icon(
            onPressed: ride.seats <= 0
                ? null
                : () async {
                    final user = Provider.of<AuthProvider>(
                      context,
                      listen: false,
                    ).user;
                    if (user == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Veuillez vous connecter.'),
                        ),
                      );
                      return;
                    }

                    final ok = await Provider.of<ReservationProvider>(
                      context,
                      listen: false,
                    ).bookRide(passengerId: user.id!, ride: ride);

                    // ✅ ICI: refresh de la liste des trajets si réservation réussie
                    if (ok) {
                      await Provider.of<RideProvider>(
                        context,
                        listen: false,
                      ).fetchRides();
                    }

                    if (!context.mounted) return;

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          ok ? 'Réservation ajoutée ✅' : 'Erreur réservation ❌',
                        ),
                      ),
                    );
                  },
            icon: const Icon(Icons.event_seat),
            label: Text(ride.seats <= 0 ? 'Complet' : 'Réserver'),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Text(
              '$label:',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
