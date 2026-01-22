class Reservation {
  int? id;
  int rideId;
  int passengerId;
  String date;

  Reservation({
    this.id,
    required this.rideId,
    required this.passengerId,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'rideId': rideId,
      'passengerId': passengerId,
      'date': date,
    };
  }

  factory Reservation.fromMap(Map<String, dynamic> map) {
    return Reservation(
      id: map['id'],
      rideId: map['rideId'],
      passengerId: map['passengerId'],
      date: map['date'],
    );
  }
}
