import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';
import '../models/pokemon.dart';
import '../config.dart';
import 'pokemon_card.dart';

class FavoritesModal extends StatefulWidget {
  const FavoritesModal({super.key});

  @override
  State<FavoritesModal> createState() => _FavoritesModalState();
}

class _FavoritesModalState extends State<FavoritesModal> {
  late Future<List<Pokemon>> _favorites;

  @override
  void initState() {
    super.initState();
    _favorites = fetchFavorites();
  }

  Future<List<Pokemon>> fetchFavorites() async {
    final token = await AuthService.getToken();

    if (token == null) {
      throw Exception("Token no disponible");
    }

    final response = await http.get(
      Uri.parse('${AppConfig.baseUrl}/favoritos/favs'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Pokemon.fromJson(json)).toList();
    } else if (response.statusCode == 401) {
      throw Exception("Token inválido o expirado");
    } else {
      throw Exception('Error ${response.statusCode}: ${response.reasonPhrase}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Tus Pokémon Favoritos',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  )
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: FutureBuilder<List<Pokemon>>(
                future: _favorites,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'Error: ${snapshot.error}',
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    );
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
                            style: TextStyle(fontSize: 18, color: Colors.grey),
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
            ),
          ],
        ),
      ),
    );
  }
}
