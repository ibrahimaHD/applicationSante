import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../constants/app_constants.dart';
import '../../widgets/app_widgets.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  bool _isLoading = false;
  bool _emailEnvoye = false;
  String? _resetUrl;
  bool _emailReellementEnvoye = true;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleForgotPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // ✅ CORRECTION : body JSON avec l'email envoyé correctement
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/auth/mot-de-passe-oublie'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': _emailController.text.trim()}),
      );
      final data = jsonDecode(response.body);

      if (!mounted) return;

      if (data['succes'] == true) {
        setState(() {
          _emailEnvoye = true;
          _resetUrl = data['reset_url'];
          _emailReellementEnvoye = data['email_envoye'] != false;
        });
      } else {
        _showError(data['message'] ?? 'Une erreur est survenue');
      }
    } catch (e) {
      if (mounted) _showError('Serveur inaccessible.');
    }

    setState(() => _isLoading = false);
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
            children: [
              const SizedBox(height: 20),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.accent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Icon(
                  _emailEnvoye
                      ? Icons.mark_email_read_outlined
                      : Icons.lock_reset,
                  color: Colors.white,
                  size: 40,
                ),
              ),
              const SizedBox(height: 24),
              _emailEnvoye ? _buildSuccessState() : _buildFormState(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormState() {
    return Container(
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
            const Text('Mot de passe oublié', style: AppTextStyles.heading2),
            const SizedBox(height: 8),
            Text(
              'Entrez votre adresse email et nous vous enverrons un lien pour réinitialiser votre mot de passe.',
              style: AppTextStyles.body.copyWith(fontSize: 13),
            ),
            const SizedBox(height: 24),
            AppTextField(
              label: 'Adresse email',
              hint: 'exemple@email.com',
              prefixIcon: Icons.email_outlined,
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Email requis';
                if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,}$').hasMatch(v)) {
                  return 'Email invalide';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            AppButton(
              text: 'Envoyer le lien',
              onPressed: _handleForgotPassword,
              isLoading: _isLoading,
              icon: Icons.send_outlined,
            ),
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Retour à la connexion',
                  style: TextStyle(color: AppColors.primary, fontSize: 13),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessState() {
    return Container(
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
      child: Column(
        children: [
          const Icon(Icons.check_circle_outline,
              color: AppColors.success, size: 64),
          const SizedBox(height: 16),
          Text(_emailReellementEnvoye ? 'Email envoyé !' : 'Lien généré',
              style: AppTextStyles.heading2),
          const SizedBox(height: 12),
          Text(
            _emailReellementEnvoye
                ? 'Un lien de réinitialisation a été envoyé à\n${_emailController.text.trim()}\n\nVérifiez votre boîte email (et vos spams).'
                : 'Le serveur email n’est pas configuré. Utilisez le lien ci-dessous pour tester la réinitialisation.',
            textAlign: TextAlign.center,
            style: AppTextStyles.body.copyWith(fontSize: 14),
          ),
          if (_resetUrl != null) ...[
            const SizedBox(height: 16),
            SelectableText(
              _resetUrl!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 24),
          AppButton(
            text: 'Retour à la connexion',
            onPressed: () => Navigator.pop(context),
            icon: Icons.login_rounded,
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => setState(() => _emailEnvoye = false),
            child: const Text(
              'Renvoyer l\'email',
              style: TextStyle(color: AppColors.primary, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
