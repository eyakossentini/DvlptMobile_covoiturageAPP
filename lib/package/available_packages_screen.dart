import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'package_provider.dart';
import '../models/package_model.dart';

class AvailablePackagesScreen extends StatefulWidget {
  const AvailablePackagesScreen({super.key});

  @override
  State<AvailablePackagesScreen> createState() =>
      _AvailablePackagesScreenState();
}

class _AvailablePackagesScreenState extends State<AvailablePackagesScreen> {
  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _fetchData() {
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user != null) {
      final provider = Provider.of<PackageProvider>(context, listen: false);
      provider.fetchAvailablePackages();
      provider.fetchMyDeliveries(user.id!);
    }
  }

  Future<void> _acceptPackage(Package package) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final packageProvider = Provider.of<PackageProvider>(
      context,
      listen: false,
    );

    if (authProvider.user == null) return;

    final success = await packageProvider.acceptPackage(
      package.id!,
      authProvider.user!.id!,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Colis accepté ! Retrouvez-le dans "Mes Livraisons".'),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur lors de l\'acceptation du colis.'),
        ),
      );
    }
  }

  Future<void> _updateStatus(Package package, String newStatus) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final packageProvider = Provider.of<PackageProvider>(
      context,
      listen: false,
    );

    if (authProvider.user == null) return;

    final success = await packageProvider.updateStatus(
      package.id!,
      newStatus,
      authProvider.user!.id!,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Statut mis à jour : $newStatus')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur lors de la mise à jour.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Espace Livreur'),
          backgroundColor: Colors.blue.shade800,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: 'Disponibles', icon: Icon(Icons.list)),
              Tab(text: 'Mes Livraisons', icon: Icon(Icons.local_shipping)),
            ],
          ),
        ),
        body: Consumer<PackageProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            return TabBarView(
              children: [
                _buildAvailableList(provider.availablePackages),
                _buildMyDeliveriesList(provider.myDeliveries),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildAvailableList(List<Package> packages) {
    if (packages.isEmpty) {
      return const Center(child: Text('Aucun colis disponible.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: packages.length,
      itemBuilder: (context, index) {
        final package = packages[index];
        return _buildPackageCard(
          package,
          actionButton: ElevatedButton.icon(
            onPressed: () => _acceptPackage(package),
            icon: const Icon(Icons.check),
            label: const Text('Accepter'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        );
      },
    );
  }

  Widget _buildMyDeliveriesList(List<Package> packages) {
    if (packages.isEmpty) {
      return const Center(child: Text('Aucune livraison en cours.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: packages.length,
      itemBuilder: (context, index) {
        final package = packages[index];

        Widget? actionButton;
        if (package.status == 'In Transit') {
          actionButton = ElevatedButton.icon(
            onPressed: () => _updateStatus(package, 'Delivered'),
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Marquer Livré'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          );
        } else if (package.status == 'Delivered') {
          actionButton = Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.done_all, color: Colors.green),
                SizedBox(width: 8),
                Text('Livré'),
              ],
            ),
          );
        }

        return _buildPackageCard(package, actionButton: actionButton);
      },
    );
  }

  Widget _buildPackageCard(Package package, {Widget? actionButton}) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    package.description,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade100),
                  ),
                  child: Text(
                    package.weight,
                    style: TextStyle(
                      color: Colors.blue.shade800,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildAddressRow(
              Icons.location_on,
              Colors.green,
              package.pickupAddress.label,
            ),
            const SizedBox(height: 8),
            _buildAddressRow(
              Icons.flag,
              Colors.red,
              package.deliveryAddress.label,
            ),
            const SizedBox(height: 16),
            if (actionButton != null) ...[
              SizedBox(width: double.infinity, child: actionButton),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAddressRow(IconData icon, Color color, String text) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
      ],
    );
  }
}
