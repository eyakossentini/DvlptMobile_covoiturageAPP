class User {
  int? id;
  String name;
  String email;
  String phone;

  //utilise seulement à inscription, login pas stocké en BD
  String? password;

  // 0: Client, 1: Conducteur
  int userType;

  User({
    this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.userType,
    required this.password,
  });

  // Convert a User into a Map. The keys must correspond to the names of the
  // columns in the database.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'password': password,
      'userType': userType,
    };
  }

  // Convert a Map into a User.
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      email: map['email'],
      password: map['password'],
      userType: map['userType'],
      name: map['name'],
      phone: map['phone'],
    );
  }
}
