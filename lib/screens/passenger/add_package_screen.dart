import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/package_provider.dart';
import '../../models/package_model.dart';
import '../../models/address.dart';
import '../maps/route_map_screen.dart';

class AddPackageScreen extends StatefulWidget {
  final Package? packageToEdit;
  const AddPackageScreen({super.key, this.packageToEdit});

  @override
  State<AddPackageScreen> createState() => _AddPackageScreenState();
}

class _AddPackageScreenState extends State<AddPackageScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _weightController = TextEditingController();
  final _dimensionsController = TextEditingController();
  final _pickupLabelController = TextEditingController();
  final _deliveryLabelController = TextEditingController();

  double _pickupLat = 0.0;
  double _pickupLng = 0.0;
  double _deliveryLat = 0.0;
  double _deliveryLng = 0.0;

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.packageToEdit != null) {
      final p = widget.packageToEdit!;
      _descriptionController.text = p.description;
      _weightController.text = p.weight;
      _dimensionsController.text = p.dimensions;
      
      _pickupLabelController.text = p.pickupAddress.label;
      _pickupLat = p.pickupAddress.lat;
      _pickupLng = p.pickupAddress.lng;

      _deliveryLabelController.text = p.deliveryAddress.label;
      _deliveryLat = p.deliveryAddress.lat;
      _deliveryLng = p.deliveryAddress.lng;
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _weightController.dispose();
    _dimensionsController.dispose();
    _pickupLabelController.dispose();
    _deliveryLabelController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final packageProvider = Provider.of<PackageProvider>(context, listen: false);

    final newPackage = Package(
      senderId: authProvider.user!.id!,
      description: _descriptionController.text,
      weight: _weightController.text,
      dimensions: _dimensionsController.text,
      pickupAddress: Address(
        label: _pickupLabelController.text,
        lat: _pickupLat,
        lng: _pickupLng,
      ),
      deliveryAddress: Address(
        label: _deliveryLabelController.text,
        lat: _deliveryLat,
        lng: _deliveryLng,
      ),
      id: widget.packageToEdit?.id,
      createdAt: widget.packageToEdit?.createdAt ?? DateTime.now().toIso8601String(),
      status: widget.packageToEdit?.status ?? 'Pending',
    );

    bool success;
    if (widget.packageToEdit == null) {
      success = await packageProvider.addPackage(newPackage);
    } else {
      success = await packageProvider.updatePackage(newPackage);
    }

    setState(() => _isSubmitting = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.packageToEdit == null 
            ? 'Colis ajouté avec succès !' 
            : 'Colis modifié avec succès !')),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur lors de l’ajout du colis.')),
      );
    }
  }

  Future<void> _selectLocation(bool isPickup) async {
    final result = await Navigator.push<Address>(
      context,
      MaterialPageRoute(builder: (_) => const RouteMapScreen()),
    );

    if (result != null) {
      setState(() {
        if (isPickup) {
          _pickupLabelController.text = result.label;
          _pickupLat = result.lat;
          _pickupLng = result.lng;
        } else {
          _deliveryLabelController.text = result.label;
          _deliveryLat = result.lat;
          _deliveryLng = result.lng;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(

        title: Text(widget.packageToEdit == null ? 'Envoyer un colis' : 'Modifier le colis'),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                "Informations sur le colis",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue.shade800),
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description du colis (ex: Vêtements, Électronique)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.inventory_2),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Champ requis' : null,
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _weightController,
                      decoration: InputDecoration(
                        labelText: 'Poids (ex: 5kg)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.monitor_weight),
                      ),
                      validator: (v) => v == null || v.isEmpty ? 'Champ requis' : null,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: TextFormField(
                      controller: _dimensionsController,
                      decoration: InputDecoration(
                        labelText: 'Dimensions',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.straighten),
                      ),
                      validator: (v) => v == null || v.isEmpty ? 'Champ requis' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              Text(
                "Adresses de livraison",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue.shade800),
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _pickupLabelController,
                decoration: InputDecoration(
                  labelText: 'Adresse de ramassage',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.location_on, color: Colors.green),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.map),
                    onPressed: () => _selectLocation(true),
                  ),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Champ requis' : null,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _deliveryLabelController,
                decoration: InputDecoration(
                  labelText: 'Adresse de destination',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.flag, color: Colors.red),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.map),
                    onPressed: () => _selectLocation(false),
                  ),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Champ requis' : null,
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade800,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(widget.packageToEdit == null ? 'Confirmer l’envoi' : 'Enregistrer les modifications', 
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
