import 'package:carpooling_app/reservation/my_bookings_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:carpooling_app/providers/auth_provider.dart';
import 'package:carpooling_app/screens/auth/login_screen.dart';
import 'package:carpooling_app/reservation/add_ride_screen.dart';
import 'package:carpooling_app/reservation/rides_list_screen.dart';
import 'package:carpooling_app/screens/admin/admin_dashboard_screen.dart';
import 'package:carpooling_app/reservation/manage_bookings_screen.dart';
import 'package:carpooling_app/providers/complaint_provider.dart';
import 'package:carpooling_app/complaints/complaints_model.dart';
import 'package:carpooling_app/complaints/complaints_screen.dart';
import 'package:carpooling_app/models/user_model.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        final user = auth.user;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Accueil Covoiturage'),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () {
                  auth.logout();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
          body: Center(
            child: user == null
                ? const Text('Non connecté')
                : Column(
                    children: [
                      const SizedBox(height: 20),
                      Text(
                        'Bienvenue, ${user.name} !',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Rôle : ${user.userType == 1
                            ? "Conducteur"
                            : user.userType == 2
                            ? "Administrateur"
                            : "Client"}',
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 30),

                      // ✅ CONDUCTEUR
                      if (user.userType == 1) ...[
                        _buildActionCard(
                          context,
                          'Proposer un trajet',
                          Icons.add_circle_outline,
                          Colors.green,
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AddRideScreen(),
                              ),
                            );
                          },
                        ),
                        _buildActionCard(
                          context,
                          'Voir mes trajets',
                          Icons.list,
                          Colors.blue,
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const RidesListScreen(),
                              ),
                            );
                          },
                        ),
                        // ✅ AJOUT : conducteur gère les réservations
                        _buildActionCard(
                          context,
                          'Gérer les réservations',
                          Icons.book_online,
                          Colors.purple,
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const ManageBookingsScreen(),
                              ),
                            );
                          },
                        ),
                      ]
                      // ✅ PASSAGER (CLIENT)
                      else if (user.userType == 0) ...[
                        _buildActionCard(
                          context,
                          'Rechercher un trajet',
                          Icons.search,
                          Colors.orange,
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const RidesListScreen(),
                              ),
                            );
                          },
                        ),

                        // ✅ AJOUT : passager voit ses réservations
                        _buildActionCard(
                          context,
                          'Mes réservations',
                          Icons.bookmark_added,
                          Colors.teal,
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const MyBookingScreen(),
                              ),
                            );
                          },
                        ),
                        
                        // ✅ NOUVEAU : passager peut créer une réclamation
                        _buildActionCard(
                          context,
                          'Créer une réclamation',
                          Icons.report_problem,
                          Colors.amber,
                          () {
                            _showAddComplaintDialog(context, user);
                          },
                        ),
                        
                        // ✅ NOUVEAU : passager peut voir ses réclamations
                        _buildActionCard(
                          context,
                          'Mes réclamations',
                          Icons.list_alt,
                          Colors.purple,
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ComplaintsScreen(
                                  userId: _getUserId(user),
                                ),
                              ),
                            );
                          },
                        ),
                      ]
                      // ✅ ADMIN
                      else if (user.userType == 2) ...[
                        _buildActionCard(
                          context,
                          'Tableau de bord Admin',
                          Icons.admin_panel_settings,
                          Colors.red,
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const AdminDashboardScreen(),
                              ),
                            );
                          },
                        ),
                        // ✅ AJOUT : CARTE POUR RÉCLAMATIONS (ADMIN)
                        _buildActionCard(
                          context,
                          'Gestion des réclamations',
                          Icons.report_gmailerrorred,
                          Colors.purple,
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const ComplaintsScreen(isAdmin: true),
                              ),
                            );
                          },
                        ),
                        _buildActionCard(
                          context,
                          'Voir tous les trajets',
                          Icons.directions_car,
                          Colors.blue,
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const RidesListScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ],
                  ),
          ),
        );
      },
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(width: 20),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  String _getUserId(User user) {
    if (user.id == null) return 'unknown';
    if (user.id is int) {
      return (user.id as int).toString();
    } else if (user.id is String) {
      return user.id as String;
    }
    return 'unknown';
  }

  // ✅ DIALOGUE POUR CRÉER UNE RÉCLAMATION
  void _showAddComplaintDialog(BuildContext context, User user) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final rideIdController = TextEditingController();
    ComplaintType _selectedType = ComplaintType.other;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Nouvelle réclamation'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<ComplaintType>(
                  value: _selectedType,
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
                    if (value != null) {
                      _selectedType = value;
                    }
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
              onPressed: () => Navigator.pop(context),
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

                try {
                  final provider = Provider.of<ComplaintProvider>(
                    context,
                    listen: false,
                  );

                  final newComplaint = Complaint(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    userId: _getUserId(user),
                    userName: user.name,
                    rideId: rideIdController.text.isNotEmpty
                        ? rideIdController.text
                        : null,
                    title: titleController.text,
                    description: descriptionController.text,
                    type: _selectedType,
                    status: ComplaintStatus.pending,
                    createdAt: DateTime.now(),
                  );

                  print('=== CRÉATION RÉCLAMATION ===');
                  print('User: ${user.name} (${_getUserId(user)})');
                  print('Titre: ${titleController.text}');
                  print('Type: ${_selectedType.label}');
                  print('Description: ${descriptionController.text}');
                  print('RideId: ${rideIdController.text}');

                  // AJOUTER LA RÉCLAMATION
                  provider.addComplaint(newComplaint);

                  Navigator.pop(context);

                  // Rediriger vers l'écran des réclamations
                  Future.delayed(const Duration(milliseconds: 300), () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ComplaintsScreen(
                          userId: _getUserId(user),
                        ),
                      ),
                    );
                  });

                  // Message de confirmation
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Réclamation "${titleController.text}" créée avec succès',
                      ),
                      backgroundColor: Colors.green,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                } catch (e) {
                  print('❌ Erreur lors de l\'ajout: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erreur: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Envoyer'),
            ),
          ],
        );
      },
    );
  }
}