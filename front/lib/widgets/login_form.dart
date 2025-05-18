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
        children: [
          Text('Iniciar sesión', style: Theme.of(context).textTheme.headlineSmall),
          SizedBox(height: 20),
          TextFormField(
            decoration: InputDecoration(labelText: 'Usuario'),
            onChanged: (value) => _username = value,
            validator: (value) => value!.isEmpty ? 'Ingresa tu usuario' : null,
          ),
          SizedBox(height: 12),
          TextFormField(
            decoration: InputDecoration(labelText: 'Contraseña'),
            obscureText: true,
            onChanged: (value) => _password = value,
            validator: (value) => value!.isEmpty ? 'Ingresa tu contraseña' : null,
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: _loading ? null : _submit,
            child: Text(_loading ? 'Cargando...' : 'Entrar'),
          ),
          SizedBox(height: 12),
          TextButton(
            onPressed: () {
              Navigator.pushNamed(context, '/register');
            },
            child: Text('¿No tienes cuenta? Regístrate'),
          ),
        ],
      ),
    );
  }
}
