import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/reservation_provider.dart';
import '../../providers/ride_provider.dart';

class MyBookingScreen extends StatefulWidget {
  const MyBookingScreen({super.key});

  @override
  State<MyBookingScreen> createState() => _MyBookingScreenState();
}

class _MyBookingScreenState extends State<MyBookingScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final user = Provider.of<AuthProvider>(context, listen: false).user;
      if (user != null) {
        await Provider.of<ReservationProvider>(
          context,
          listen: false,
        ).loadMyReservations(user.id!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Veuillez vous connecter.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Mes réservations')),
      body: Consumer<ReservationProvider>(
        builder: (context, provider, _) {
          if (provider.items.isEmpty) {
            return const Center(child: Text('Aucune réservation.'));
          }

          return ListView.builder(
            itemCount: provider.items.length,
            itemBuilder: (context, index) {
              final reservation = provider.items[index]['reservation'];
              final ride = provider.items[index]['ride'];

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text('${ride.from.label} → ${ride.to.label}'),
                  subtitle: Text(
                    'Date: ${ride.date} | Prix: ${ride.price} TND',
                  ),
                  trailing: TextButton.icon(
                    icon: const Icon(Icons.close),
                    label: const Text('Annuler'),
                    onPressed: () async {
                      final ok =
                          await Provider.of<ReservationProvider>(
                            context,
                            listen: false,
                          ).cancelReservation(
                            reservationId: reservation.id!,
                            passengerId: user.id!,
                          );

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
                            ok ? 'Réservation annulée ✅' : 'Erreur ❌',
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
