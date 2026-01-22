import 'dart:typed_data';

class Vehicule {
  int id;
  String type;
  String marque;
  String modele;
  String immatriculation;
  int places;

  String? photoPath;   // chemin pour mobile
  Uint8List? photoBytes; // image en bytes pour web

  Vehicule({
    required this.id,
    required this.type,
    required this.marque,
    required this.modele,
    required this.immatriculation,
    required this.places,
    this.photoPath,
    this.photoBytes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'marque': marque,
      'modele': modele,
      'immatriculation': immatriculation,
      'places': places,
      'photoPath': photoPath,
      'photoBytes': photoBytes,
    };
  }

  factory Vehicule.fromMap(Map<String, dynamic> map) {
    return Vehicule(
      id: map['id'],
      type: map['type'],
      marque: map['marque'],
      modele: map['modele'],
      immatriculation: map['immatriculation'],
      places: map['places'],
      photoPath: map['photoPath'],
      photoBytes: map['photoBytes'] != null
          ? Uint8List.fromList(List<int>.from(map['photoBytes']))
          : null,
    );
  }
}
