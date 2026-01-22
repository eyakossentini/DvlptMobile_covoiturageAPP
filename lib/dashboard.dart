import 'package:carpooling_app/providers/auth_provider.dart';
import 'package:carpooling_app/screens/admin/admin_dashboard_screen.dart';
import 'package:carpooling_app/screens/home_screen.dart';
import 'package:carpooling_app/package/my_packages_screen.dart';
import 'package:flutter/material.dart';
import 'package:carpooling_app/vehicule/vehicule_repository.dart';
import 'package:carpooling_app/vehicule/home_vehicule_screen.dart';
import 'package:carpooling_app/screens/auth/login_screen.dart';
import 'package:carpooling_app/package/available_packages_screen.dart';
import 'package:carpooling_app/package/admin_packages_screen.dart';
import 'package:provider/provider.dart';

import 'package:carpooling_app/models/vehicule.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final VehiculeRepository repo = VehiculeRepository();

  // Fonction pour rafraîchir le dashboard quand on revient d'une page
  void _refresh() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final bool isDriver = authProvider.isDriver;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          // --- EN-TÊTE (Header) ---
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(
              top: 60,
              bottom: 30,
              left: 20,
              right: 20,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue[900]!, Colors.blue[600]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Icon(Icons.dashboard, color: Colors.white, size: 30),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.logout, color: Colors.white),
                          onPressed: () {
                            Provider.of<AuthProvider>(
                              context,
                              listen: false,
                            ).logout();
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const LoginScreen(),
                              ),
                              (route) => false,
                            );
                          },
                        ),
                        const CircleAvatar(
                          backgroundColor: Colors.white24,
                          child: Icon(Icons.person, color: Colors.white),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                Text(
                  "Tableau de bord",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  user != null && user.userType == 2
                      ? "Bienvenue admin"
                      : isDriver
                      ? "Bienvenue conducteur"
                      : "Bienvenue passager",
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                ),

                const SizedBox(height: 20),

                // Petite stat rapide : Nombre de véhicules
                FutureBuilder<List<Vehicule>>(
                  future: repo
                      .getAll(), // Plus besoin de 'as ...' car les imports sont les mêmes
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SizedBox(
                        height: 50,
                        child: Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                      );
                    }
                    final count = snapshot.data?.length ?? 0;
                    return Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.directions_car, color: Colors.white),
                          const SizedBox(width: 10),
                          Text(
                            "$count Véhicules enregistrés",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // --- GRILLE DE MENU ---
          Expanded(
            child: GridView.count(
              crossAxisCount: 2, // 2 colonnes
              padding: const EdgeInsets.all(20),
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
              children: [
                // Carte 1 : Gestion Véhicules (Fonctionnelle)
                _buildMenuCard(
                  title: "Véhicules",
                  icon: Icons.directions_car_filled,
                  color: Colors.blue,
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const HomeVehiculeScreen(),
                      ),
                    );
                    _refresh(); // Rafraîchir le compteur au retour
                  },
                ),

                // Carte 2 : Accueil (anciennement Réservations)
                // ❌ Admin n’a PAS accès à Réservations
                if (user != null && user.userType != 2)
                  _buildMenuCard(
                    title: isDriver ? "Gestion du conducteur" : "Réservations",
                    icon: isDriver ? Icons.manage_accounts : Icons.event_seat,
                    color: Colors.purple,
                    onTap: () async {
                      if (isDriver) {
                        // 👉 Écran conducteur
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const HomeScreen()),
                        );
                      } else {
                        // 👉 Écran passager (réservations)
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const HomeScreen()),
                        );
                      }
                      _refresh();
                    },
                  ),

                // ✅ Carte 3 : Gestion utilisateur (ADMIN ONLY)
                if (user != null && user.userType == 2)
                  _buildMenuCard(
                    title: "Gestion utilisateur",
                    icon: Icons.person_pin_circle,
                    color: Colors.orange,
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AdminDashboardScreen(),
                        ),
                      );
                      _refresh();
                    },
                  ),

                if (Provider.of<AuthProvider>(context).user?.userType ==
                    0) // Passager
                  _buildMenuCard(
                    title: "Mes Colis",
                    icon: Icons.local_shipping,
                    color: Colors.orange,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const MyPackagesScreen(),
                        ),
                      );
                    },
                  ),

                if (Provider.of<AuthProvider>(context).user?.userType ==
                    1) // Chauffeur
                  _buildMenuCard(
                    title: "Livrer Colis",
                    icon: Icons.local_shipping,
                    color: Colors.orange,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AvailablePackagesScreen(),
                        ),
                      );
                    },
                  ),

                if (Provider.of<AuthProvider>(context).user?.userType ==
                    2) // Admin
                  _buildMenuCard(
                    title: "Gestion Colis",
                    icon: Icons.inventory,
                    color: Colors.teal,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AdminPackagesScreen(),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget helper pour créer une carte de menu
  Widget _buildMenuCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [Colors.white, color.withOpacity(0.05)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 40, color: color),
              ),
              const SizedBox(height: 15),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
