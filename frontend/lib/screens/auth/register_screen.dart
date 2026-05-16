import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';
import '../../services/auth_service.dart';
import '../../widgets/app_widgets.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();

  // Contrôleurs communs
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Contrôleurs spécifiques aux rôles
  final _specialiteController = TextEditingController();
  final _licenceController = TextEditingController();
  final _pharmacieController = TextEditingController();
  final _zoneController = TextEditingController();

  String? _selectedRole;
  String? _selectedVehicle;
  bool _isLoading = false;
  int _currentStep = 0;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  final List<String> _registerableRoles = [
    UserRole.patient,
    UserRole.medecin,
    UserRole.pharmacien,
    UserRole.livreur,
  ];

  final List<String> _vehicleTypes = [
    'Moto',
    'Vélo',
    'Voiture',
    'À pied',
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _nomController.dispose();
    _prenomController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _specialiteController.dispose();
    _licenceController.dispose();
    _pharmacieController.dispose();
    _zoneController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final Map<String, dynamic> userData = {
      'nom': _nomController.text.trim(),
      'prenom': _prenomController.text.trim(),
      'email': _emailController.text.trim(),
      'telephone': _phoneController.text.trim(),
      'password': _passwordController.text,
      'role': _selectedRole,
    };

    // Champs spécifiques selon le rôle
    if (_selectedRole == UserRole.medecin) {
      userData['specialite'] = _specialiteController.text.trim();
      userData['numero_licence'] = _licenceController.text.trim();
    } else if (_selectedRole == UserRole.pharmacien) {
      userData['nom_pharmacie'] = _pharmacieController.text.trim();
      userData['numero_licence'] = _licenceController.text.trim();
    } else if (_selectedRole == UserRole.livreur) {
      userData['vehicle_type'] = _selectedVehicle;
      userData['zone'] = _zoneController.text.trim();
    }

    final result = await _authService.register(userData);
    setState(() => _isLoading = false);

    if (!mounted) return;

    if (result.success) {
      _showSuccess(result.message ?? 'Compte créé ! Vous pouvez vous connecter.');
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) Navigator.pop(context);
      });
    } else {
      _showError(result.message ?? 'Erreur lors de la création du compte');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          const Icon(Icons.error_outline, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(message)),
        ]),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(message)),
        ]),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ─── Champs spécifiques au rôle ─────────────────────────────────────────
  Widget _buildRoleSpecificFields() {
    if (_selectedRole == null) return const SizedBox.shrink();

    switch (_selectedRole) {
      case UserRole.medecin:
        return Column(children: [
          const SizedBox(height: 16),
          _buildSectionHeader('Informations médicales', Icons.local_hospital_outlined),
          const SizedBox(height: 14),
          AppTextField(
            label: 'Spécialité',
            hint: 'Ex: Cardiologie, Pédiatrie...',
            prefixIcon: Icons.medical_services_outlined,
            controller: _specialiteController,
            validator: (v) =>
                v == null || v.isEmpty ? 'Spécialité requise' : null,
          ),
          const SizedBox(height: 14),
          AppTextField(
            label: "Numéro de licence médicale",
            hint: 'N° CNOM / Ordre des médecins',
            prefixIcon: Icons.badge_outlined,
            controller: _licenceController,
            validator: (v) =>
                v == null || v.isEmpty ? 'Numéro de licence requis' : null,
          ),
        ]);

      case UserRole.pharmacien:
        return Column(children: [
          const SizedBox(height: 16),
          _buildSectionHeader('Informations pharmacie', Icons.medication_outlined),
          const SizedBox(height: 14),
          AppTextField(
            label: 'Nom de la pharmacie',
            hint: 'Ex: Pharmacie Centrale...',
            prefixIcon: Icons.store_outlined,
            controller: _pharmacieController,
            validator: (v) =>
                v == null || v.isEmpty ? 'Nom de pharmacie requis' : null,
          ),
          const SizedBox(height: 14),
          AppTextField(
            label: 'Numéro de licence',
            hint: 'Numéro autorisation exploitation',
            prefixIcon: Icons.badge_outlined,
            controller: _licenceController,
            validator: (v) =>
                v == null || v.isEmpty ? 'Numéro de licence requis' : null,
          ),
        ]);

      case UserRole.livreur:
        return Column(children: [
          const SizedBox(height: 16),
          _buildSectionHeader('Informations livraison', Icons.delivery_dining_outlined),
          const SizedBox(height: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Type de véhicule', style: AppTextStyles.label),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _selectedVehicle,
                onChanged: (v) => setState(() => _selectedVehicle = v),
                validator: (v) =>
                    v == null ? 'Veuillez sélectionner un véhicule' : null,
                decoration: InputDecoration(
                  prefixIcon: const Icon(
                    Icons.two_wheeler_outlined,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  filled: true,
                  fillColor: AppColors.inputFill,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppColors.divider, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                ),
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
                dropdownColor: Colors.white,
                borderRadius: BorderRadius.circular(12),
                items: _vehicleTypes.map((v) {
                  return DropdownMenuItem(value: v, child: Text(v));
                }).toList(),
              ),
            ],
          ),
          const SizedBox(height: 14),
          AppTextField(
            label: 'Zone de livraison',
            hint: 'Ex: Centre-ville, Secteur 1...',
            prefixIcon: Icons.map_outlined,
            controller: _zoneController,
            validator: (v) =>
                v == null || v.isEmpty ? 'Zone requise' : null,
          ),
        ]);

      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withOpacity(0.4),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.primaryDark),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryDark,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── En-tête ──────────────────────────────────────────────
              const Text("Créer un compte", style: AppTextStyles.heading1),
              const SizedBox(height: 4),
              Text(
                "Remplissez les informations ci-dessous",
                style: AppTextStyles.body.copyWith(fontSize: 13),
              ),

              const SizedBox(height: 24),

              // ── Formulaire ───────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.08),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Infos personnelles ──────────────────────────
                      _buildSectionHeader(
                          'Informations personnelles', Icons.person_outline),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: AppTextField(
                              label: 'Prénom',
                              hint: 'Votre prénom',
                              prefixIcon: Icons.person_outline,
                              controller: _prenomController,
                              validator: (v) => v == null || v.isEmpty
                                  ? 'Requis'
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: AppTextField(
                              label: 'Nom',
                              hint: 'Votre nom',
                              prefixIcon: Icons.person_outline,
                              controller: _nomController,
                              validator: (v) => v == null || v.isEmpty
                                  ? 'Requis'
                                  : null,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      AppTextField(
                        label: 'Email',
                        hint: 'exemple@email.com',
                        prefixIcon: Icons.email_outlined,
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Email requis';
                          if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,}$')
                              .hasMatch(v))
                            return 'Email invalide';
                          return null;
                        },
                      ),

                      const SizedBox(height: 14),

                      AppTextField(
                        label: 'Téléphone',
                        hint: '+226 XX XX XX XX',
                        prefixIcon: Icons.phone_outlined,
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Téléphone requis' : null,
                      ),

                      const SizedBox(height: 16),

                      // ── Sélection du rôle ───────────────────────────
                      _buildSectionHeader('Type de compte', Icons.badge_outlined),
                      const SizedBox(height: 14),

                      RoleDropdown(
                        value: _selectedRole,
                        roles: _registerableRoles,
                        onChanged: (v) => setState(() => _selectedRole = v),
                      ),

                      // ── Champs dynamiques selon le rôle ────────────
                      _buildRoleSpecificFields(),

                      const SizedBox(height: 16),

                      // ── Mot de passe ────────────────────────────────
                      _buildSectionHeader(
                          'Sécurité', Icons.lock_outline_rounded),
                      const SizedBox(height: 14),

                      AppTextField(
                        label: 'Mot de passe',
                        hint: 'Minimum 6 caractères',
                        prefixIcon: Icons.lock_outlined,
                        controller: _passwordController,
                        isPassword: true,
                        validator: (v) {
                          if (v == null || v.isEmpty)
                            return 'Mot de passe requis';
                          if (v.length < 6) return 'Minimum 6 caractères';
                          return null;
                        },
                      ),

                      const SizedBox(height: 14),

                      AppTextField(
                        label: 'Confirmer le mot de passe',
                        hint: 'Répétez le mot de passe',
                        prefixIcon: Icons.lock_outlined,
                        controller: _confirmPasswordController,
                        isPassword: true,
                        validator: (v) {
                          if (v == null || v.isEmpty)
                            return 'Confirmation requise';
                          if (v != _passwordController.text)
                            return 'Les mots de passe ne correspondent pas';
                          return null;
                        },
                      ),

                      const SizedBox(height: 24),

                      AppButton(
                        text: "Créer mon compte",
                        onPressed: _handleRegister,
                        isLoading: _isLoading,
                        icon: Icons.person_add_outlined,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Déjà un compte ? ",
                    style: AppTextStyles.body.copyWith(fontSize: 14),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Text(
                      "Se connecter",
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
