import 'package:carpooling_app/complaints/complaints_model.dart';
import 'package:carpooling_app/providers/complaint_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:carpooling_app/providers/auth_provider.dart';

class ComplaintsScreen extends StatefulWidget {
  final bool isAdmin;
  final String? userId;

  const ComplaintsScreen({super.key, this.isAdmin = false, this.userId});

  @override
  State<ComplaintsScreen> createState() => _ComplaintsScreenState();
}

class _ComplaintsScreenState extends State<ComplaintsScreen> {
  ComplaintStatus? _filterStatus;
  bool _isDialogOpen = false;
  bool _hasLoaded = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadInitialData();
      }
    });
  }

  void _loadInitialData() {
    if (!mounted || _hasLoaded) return;

    final provider = Provider.of<ComplaintProvider>(context, listen: false);

    if (widget.isAdmin || provider.complaints.isEmpty) {
      _loadComplaints();
    }

    _hasLoaded = true;
  }

  void _loadComplaints({bool refresh = false}) {
    if (!mounted) return;

    try {
      final provider = Provider.of<ComplaintProvider>(context, listen: false);

      if (refresh) {
        // Utiliser refreshComplaints qui ne réinitialise pas les données
        provider.refreshComplaints();
      } else if (provider.complaints.isEmpty) {
        // Chargement initial seulement
        provider.fetchComplaints(reset: false);
      }
    } catch (e) {
      print('Erreur lors du chargement: $e');
    }
  }

  @override
  void dispose() {
    _isDialogOpen = false;
    super.dispose();
  }

  Color _getStatusColor(ComplaintStatus status) {
    switch (status) {
      case ComplaintStatus.pending:
        return Colors.orange;
      case ComplaintStatus.inProgress:
        return Colors.blue;
      case ComplaintStatus.resolved:
        return Colors.green;
      case ComplaintStatus.rejected:
        return Colors.red;
    }
  }

  IconData _getStatusIcon(ComplaintStatus status) {
    switch (status) {
      case ComplaintStatus.pending:
        return Icons.access_time;
      case ComplaintStatus.inProgress:
        return Icons.sync;
      case ComplaintStatus.resolved:
        return Icons.check_circle;
      case ComplaintStatus.rejected:
        return Icons.cancel;
    }
  }

  Color _getTypeColor(ComplaintType type) {
    switch (type) {
      case ComplaintType.driverBehavior:
        return Colors.red;
      case ComplaintType.vehicleCondition:
        return Colors.blue;
      case ComplaintType.delay:
        return Colors.orange;
      case ComplaintType.cancellation:
        return Colors.purple;
      case ComplaintType.payment:
        return Colors.green;
      case ComplaintType.other:
        return Colors.grey;
      case ComplaintType.passengerBehavior:
        return Colors.brown;
      case ComplaintType.safetyIssue:
        return Colors.redAccent;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isAdmin ? 'Gestion des réclamations' : 'Mes réclamations',
        ),
        actions: [
          if (widget.isAdmin)
            PopupMenuButton<ComplaintStatus>(
              onSelected: (status) {
                setState(() {
                  _filterStatus = status;
                });
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: null,
                  child: Text('Tous les statuts'),
                ),
                ...ComplaintStatus.values.map((status) {
                  return PopupMenuItem(
                    value: status,
                    child: Text(status.label),
                  );
                }).toList(),
              ],
              icon: const Icon(Icons.filter_list),
            ),
        ],
      ),
      body: Consumer<ComplaintProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          List<Complaint> displayedComplaints = provider.complaints;

          if (widget.isAdmin && _filterStatus != null) {
            displayedComplaints = displayedComplaints
                .where((c) => c.status == _filterStatus)
                .toList();
          }

          if (!widget.isAdmin && widget.userId != null) {
            displayedComplaints = displayedComplaints
                .where((c) => c.userId == widget.userId)
                .toList();
          }

          if (displayedComplaints.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.report_problem,
                    size: 60,
                    color: widget.isAdmin ? Colors.blue : Colors.grey,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    widget.isAdmin && _filterStatus != null
                        ? 'Aucune réclamation ${_filterStatus!.label.toLowerCase()}'
                        : widget.isAdmin
                        ? 'Aucune réclamation'
                        : 'Vous n\'avez pas encore de réclamation',
                    style: const TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          // Utiliser refreshComplaints
                          final provider = Provider.of<ComplaintProvider>(context, listen: false);
                          provider.refreshComplaints();
                        },
                        child: const Text('Actualiser'),
                      ),
                      const SizedBox(width: 10),
                      if (!widget.isAdmin)
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Retour'),
                        ),
                    ],
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              // Utiliser refreshComplaints au lieu de fetchComplaints
              try {
                final provider = Provider.of<ComplaintProvider>(context, listen: false);
                await provider.refreshComplaints();
              } catch (e) {
                print('Erreur lors du rafraîchissement: $e');
              }
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: displayedComplaints.length,
              itemBuilder: (context, index) {
                final complaint = displayedComplaints[index];
                return _buildComplaintCard(context, complaint, provider);
              },
            ),
          );
        },
      ),
      floatingActionButton: widget.isAdmin
          ? FloatingActionButton(
              onPressed: () {
                // Pour l'admin, utiliser refreshComplaints
                final provider = Provider.of<ComplaintProvider>(context, listen: false);
                provider.refreshComplaints();
              },
              mini: true,
              child: const Icon(Icons.refresh),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton(
                  heroTag: "refresh",
                  onPressed: () {
                    // Pour l'utilisateur, utiliser refreshComplaints
                    final provider = Provider.of<ComplaintProvider>(context, listen: false);
                    provider.refreshComplaints();
                  },
                  mini: true,
                  child: const Icon(Icons.refresh),
                ),
                const SizedBox(height: 10),
                FloatingActionButton(
                  heroTag: "add",
                  onPressed: () => _showAddComplaintDialog(context),
                  backgroundColor: Colors.amber,
                  child: const Icon(Icons.add_comment, color: Colors.white),
                ),
              ],
            ),
    );
  }

  Widget _buildComplaintCard(
    BuildContext context,
    Complaint complaint,
    ComplaintProvider provider,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 5),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _getStatusColor(complaint.status),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getStatusIcon(complaint.status),
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          complaint.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              complaint.description.length > 60
                  ? '${complaint.description.substring(0, 60)}...'
                  : complaint.description,
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 5),
            Wrap(
              spacing: 8,
              children: [
                Chip(
                  label: Text(
                    complaint.type.label,
                    style: const TextStyle(fontSize: 11),
                  ),
                  backgroundColor: _getTypeColor(
                    complaint.type,
                  ).withOpacity(0.1),
                  labelStyle: TextStyle(color: _getTypeColor(complaint.type)),
                ),
                Chip(
                  label: Text(
                    complaint.status.label,
                    style: const TextStyle(fontSize: 11),
                  ),
                  backgroundColor: _getStatusColor(
                    complaint.status,
                  ).withOpacity(0.1),
                  labelStyle: TextStyle(
                    color: _getStatusColor(complaint.status),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (widget.isAdmin && complaint.userName.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 5),
                child: Text(
                  'Par: ${complaint.userName}',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ),
          ],
        ),
        trailing: widget.isAdmin
            ? _buildAdminQuickActions(complaint, provider)
            : _buildUserActions(complaint, provider),
        onTap: () {
          _showComplaintDetail(context, complaint, provider);
        },
      ),
    );
  }

  Widget _buildAdminQuickActions(
    Complaint complaint,
    ComplaintProvider provider,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (complaint.status != ComplaintStatus.inProgress)
          IconButton(
            icon: const Icon(Icons.play_arrow, size: 18, color: Colors.blue),
            tooltip: 'Mettre en cours',
            onPressed: () {
              if (!mounted) return;

              provider.updateComplaintStatus(
                complaint.id,
                ComplaintStatus.inProgress,
              );

              Future.microtask(() {
                if (mounted && ScaffoldMessenger.of(context).mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('"${complaint.title}" mis en cours'),
                      backgroundColor: Colors.blue,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              });
            },
          ),

        if (complaint.status != ComplaintStatus.resolved)
          IconButton(
            icon: const Icon(Icons.check, size: 18, color: Colors.green),
            tooltip: 'Marquer comme résolu',
            onPressed: () {
              if (!mounted) return;

              provider.updateComplaintStatus(
                complaint.id,
                ComplaintStatus.resolved,
              );

              Future.microtask(() {
                if (mounted && ScaffoldMessenger.of(context).mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('"${complaint.title}" résolu'),
                      backgroundColor: Colors.green,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              });
            },
          ),

        if (complaint.status != ComplaintStatus.rejected)
          IconButton(
            icon: const Icon(Icons.close, size: 18, color: Colors.red),
            tooltip: 'Rejeter',
            onPressed: () {
              if (!mounted) return;

              provider.updateComplaintStatus(
                complaint.id,
                ComplaintStatus.rejected,
              );

              Future.microtask(() {
                if (mounted && ScaffoldMessenger.of(context).mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('"${complaint.title}" rejeté'),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              });
            },
          ),
        
        // Bouton de suppression pour admin
        IconButton(
          icon: const Icon(Icons.delete, size: 18, color: Colors.red),
          tooltip: 'Supprimer',
          onPressed: () => _showDeleteConfirmationDialog(context, complaint, provider),
        ),
      ],
    );
  }

  Widget _buildUserActions(Complaint complaint, ComplaintProvider provider) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Bouton de modification seulement si la réclamation est en attente
        if (complaint.status == ComplaintStatus.pending)
          IconButton(
            icon: const Icon(Icons.edit, size: 18, color: Colors.blue),
            tooltip: 'Modifier',
            onPressed: () => _showEditComplaintDialog(context, complaint, provider),
          ),
        
        // Bouton de suppression seulement si la réclamation est en attente
        if (complaint.status == ComplaintStatus.pending)
          IconButton(
            icon: const Icon(Icons.delete, size: 18, color: Colors.red),
            tooltip: 'Supprimer',
            onPressed: () => _showDeleteConfirmationDialog(context, complaint, provider),
          ),
        
        const Icon(Icons.arrow_forward_ios, size: 16),
      ],
    );
  }

  void _showAddComplaintDialog(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.user;

    // sécurité
    if (user == null) return;

    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final rideIdController = TextEditingController();
    ComplaintType selectedType = ComplaintType.other;

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Nouvelle réclamation'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<ComplaintType>(
                  value: selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Type de réclamation',
                    border: OutlineInputBorder(),
                  ),
                  items: ComplaintType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type.label),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) selectedType = value;
                  },
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: rideIdController,
                  decoration: const InputDecoration(
                    labelText: 'ID du trajet (optionnel)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Titre*',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description*',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 4,
                ),
                const SizedBox(height: 10),
                const Text(
                  '* Champs obligatoires',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Veuillez saisir un titre'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                if (descriptionController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Veuillez saisir une description'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                final provider = Provider.of<ComplaintProvider>(
                  context,
                  listen: false,
                );

                final newComplaint = Complaint(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  userId: widget.userId ?? user.id.toString(),
                  userName: user.name,
                  rideId: rideIdController.text.isNotEmpty
                      ? rideIdController.text
                      : null,
                  title: titleController.text,
                  description: descriptionController.text,
                  type: selectedType,
                  status: ComplaintStatus.pending,
                  createdAt: DateTime.now(),
                );

                provider.addComplaint(newComplaint);

                Navigator.pop(ctx);

                // ✅ pas de fetch/reset ici (sinon tu écrases la liste)
                setState(() {});

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Réclamation "${titleController.text}" ajoutée',
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: const Text('Envoyer'),
            ),
          ],
        );
      },
    );
  }

  void _showEditComplaintDialog(BuildContext context, Complaint complaint, ComplaintProvider provider) {
    final titleController = TextEditingController(text: complaint.title);
    final descriptionController = TextEditingController(text: complaint.description);
    final rideIdController = TextEditingController(text: complaint.rideId ?? '');
    ComplaintType selectedType = complaint.type;

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Modifier la réclamation'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<ComplaintType>(
                  value: selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Type de réclamation',
                    border: OutlineInputBorder(),
                  ),
                  items: ComplaintType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type.label),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) selectedType = value;
                  },
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: rideIdController,
                  decoration: const InputDecoration(
                    labelText: 'ID du trajet (optionnel)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Titre*',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description*',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 4,
                ),
                const SizedBox(height: 10),
                const Text(
                  '* Champs obligatoires',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Veuillez saisir un titre'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                if (descriptionController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Veuillez saisir une description'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                // Créer une copie mise à jour de la réclamation
                final updatedComplaint = complaint.copyWith(
                  title: titleController.text,
                  description: descriptionController.text,
                  type: selectedType,
                  rideId: rideIdController.text.isNotEmpty ? rideIdController.text : null,
                );

                provider.updateComplaint(updatedComplaint);

                Navigator.pop(ctx);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Réclamation "${titleController.text}" modifiée',
                    ),
                    backgroundColor: Colors.blue,
                  ),
                );
              },
              child: const Text('Enregistrer'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context, Complaint complaint, ComplaintProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Confirmer la suppression'),
          content: Text(
            widget.isAdmin
                ? 'Voulez-vous vraiment supprimer la réclamation "${complaint.title}" ?'
                : 'Voulez-vous vraiment supprimer votre réclamation "${complaint.title}" ?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                provider.deleteComplaint(complaint.id);
                Navigator.pop(ctx);
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Réclamation "${complaint.title}" supprimée',
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showComplaintDetail(
    BuildContext context,
    Complaint complaint,
    ComplaintProvider provider,
  ) {
    if (_isDialogOpen || !mounted) return;

    _isDialogOpen = true;
    ComplaintStatus selectedStatus = complaint.status;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(complaint.title),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.isAdmin) ...[
                      const Text(
                        'Changer le statut:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<ComplaintStatus>(
                        value: selectedStatus,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 10),
                        ),
                        isExpanded: true,
                        items: ComplaintStatus.values.map((status) {
                          return DropdownMenuItem(
                            value: status,
                            child: Row(
                              children: [
                                Icon(
                                  _getStatusIcon(status),
                                  color: _getStatusColor(status),
                                ),
                                const SizedBox(width: 10),
                                Text(status.label),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (newStatus) {
                          if (newStatus != null) {
                            setState(() {
                              selectedStatus = newStatus;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 20),
                      const Divider(),
                    ],

                    const Text(
                      'Détails:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 10),

                    Row(
                      children: [
                        const Text(
                          'Type: ',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(complaint.type.label),
                      ],
                    ),
                    const SizedBox(height: 5),

                    Row(
                      children: [
                        const Text(
                          'Statut actuel: ',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Chip(
                          label: Text(complaint.status.label),
                          backgroundColor: _getStatusColor(
                            complaint.status,
                          ).withOpacity(0.1),
                          labelStyle: TextStyle(
                            color: _getStatusColor(complaint.status),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    const Text(
                      'Description:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 5),
                    Text(complaint.description),
                    const SizedBox(height: 10),

                    Row(
                      children: [
                        const Text(
                          'Date: ',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(_formatDate(complaint.createdAt)),
                      ],
                    ),

                    if (complaint.userName.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          const Text(
                            'Par: ',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(complaint.userName),
                        ],
                      ),
                    ],

                    if (complaint.rideId != null &&
                        complaint.rideId!.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          const Text(
                            'Trajet ID: ',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(complaint.rideId!),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                if (!widget.isAdmin && complaint.status == ComplaintStatus.pending)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        tooltip: 'Modifier',
                        onPressed: () {
                          Navigator.pop(context);
                          _showEditComplaintDialog(context, complaint, provider);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        tooltip: 'Supprimer',
                        onPressed: () {
                          Navigator.pop(context);
                          _showDeleteConfirmationDialog(context, complaint, provider);
                        },
                      ),
                    ],
                  ),
                
                TextButton(
                  onPressed: () {
                    _isDialogOpen = false;
                    Navigator.pop(context);
                  },
                  child: const Text('Fermer'),
                ),

                if (widget.isAdmin && selectedStatus != complaint.status)
                  ElevatedButton(
                    onPressed: () {
                      if (!mounted) return;

                      provider.updateComplaintStatus(
                        complaint.id,
                        selectedStatus,
                      );
                      _isDialogOpen = false;
                      Navigator.pop(context);

                      Future.microtask(() {
                        if (mounted && ScaffoldMessenger.of(context).mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Statut changé à: ${selectedStatus.label}',
                              ),
                              backgroundColor: Colors.green,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      });
                    },
                    child: const Text('Sauvegarder'),
                  ),
              ],
            );
          },
        );
      },
    ).then((_) {
      _isDialogOpen = false;
    });
  }
}