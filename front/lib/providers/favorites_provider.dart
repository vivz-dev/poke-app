import 'package:flutter/material.dart';
import '../models/pokemon.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/auth_service.dart';
import '../config.dart';

class FavoritesProvider extends ChangeNotifier {
  final List<Pokemon> _favorites = [];

  List<Pokemon> get favorites => _favorites;

  /// Llama al backend para cargar los favoritos al iniciar
  Future<void> fetchFavoritesFromBackend() async {
    try {
      final token = await AuthService.getToken();

      if (token == null) throw Exception("Token no disponible");

      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/favoritos/favs'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final favoritos = data.map((json) => Pokemon.fromJson(json)).toList();

        _favorites.clear();
        _favorites.addAll(favoritos);
        notifyListeners();
      } else {
        throw Exception("Error ${response.statusCode}: ${response.reasonPhrase}");
      }
    } catch (e) {
      debugPrint("Error al cargar favoritos: $e");
    }
  }

  void addFavorite(Pokemon pokemon) {
    _favorites.add(pokemon);
    notifyListeners();
  }

  void removeFavorite(int pokemonId) {
    _favorites.removeWhere((p) => p.id == pokemonId);
    notifyListeners();
  }

  bool isFavorite(int pokemonId) {
    return _favorites.any((p) => p.id == pokemonId);
  }

  void setFavorites(List<Pokemon> pokemons) {
    _favorites.clear();
    _favorites.addAll(pokemons);
    notifyListeners();
  }
}
