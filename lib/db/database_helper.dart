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
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    if (kIsWeb) {
      throw Exception("SQLite not supported on Web.");
    }

    final path = join(await getDatabasesPath(), 'carpooling.db');
    return openDatabase(
      path,
      version: 4, // ✅ IMPORTANT: bump version
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  // --------------------------
  // CREATE TABLES
  // --------------------------
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

    // ✅ UNIQUE(rideId, passengerId) empêche doublon
    await db.execute('''
      CREATE TABLE reservations(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        rideId INTEGER,
        passengerId INTEGER,
        date TEXT,
        UNIQUE(rideId, passengerId)
      )
    ''');
  }

  // --------------------------
  // MIGRATIONS
  // --------------------------
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Migration rides (Address columns) si tu venais d’une ancienne version
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

    // Migration reservations (UNIQUE) => version 4
    if (oldVersion < 4) {
      await db.execute('DROP TABLE IF EXISTS reservations');
      await db.execute('''
        CREATE TABLE reservations(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          rideId INTEGER,
          passengerId INTEGER,
          date TEXT,
          UNIQUE(rideId, passengerId)
        )
      ''');
    }
  }

  // --------------------------
  // USERS
  // --------------------------
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

  Future<int> getUserCount(String email) async {
    if (kIsWeb) {
      return _webMockUsers.where((u) => u['email'] == email).length;
    }
    final db = await database;
    final x = await db.rawQuery('SELECT COUNT(*) FROM users WHERE email = ?', [
      email,
    ]);
    return Sqflite.firstIntValue(x) ?? 0;
  }

  Future<List<User>> getAllUsers() async {
    if (kIsWeb) {
      return _webMockUsers.map((e) => User.fromMap(e)).toList();
    }
    final db = await database;
    final maps = await db.query('users');
    return maps.map((m) => User.fromMap(m)).toList();
  }

  Future<int> updateUser(User user) async {
    if (kIsWeb) {
      final index = _webMockUsers.indexWhere((u) => u['id'] == user.id);
      if (index != -1) {
        _webMockUsers[index] = user.toMap();
        return 1;
      }
      return 0;
    }
    final db = await database;
    return db.update('users', user.toMap(), where: 'id = ?', whereArgs: [user.id]);
  }

  Future<int> deleteUser(int id) async {
    if (kIsWeb) {
      _webMockUsers.removeWhere((u) => u['id'] == id);
      return 1;
    }
    final db = await database;
    return db.delete('users', where: 'id = ?', whereArgs: [id]);
  }

  // --------------------------
  // RIDES
  // --------------------------
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
    final maps = await db.query('rides', where: 'id = ?', whereArgs: [id], limit: 1);
    if (maps.isNotEmpty) return Ride.fromMap(maps.first);
    return null;
  }

  Future<List<Ride>> getAllRides() async {
    if (kIsWeb) {
      return _webMockRides.map((e) => Ride.fromMap(e)).toList();
    }
    final db = await database;
    final maps = await db.query('rides');
    return maps.map((m) => Ride.fromMap(m)).toList();
  }

  // --------------------------
  // RESERVATIONS
  // --------------------------

  /// check si déjà réservé
  Future<Reservation?> getReservationForPassengerOnRide(int passengerId, int rideId) async {
    if (kIsWeb) {
      try {
        final m = _webMockReservations.firstWhere(
          (r) => r['passengerId'] == passengerId && r['rideId'] == rideId,
        );
        return Reservation.fromMap(m);
      } catch (_) {
        return null;
      }
    }

    final db = await database;
    final rows = await db.query(
      'reservations',
      where: 'passengerId = ? AND rideId = ?',
      whereArgs: [passengerId, rideId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Reservation.fromMap(rows.first);
  }

  /// ✅ Réserve 1 place si disponible + empêche doublon
  Future<bool> bookRideAndDecrementSeats({
    required int rideId,
    required int passengerId,
    required String dateIso,
  }) async {
    // ---- WEB MOCK ----
    if (kIsWeb) {
      final rideIndex = _webMockRides.indexWhere((r) => r['id'] == rideId);
      if (rideIndex == -1) return false;

      // ✅ déjà réservé ?
      final already = _webMockReservations.any(
        (r) => r['rideId'] == rideId && r['passengerId'] == passengerId,
      );
      if (already) return false;

      final seats = (_webMockRides[rideIndex]['seats'] as int?) ?? 0;
      if (seats <= 0) return false;

      final resId = _webMockReservations.length + 1;
      _webMockReservations.add({
        'id': resId,
        'rideId': rideId,
        'passengerId': passengerId,
        'date': dateIso,
      });

      _webMockRides[rideIndex]['seats'] = seats - 1;
      return true;
    }

    // ---- SQLITE ----
    final db = await database;

    try {
      return await db.transaction((txn) async {
        // ✅ déjà réservé ?
        final exists = await txn.query(
          'reservations',
          where: 'rideId = ? AND passengerId = ?',
          whereArgs: [rideId, passengerId],
          limit: 1,
        );
        if (exists.isNotEmpty) return false;

        // seats ?
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

        // insert reservation
        await txn.insert('reservations', {
          'rideId': rideId,
          'passengerId': passengerId,
          'date': dateIso,
        });

        // decrement seats
        await txn.update(
          'rides',
          {'seats': seats - 1},
          where: 'id = ?',
          whereArgs: [rideId],
        );

        return true;
      });
    } on DatabaseException catch (e) {
      // ✅ si UNIQUE déclenche erreur => déjà réservé
      if (e.isUniqueConstraintError()) return false;
      rethrow;
    }
  }

  Future<List<Reservation>> getReservationsByPassenger(int passengerId) async {
    if (kIsWeb) {
      final list = _webMockReservations.where((r) => r['passengerId'] == passengerId).toList();
      return list.map((e) => Reservation.fromMap(e)).toList();
    }

    final db = await database;
    final maps = await db.query(
      'reservations',
      where: 'passengerId = ?',
      whereArgs: [passengerId],
      orderBy: 'id DESC',
    );
    return maps.map((e) => Reservation.fromMap(e)).toList();
  }

  Future<void> deleteReservationAndIncrementSeats(int reservationId) async {
    if (kIsWeb) {
      final idx = _webMockReservations.indexWhere((r) => r['id'] == reservationId);
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
      final res = await txn.query(
        'reservations',
        columns: ['rideId'],
        where: 'id = ?',
        whereArgs: [reservationId],
        limit: 1,
      );
      if (res.isEmpty) return;

      final rideId = res.first['rideId'] as int;

      await txn.delete(
        'reservations',
        where: 'id = ?',
        whereArgs: [reservationId],
      );

      await txn.rawUpdate('UPDATE rides SET seats = seats + 1 WHERE id = ?', [rideId]);
    });
  }

  // Gérer les réservations conducteur (tu peux garder ton code rawQuery actuel si tu veux)
  Future<List<Map<String, dynamic>>> getReservationsForDriver(int driverId) async {
    if (kIsWeb) {
      final result = <Map<String, dynamic>>[];

      for (final r in _webMockReservations) {
        final rideId = r['rideId'] as int?;
        if (rideId == null) continue;

        final ride = await getRideById(rideId);
        if (ride == null || ride.driverId != driverId) continue;

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
}
