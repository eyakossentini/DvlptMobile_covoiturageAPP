import 'package:carpooling_app/vehicule/vehicule_list_page.dart';
import 'package:flutter/material.dart';
import 'package:carpooling_app/db/database_helper.dart';
import 'package:carpooling_app/models/user_model.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  _AdminDashboardScreenState createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  List<User> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  void _fetchUsers() async {
    List<User> users = await _db.getAllUsers();
    setState(() {
      _users = users;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    int clientCount = _users.where((u) => u.userType == 0).length;
    int driverCount = _users.where((u) => u.userType == 1).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tableau de Bord Admin'),
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Clients',
                          clientCount.toString(),
                          Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildStatCard(
                          'Conducteurs',
                          driverCount.toString(),
                          Colors.blue,
                        ),
                      ),
                      Expanded(
                        child: _buildStatCard(
                          'Véhicules',
                          'À implémenter',
                          Colors.green,
                        ),
                      ),
                    ], 
                  ),
                  const SizedBox(height: 20),

                 // ✅ GESTION DES VÉHICULES
                  _buildActionCard(
                    context,
                    'Gestion des véhicules',
                    Icons.directions_car,
                    Colors.green,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const VehiculeListPage(),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 30),
                  const Text(
                    'Liste des Utilisateurs',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('ID')),
                        DataColumn(label: Text('Nom')),
                        DataColumn(label: Text('Email')),
                        DataColumn(label: Text('Rôle')),
                      ],
                      rows: _users.map((user) {
                        return DataRow(
                          cells: [
                            DataCell(Text(user.id?.toString() ?? '-')),
                            DataCell(Text(user.name)),
                            DataCell(Text(user.email)),
                            DataCell(
                              Text(
                                user.userType == 0 ? 'Client' : 'Conducteur',
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
              
            ),
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
    elevation: 4,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 25),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.8), color],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 40, color: Colors.white),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        
      ),
    ),
  );
}


  Widget _buildStatCard(String title, String value, Color color) {
    return Card(
      elevation: 4,
      color: color,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
          
        ),
        
      ),
    );
  }
}
