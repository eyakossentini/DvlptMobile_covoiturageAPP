import '../models/address.dart';

class Ride {
  int? id;
  final int driverId;
  final Address from;
  final Address to;
  final String date;
  final String time;
  final double price;
  int durationMinutes;
  final int seats;

  Ride({
    this.id,
    required this.driverId,
    required this.from,
    required this.to,
    required this.date,
    required this.time,
    required this.price,
    required this.durationMinutes,
    required this.seats,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'driverId': driverId,

      'fromLabel': from.label,
      'fromLat': from.lat,
      'fromLng': from.lng,

      'toLabel': to.label,
      'toLat': to.lat,
      'toLng': to.lng,

      'date': date,
      'time': time,
      'price': price,
      'durationMinutes': durationMinutes,
      'seats': seats,
    };
  }

  factory Ride.fromMap(Map<String, dynamic> map) {
    return Ride(
      id: map['id'],
      driverId: map['driverId'],

      from: Address(
        label: map['fromLabel'],
        lat: map['fromLat'],
        lng: map['fromLng'],
      ),

      to: Address(label: map['toLabel'], lat: map['toLat'], lng: map['toLng']),

      date: map['date'],
      time: map['time'],
      price: map['price'],
      durationMinutes: map['durationMinutes'],
      seats: map['seats'],
    );
  }
}
