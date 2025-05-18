import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';
import '../widgets/pokemon_card.dart';
import '../models/pokemon.dart';
import '../config.dart';


class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  late Future<List<Pokemon>> _favorites;

  Future<List<Pokemon>> fetchFavorites() async {
    print('🚀 fetchFavorites() fue llamado');
    final token = await AuthService.getToken();
    print(token);

    if (token == null) {
      // Token ausente → sesión inválida
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sesión expirada. Inicia sesión nuevamente.'),
            backgroundColor: Colors.orange,
          ),
        );
        Navigator.pushReplacementNamed(context, '/'); // Regresa al login
      });
      return []; // Devuelve lista vacía para que el Future no quede colgado
    }

    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/favoritos/favs'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      print(response);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Pokemon.fromJson(json)).toList();
      } else if (response.statusCode == 401) {
        // Token inválido o expirado
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Token inválido. Por favor inicia sesión de nuevo.'),
              backgroundColor: Colors.red,
            ),
          );
          Navigator.pushReplacementNamed(context, '/');
        });
        return [];
      } else {
        throw Exception('Error ${response.statusCode}: ${response.reasonPhrase}');
      }
    } catch (e) {
        print('❌ ERROR en fetchFavorites: $e');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
            content: Text('Error al cargar favoritos: $e'),
            backgroundColor: Colors.red,
            ),
          );
        });
        return [];
  }
  }


  @override
  void initState() {
    super.initState();
    _favorites = fetchFavorites();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis Pokémon Favoritos')),
      body: FutureBuilder<List<Pokemon>>(
        future: _favorites,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final favorites = snapshot.data ?? [];

          if (favorites.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.hourglass_empty, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Aún no tienes favoritos',
                    style: TextStyle(fontSize: 20, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: favorites.length,
            itemBuilder: (context, index) {
              return PokemonCard(pokemon: favorites[index]);
            },
          );
        },
      ),
    );
  }
}
