import 'package:carpooling_app/models/reservation_model.dart';
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

  /// ✅ check si ce passager a déjà réservé ce ride
  Future<bool> hasReservation({
    required int passengerId,
    required int rideId,
  }) async {
    final res = await _db.getReservationForPassengerOnRide(passengerId, rideId);
    return res != null;
  }

  /// ✅ alias clair utilisé par TripDetailsScreen
  Future<Reservation?> getMyReservation({
    required int passengerId,
    required int rideId,
  }) async {
    return _db.getReservationForPassengerOnRide(passengerId, rideId);
  }

  /// ✅ garde aussi ton ancienne méthode (compat)
  Future<Reservation?> myReservationForRide(int passengerId, int rideId) async {
    return _db.getReservationForPassengerOnRide(passengerId, rideId);
  }

  /// ✅ réserver (avec protection anti double réservation)
  Future<bool> bookRide({required int passengerId, required Ride ride}) async {
    try {
      if (ride.id == null) return false;

      // ✅ empêche réservation multiple (UI + DB)
      final already = await hasReservation(
        passengerId: passengerId,
        rideId: ride.id!,
      );
      if (already) return false;

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

  /// ✅ annuler (ta méthode existante)
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

  /// (l’écran recharge ensuite l’état avec getMyReservation)
  Future<bool> cancelMyReservation({
    required int reservationId,
    required int passengerId,
  }) async {
    return cancelReservation(reservationId: reservationId, passengerId: passengerId);
  }

  Future<void> refresh(int passengerId) async {
    await loadMyReservations(passengerId);
  }
}
