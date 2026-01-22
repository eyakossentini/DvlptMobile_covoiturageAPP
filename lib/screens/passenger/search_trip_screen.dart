import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/ride_provider.dart';
import '../../models/ride_model.dart';
import 'trip_details_screen.dart';

class SearchTripScreen extends StatefulWidget {
  const SearchTripScreen({super.key});

  @override
  State<SearchTripScreen> createState() => _SearchTripScreenState();
}

class _SearchTripScreenState extends State<SearchTripScreen> {
  final _fromController = TextEditingController();
  final _toController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Charge la liste au démarrage (si pas déjà fait)
    Future.microtask(() {
      Provider.of<RideProvider>(context, listen: false).fetchRides();
    });
  }

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    super.dispose();
  }

  bool _match(String query, String target) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return target.toLowerCase().contains(q);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rechercher un trajet')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _fromController,
              decoration: const InputDecoration(
                labelText: 'Départ',
                prefixIcon: Icon(Icons.my_location),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _toController,
              decoration: const InputDecoration(
                labelText: 'Arrivée',
                prefixIcon: Icon(Icons.place),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),

            Expanded(
              child: Consumer<RideProvider>(
                builder: (context, rideProvider, _) {
                  final rides = rideProvider.rides;

                  // Filtrage
                  final filtered = rides.where((Ride ride) {
                    final okFrom = _match(
                      _fromController.text,
                      ride.from.label,
                    );
                    final okTo = _match(_toController.text, ride.to.label);
                    return okFrom && okTo;
                  }).toList();

                  if (filtered.isEmpty) {
                    return const Center(
                      child: Text(
                        'Aucun trajet ne correspond à votre recherche.',
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final ride = filtered[index];

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          leading: const Icon(Icons.directions_car),
                          title: Text('${ride.from.label} → ${ride.to.label}'),
                          subtitle: Text(
                            'Date: ${ride.date} | Prix: ${ride.price} TND',
                          ),
                          trailing: Text('${ride.seats} places'),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => TripDetailsScreen(ride: ride),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
