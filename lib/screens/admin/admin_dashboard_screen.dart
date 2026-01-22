import 'package:carpooling_app/vehicule/vehicule_list_page.dart';
import 'package:flutter/material.dart';
import 'package:carpooling_app/db/database_helper.dart';
import 'package:carpooling_app/models/user_model.dart';
import 'package:carpooling_app/providers/auth_provider.dart';
import 'package:carpooling_app/screens/auth/login_screen.dart';
import 'package:provider/provider.dart';
import 'package:carpooling_app/vehicule/vehicule_repository.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  _AdminDashboardScreenState createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  List<User> _users = [];
  bool _isLoading = true;
  int _vehiculeCount = 0;
  int _taxiCount = 0;
  int _persoCount =0;

  // ✅ NEW: pour scroll vers la section users
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _usersSectionKey = GlobalKey();
  final VehiculeRepository _vehiculeRepo = VehiculeRepository();

  @override
  void initState() {
    super.initState();
    _fetchUsers();
    _fetchVehicules();
  }

  void _fetchVehicules() async {
    final vehicules = await _vehiculeRepo.getAll();

    setState(() {
      _vehiculeCount = vehicules.length;
      _taxiCount = vehicules
          .where((v) => v.type.toLowerCase() == 'taxi')
          .length;
      _persoCount = vehicules
          .where((v) => v.type.toLowerCase() != 'taxi')
          .length;
    });
  }

  void _fetchUsers() async {
    List<User> users = await _db.getAllUsers();
    if (!mounted) return;
    setState(() {
      _users = users;
      _isLoading = false;
    });
  }

  void _scrollToUsers() {
    final contextKey = _usersSectionKey.currentContext;
    if (contextKey == null) return;
    Scrollable.ensureVisible(
      contextKey,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  void _deleteUser(int id) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text('Voulez-vous vraiment supprimer cet utilisateur ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _db.deleteUser(id);
      _fetchUsers();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Utilisateur supprimé')));
    }
  }

  void _editUser(User user) async {
    final nameController = TextEditingController(text: user.name);
    final emailController = TextEditingController(text: user.email);
    final phoneController = TextEditingController(text: user.phone);
    int selectedRole = user.userType;

    bool? saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Modifier l\'utilisateur'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Nom'),
                ),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: 'Téléphone'),
                ),
                const SizedBox(height: 10),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Rôle :'),
                ),
                DropdownButton<int>(
                  value: selectedRole,
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(value: 0, child: Text('Client')),
                    DropdownMenuItem(value: 1, child: Text('Conducteur')),
                    DropdownMenuItem(value: 2, child: Text('Administrateur')),
                  ],
                  onChanged: (v) => setDialogState(() => selectedRole = v!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );

    if (saved == true) {
      user.name = nameController.text.trim();
      user.email = emailController.text.trim();
      user.phone = phoneController.text.trim();
      user.userType = selectedRole;

      await _db.updateUser(user);
      _fetchUsers();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Utilisateur mis à jour')));
    }
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
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ✅ STATS
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
                      const SizedBox(height: 10),
                      Expanded(
                        child: _buildStatCard(
                          'Véhicules',
                          _vehiculeCount.toString(),
                          Colors.green,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildStatCard(
                          'Taxis',
                          _taxiCount.toString(),
                          Colors.amber,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildStatCard(
                          'Voiture Perso',
                          _persoCount.toString(),
                          Colors.indigo,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 22),

                  // ✅ NEW SECTION: Gestion Admin (dashboard style)
                  const Text(
                    "Gestion Admin",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    children: [
                      _buildDashboardTile(
                        title: "Gestion des véhicules",
                        icon: Icons.directions_car,
                        color: Colors.green,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const VehiculeListPage(),
                            ),
                          );
                        },
                      ),
                      _buildDashboardTile(
                        title: "Gestion des utilisateurs",
                        icon: Icons.people,
                        color: Colors.red,
                        onTap: _scrollToUsers,
                      ),
                    ],
                  ),

                  const SizedBox(height: 26),

                  // ✅ USERS TABLE (inchangée)
                  Container(
                    key: _usersSectionKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Liste des Utilisateurs',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
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
                              DataColumn(label: Text('Actions')),
                            ],
                            rows: _users.map((user) {
                              return DataRow(
                                cells: [
                                  DataCell(Text(user.id?.toString() ?? '-')),
                                  DataCell(Text(user.name)),
                                  DataCell(Text(user.email)),
                                  DataCell(
                                    Text(
                                      user.userType == 0
                                          ? 'Client'
                                          : user.userType == 1
                                          ? 'Conducteur'
                                          : 'Admin',
                                    ),
                                  ),
                                  DataCell(
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                            Icons.edit,
                                            color: Colors.blue,
                                          ),
                                          onPressed: () => _editUser(user),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete,
                                            color: Colors.red,
                                          ),
                                          onPressed: () =>
                                              _deleteUser(user.id!),
                                        ),
                                      ],
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
                ],
              ),
            ),
    );
  }

  // ✅ NEW: tuile dashboard
  Widget _buildDashboardTile({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.8), color],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 42, color: Colors.white),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // (Tu gardes tes fonctions existantes)
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
