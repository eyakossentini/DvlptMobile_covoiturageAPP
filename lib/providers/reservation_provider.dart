import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../models/ride_model.dart';

class ReservationProvider with ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();

  // chaque item contient: reservation + ride
  List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> get items => _items;

  Future<void> loadMyReservations(int passengerId) async {
    final reservations = await _db.getReservationsByPassenger(passengerId);
    final list = <Map<String, dynamic>>[];

    for (final r in reservations) {
      final ride = await _db.getRideById(r.rideId);
      if (ride != null) {
        list.add({'reservation': r, 'ride': ride});
      }
    }

    _items = list;
    notifyListeners();
  }

  Future<bool> bookRide({required int passengerId, required Ride ride}) async {
    try {
      if (ride.id == null) return false;

      final ok = await _db.bookRideAndDecrementSeats(
        rideId: ride.id!,
        passengerId: passengerId,
        dateIso: DateTime.now().toIso8601String(),
      );

      if (!ok) return false;

      // refresh "my bookings"
      await loadMyReservations(passengerId);

      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> cancelReservation({
    required int reservationId,
    required int passengerId,
  }) async {
    try {
      await _db.deleteReservationAndIncrementSeats(reservationId);
      await loadMyReservations(passengerId);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> refresh(int passengerId) async {
    await loadMyReservations(passengerId);
  }
}
