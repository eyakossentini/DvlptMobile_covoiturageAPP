import 'package:carpooling_app/providers/auth_provider.dart';
import 'package:carpooling_app/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:carpooling_app/vehicule/vehicule_repository.dart';
import 'package:carpooling_app/vehicule/home_vehicule_screen.dart';
import 'package:carpooling_app/screens/auth/login_screen.dart';
import 'package:provider/provider.dart';

// IMPORT CORRIGÉ (minuscule 'v') pour correspondre au repository

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
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          // --- EN-TÊTE (Header) ---
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 60, bottom: 30, left: 20, right: 20),
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
              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 5))],
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
                            Provider.of<AuthProvider>(context, listen: false).logout();
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(builder: (_) => const LoginScreen()),
                              (route) => false,
                            );
                          },
                        ),
                        const CircleAvatar(
                          backgroundColor: Colors.white24,
                          child: Icon(Icons.person, color: Colors.white),
                        ),
                      ],
                    )
                  ],
                ),
                const SizedBox(height: 20),
                const Text(
                  "Tableau de bord",
                  style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const Text(
                  "Bienvenue dans votre gestionnaire",
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 20),
                
                // Petite stat rapide : Nombre de véhicules
                FutureBuilder<List<Vehicule>>(
                  future: repo.getAll(), // Plus besoin de 'as ...' car les imports sont les mêmes
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                       return const SizedBox(height: 50, child: Center(child: CircularProgressIndicator(color: Colors.white)));
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
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          )
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
                      MaterialPageRoute(builder: (_) => const HomeVehiculeScreen()),
                    );
                    _refresh(); // Rafraîchir le compteur au retour
                  },
                ),

                // Carte 2 : Accueil (anciennement Réservations)
                _buildMenuCard(
                  title: "Accueil",
                  icon: Icons.home,
                  color: Colors.purple,
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const HomeScreen()),
                    );
                    _refresh(); // Rafraîchir le compteur au retour
                  },                
                  ),

                     // Carte 3 : Chauffeurs
                _buildMenuCard(
                  title: "Chauffeurs",
                  icon: Icons.person_pin_circle,
                  color: Colors.orange,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Module Chauffeurs bientôt disponible !")),
                    );
                  },
                ),


                // Carte 4 : Statistiques
                _buildMenuCard(
                  title: "Statistiques",
                  icon: Icons.bar_chart,
                  color: Colors.green,
                  onTap: () {},
                ),
                 // Carte 5 : Déconnecter (anciennement Paramètres)
                _buildMenuCard(
                  title: "Déconnecter",
                  icon: Icons.logout,
                  color: Colors.red,
                  onTap: () {
                    Provider.of<AuthProvider>(context, listen: false).logout();
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
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