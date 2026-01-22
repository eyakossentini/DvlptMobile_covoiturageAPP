import 'package:carpooling_app/providers/auth_provider.dart';
import 'package:carpooling_app/screens/auth/login_screen.dart';
import 'package:carpooling_app/screens/passenger/trip_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:carpooling_app/providers/ride_provider.dart';

class RidesListScreen extends StatefulWidget {
  const RidesListScreen({super.key});

  @override
  _RidesListScreenState createState() => _RidesListScreenState();
}

class _RidesListScreenState extends State<RidesListScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch rides when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<RideProvider>(context, listen: false).fetchRides();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trajets disponibles'),
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
      body: Consumer<RideProvider>(
        builder: (context, rideProvider, _) {
          final rides = rideProvider.rides;
          if (rides.isEmpty) {
            return const Center(
              child: Text('Aucun trajet disponible pour le moment.'),
            );
          }
          return ListView.builder(
            itemCount: rides.length,
            itemBuilder: (context, index) {
              final ride = rides[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 3,
                child: ListTile(
                  leading: const Icon(Icons.directions_car, color: Colors.blue),
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
    );
  }
}
