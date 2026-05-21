import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';
import '../../models/user_model.dart';
import '../../widgets/app_widgets.dart';

class InformationsPersonnellesScreen extends StatefulWidget {
  final UserModel user;
  const InformationsPersonnellesScreen({super.key, required this.user});

  @override
  State<InformationsPersonnellesScreen> createState() =>
      _InformationsPersonnellesScreenState();
}

class _InformationsPersonnellesScreenState
    extends State<InformationsPersonnellesScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nomController;
  late TextEditingController _prenomController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _adresseController;
  bool _isEditing = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nomController = TextEditingController(text: widget.user.nom);
    _prenomController = TextEditingController(text: widget.user.prenom);
    _emailController = TextEditingController(text: widget.user.email);
    _phoneController = TextEditingController(text: widget.user.telephone);
    _adresseController = TextEditingController();
  }

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _adresseController.dispose();
    super.dispose();
  }

  Future<void> _sauvegarder() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    await Future.delayed(const Duration(seconds: 1));
    setState(() { _isSaving = false; _isEditing = false; });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Informations mises à jour !'),
        backgroundColor: AppColors.success,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E88E5),
        title: const Text('Informations personnelles',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.close : Icons.edit_outlined,
                color: Colors.white),
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
              // Avatar
              Center(
                child: Stack(
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1E88E5), Color(0xFF00ACC1)],
                        ),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Center(
                        child: Text(
                          '${widget.user.prenom[0]}${widget.user.nom[0]}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    if (_isEditing)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt_outlined,
                              size: 16, color: Color(0xFF1E88E5)),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              _buildCard('Identité', Icons.person_outline, [
                Row(children: [
                  Expanded(
                    child: AppTextField(
                      label: 'Prénom',
                      hint: 'Votre prénom',
                      prefixIcon: Icons.person_outline,
                      controller: _prenomController,
                      validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppTextField(
                      label: 'Nom',
                      hint: 'Votre nom',
                      prefixIcon: Icons.person_outline,
                      controller: _nomController,
                      validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
                    ),
                  ),
                ]),
              ]),

              const SizedBox(height: 16),

              _buildCard('Contact', Icons.contact_phone_outlined, [
                AppTextField(
                  label: 'Email',
                  hint: 'exemple@email.com',
                  prefixIcon: Icons.email_outlined,
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
                ),
                const SizedBox(height: 14),
                AppTextField(
                  label: 'Téléphone',
                  hint: '+226 XX XX XX XX',
                  prefixIcon: Icons.phone_outlined,
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
                ),
                const SizedBox(height: 14),
                AppTextField(
                  label: 'Adresse',
                  hint: 'Votre adresse',
                  prefixIcon: Icons.location_on_outlined,
                  controller: _adresseController,
                  maxLines: 2,
                ),
              ]),

              if (_isEditing) ...[
                const SizedBox(height: 24),
                AppButton(
                  text: 'Sauvegarder',
                  onPressed: _sauvegarder,
                  isLoading: _isSaving,
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

  Widget _buildCard(String title, IconData icon, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: const Color(0xFF1E88E5), size: 18),
            const SizedBox(width: 8),
            Text(title,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
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
}
