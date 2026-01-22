import 'dart:io'; // Nécessaire pour vérifier si on est sur Windows
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
// 👇 CETTE LIGNE EST OBLIGATOIRE POUR LE PC 👇
import 'package:carpooling_app/models/vehicule.dart';



class VehiculeRepository {
  static Database? _db;

  // --- MOCK DATA POUR LE WEB ---
  static final List<Map<String, dynamic>> _webMockVehicules = [];

  // --- GESTION DE LA CONNEXION ---
  Future<Database> get database async {
    // Sur le Web, on n'utilise pas SQLite du tout
    if (kIsWeb) {
      throw Exception("SQLite not supported on Web. Using mock data instead.");
    }
    
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {

    String path;
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      // Sur PC, on stocke le fichier localement
      path = join(Directory.current.path, 'vehicules_manager.db');
    } else {
      // Sur Mobile, chemin standard
      final dbPath = await getDatabasesPath();
      path = join(dbPath, 'vehicules_manager.db');
    }

    return await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE vehicules(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            type TEXT NOT NULL,
            marque TEXT NOT NULL,
            modele TEXT NOT NULL,
            immatriculation TEXT NOT NULL,
            places INTEGER NOT NULL,
            photo_path TEXT,
            photo_bytes BLOB
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          try {
            await db.execute("ALTER TABLE vehicules ADD COLUMN photo_path TEXT");
            await db.execute("ALTER TABLE vehicules ADD COLUMN photo_bytes BLOB");
          } catch (_) {}
        }
      },
    );
  }

  // --- CRUD (WEB & MOBILE/PC) ---

  // AJOUTER
  Future<int> addVehicule(Vehicule v) async {
    if (kIsWeb) {
      final map = v.toMap();
      final newId = (_webMockVehicules.isEmpty) 
          ? 1 
          : (_webMockVehicules.map((e) => e['id'] as int).reduce((a, b) => a > b ? a : b) + 1);
      map['id'] = newId;
      _webMockVehicules.add(map);
      return newId;
    }

    final db = await database;
    final map = v.toMap();
    if (map['id'] == 0 || map['id'] == null) map.remove('id');
    return await db.insert('vehicules', map);
  }

  // LIRE TOUT
  Future<List<Vehicule>> getAll() async {
    if (kIsWeb) {
      return _webMockVehicules.map((e) => Vehicule.fromMap(e)).toList();
    }

    final db = await database;
    final res = await db.query('vehicules');
    return res.map((e) => Vehicule.fromMap(e)).toList();
  }

  // MODIFIER
  Future<void> updateVehicule(int id, Vehicule v) async {
    if (kIsWeb) {
      final index = _webMockVehicules.indexWhere((e) => e['id'] == id);
      if (index != -1) {
        final newMap = v.toMap();
        newMap['id'] = id;
        _webMockVehicules[index] = newMap;
      }
      return;
    }

    final db = await database;
    await db.update('vehicules', v.toMap(), where: 'id = ?', whereArgs: [id]);
  }

  // SUPPRIMER
  Future<void> deleteVehicule(int id) async {
    if (kIsWeb) {
      _webMockVehicules.removeWhere((e) => e['id'] == id);
      return;
    }

    final db = await database;
    await db.delete('vehicules', where: 'id = ?', whereArgs: [id]);
  }
}