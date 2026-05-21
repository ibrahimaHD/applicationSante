import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';
import '../../models/user_model.dart';
import '../../widgets/app_widgets.dart';

class ProfilMedicalScreen extends StatefulWidget {
  final UserModel user;
  const ProfilMedicalScreen({super.key, required this.user});

  @override
  State<ProfilMedicalScreen> createState() => _ProfilMedicalScreenState();
}

class _ProfilMedicalScreenState extends State<ProfilMedicalScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isEditing = false;
  bool _isSaving = false;

  String? _groupeSanguin;
  String? _sexe;
  final _dateNaissanceController = TextEditingController();
  final _tailleController = TextEditingController();
  final _poidsController = TextEditingController();
  final _allergiesController = TextEditingController();
  final _antecedentsController = TextEditingController();
  final _medicamentsController = TextEditingController();
  final _medecinController = TextEditingController();

  final List<String> _groupesSanguins = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];
  final List<String> _sexes = ['Masculin', 'Féminin', 'Autre'];

  @override
  void dispose() {
    _dateNaissanceController.dispose();
    _tailleController.dispose();
    _poidsController.dispose();
    _allergiesController.dispose();
    _antecedentsController.dispose();
    _medicamentsController.dispose();
    _medecinController.dispose();
    super.dispose();
  }

  Future<void> _sauvegarder() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    await Future.delayed(const Duration(seconds: 1));
    setState(() { _isSaving = false; _isEditing = false; });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Profil médical sauvegardé !'),
        backgroundColor: AppColors.success,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: const Color(0xFF00897B),
        title: const Text('Profil médical',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.close : Icons.edit_outlined, color: Colors.white),
            onPressed: () => setState(() => _isEditing = !_isEditing),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Résumé groupe sanguin
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00897B), Color(0xFF00ACC1)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _statItem('Groupe sanguin', _groupeSanguin ?? '--', Icons.bloodtype_outlined),
                    _statItem('Taille', _tailleController.text.isEmpty ? '--' : '${_tailleController.text} cm', Icons.height),
                    _statItem('Poids', _poidsController.text.isEmpty ? '--' : '${_poidsController.text} kg', Icons.monitor_weight_outlined),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Informations de base
              _buildCard('Informations de base', Icons.person_outline, const Color(0xFF00897B), [
                _buildDropdown('Sexe', _sexes, _sexe, (v) => setState(() => _sexe = v)),
                const SizedBox(height: 14),
                AppTextField(
                  label: 'Date de naissance',
                  hint: 'JJ/MM/AAAA',
                  prefixIcon: Icons.calendar_today_outlined,
                  controller: _dateNaissanceController,
                ),
                const SizedBox(height: 14),
                _buildDropdown('Groupe sanguin', _groupesSanguins, _groupeSanguin,
                    (v) => setState(() => _groupeSanguin = v)),
                const SizedBox(height: 14),
                Row(children: [
                  Expanded(child: AppTextField(
                    label: 'Taille (cm)',
                    hint: 'Ex: 175',
                    prefixIcon: Icons.height,
                    controller: _tailleController,
                    keyboardType: TextInputType.number,
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: AppTextField(
                    label: 'Poids (kg)',
                    hint: 'Ex: 70',
                    prefixIcon: Icons.monitor_weight_outlined,
                    controller: _poidsController,
                    keyboardType: TextInputType.number,
                  )),
                ]),
              ]),

              const SizedBox(height: 16),

              // Antécédents
              _buildCard('Antécédents médicaux', Icons.history_outlined, const Color(0xFF1E88E5), [
                AppTextField(
                  label: 'Antécédents',
                  hint: 'Ex: Diabète, hypertension...',
                  prefixIcon: Icons.medical_information_outlined,
                  controller: _antecedentsController,
                  maxLines: 3,
                ),
              ]),

              const SizedBox(height: 16),

              // Allergies
              _buildCard('Allergies', Icons.warning_amber_outlined, const Color(0xFFF4511E), [
                AppTextField(
                  label: 'Allergies connues',
                  hint: 'Ex: Pénicilline, arachides...',
                  prefixIcon: Icons.warning_amber_outlined,
                  controller: _allergiesController,
                  maxLines: 3,
                ),
              ]),

              const SizedBox(height: 16),

              // Médicaments
              _buildCard('Traitements en cours', Icons.medication_outlined, const Color(0xFF8E24AA), [
                AppTextField(
                  label: 'Médicaments actuels',
                  hint: 'Ex: Metformine 500mg, Paracétamol...',
                  prefixIcon: Icons.medication_outlined,
                  controller: _medicamentsController,
                  maxLines: 3,
                ),
              ]),

              const SizedBox(height: 16),

              // Médecin traitant
              _buildCard('Médecin traitant', Icons.local_hospital_outlined, const Color(0xFF00897B), [
                AppTextField(
                  label: 'Nom du médecin traitant',
                  hint: 'Dr. Nom Prénom',
                  prefixIcon: Icons.person_outlined,
                  controller: _medecinController,
                ),
              ]),

              if (_isEditing) ...[
                const SizedBox(height: 24),
                AppButton(
                  text: 'Sauvegarder le profil',
                  onPressed: _sauvegarder,
                  isLoading: _isSaving,
                  color: const Color(0xFF00897B),
                  icon: Icons.save_outlined,
                ),
              ],

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statItem(String label, String value, IconData icon) {
    return Column(children: [
      Icon(icon, color: Colors.white70, size: 20),
      const SizedBox(height: 4),
      Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
      Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
    ]);
  }

  Widget _buildCard(String title, IconData icon, Color color, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          ]),
          const SizedBox(height: 16),
          if (!_isEditing)
            ...children.map((w) => IgnorePointer(child: w))
          else
            ...children,
        ],
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> items, String? value, ValueChanged<String?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.label),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: value,
          onChanged: _isEditing ? onChanged : null,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.inputFill,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.divider)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          hint: Text('Sélectionner', style: TextStyle(color: AppColors.textSecondary.withOpacity(0.5))),
          items: items.map((i) => DropdownMenuItem(value: i, child: Text(i))).toList(),
        ),
      ],
    );
  }
}
