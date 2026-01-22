import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:carpooling_app/vehicule/vehicule_repository.dart';
import 'package:carpooling_app/models/vehicule.dart';
import 'Vehicule_form_page.dart';

class VehiculeListPage extends StatefulWidget {
  final bool readOnly; // ✅ Lecture seule pour les clients

  const VehiculeListPage({
    super.key,
    this.readOnly = false, // false par défaut → conducteur/admin
  });

  @override
  State<VehiculeListPage> createState() => _VehiculeListPageState();
}

class _VehiculeListPageState extends State<VehiculeListPage> {
  final VehiculeRepository repo = VehiculeRepository();
  String filterType = 'Tous';

  Future<void> confirmDelete(int id) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text('Voulez-vous vraiment supprimer ce véhicule ?'),
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

    if (result == true) {
      await repo.deleteVehicule(id);
      setState(() {});
    }
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.blueGrey[300]),
          const SizedBox(width: 8),
          Text(
            "$label : ",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
              fontSize: 14,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.black87,
                fontSize: 15,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 1,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: const Text('Mes Véhicules', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: filterType,
                icon: const Icon(Icons.filter_list, color: Colors.blue),
                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w500),
                items: const [
                  DropdownMenuItem(value: 'Tous', child: Text('Tous')),
                  DropdownMenuItem(value: 'Taxi', child: Text('Taxi')),
                  DropdownMenuItem(value: 'Personnelle', child: Text('Perso')),
                ],
                onChanged: (v) => setState(() => filterType = v!),
              ),
            ),
          ),
        ],
      ),
      body: FutureBuilder<List<Vehicule>>(
        future: repo.getAll(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          }

          List<Vehicule> vehicules = snapshot.data ?? [];

          if (filterType != 'Tous') {
            vehicules = vehicules
                .where((v) => v.type.toLowerCase() == filterType.toLowerCase())
                .toList();
          }

          if (vehicules.isEmpty) {
            return Center(child: Text("Aucun véhicule trouvé.", style: TextStyle(color: Colors.grey[600])));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: vehicules.length,
            itemBuilder: (context, index) {
              final v = vehicules[index];
              final isTaxi = v.type.toLowerCase() == 'taxi';

              return Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 600),
                  margin: const EdgeInsets.only(bottom: 20),
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Stack(
                          children: [
                            Container(
                              height: 200,
                              width: double.infinity,
                              color: Colors.grey[200],
                              child: (kIsWeb && v.photoBytes != null)
                                  ? Image.memory(v.photoBytes!, fit: BoxFit.contain)
                                  : (!kIsWeb && v.photoPath != null)
                                      ? Image.file(File(v.photoPath!), fit: BoxFit.contain)
                                      : Icon(isTaxi ? Icons.local_taxi : Icons.directions_car, size: 80, color: Colors.grey[400]),
                            ),
                            Positioned(
                              top: 12,
                              right: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: isTaxi ? Colors.amber[700] : Colors.blue[700],
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                                ),
                                child: Text(
                                  isTaxi ? "TAXI" : "PERSO",
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildDetailRow(Icons.branding_watermark, "Marque", v.marque),
                                    _buildDetailRow(Icons.model_training, "Modèle", v.modele),
                                    _buildDetailRow(Icons.pin_drop, "Immat", v.immatriculation.toUpperCase()),
                                    _buildDetailRow(Icons.event_seat, "Places", "${v.places} places"),
                                  ],
                                ),
                              ),
                              Column(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.blueGrey),
                                    onPressed: widget.readOnly
                                        ? null
                                        : () async {
                                            final result = await Navigator.push(
                                              context,
                                              MaterialPageRoute(builder: (_) => VehiculeFormPage(vehicule: v)),
                                            );
                                            if (result == true) setState(() {});
                                          },
                                  ),
                                  const SizedBox(height: 8),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                                    onPressed: widget.readOnly ? null : () => confirmDelete(v.id),
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: widget.readOnly
          ? null
          : FloatingActionButton.extended(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const VehiculeFormPage()),
                );
                if (result == true) setState(() {});
              },
              label: const Text("Ajouter"),
              icon: const Icon(Icons.add),
              backgroundColor: Colors.blue[800],
            ),
    );
  }
}

