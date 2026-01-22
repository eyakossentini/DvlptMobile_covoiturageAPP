import 'package:flutter/material.dart';
import '../models/package_model.dart';
import '../db/database_helper.dart';

class PackageProvider with ChangeNotifier {
  List<Package> _allPackages = [];
  List<Package> _availablePackages = [];
  List<Package> _mySentPackages = [];
  List<Package> _myDeliveries = [];
  bool _isLoading = false;

  List<Package> get allPackages => _allPackages;
  List<Package> get availablePackages => _availablePackages;
  List<Package> get mySentPackages => _mySentPackages;
  List<Package> get myDeliveries => _myDeliveries;
  bool get isLoading => _isLoading;

  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<void> fetchAllPackages() async {
    _isLoading = true;
    notifyListeners();
    _allPackages = await _dbHelper.getAllPackages();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchAvailablePackages() async {
    _isLoading = true;
    notifyListeners();
    _availablePackages = await _dbHelper.getAvailablePackages();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchMySentPackages(int senderId) async {
    _isLoading = true;
    notifyListeners();
    _mySentPackages = await _dbHelper.getPackagesBySender(senderId);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchMyDeliveries(int driverId) async {
    _isLoading = true;
    notifyListeners();
    _myDeliveries = await _dbHelper.getPackagesByDriver(driverId);
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> addPackage(Package package) async {
    try {
      await _dbHelper.insertPackage(package);
      await fetchMySentPackages(package.senderId);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> acceptPackage(int packageId, int driverId) async {
    try {
      await _dbHelper.updatePackageStatus(packageId, 'In Transit', driverId: driverId);
      await fetchAvailablePackages();
      await fetchMyDeliveries(driverId);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateStatus(int packageId, String nextStatus, int driverId) async {
    try {
      await _dbHelper.updatePackageStatus(packageId, nextStatus);
      await fetchMyDeliveries(driverId);
      return true;
    } catch (e) {
      return false;
    }
  }


  Future<bool> updatePackage(Package package) async {
    try {
      await _dbHelper.updatePackage(package);
      await fetchMySentPackages(package.senderId);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deletePackage(int packageId, int senderId) async {
    try {
      await _dbHelper.deletePackage(packageId);
      await fetchMySentPackages(senderId);
      return true;
    } catch (e) {
      return false;
    }
  }
}