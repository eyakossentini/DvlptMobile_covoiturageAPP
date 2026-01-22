import 'package:carpooling_app/reservation/my_bookings_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:carpooling_app/providers/auth_provider.dart';
import 'package:carpooling_app/screens/auth/login_screen.dart';
import 'package:carpooling_app/reservation/add_ride_screen.dart';
import 'package:carpooling_app/reservation/rides_list_screen.dart';
import 'package:carpooling_app/screens/admin/admin_dashboard_screen.dart';
import 'package:carpooling_app/reservation/manage_bookings_screen.dart';

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
                      // ✅ PASSAGER
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
}
