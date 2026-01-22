import 'package:flutter/material.dart';
import '../models/ride_model.dart';
import '../db/database_helper.dart';

class RideProvider with ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();
  List<Ride> _rides = [];

  List<Ride> get rides => _rides;

  Future<void> fetchRides() async {
    _rides = await _db.getAllRides();
    notifyListeners();
  }

  Future<bool> addRide(Ride ride) async {
    try {
      final id = await _db.insertRide(ride);

      // 🔥 IMPORTANT : on met l'id dans l'objet ride
      ride.id = id;

      _rides.add(ride);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint(e.toString());
      return false;
    }
  }
}
