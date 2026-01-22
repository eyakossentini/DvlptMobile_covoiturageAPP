import 'package:carpooling_app/screens/auth/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:carpooling_app/providers/ride_provider.dart';
import 'package:carpooling_app/providers/auth_provider.dart';

import '../../models/address.dart';
import '../../models/ride_model.dart';
import '../maps/route_map_screen.dart';

class AddRideScreen extends StatefulWidget {
  const AddRideScreen({super.key});

  @override
  State<AddRideScreen> createState() => _AddRideScreenState();
}

class _AddRideScreenState extends State<AddRideScreen> {
  final _formKey = GlobalKey<FormState>();

  final _dateController = TextEditingController();
  final _priceController = TextEditingController();
  final _seatsController = TextEditingController();

  Address? fromAddress;
  Address? toAddress;

  bool _isLoading = false;

  Future<void> _pickFrom() async {
    final result = await Navigator.push<Address>(
      context,
      MaterialPageRoute(builder: (_) => const RouteMapScreen()),
    );

    if (!mounted) return;
    if (result != null) setState(() => fromAddress = result);
  }

  Future<void> _pickTo() async {
    final result = await Navigator.push<Address>(
      context,
      MaterialPageRoute(builder: (_) => const RouteMapScreen()),
    );

    if (!mounted) return;
    if (result != null) {
      setState(() => toAddress = result);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    // validation map selection
    if (fromAddress == null || toAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Veuillez choisir le départ et l\'arrivée sur la carte',
          ),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = Provider.of<AuthProvider>(context, listen: false).user;
      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }

      // Clean input
      final priceText = _priceController.text.replaceAll(
        RegExp(r'[^0-9.]'),
        '',
      );

      if (priceText.isEmpty) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Prix invalide')));
        return;
      }

      final seats = int.tryParse(_seatsController.text);
      if (seats == null || seats <= 0) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nombre de places invalide')),
        );
        return;
      }

      final newRide = Ride(
        driverId: user.id!,
        from: fromAddress!,
        to: toAddress!,
        date: _dateController.text,
        price: double.parse(priceText),
        seats: seats,
      );

      final success = await Provider.of<RideProvider>(
        context,
        listen: false,
      ).addRide(newRide);

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Trajet ajouté !')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur : impossible d\'ajouter le trajet'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur : $e')));
    }
  }

  @override
  void dispose() {
    _dateController.dispose();
    _priceController.dispose();
    _seatsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Proposer un trajet'),
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // FROM (Maps)
              ListTile(
                title: Text(
                  fromAddress?.label ?? 'Choisir le départ sur la carte',
                ),
                subtitle: fromAddress == null
                    ? null
                    : Text(
                        'Lat: ${fromAddress!.lat.toStringAsFixed(6)} | Lng: ${fromAddress!.lng.toStringAsFixed(6)}',
                      ),
                trailing: const Icon(Icons.map),
                onTap: _pickFrom,
              ),

              // TO (Maps)
              ListTile(
                title: Text(
                  toAddress?.label ?? 'Choisir l\'arrivée sur la carte',
                ),
                subtitle: toAddress == null
                    ? null
                    : Text(
                        'Lat: ${toAddress!.lat.toStringAsFixed(6)} | Lng: ${toAddress!.lng.toStringAsFixed(6)}',
                      ),
                trailing: const Icon(Icons.map),
                onTap: _pickTo,
              ),

              const SizedBox(height: 12),

              TextFormField(
                controller: _dateController,
                decoration: const InputDecoration(
                  labelText: 'Date (ex: 20/01/2026)',
                ),
                validator: (v) => (v == null || v.isEmpty) ? 'Requis' : null,
              ),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'Prix (TND)'),
                keyboardType: TextInputType.number,
                validator: (v) => (v == null || v.isEmpty) ? 'Requis' : null,
              ),
              TextFormField(
                controller: _seatsController,
                decoration: const InputDecoration(
                  labelText: 'Nombre de places',
                ),
                keyboardType: TextInputType.number,
                validator: (v) => (v == null || v.isEmpty) ? 'Requis' : null,
              ),

              const SizedBox(height: 20),

              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _submit,
                      child: const Text('Publier le trajet'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
