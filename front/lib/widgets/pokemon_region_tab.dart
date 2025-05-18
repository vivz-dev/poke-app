import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/pokemon.dart';
import '../widgets/pokemon_card.dart';
import '../config.dart';

class PokemonRegionTab extends StatefulWidget {
  final String region;

  const PokemonRegionTab({super.key, required this.region});

  @override
  State<PokemonRegionTab> createState() => _PokemonRegionTabState();

  static void clearCache() {
    _cache.clear();
    _offsets.clear();
    _hasMoreFlags.clear();
  }

  static final Map<String, List<Pokemon>> _cache = {};
  static final Map<String, int> _offsets = {};
  static final Map<String, bool> _hasMoreFlags = {};
}

class _PokemonRegionTabState extends State<PokemonRegionTab> {
  final ScrollController _scrollController = ScrollController();
  final Map<int, List<Map<String, dynamic>>> _evolutionCache = {};

  List<Pokemon> _pokemones = [];
  int _offset = 0;
  bool _hasMore = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    if (PokemonRegionTab._cache.containsKey(widget.region)) {
      _pokemones = PokemonRegionTab._cache[widget.region]!;
      _offset = PokemonRegionTab._offsets[widget.region] ?? 0;
      _hasMore = PokemonRegionTab._hasMoreFlags[widget.region] ?? true;
    } else {
      _fetchPokemons();
    }

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200 &&
          !_isLoading &&
          _hasMore) {
        _fetchPokemons();
      }
    });
  }

  Future<List<Map<String, dynamic>>> _getEvolutionChain(int id) async {
    if (_evolutionCache.containsKey(id)) {
      return _evolutionCache[id]!;
    }

    try {
      final response = await http.get(Uri.parse('${AppConfig.baseUrl}/pokemons/getPokemon/$id'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final chain = List<Map<String, dynamic>>.from(data['cadena_evolutiva']);
        _evolutionCache[id] = chain;
        return chain;
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }


  Future<void> _fetchPokemons() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final uri = Uri.parse(
        '${AppConfig.baseUrl}/pokemons/getPokemonsByRegion/${widget.region}?offset=$_offset',
      );

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> nuevos = data['pokemones'];
        final List<Pokemon> nuevosPokemones =
        nuevos.map((json) => Pokemon.fromJson(json)).toList();

        setState(() {
          _pokemones.addAll(nuevosPokemones);
          _offset = data['offset_siguiente'] ?? _offset;
          _hasMore = data['existe_siguiente'] ?? false;

          PokemonRegionTab._cache[widget.region] = _pokemones;
          PokemonRegionTab._offsets[widget.region] = _offset;
          PokemonRegionTab._hasMoreFlags[widget.region] = _hasMore;
        });
      } else {
        throw Exception('Error al cargar datos: ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constraints) {
        if (_pokemones.isEmpty && _isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        int crossAxisCount = (constraints.maxWidth / 300).floor();
        crossAxisCount = crossAxisCount < 1 ? 1 : crossAxisCount;

        return Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                itemCount: _pokemones.length + (_hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index < _pokemones.length) {
                    final pokemon = _pokemones[index];
                    return FutureBuilder<List<Map<String, dynamic>>>(
                      future: _getEvolutionChain(pokemon.id),
                      builder: (context, snapshot) {
                        final cadenaEvolutiva = snapshot.data ?? [];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: PokemonCard(
                            pokemon: pokemon,
                            cadenaEvolutiva: cadenaEvolutiva,
                          ),
                        );
                      },
                    );
                  } else {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }
                },
              ),
            ),

          ],
        );
      },
    );
  }
}
