class Address {
  final String label; // address text
  final double lat;
  final double lng;

  Address({
    required this.label,
    //latitude
    required this.lat,
    //longtitude
    required this.lng,
  });

  factory Address.fromMap(Map<String, dynamic> map) {
    return Address(label: map['label'], lat: map['lat'], lng: map['lng']);
  }

  Map<String, dynamic> toMap() {
    return {'label': label, 'lat': lat, 'lng': lng};
  }
}
