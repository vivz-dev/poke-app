import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';

class LoginForm extends StatefulWidget {
  @override
  _LoginFormState createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  String _username = '';
  String _password = '';
  bool _loading = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    final result = await AuthService.loginUser(_username, _password);

    setState(() => _loading = false);

    if (result.success) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Imagen centrada arriba del título
          Center(
            child: Image.asset(
              'assets/images/pokemon_placeholder.png',
              height: 120,
            ),
          ),
          const SizedBox(height: 24),

          // Título
          Text(
            'Iniciar sesión',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),

          // Campo de usuario
          TextFormField(
            decoration: InputDecoration(labelText: 'Usuario'),
            onChanged: (value) => _username = value,
            validator: (value) => value!.isEmpty ? 'Ingresa tu usuario' : null,
          ),
          const SizedBox(height: 12),

          // Campo de contraseña
          TextFormField(
            decoration: InputDecoration(labelText: 'Contraseña'),
            obscureText: true,
            onChanged: (value) => _password = value,
            validator: (value) => value!.isEmpty ? 'Ingresa tu contraseña' : null,
          ),
          const SizedBox(height: 20),

          // Botón de entrar
          ElevatedButton(
            onPressed: _loading ? null : _submit,
            child: Text(_loading ? 'Cargando...' : 'Entrar'),
          ),
          const SizedBox(height: 12),

          // Link de registro
          TextButton(
            onPressed: () {
              Navigator.pushNamed(context, '/register');
            },
            child: Text(
              '¿No tienes cuenta? Regístrate',
              style: TextStyle(color: Colors.deepPurple),
            ),
          ),
        ],
      ),
    );
  }
}
