import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (username.isEmpty || email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Todos los campos son requeridos');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      await _authService.register(username, email, password);
      if (mounted) {
        setState(() {
          _successMessage = 'Superviviente registrado. Iniciando sesión...';
        });
        await Future.delayed(const Duration(seconds: 1));
        // Auto-login tras registro
        await _authService.login(username, password);
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/home');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0000),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFCC0000)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          '[ NUEVO SUPERVIVIENTE ]',
          style: TextStyle(
            color: Color(0xFFCC0000),
            fontFamily: 'monospace',
            fontWeight: FontWeight.bold,
            fontSize: 14,
            letterSpacing: 2,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFF3A0000)),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 32),
            const Text(
              'REGISTRO DE SUPERVIVIENTE',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF555555),
                fontFamily: 'monospace',
                fontSize: 11,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 32),
            _buildField(
              controller: _usernameController,
              hint: 'NOMBRE DE SUPERVIVIENTE',
              icon: Icons.person_outline,
            ),
            const SizedBox(height: 16),
            _buildField(
              controller: _emailController,
              hint: 'CORREO DE CONTACTO',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            _buildField(
              controller: _passwordController,
              hint: 'CLAVE DE ACCESO',
              icon: Icons.lock_outline,
              obscure: true,
            ),
            const SizedBox(height: 24),
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A0000),
                  border: Border.all(color: const Color(0xFFCC0000)),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '[ ERROR ] $_errorMessage',
                  style: const TextStyle(
                    color: Color(0xFFCC0000),
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (_successMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF002A00),
                  border: Border.all(color: Colors.green),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '[ OK ] $_successMessage',
                  style: const TextStyle(
                    color: Colors.green,
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            ElevatedButton(
              onPressed: _isLoading ? null : _handleRegister,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFCC0000),
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFF660000),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'UNIRSE A LA RED',
                      style: TextStyle(
                        letterSpacing: 2,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                '¿Ya tienes cuenta? INICIAR SESIÓN',
                style: TextStyle(
                  color: Color(0xFF666666),
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white, fontFamily: 'monospace'),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          color: Color(0xFF555555),
          fontFamily: 'monospace',
          fontSize: 13,
        ),
        prefixIcon: Icon(icon, color: const Color(0xFFCC0000), size: 20),
        filled: true,
        fillColor: const Color(0xFF1A0000),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: Color(0xFF3A0000)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: Color(0xFF3A0000)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: Color(0xFFCC0000)),
        ),
      ),
      enabled: !_isLoading,
    );
  }
}