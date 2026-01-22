import 'package:carpooling_app/models/reservation_model.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:carpooling_app/models/user_model.dart';
import 'package:carpooling_app/models/ride_model.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  // MOCK DATA FOR WEB
  static final List<Map<String, dynamic>> _webMockUsers = [];
  static final List<Map<String, dynamic>> _webMockRides = [];
  static final List<Map<String, dynamic>> _webMockReservations = [];

  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    if (!kIsWeb) {
      _database = await _initDatabase();
      return _database!;
    }
    // Sur Web, SQLite n’existe pas
    throw Exception("SQLite not supported on Web (kIsWeb=true).");
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'carpooling.db');
    return await openDatabase(
      path,
      version: 3,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Migration rides (Address columns)
    if (oldVersion < 2) {
      await db.execute('DROP TABLE IF EXISTS rides');
      await db.execute('''
        CREATE TABLE rides(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          driverId INTEGER,
          fromLabel TEXT,
          fromLat REAL,
          fromLng REAL,
          toLabel TEXT,
          toLat REAL,
          toLng REAL,
          date TEXT,
          price REAL,
          seats INTEGER
        )
      ''');
    }

    // Migration reservations
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS reservations(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          rideId INTEGER,
          passengerId INTEGER,
          date TEXT
        )
      ''');
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        email TEXT,
        password TEXT,
        userType INTEGER,
        name TEXT,
        phone TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE rides(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        driverId INTEGER,
        fromLabel TEXT,
        fromLat REAL,
        fromLng REAL,
        toLabel TEXT,
        toLat REAL,
        toLng REAL,
        date TEXT,
        price REAL,
        seats INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE reservations(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        rideId INTEGER,
        passengerId INTEGER,
        date TEXT
      )
    ''');
  }

  // Insert User
  Future<int> insertUser(User user) async {
    if (kIsWeb) {
      final userMap = user.toMap();
      userMap['id'] = _webMockUsers.length + 1;
      _webMockUsers.add(userMap);
      return userMap['id'] as int;
    }
    final db = await database;
    return db.insert('users', user.toMap());
  }

  // Get User
  Future<User?> getUser(String email, String password) async {
    if (kIsWeb) {
      try {
        final userMap = _webMockUsers.firstWhere(
          (u) => u['email'] == email && u['password'] == password,
        );
        return User.fromMap(userMap);
      } catch (_) {
        if (email == 'admin' && password == 'admin') {
          return User(
            id: 999,
            email: 'admin',
            password: 'admin',
            userType: 2,
            name: 'Admin',
            phone: '0000',
          );
        }
        return null;
      }
    }

    final db = await database;
    final maps = await db.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [email, password],
    );
    if (maps.isNotEmpty) return User.fromMap(maps.first);
    return null;
  }

  // Insert Ride
  Future<int> insertRide(Ride ride) async {
    if (kIsWeb) {
      final rideMap = ride.toMap();
      rideMap['id'] = _webMockRides.length + 1;
      _webMockRides.add(rideMap);
      return rideMap['id'] as int;
    }
    final db = await database;
    return db.insert('rides', ride.toMap());
  }

  // Get ride by id
  Future<Ride?> getRideById(int id) async {
    if (kIsWeb) {
      try {
        final map = _webMockRides.firstWhere((r) => r['id'] == id);
        return Ride.fromMap(map);
      } catch (_) {
        return null;
      }
    }

    final db = await database;
    final maps = await db.query('rides', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) return Ride.fromMap(maps.first);
    return null;
  }

  // Get All Rides
  Future<List<Ride>> getAllRides() async {
    if (kIsWeb) {
      return _webMockRides.map((e) => Ride.fromMap(e)).toList();
    }
    final db = await database;
    final maps = await db.query('rides');
    return maps.map((m) => Ride.fromMap(m)).toList();
  }

  // Get User Count
  Future<int> getUserCount(String email) async {
    if (kIsWeb) {
      return _webMockUsers.where((u) => u['email'] == email).length;
    }
    final db = await database;
    final x = await db.rawQuery('SELECT COUNT (*) from users WHERE email = ?', [
      email,
    ]);
    return Sqflite.firstIntValue(x) ?? 0;
  }

  // Get All Users (for Admin)
  Future<List<User>> getAllUsers() async {
    if (kIsWeb) {
      return _webMockUsers.map((e) => User.fromMap(e)).toList();
    }
    final db = await database;
    final maps = await db.query('users');
    return maps.map((m) => User.fromMap(m)).toList();
  }

  // Insert Reservation
  Future<int> insertReservation(Reservation reservation) async {
    if (kIsWeb) {
      final map = reservation.toMap();
      map['id'] = _webMockReservations.length + 1;
      _webMockReservations.add(map);
      return map['id'] as int;
    }
    final db = await database;
    return db.insert('reservations', reservation.toMap());
  }

  /// Réserve 1 place: crée reservation + décrémente seats.
  /// Retourne true si ok, false si plus de place.
  Future<bool> bookRideAndDecrementSeats({
    required int rideId,
    required int passengerId,
    required String dateIso,
  }) async {
    if (kIsWeb) {
      // --- WEB MOCK ---
      // 1) trouver ride
      final rideIndex = _webMockRides.indexWhere((r) => r['id'] == rideId);
      if (rideIndex == -1) return false;

      final seats = (_webMockRides[rideIndex]['seats'] as int?) ?? 0;
      if (seats <= 0) return false;

      // 2) insert reservation mock
      final resId = _webMockReservations.length + 1;
      _webMockReservations.add({
        'id': resId,
        'rideId': rideId,
        'passengerId': passengerId,
        'date': dateIso,
      });

      // 3) decrement seats
      _webMockRides[rideIndex]['seats'] = seats - 1;
      return true;
    }

    // --- SQLITE ---
    final db = await database;

    return await db.transaction((txn) async {
      // 1) Lire seats actuel
      final rows = await txn.query(
        'rides',
        columns: ['seats'],
        where: 'id = ?',
        whereArgs: [rideId],
        limit: 1,
      );

      if (rows.isEmpty) return false;

      final seats = (rows.first['seats'] as int?) ?? 0;
      if (seats <= 0) return false;

      // 2) Insert reservation
      await txn.insert('reservations', {
        'rideId': rideId,
        'passengerId': passengerId,
        'date': dateIso,
      });

      // 3) Decrement seats
      await txn.update(
        'rides',
        {'seats': seats - 1},
        where: 'id = ?',
        whereArgs: [rideId],
      );

      return true;
    });
  }

  // Get reservations by passenger
  Future<List<Reservation>> getReservationsByPassenger(int passengerId) async {
    if (kIsWeb) {
      final list = _webMockReservations
          .where((r) => r['passengerId'] == passengerId)
          .toList();
      return list.map((e) => Reservation.fromMap(e)).toList();
    }

    final db = await database;
    final maps = await db.query(
      'reservations',
      where: 'passengerId = ?',
      whereArgs: [passengerId],
    );
    return maps.map((e) => Reservation.fromMap(e)).toList();
  }

  Future<List<Map<String, dynamic>>> getReservationsForDriver(
    int driverId,
  ) async {
    if (kIsWeb) {
      final result = <Map<String, dynamic>>[];

      for (final r in _webMockReservations) {
        final rideId = r['rideId'] as int?;
        if (rideId == null) continue;

        final ride = await getRideById(rideId);
        if (ride == null || ride.driverId != driverId) continue;

        // trouver le passager dans users
        final passengerId = r['passengerId'] as int?;
        Map<String, dynamic>? passenger;
        try {
          passenger = _webMockUsers.firstWhere((u) => u['id'] == passengerId);
        } catch (_) {
          passenger = null;
        }

        result.add({
          'reservation': Reservation.fromMap(r),
          'ride': ride,
          'passengerName': passenger?['name'] ?? 'Inconnu',
          'passengerPhone': passenger?['phone'] ?? 'N/A',
          'fromLabel': ride.from.label,
        });
      }
      return result;
    }

    final db = await database;

    final rows = await db.rawQuery(
      '''
    SELECT 
      res.id as resId,
      res.rideId as rideId,
      res.passengerId as passengerId,
      res.date as resDate,

      r.id as rId,
      r.driverId as driverId,
      r.fromLabel as fromLabel,
      r.fromLat as fromLat,
      r.fromLng as fromLng,
      r.toLabel as toLabel,
      r.toLat as toLat,
      r.toLng as toLng,
      r.date as rideDate,
      r.price as price,
      r.seats as seats,

      u.name as passengerName,
      u.phone as passengerPhone
    FROM reservations res
    INNER JOIN rides r ON r.id = res.rideId
    INNER JOIN users u ON u.id = res.passengerId
    WHERE r.driverId = ?
    ORDER BY res.id DESC
  ''',
      [driverId],
    );

    return rows.map((row) {
      final reservation = Reservation(
        id: row['resId'] as int?,
        rideId: row['rideId'] as int,
        passengerId: row['passengerId'] as int,
        date: row['resDate'] as String,
      );

      final rideMap = {
        'id': row['rId'],
        'driverId': row['driverId'],
        'fromLabel': row['fromLabel'],
        'fromLat': row['fromLat'],
        'fromLng': row['fromLng'],
        'toLabel': row['toLabel'],
        'toLat': row['toLat'],
        'toLng': row['toLng'],
        'date': row['rideDate'],
        'price': row['price'],
        'seats': row['seats'],
      };

      final ride = Ride.fromMap(rideMap);

      return {
        'reservation': reservation,
        'ride': ride,
        'passengerName': row['passengerName'] ?? 'Inconnu',
        'passengerPhone': row['passengerPhone'] ?? 'N/A',
        'fromLabel': row['fromLabel'] ?? ride.from.label,
      };
    }).toList();
  }

  // Delete reservation by id and increment seat
  Future<void> deleteReservationAndIncrementSeats(int reservationId) async {
    if (kIsWeb) {
      // trouver reservation
      final idx = _webMockReservations.indexWhere(
        (r) => r['id'] == reservationId,
      );
      if (idx == -1) return;
      final rideId = _webMockReservations[idx]['rideId'] as int?;
      _webMockReservations.removeAt(idx);

      if (rideId != null) {
        final rideIndex = _webMockRides.indexWhere((r) => r['id'] == rideId);
        if (rideIndex != -1) {
          final seats = (_webMockRides[rideIndex]['seats'] as int?) ?? 0;
          _webMockRides[rideIndex]['seats'] = seats + 1;
        }
      }
      return;
    }

    final db = await database;
    await db.transaction((txn) async {
      // 1) get rideId
      final res = await txn.query(
        'reservations',
        columns: ['rideId'],
        where: 'id = ?',
        whereArgs: [reservationId],
        limit: 1,
      );
      if (res.isEmpty) return;

      final rideId = res.first['rideId'] as int;

      // 2) delete reservation
      await txn.delete(
        'reservations',
        where: 'id = ?',
        whereArgs: [reservationId],
      );

      // 3) increment seats
      await txn.rawUpdate('UPDATE rides SET seats = seats + 1 WHERE id = ?', [
        rideId,
      ]);
    });
  }
}
