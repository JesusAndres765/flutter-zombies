import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final user = await _authService.login(
        _usernameController.text.trim(),
        _passwordController.text,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('[ ACCESO CONCEDIDO: ${user.username} ]'),
            backgroundColor: const Color(0xFFCC0000),
          ),
        );
        Navigator.of(context).pushReplacementNamed('/home');
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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 80),
              const Text(
                '☣',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 72,
                  color: Color(0xFFCC0000),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '[ ZOMBIE NETWORK ]',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFCC0000),
                  letterSpacing: 4,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'SISTEMA DE COMUNICACIÓN DE SUPERVIVIENTES',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  color: Color(0xFF666666),
                  letterSpacing: 2,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(height: 48),
              _buildField(
                controller: _usernameController,
                hint: 'IDENTIFICADOR',
                icon: Icons.person_outline,
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
              ElevatedButton(
                onPressed: _isLoading ? null : _handleLogin,
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
                        'INGRESAR AL SISTEMA',
                        style: TextStyle(
                          letterSpacing: 2,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => Navigator.of(context).pushNamed('/register'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFCC0000),
                  side: const BorderSide(color: Color(0xFF3A0000)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                child: const Text(
                  'REGISTRAR NUEVO SUPERVIVIENTE',
                  style: TextStyle(
                    letterSpacing: 1,
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(
        color: Colors.white,
        fontFamily: 'monospace',
      ),
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