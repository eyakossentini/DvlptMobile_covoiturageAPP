import 'package:carpooling_app/screens/auth/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../reservation/manage_booking_provider.dart';

class ManageBookingsScreen extends StatefulWidget {
  const ManageBookingsScreen({super.key});

  @override
  State<ManageBookingsScreen> createState() => _ManageBookingsScreenState();
}

class _ManageBookingsScreenState extends State<ManageBookingsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final user = Provider.of<AuthProvider>(context, listen: false).user;
      if (user != null) {
        Provider.of<ManageBookingProvider>(context, listen: false)
            .loadForDriver(user.id!);
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
      appBar: AppBar(
        title: const Text('Gérer les réservations'),
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
      body: Consumer<ManageBookingProvider>(
        builder: (context, provider, _) {
          if (provider.items.isEmpty) {
            return const Center(
              child: Text('Aucune réservation pour vos trajets.'),
            );
          }

          return ListView.builder(
            itemCount: provider.items.length,
            itemBuilder: (context, index) {
              final reservation = provider.items[index]['reservation'];
              final ride = provider.items[index]['ride'];

              final passengerName =
                  provider.items[index]['passengerName'] ?? 'Inconnu';
              final passengerPhone =
                  provider.items[index]['passengerPhone'] ?? 'N/A';
              final fromLabel =
                  provider.items[index]['fromLabel'] ?? ride.from.label;

              return Card(
                margin:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: const Icon(Icons.book_online),
                  title: Text('${ride.from.label} → ${ride.to.label}'),
                  subtitle: Text(
                    'Départ: $fromLabel\n'
                    'Passager: $passengerName | Tél: $passengerPhone\n'
                    'Date trajet: ${ride.date}',
                  ),
                  isThreeLine: true,
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () async {
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Annuler la réservation ?'),
                          content: const Text(
                              'Cette action supprimera la réservation.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Non'),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Oui'),
                            ),
                          ],
                        ),
                      );

                      if (ok == true) {
                        await Provider.of<ManageBookingProvider>(
                          context,
                          listen: false,
                        ).cancelReservation(reservation.id!, user.id!);

                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Réservation annulée')),
                        );
                      }
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
