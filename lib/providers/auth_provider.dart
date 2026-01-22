import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../db/database_helper.dart';

class AuthProvider with ChangeNotifier {
  User? _user;
  final DatabaseHelper _db = DatabaseHelper();

  User? get user => _user;

  // Sign Up
  Future<bool> signUp(User user) async {
    try {
      // Check if email already exists
      int count = await _db.getUserCount(user.email);
      if (count > 0) {
        return false; // Email already exists
      }

      await _db.insertUser(user);
      return true;
    } catch (e) {
      print(e);
      return false;
    }
  }

  // Login
  Future<bool> login(String email, String password) async {
    try {
      User? user = await _db.getUser(email, password);
      if (user != null) {
        _user = user;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      print(e);
      return false;
    }
  }

  // Logout
  void logout() {
    _user = null;
    notifyListeners();
  }
}
