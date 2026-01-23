import 'package:carpooling_app/complaints/complaints_model.dart';
import 'package:flutter/material.dart';

class ComplaintProvider with ChangeNotifier {
  List<Complaint> _complaints = [];
  bool _isLoading = false;

  List<Complaint> get complaints => _complaints;
  bool get isLoading => _isLoading;

  Future<void> fetchComplaints({String? userId, bool reset = false}) async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 500));
    
    // DONNÉES MOCKÉES
    final mockComplaints = [
      Complaint(
        id: '1',
        userId: '1',
        userName: 'Jean Dupont',
        rideId: '123',
        title: 'Conducteur impoli',
        description: 'Le conducteur a été très impoli pendant le trajet.',
        type: ComplaintType.driverBehavior,
        status: ComplaintStatus.pending,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      Complaint(
        id: '2',
        userId: '2',
        userName: 'Marie Martin',
        rideId: '456',
        title: 'Véhicule sale',
        description: 'Le véhicule était sale et sentait mauvais.',
        type: ComplaintType.vehicleCondition,
        status: ComplaintStatus.inProgress,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      Complaint(
        id: '3',
        userId: '3',
        userName: 'Paul Dubois',
        rideId: '789',
        title: 'Retard important',
        description: 'Le conducteur avait 45 minutes de retard.',
        type: ComplaintType.delay,
        status: ComplaintStatus.resolved,
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
      ),
      Complaint(
        id: '4',
        userId: '1',
        userName: 'Jean Dupont',
        rideId: '999',
        title: 'Itinéraire modifié',
        description: 'Le conducteur a changé l\'itinéraire sans prévenir.',
        type: ComplaintType.other,
        status: ComplaintStatus.pending,
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      ),
    ];
    
    // LOGIQUE DE CHARGEMENT
    if (reset || _complaints.isEmpty) {
      print('🔄 Chargement des données mockées (reset: $reset)');
      
      if (reset) {
        _complaints = mockComplaints;
      } else {
        for (var mock in mockComplaints) {
          if (!_complaints.any((c) => c.id == mock.id)) {
            _complaints.add(mock);
          }
        }
      }
    } else {
      print('📊 Utilisation des données existantes (${_complaints.length} réclamations)');
    }
    
    // FILTRAGE POUR L'AFFICHAGE (NE PAS MODIFIER _complaints)
    if (userId != null) {
      final userIdStr = userId.toString();
      final filtered = _complaints.where((c) => c.userId == userIdStr).toList();
      print('🔍 Filtrage pour userId "$userIdStr": ${filtered.length} résultats');
      
      // Debug
      print('📋 Liste complète (${_complaints.length}):');
      for (var c in _complaints) {
        print('   - ${c.title} (user: ${c.userId}, id: ${c.id})');
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addComplaint(Complaint complaint) async {
    try {
      print('➕ AJOUT Réclamation pour ${complaint.userName} (${complaint.userId})');
      print('   Titre: ${complaint.title}');
      print('   Avant ajout: ${_complaints.length} réclamations');
      
      // CRÉER UN ID UNIQUE
      final newComplaint = complaint.copyWith(
        id: 'user_${complaint.userId}_${DateTime.now().millisecondsSinceEpoch}',
        userId: complaint.userId.toString(),
      );
      
      // ÉVITER LES DOUBLONS
      final similarExists = _complaints.any((c) => 
        c.userId == newComplaint.userId && 
        c.title.toLowerCase() == newComplaint.title.toLowerCase() &&
        DateTime.now().difference(c.createdAt).inMinutes < 2
      );
      
      if (similarExists) {
        print('⚠️ Réclamation similaire existe déjà, ignorée');
        return;
      }
      
      // AJOUTER
      _complaints.insert(0, newComplaint);
      
      print('✅ Après ajout: ${_complaints.length} réclamations');
      print('📋 Liste complète:');
      for (var c in _complaints) {
        print('   - ${c.title} (user: ${c.userId}, id: ${c.id})');
      }
      
      notifyListeners();
      
    } catch (e) {
      print('❌ Erreur dans addComplaint: $e');
    }
  }

  Future<void> updateComplaintStatus(String id, ComplaintStatus newStatus) async {
    try {
      print('🔄 Mise à jour statut pour $id -> ${newStatus.label}');
      
      final index = _complaints.indexWhere((c) => c.id == id);
      if (index != -1) {
        final oldComplaint = _complaints[index];
        _complaints[index] = oldComplaint.copyWith(status: newStatus);
        
        print('✅ Statut mis à jour: ${oldComplaint.title} -> ${newStatus.label}');
        
        notifyListeners();
      } else {
        print('❌ Réclamation non trouvée: $id');
      }
    } catch (e) {
      print('❌ Erreur dans updateComplaintStatus: $e');
    }
  }

  // ... autres méthodes inchangées ...

}

// Extension inchangée
extension ComplaintCopyWith on Complaint {
  Complaint copyWith({
    String? id,
    String? userId,
    String? userName,
    String? rideId,
    String? title,
    String? description,
    ComplaintType? type,
    ComplaintStatus? status,
    DateTime? createdAt,
  }) {
    return Complaint(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      rideId: rideId ?? this.rideId,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}