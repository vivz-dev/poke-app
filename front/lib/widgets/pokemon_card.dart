import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/pokemon.dart';
import '../utils/pokemon_colors.dart';
import '../config.dart';
import 'package:provider/provider.dart';
import '../providers/favorites_provider.dart';
import '../services/auth_service.dart'; // ← agregado

class PokemonCard extends StatefulWidget {
  final Pokemon pokemon;
  final VoidCallback? onRemovedFromFavorites;

  const PokemonCard({
    super.key,
    required this.pokemon,
    this.onRemovedFromFavorites,
  });

  @override
  State<PokemonCard> createState() => _PokemonCardState();
}

class _PokemonCardState extends State<PokemonCard> {
  Future<void> _evolucionarPokemon(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Image.asset(
          'assets/animations/evolution.gif',
          height: 100,
        ),
      ),
    );

    try {
      final uri = Uri.parse('${AppConfig.baseUrl}/pokemons/evolucionarPokemon/${widget.pokemon.id}');
      final response = await http.post(uri);

      Navigator.of(context).pop();

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['evolucionado']) {
          final evolucionado = Pokemon.fromJson(data['pokemon']);
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('¡Evolución Exitosa!'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.network(
                    evolucionado.imagen,
                    height: 100,
                    errorBuilder: (context, error, stackTrace) {
                      return Image.asset(
                        'assets/images/pokemon_placeholder.png',
                        height: 100,
                        fit: BoxFit.contain,
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "#${evolucionado.id.toString().padLeft(3, '0')} ${evolucionado.nombre}".toUpperCase(),
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: evolucionado.tipos.map((tipo) {
                      final color = pokemonTypeColors[tipo.toLowerCase()] ?? Colors.grey;
                      return Chip(
                        label: Text(
                          tipo,
                          style: const TextStyle(color: Colors.white),
                        ),
                        backgroundColor: color,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Habilidades: ${evolucionado.habilidades.join(", ")}",
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    runSpacing: 4,
                    children: evolucionado.estadisticas.entries.map((e) {
                      return Text(
                        "${e.key}: ${e.value}",
                        style: const TextStyle(fontSize: 12),
                      );
                    }).toList(),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cerrar'),
                ),
              ],
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['mensaje']),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        throw Exception('Error al evolucionar: ${response.statusCode}');
      }
    } catch (e) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _agregarFavorito() async {
    final token = await AuthService.getToken();
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Inicia sesión para agregar a favoritos'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/favoritos/favs'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(widget.pokemon.toJson()),
      );

      if (response.statusCode == 200) {
        Provider.of<FavoritesProvider>(context, listen: false).addFavorite(widget.pokemon);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.pokemon.nombre} agregado a favoritos'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        final body = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(body['detail'] ?? 'Error al agregar favorito'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error de red: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _eliminarFavorito() async {
    final token = await AuthService.getToken();
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Inicia sesión para eliminar favoritos'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final response = await http.delete(
        Uri.parse('${AppConfig.baseUrl}/favoritos/favs/${widget.pokemon.nombre}'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        Provider.of<FavoritesProvider>(context, listen: false).removeFavorite(widget.pokemon.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.pokemon.nombre} eliminado de favoritos'),
            backgroundColor: Colors.grey,
          ),
        );

        // 🔁 Refrescar lista si viene de modal
        if (widget.onRemovedFromFavorites != null) {
          widget.onRemovedFromFavorites!();
        }
      }
      else {
        final body = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(body['detail'] ?? 'Error al eliminar favorito'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error de red: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final favoritesProvider = Provider.of<FavoritesProvider>(context);
    final esFavorito = favoritesProvider.isFavorite(widget.pokemon.id);

    return Stack(
      children: [
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 4,
          margin: const EdgeInsets.all(8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Image.network(
                    widget.pokemon.imagen,
                    height: 72,
                    errorBuilder: (context, error, stackTrace) {
                      return Image.asset(
                        'assets/images/pokemon_placeholder.png',
                        height: 72,
                        fit: BoxFit.contain,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "#${widget.pokemon.id.toString().padLeft(3, '0')} ${widget.pokemon.nombre}".toUpperCase(),
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: widget.pokemon.tipos.map((tipo) {
                    final color = pokemonTypeColors[tipo.toLowerCase()] ?? Colors.grey;
                    return Chip(
                      label: Text(
                        tipo,
                        style: const TextStyle(color: Colors.white),
                      ),
                      backgroundColor: color,
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
                Text(
                  "Habilidades: ${widget.pokemon.habilidades.join(", ")}",
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  children: widget.pokemon.estadisticas.entries.map((e) {
                    return Text(
                      "${e.key}: ${e.value}",
                      style: const TextStyle(fontSize: 12),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    icon: const Icon(Icons.auto_fix_high),
                    label: const Text("Evolucionar"),
                    onPressed: () => _evolucionarPokemon(context),
                  ),
                )
              ],
            ),
          ),
        ),
        Positioned(
          top: 12,
          right: 12,
          child: IconButton(
            icon: Icon(
              esFavorito ? Icons.favorite : Icons.favorite_border,
              color: esFavorito ? Colors.red : Colors.grey,
            ),
            onPressed: () {
              if (esFavorito) {
                _eliminarFavorito();
              } else {
                _agregarFavorito();
              }
            },
          ),
        )
      ],
    );
  }
}
