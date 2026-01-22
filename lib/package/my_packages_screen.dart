import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'package_provider.dart';
import '../models/package_model.dart';
import 'add_package_screen.dart';

class MyPackagesScreen extends StatefulWidget {
  const MyPackagesScreen({super.key});

  @override
  State<MyPackagesScreen> createState() => _MyPackagesScreenState();
}

class _MyPackagesScreenState extends State<MyPackagesScreen> {
  @override
  void initState() {
    super.initState();
    _fetchPackages();
  }

  void _fetchPackages() {
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user != null) {
      Provider.of<PackageProvider>(
        context,
        listen: false,
      ).fetchMySentPackages(user.id!);
    }
  }

  Future<void> _deletePackage(int packageId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text('Voulez-vous vraiment supprimer ce colis ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final user = Provider.of<AuthProvider>(context, listen: false).user;
      final success = await Provider.of<PackageProvider>(
        context,
        listen: false,
      ).deletePackage(packageId, user!.id!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success ? 'Colis supprimé' : 'Erreur lors de la suppression',
            ),
          ),
        );
      }
    }
  }

  void _editPackage(Package package) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddPackageScreen(packageToEdit: package),
      ),
    ).then((_) => _fetchPackages());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Colis Sent'),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddPackageScreen()),
          ).then((_) => _fetchPackages());
        },
        backgroundColor: Colors.blue.shade800,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Consumer<PackageProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.mySentPackages.isEmpty) {
            return const Center(child: Text('Aucun colis envoyé.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.mySentPackages.length,
            itemBuilder: (context, index) {
              final package = provider.mySentPackages[index];
              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  title: Text(
                    package.description,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 5),
                      Text('Vers: ${package.deliveryAddress.label}'),
                      const SizedBox(height: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(
                            package.status,
                          ).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          package.status,
                          style: TextStyle(
                            color: _getStatusColor(package.status),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Edit Button (Only if Pending)
                      if (package.status == 'Pending')
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _editPackage(package),
                        ),

                      // Delete Button (Only if Pending)
                      if (package.status == 'Pending')
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deletePackage(package.id!),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending':
        return Colors.orange;
      case 'In Transit':
        return Colors.blue;
      case 'Delivered':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
