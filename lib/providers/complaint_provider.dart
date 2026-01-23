import 'package:carpooling_app/complaints/complaints_model.dart';
import 'package:flutter/material.dart';

class ComplaintProvider with ChangeNotifier {
  List<Complaint> _complaints = [];
  bool _isLoading = false;
  bool _mockDataLoaded = false;

  List<Complaint> get complaints => _complaints;
  bool get isLoading => _isLoading;

  // DONNÉES MOCKÉES
  List<Complaint> get _mockComplaints {
    return [
      Complaint(
        id: 'mock_1',
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
        id: 'mock_2',
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
        id: 'mock_3',
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
        id: 'mock_4',
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
  }

  Future<void> fetchComplaints({String? userId, bool reset = false}) async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 500));
    
    print('🔄 fetchComplaints appelé (reset: $reset, mockLoaded: $_mockDataLoaded)');
    
    if (reset) {
      print('🔄 Réinitialisation complète demandée');
      _complaints.clear();
      _mockDataLoaded = false;
    }
    
    // Charger les données mockées SEULEMENT si elles ne sont pas déjà chargées
    if (!_mockDataLoaded) {
      print('📥 Chargement des données mockées');
      for (var mock in _mockComplaints) {
        if (!_complaints.any((c) => c.id == mock.id)) {
          _complaints.add(mock);
        }
      }
      _mockDataLoaded = true;
    } else {
      print('📊 Utilisation des données existantes (${_complaints.length} réclamations)');
    }

    _isLoading = false;
    notifyListeners();
  }

  // NOUVELLE MÉTHODE POUR ACTUALISER SANS RÉINITIALISER
  Future<void> refreshComplaints({String? userId}) async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 300));
    
    print('🔄 refreshComplaints appelé (simulation de rafraîchissement)');
    print('   Liste actuelle: ${_complaints.length} réclamations');
    
    // Ne fait rien d'autre que notifier - garde toutes les données existantes
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addComplaint(Complaint complaint) async {
    try {
      print('➕ AJOUT Réclamation pour ${complaint.userName}');
      
      // CRÉER UN ID UNIQUE avec préfixe "user_"
      final newComplaint = complaint.copyWith(
        id: 'user_${complaint.userId}_${DateTime.now().millisecondsSinceEpoch}',
        userId: complaint.userId.toString(),
      );
      
      // ÉVITER LES DOUBLONS
      final similarExists = _complaints.any((c) => 
        c.userId == newComplaint.userId && 
        c.title.toLowerCase() == newComplaint.title.toLowerCase() &&
        c.id.startsWith('user_') &&
        DateTime.now().difference(c.createdAt).inMinutes < 5
      );
      
      if (similarExists) {
        print('⚠️ Réclamation similaire existe déjà (moins de 5 minutes), ignorée');
        return;
      }
      
      // AJOUTER AU DÉBUT DE LA LISTE
      _complaints.insert(0, newComplaint);
      
      print('✅ Réclamation ajoutée: ${_complaints.length} total');
      
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

  Future<void> updateComplaint(Complaint updatedComplaint) async {
    try {
      print('✏️ MODIFICATION Réclamation ${updatedComplaint.id}');
      
      final index = _complaints.indexWhere((c) => c.id == updatedComplaint.id);
      
      if (index != -1) {
        final oldComplaint = _complaints[index];
        
        if (oldComplaint.status != ComplaintStatus.pending) {
          print('⚠️ Impossible de modifier une réclamation non en attente');
          throw Exception('Seules les réclamations en attente peuvent être modifiées');
        }
        
        _complaints[index] = updatedComplaint.copyWith(
          createdAt: oldComplaint.createdAt,
        );
        
        print('✅ Réclamation modifiée: ${oldComplaint.title} -> ${updatedComplaint.title}');
        
        notifyListeners();
      } else {
        print('❌ Réclamation non trouvée: ${updatedComplaint.id}');
        throw Exception('Réclamation non trouvée');
      }
    } catch (e) {
      print('❌ Erreur dans updateComplaint: $e');
      rethrow;
    }
  }

  Future<void> deleteComplaint(String complaintId) async {
    try {
      print('🗑️ SUPPRESSION Réclamation $complaintId');
      
      final index = _complaints.indexWhere((c) => c.id == complaintId);
      
      if (index != -1) {
        final complaintToDelete = _complaints[index];
        
        _complaints.removeAt(index);
        
        print('✅ Réclamation supprimée: ${complaintToDelete.title}');
        
        notifyListeners();
      } else {
        print('❌ Réclamation non trouvée: $complaintId');
        throw Exception('Réclamation non trouvée');
      }
    } catch (e) {
      print('❌ Erreur dans deleteComplaint: $e');
      rethrow;
    }
  }

  Complaint? getComplaintById(String id) {
    try {
      return _complaints.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }

  List<Complaint> getComplaintsByUserId(String userId) {
    return _complaints.where((c) => c.userId == userId).toList();
  }

  List<Complaint> getComplaintsByStatus(ComplaintStatus status) {
    return _complaints.where((c) => c.status == status).toList();
  }

  Map<ComplaintStatus, int> getComplaintsCountByStatus() {
    final Map<ComplaintStatus, int> counts = {};
    
    for (final status in ComplaintStatus.values) {
      counts[status] = _complaints.where((c) => c.status == status).length;
    }
    
    return counts;
  }

  bool canUserModifyComplaint(String complaintId, String userId, {bool isAdmin = false}) {
    try {
      final complaint = _complaints.firstWhere((c) => c.id == complaintId);
      
      if (isAdmin) {
        return true;
      }
      
      return complaint.userId == userId && complaint.status == ComplaintStatus.pending;
    } catch (e) {
      return false;
    }
  }

  bool canUserDeleteComplaint(String complaintId, String userId, {bool isAdmin = false}) {
    try {
      final complaint = _complaints.firstWhere((c) => c.id == complaintId);
      
      if (isAdmin) {
        return true;
      }
      
      return complaint.userId == userId && 
             complaint.status == ComplaintStatus.pending &&
             complaint.id.startsWith('user_');
    } catch (e) {
      return false;
    }
  }
}

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