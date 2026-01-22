import 'package:carpooling_app/screens/auth/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:carpooling_app/reservation/ride_provider.dart';
import 'package:carpooling_app/providers/auth_provider.dart';

import '../../models/address.dart';
import '../../models/ride_model.dart';
import '../reservation/route_map_screen.dart';

class AddRideScreen extends StatefulWidget {
  const AddRideScreen({super.key});

  @override
  State<AddRideScreen> createState() => _AddRideScreenState();
}

class _AddRideScreenState extends State<AddRideScreen> {
  final _formKey = GlobalKey<FormState>();

  final _dateController = TextEditingController();
  final _timeController = TextEditingController();
  final _durationController = TextEditingController();

  final _priceController = TextEditingController();
  final _seatsController = TextEditingController();

  Address? fromAddress;
  Address? toAddress;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    // ✅ date du jour par défaut
    final now = DateTime.now();
    _dateController.text =
        '${now.day.toString().padLeft(2, '0')}/'
        '${now.month.toString().padLeft(2, '0')}/'
        '${now.year}';

    // ✅ heure actuelle par défaut
    final t = TimeOfDay.now();
    _timeController.text =
        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

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
    if (result != null) setState(() => toAddress = result);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

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

      final durationMin = int.tryParse(_durationController.text) ?? 0;

      final newRide = Ride(
        driverId: user.id!,
        from: fromAddress!,
        to: toAddress!,
        date: _dateController.text,
        time: _timeController.text,
        durationMinutes: durationMin,
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
    _timeController.dispose();
    _durationController.dispose();
    _priceController.dispose();
    _timeController.dispose();
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

              // ✅ Date picker
              TextFormField(
                controller: _dateController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Date du trajet',
                  hintText: 'jj/MM/aaaa',
                  suffixIcon: Icon(Icons.calendar_month),
                ),
                onTap: () async {
                  FocusScope.of(context).unfocus();
                  final now = DateTime.now();
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: now,
                    firstDate: now,
                    lastDate: DateTime(now.year + 2),
                    locale: const Locale('fr', 'FR'),
                  );

                  if (pickedDate != null) {
                    _dateController.text =
                        '${pickedDate.day.toString().padLeft(2, '0')}/'
                        '${pickedDate.month.toString().padLeft(2, '0')}/'
                        '${pickedDate.year}';
                  }
                },
                validator: (v) => (v == null || v.isEmpty) ? 'Requis' : null,
              ),

              // ✅ Time picker
              TextFormField(
                controller: _timeController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Heure du trajet',
                  hintText: 'HH:mm',
                  suffixIcon: Icon(Icons.access_time),
                ),
                onTap: () async {
                  FocusScope.of(context).unfocus();
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  if (picked != null) {
                    _timeController.text =
                        '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                  }
                },
                validator: (v) => (v == null || v.isEmpty) ? 'Requis' : null,
              ),

              // ✅ Duration
              TextFormField(
                controller: _durationController,
                decoration: const InputDecoration(
                  labelText: 'Durée estimée (minutes)',
                  hintText: 'ex: 45',
                ),
                keyboardType: TextInputType.number,
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
