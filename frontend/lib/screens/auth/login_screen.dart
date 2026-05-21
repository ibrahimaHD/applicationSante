import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';
import '../../services/auth_service.dart';
import '../../widgets/app_widgets.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';
import '../role_redirect.dart';
 
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
 
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}
 
class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
 
  bool _isLoading = false;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
 
  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }
 
  @override
  void dispose() {
    _animController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
 
  // ── Même validation que register ──────────────────────────────────────────
  String? _validateEmail(String? v) {
    if (v == null || v.isEmpty) return 'Email requis';
    if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,}$').hasMatch(v))
      return 'Email invalide (ex: nom@domaine.com)';
    return null;
  }
 
  String? _validatePassword(String? v) {
    if (v == null || v.isEmpty) return 'Mot de passe requis';
    if (v.length < 8) return 'Minimum 8 caractères';
    if (!RegExp(r'[A-Z]').hasMatch(v)) return 'Au moins une majuscule (A-Z)';
    if (!RegExp(r'[0-9]').hasMatch(v)) return 'Au moins un chiffre (0-9)';
    if (!RegExp(r'[!@#\$&*~%^()_\-+=\[\]{};:,.<>?/\\|]').hasMatch(v))
      return 'Au moins un caractère spécial (!@#\$...)';
    return null;
  }
 
  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
 
    setState(() => _isLoading = true);
 
    final result = await _authService.login(
      _emailController.text.trim(),
      _passwordController.text,
    );
 
    setState(() => _isLoading = false);
 
    if (!mounted) return;
 
    if (result.success && result.user != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => RoleRedirectScreen(user: result.user!),
        ),
      );
    } else {
      _showError(result.message ?? 'Erreur de connexion');
    }
  }
 
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.error_outline, color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(message)),
      ]),
      backgroundColor: AppColors.error,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(16),
    ));
  }
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 48),
 
                  // ── Logo ───────────────────────────────────────────────
                  Center(
                    child: Column(children: [
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
                        child: const Icon(Icons.health_and_safety_outlined,
                            color: Colors.white, size: 42),
                      ),
                      const SizedBox(height: 20),
                      const Text('LaafiBa', style: AppTextStyles.heading1),
                      const SizedBox(height: 6),
                      Text('Votre santé, notre priorité',
                          style: AppTextStyles.body.copyWith(fontSize: 14)),
                    ]),
                  ),
 
                  const SizedBox(height: 44),
 
                  // ── Formulaire ─────────────────────────────────────────
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
                          const Text('Connexion', style: AppTextStyles.heading2),
                          const SizedBox(height: 4),
                          Text('Connectez-vous à votre compte',
                              style: AppTextStyles.body.copyWith(fontSize: 13)),
                          const SizedBox(height: 24),
 
                          // Email
                          AppTextField(
                            label: 'Adresse email',
                            hint: 'exemple@email.com',
                            prefixIcon: Icons.email_outlined,
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            validator: _validateEmail,
                          ),
 
                          const SizedBox(height: 16),
 
                          // Mot de passe
                          AppTextField(
                            label: 'Mot de passe',
                            hint: '••••••••',
                            prefixIcon: Icons.lock_outlined,
                            controller: _passwordController,
                            isPassword: true,
                            validator: _validatePassword,
                          ),
 
                          // Indicateur règles en temps réel
                          const SizedBox(height: 8),
                          StatefulBuilder(
                            builder: (context, setStateLocal) {
                              _passwordController.addListener(
                                  () => setStateLocal(() {}));
                              return _PasswordRules(
                                  password: _passwordController.text);
                            },
                          ),
 
                          const SizedBox(height: 8),
 
                          // Mot de passe oublié
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const ForgotPasswordScreen()),
                              ),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                foregroundColor: AppColors.primary,
                              ),
                              child: const Text('Mot de passe oublié ?',
                                  style: TextStyle(fontSize: 13)),
                            ),
                          ),
 
                          const SizedBox(height: 20),
 
                          AppButton(
                            text: 'Se connecter',
                            onPressed: _handleLogin,
                            isLoading: _isLoading,
                            icon: Icons.login_rounded,
                          ),
                        ],
                      ),
                    ),
                  ),
 
                  const SizedBox(height: 24),
 
                  // ── Lien inscription ───────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Pas encore de compte ? ",
                          style: AppTextStyles.body.copyWith(fontSize: 14)),
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const RegisterScreen()),
                        ),
                        child: const Text("S'inscrire",
                            style: TextStyle(
                                fontSize: 14,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
 
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
 
// ── Indicateur règles mot de passe ─────────────────────────────────────────
class _PasswordRules extends StatelessWidget {
  final String password;
  const _PasswordRules({required this.password});
 
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _rule('8 caractères minimum', password.length >= 8),
        _rule('Une majuscule (A-Z)', RegExp(r'[A-Z]').hasMatch(password)),
        _rule('Un chiffre (0-9)', RegExp(r'[0-9]').hasMatch(password)),
        _rule('Un caractère spécial (!@#\$...)',
            RegExp(r'[!@#\$&*~%^()_\-+=\[\]{};:,.<>?/\\|]').hasMatch(password)),
      ],
    );
  }
 
  Widget _rule(String label, bool valid) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(children: [
        Icon(
          valid ? Icons.check_circle : Icons.radio_button_unchecked,
          size: 14,
          color: valid ? AppColors.success : AppColors.textSecondary,
        ),
        const SizedBox(width: 6),
        Text(label,
            style: TextStyle(
                fontSize: 12,
                color: valid ? AppColors.success : AppColors.textSecondary)),
      ]),
    );
  }
}
 