import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/auth_result.dart';

class AuthService {
  static const String baseUrl = 'http://localhost:8000/auth';

  /// Registra un usuario y lo autentica automáticamente
  static Future<AuthResult> registerAndLogin(String username, String password, String? email) async {
    try {
      final registerRes = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
          if (email != null) 'email': email,
        }),
      );

      if (registerRes.statusCode == 200 || registerRes.statusCode == 201) {
        // Usuario creado, intentamos loguear
        return await loginUser(username, password);
      }

      // Si hubo un error, analizamos el cuerpo de la respuesta
      final data = jsonDecode(registerRes.body);

      // Errores comunes con campo "detail"
      if (data is Map && data.containsKey('detail')) {
        return AuthResult(success: false, message: data['detail']);
      }

      return AuthResult(success: false, message: 'Error desconocido al registrar');
    } catch (e) {
      return AuthResult(success: false, message: 'Error de red o del servidor');
    }
  }

  /// Login directo con credenciales
  static Future<AuthResult> loginUser(String username, String password) async {
    try {
      final loginRes = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'username': username,
          'password': password,
        },
      );

      if (loginRes.statusCode == 200) {
        final data = jsonDecode(loginRes.body);
        final token = data['access_token'];

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);

        return AuthResult(success: true, message: 'Login exitoso');
      }

      final data = jsonDecode(loginRes.body);
      if (data is Map && data.containsKey('detail')) {
        return AuthResult(success: false, message: data['detail']);
      }

      return AuthResult(success: false, message: 'Credenciales inválidas');
    } catch (e) {
      return AuthResult(success: false, message: 'Error de red o del servidor');
    }
  }

  /// Cierra sesión eliminando el token guardado
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }

  /// Recupera el token JWT actual
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }
}
