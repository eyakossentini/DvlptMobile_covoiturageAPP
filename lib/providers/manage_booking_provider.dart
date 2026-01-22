import 'package:flutter/material.dart';
import '../db/database_helper.dart';


class ManageBookingProvider with ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();

  List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> get items => _items;

  Future<void> loadForDriver(int driverId) async {
    _items = await _db.getReservationsForDriver(driverId);
    notifyListeners();
  }

  Future<void> cancelReservation(int reservationId, int driverId) async {
    await _db.deleteReservationAndIncrementSeats(reservationId);
    await loadForDriver(driverId);
  }
}
