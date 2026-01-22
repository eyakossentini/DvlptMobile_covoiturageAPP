import 'address.dart';

class Package {
  int? id;
  final int senderId;
  int? driverId;
  final String description;
  final String weight; // e.g., "5kg"
  final String dimensions; // e.g., "30x20x10 cm"
  final Address pickupAddress;
  final Address deliveryAddress;
  String status; // "Pending", "In Transit", "Delivered"
  final String createdAt;

  Package({
    this.id,
    required this.senderId,
    this.driverId,
    required this.description,
    required this.weight,
    required this.dimensions,
    required this.pickupAddress,
    required this.deliveryAddress,
    this.status = 'Pending',
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderId': senderId,
      'driverId': driverId,
      'description': description,
      'weight': weight,
      'dimensions': dimensions,
      'pickupLabel': pickupAddress.label,
      'pickupLat': pickupAddress.lat,
      'pickupLng': pickupAddress.lng,
      'deliveryLabel': deliveryAddress.label,
      'deliveryLat': deliveryAddress.lat,
      'deliveryLng': deliveryAddress.lng,
      'status': status,
      'createdAt': createdAt,
    };
  }

  factory Package.fromMap(Map<String, dynamic> map) {
    return Package(
      id: map['id'],
      senderId: map['senderId'],
      driverId: map['driverId'],
      description: map['description'],
      weight: map['weight'],
      dimensions: map['dimensions'],
      pickupAddress: Address(
        label: map['pickupLabel'],
        lat: map['pickupLat'],
        lng: map['pickupLng'],
      ),
      deliveryAddress: Address(
        label: map['deliveryLabel'],
        lat: map['deliveryLat'],
        lng: map['deliveryLng'],
      ),
      status: map['status'],
      createdAt: map['createdAt'],
    );
  }
}
