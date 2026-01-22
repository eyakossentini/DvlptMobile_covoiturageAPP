import 'package:carpooling_app/providers/auth_provider.dart';
import 'package:carpooling_app/reservation/ride_provider.dart';
import 'package:carpooling_app/reservation/reservation_provider.dart';
import 'package:carpooling_app/screens/auth/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../models/ride_model.dart';
import '../../models/reservation_model.dart';

class TripDetailsScreen extends StatefulWidget {
  final Ride ride;
  const TripDetailsScreen({super.key, required this.ride});

  @override
  State<TripDetailsScreen> createState() => _TripDetailsScreenState();
}

class _TripDetailsScreenState extends State<TripDetailsScreen> {
  Reservation? _myReservation;
  bool _loadingReservationState = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _loadReservationState();
  }

  // --- Date parse "dd/MM/yyyy"
  DateTime? _parseRideDate(String dateStr) {
    try {
      final p = dateStr.split('/');
      return DateTime(int.parse(p[2]), int.parse(p[1]), int.parse(p[0]));
    } catch (_) {
      return null;
    }
  }

  bool get _isExpired {
    final d = _parseRideDate(widget.ride.date);
    if (d == null) return false; // si format inconnu, on ne bloque pas
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final rideDay = DateTime(d.year, d.month, d.day);
    return rideDay.isBefore(today);
  }

  Future<void> _loadReservationState() async {
    final user = Provider.of<AuthProvider>(context, listen: false).user;

    // si pas connecté ou pas client => pas besoin de checker
    if (user == null || user.userType != 0 || user.id == widget.ride.driverId) {
      if (!mounted) return;
      setState(() {
        _myReservation = null;
        _loadingReservationState = false;
      });
      return;
    }

    // ride.id peut être null si bug insertion => on ne peut pas réserver
    if (widget.ride.id == null) {
      if (!mounted) return;
      setState(() {
        _myReservation = null;
        _loadingReservationState = false;
      });
      return;
    }

    final resProvider = Provider.of<ReservationProvider>(
      context,
      listen: false,
    );
    final existing = await resProvider.getMyReservation(
      passengerId: user.id!,
      rideId: widget.ride.id!,
    );

    if (!mounted) return;
    setState(() {
      _myReservation = existing;
      _loadingReservationState = false;
    });
  }

  Future<void> _refreshRides() async {
    await Provider.of<RideProvider>(context, listen: false).fetchRides();
  }

  @override
  Widget build(BuildContext context) {
    final ride = widget.ride;

    final fromLatLng = LatLng(ride.from.lat, ride.from.lng);
    final toLatLng = LatLng(ride.to.lat, ride.to.lng);

    final center = LatLng(
      (ride.from.lat + ride.to.lat) / 2,
      (ride.from.lng + ride.to.lng) / 2,
    );

    final user = Provider.of<AuthProvider>(context).user;

    final isClient = user != null && user.userType == 0;
    final isDriverOfThisRide = user != null && user.id == ride.driverId;

    // ✅ Le client peut réserver seulement si:
    // - client
    // - pas conducteur du trajet
    // - ride.id != null
    final canBookBase = isClient && !isDriverOfThisRide && ride.id != null;

    // --- Déterminer état bouton
    final bool alreadyBooked = _myReservation != null;
    final bool full = ride.seats <= 0;

    // priorité: Expiré > Mon trajet > pas client > loading > déjà réservé > complet > réserver
    String? disabledReason;
    if (user == null) disabledReason = 'Connectez-vous pour réserver.';
    if (user != null && !isClient)
      disabledReason = 'Réservation disponible uniquement pour les clients.';
    if (isDriverOfThisRide) disabledReason = 'C’est votre trajet (conducteur).';
    if (_isExpired) disabledReason = 'Trajet expiré (date passée).';
    if (ride.id == null) disabledReason = 'Trajet invalide (id manquant).';

    final showButton = canBookBase && disabledReason == null;

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
                          onTap: () =>
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Départ : ${ride.from.label}'),
                                ),
                              ),
                          child: const Icon(Icons.location_pin, size: 44),
                        ),
                      ),
                      Marker(
                        point: toLatLng,
                        width: 44,
                        height: 44,
                        child: GestureDetector(
                          onTap: () =>
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Arrivée : ${ride.to.label}'),
                                ),
                              ),
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

          if (_loadingReservationState && canBookBase) ...[
            const Center(child: CircularProgressIndicator()),
          ] else if (!showButton) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                disabledReason ?? 'Action indisponible.',
                textAlign: TextAlign.center,
              ),
            ),
          ] else ...[
            // ✅ si déjà réservé => bouton Annuler, sinon Réserver (ou Complet)
            if (alreadyBooked) ...[
              ElevatedButton.icon(
                onPressed: _busy
                    ? null
                    : () async {
                        setState(() => _busy = true);

                        final ok =
                            await Provider.of<ReservationProvider>(
                              context,
                              listen: false,
                            ).cancelMyReservation(
                              reservationId: _myReservation!.id!,
                              passengerId: user!.id!,
                            );
                        if (ok) {
                          // refresh UI + rides seats
                          await _refreshRides();
                          await _loadReservationState();
                        }

                        if (!mounted) return;
                        setState(() => _busy = false);

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              ok
                                  ? 'Réservation annulée ✅'
                                  : 'Annulation impossible ❌',
                            ),
                          ),
                        );
                      },
                icon: const Icon(Icons.cancel),
                label: const Text('Annuler ma réservation'),
              ),
            ] else ...[
              ElevatedButton.icon(
                onPressed: (_busy || full)
                    ? null
                    : () async {
                        setState(() => _busy = true);

                        final ok = await Provider.of<ReservationProvider>(
                          context,
                          listen: false,
                        ).bookRide(passengerId: user!.id!, ride: ride);

                        if (ok) {
                          // ✅ refresh seats + état "déjà réservé"
                          await _refreshRides();
                          await _loadReservationState();
                        }

                        if (!mounted) return;
                        setState(() => _busy = false);

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              ok
                                  ? 'Réservation ajoutée ✅'
                                  : 'Déjà réservé / plus de place ❌',
                            ),
                          ),
                        );
                      },
                icon: const Icon(Icons.event_seat),
                label: Text(full ? 'Complet' : 'Réserver'),
              ),
            ],

            const SizedBox(height: 8),

            // ✅ petits badges d’état
            Row(
              children: [
                if (_isExpired) _Badge(text: 'Expiré'),
                if (!_isExpired && alreadyBooked) _Badge(text: 'Déjà réservé'),
                if (!_isExpired && full) _Badge(text: 'Complet'),
              ],
            ),
          ],
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

class _Badge extends StatelessWidget {
  final String text;
  const _Badge({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.06),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(text),
    );
  }
}
