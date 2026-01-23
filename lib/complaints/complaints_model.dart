class Complaint {
  final String id;
  final String userId;
  final String userName;
  final String? rideId;
  final ComplaintType type;
  final String title;
  final String description;
  //final List<String> photos; // URLs ou chemins des photos
  final DateTime createdAt;
  final ComplaintStatus status;
  final String? adminResponse;
  final DateTime? resolvedAt;
 

  Complaint({
    required this.id,
    required this.userId,
    this.rideId,
    required this.type,
    required this.title,
    required this.description,
   // required this.photos,
    required this.createdAt,
    this.status = ComplaintStatus.pending,
    this.adminResponse,
    this.resolvedAt, 
    required this.userName,
  
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'rideId': rideId,
    'type': type.toString().split('.').last,
    'title': title,
    'description': description,
    //'photos': photos,
    'createdAt': createdAt.toIso8601String(),
    'status': status.toString().split('.').last,
    'adminResponse': adminResponse,
    'resolvedAt': resolvedAt?.toIso8601String(),
    
  };

  factory Complaint.fromJson(Map<String, dynamic> json) => Complaint(
    id: json['id'],
    userId: json['userId'],
    rideId: json['rideId'],
    type: ComplaintType.values.firstWhere(
      (e) => e.toString() == 'ComplaintType.${json['type']}'
    ),
    title: json['title'],
    description: json['description'],
    //photos: List<String>.from(json['photos']),
    createdAt: DateTime.parse(json['createdAt']),
    status: ComplaintStatus.values.firstWhere(
      (e) => e.toString() == 'ComplaintStatus.${json['status']}'
    ),
    adminResponse: json['adminResponse'],
    resolvedAt: json['resolvedAt'] != null 
      ? DateTime.parse(json['resolvedAt']) 
      : null, userName: '',
  );
}

enum ComplaintType {
  driverBehavior('Comportement du conducteur'),
  vehicleCondition('État du véhicule'),
  passengerBehavior ('Comportement du passager'),
  safetyIssue ('Problème de sécurité'),
  delay('Retard'),
  cancellation('Annulation'),
  payment('Paiement'),
  other('Autre');

  final String label;
  const ComplaintType(this.label);
}

enum ComplaintStatus {
  pending('En attente'),
  inProgress('En cours'),
  resolved('Résolu'),
  rejected('Rejeté');
// PAS: inReview, needsInfo
  final String label;
  const ComplaintStatus(this.label);
}