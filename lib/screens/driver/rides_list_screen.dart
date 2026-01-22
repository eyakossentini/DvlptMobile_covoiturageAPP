import 'package:carpooling_app/providers/auth_provider.dart';
import 'package:carpooling_app/screens/auth/login_screen.dart';
import 'package:carpooling_app/screens/passenger/trip_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:carpooling_app/providers/ride_provider.dart';

class RidesListScreen extends StatefulWidget {
  const RidesListScreen({super.key});

  @override
  State<RidesListScreen> createState() => _RidesListScreenState();
}

class _RidesListScreenState extends State<RidesListScreen> {
  @override
  void initState() {
    super.initState();
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

              final dateBadge = rideBadgeText(ride.date); // Aujourd’hui / Demain / Expiré
              final isExpired = dateBadge == 'Expiré';

              final isFull = ride.seats <= 0;
              final canOpenDetails = !isExpired && !isFull;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 3,
                child: ListTile(
                  leading: const Icon(Icons.directions_car, color: Colors.blue),

                  // ✅ Title + badges (plus beau)
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${ride.from.label} → ${ride.to.label}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (dateBadge.isNotEmpty)
                        _Badge(
                          text: dateBadge,
                          type: isExpired ? _BadgeType.danger : _BadgeType.info,
                        ),
                      if (isFull) const SizedBox(width: 6),
                      if (isFull) const _Badge(text: 'Complet', type: _BadgeType.danger),
                    ],
                  ),

                  subtitle: Text(
                    'Date: ${ride.date} | Prix: ${ride.price} TND',
                  ),

                  // ✅ trailing plus clair
                  trailing: Text(
                    '${ride.seats} places',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isFull ? Colors.red : null,
                    ),
                  ),

                  // ✅ Désactiver si expiré ou complet
                  onTap: !canOpenDetails
                      ? () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                isExpired
                                    ? 'Trajet expiré : réservation impossible.'
                                    : 'Trajet complet : aucune place disponible.',
                              ),
                            ),
                          );
                        }
                      : () {
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

  // ---------- Helpers date badge ----------
  DateTime? parseRideDate(String dateStr) {
    try {
      final p = dateStr.split('/');
      return DateTime(int.parse(p[2]), int.parse(p[1]), int.parse(p[0]));
    } catch (_) {
      return null;
    }
  }

  String rideBadgeText(String dateStr) {
    final d = parseRideDate(dateStr);
    if (d == null) return '';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final rideDay = DateTime(d.year, d.month, d.day);

    if (rideDay.isBefore(today)) return 'Expiré';
    if (rideDay.isAtSameMomentAs(today)) return 'Aujourd’hui';
    if (rideDay.isAtSameMomentAs(today.add(const Duration(days: 1)))) return 'Demain';

    return '';
  }
}

// ---------- Badge widget ----------
enum _BadgeType { info, danger }

class _Badge extends StatelessWidget {
  final String text;
  final _BadgeType type;

  const _Badge({required this.text, required this.type});

  @override
  Widget build(BuildContext context) {
    final Color bg = type == _BadgeType.danger
        ? Colors.red.withOpacity(0.12)
        : Colors.blue.withOpacity(0.12);

    final Color fg = type == _BadgeType.danger ? Colors.red : Colors.blue;

    return Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 12, color: fg, fontWeight: FontWeight.w600),
      ),
    );
  }
}
