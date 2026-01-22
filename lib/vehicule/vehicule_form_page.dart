import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:carpooling_app/vehicule/vehicule_repository.dart';
import 'package:carpooling_app/models/vehicule.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';


class VehiculeFormPage extends StatefulWidget {
  final Vehicule? vehicule; // Si null → ajout, sinon édition

  const VehiculeFormPage({super.key, this.vehicule});

  @override
  State<VehiculeFormPage> createState() => _VehiculeFormPageState();
}

class _VehiculeFormPageState extends State<VehiculeFormPage> {
  final VehiculeRepository repo = VehiculeRepository();
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController marqueController = TextEditingController();
  final TextEditingController modeleController = TextEditingController();
  final TextEditingController immatriculationController = TextEditingController();
  final TextEditingController placesController = TextEditingController();

  String type = 'taxi';
  int? editingId;
  String? photoPath;        // pour mobile (chemin fichier)
Uint8List? photoBytes;    // pour web (contenu image)

  final ImagePicker picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (widget.vehicule != null) {
      final v = widget.vehicule!;
      editingId = v.id;
      type = v.type;
      marqueController.text = v.marque;
      modeleController.text = v.modele;
      immatriculationController.text = v.immatriculation;
      placesController.text = v.places.toString();

    // Set photo depending on platform
    if (kIsWeb) {
      photoBytes = v.photoBytes;
      photoPath = null; // not used on web
    } else {
      photoPath = v.photoPath;
      photoBytes = null; // not used on mobile
    }

  } else {
    placesController.text = '4'; // default
  }


  }

  // Sélectionner une image depuis la galerie
 Future<void> pickImage() async {
  final XFile? image = await picker.pickImage(source: ImageSource.gallery);
  if (image != null) {
    if (kIsWeb) {
      // Lire les bytes de l'image pour web
      final bytes = await image.readAsBytes();
      setState(() {
        photoBytes = bytes;
        photoPath = null;  // pas utilisé sur web
      });
    } else {
      // Sur mobile on garde juste le chemin
      setState(() {
        photoPath = image.path;
        photoBytes = null;
      });
    }
  }
}


void submitForm() async {
  if (_formKey.currentState!.validate()) {
    final vehicule = Vehicule(
      id: editingId ?? 0,
      type: type,
      marque: marqueController.text,
      modele: modeleController.text,
      immatriculation: immatriculationController.text,
      places: int.tryParse(placesController.text) ?? 4,
      photoBytes: photoBytes,
    );

    final bool isEdit = editingId != null;

    if (isEdit) {
      await repo.updateVehicule(editingId!, vehicule);
    } else {
      await repo.addVehicule(vehicule);
    }

    // MESSAGE DE SUCCÈS
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isEdit
              ? 'Véhicule modifié avec succès '
              : 'Véhicule ajouté avec succès ',
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );

    //  Petite pause pour laisser le message s’afficher
    await Future.delayed(const Duration(milliseconds: 600));

    // Retour à la page précédente
    Navigator.pop(context, true);
  }
}


 @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(editingId == null ? 'Ajouter Véhicule' : 'Modifier Véhicule'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            shrinkWrap: true,
            children: [
              // Bouton pour ajouter/modifier la photo au-dessus de la carte
              ElevatedButton.icon(
                onPressed: pickImage,
                icon: const Icon(Icons.camera_alt),
                label: const Text('Choisir une photo'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
              const SizedBox(height: 20),

              // LA CARTE QUI CONTIENT L'IMAGE ET LES DONNÉES
              Card(
                elevation: 6, // Donne un effet d'ombre
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16), // Bords arrondis
                ),
                child: Column(
                  children: [
                    // --- SECTION IMAGE (En-tête de la carte) ---
                    if (kIsWeb && photoBytes != null)
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                        child: Image.memory(
                          photoBytes!,
                          height: 250, // Hauteur réduite
                          width: double.infinity,
                          fit: BoxFit.contain, // L'image est entière et visible
                        ),
                      )
                    else if (!kIsWeb && photoPath != null)
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                        child: Image.file(
                          File(photoPath!),
                          height: 250, // Hauteur réduite
                          width: double.infinity,
                          fit: BoxFit.contain, // L'image est entière et visible
                        ),
                      )
                    else
                      // Placeholder si aucune image n'est choisie
                      Container(
                        height: 150,
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          color: Color(0xFFE0E0E0),
                          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                        ),
                        child: const Icon(Icons.directions_car, size: 60, color: Colors.grey),
                      ),

                    // --- SECTION FORMULAIRE (Corps de la carte) ---
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          DropdownButtonFormField<String>(
                            initialValue: type,
                            decoration: const InputDecoration(
                              labelText: 'Type de véhicule',
                              prefixIcon: Icon(Icons.category),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'taxi', child: Text('Taxi')),
                              DropdownMenuItem(value: 'personnelle', child: Text('Voiture personnelle')),
                            ],
                            onChanged: (v) => setState(() => type = v!),
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: marqueController,
                            decoration: const InputDecoration(
                              labelText: 'Marque',
                              prefixIcon: Icon(Icons.branding_watermark),
                            ),
                            validator: (v) => v!.isEmpty ? 'Champ requis' : null,
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: modeleController,
                            decoration: const InputDecoration(
                              labelText: 'Modèle',
                              prefixIcon: Icon(Icons.drive_eta),
                            ),
                            validator: (v) => v!.isEmpty ? 'Champ requis' : null,
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: immatriculationController,
                            decoration: const InputDecoration(
                              labelText: 'Immatriculation',
                              prefixIcon: Icon(Icons.pin),
                            ),
                            validator: (v) => v!.isEmpty ? 'Champ requis' : null,
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: placesController,
                            decoration: const InputDecoration(
                              labelText: 'Nombre de places',
                              prefixIcon: Icon(Icons.group),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (v) => v!.isEmpty ? 'Champ requis' : null,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // BOUTON DE SOUMISSION EN BAS
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(
                    editingId == null ? 'Ajouter le véhicule' : 'Enregistrer les modifications',
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

}
