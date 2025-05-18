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
}

class _PokemonRegionTabState extends State<PokemonRegionTab> {
  final ScrollController _scrollController = ScrollController();

  // 🔁 Cache local por región
  static final Map<String, List<Pokemon>> _cache = {};
  static final Map<String, int> _offsets = {};
  static final Map<String, bool> _hasMoreFlags = {};

  List<Pokemon> _pokemones = [];
  int _offset = 0;
  bool _hasMore = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    // Si ya hay cache, usarlo
    if (_cache.containsKey(widget.region)) {
      _pokemones = _cache[widget.region]!;
      _offset = _offsets[widget.region] ?? 0;
      _hasMore = _hasMoreFlags[widget.region] ?? true;
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

          // 🔁 Actualiza cache
          _cache[widget.region] = _pokemones;
          _offsets[widget.region] = _offset;
          _hasMoreFlags[widget.region] = _hasMore;
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
        return Column(
          children: [
            Expanded(
              child: _pokemones.isEmpty && _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                controller: _scrollController,
                itemCount: _pokemones.length + (_hasMore ? 1 : 0),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemBuilder: (context, index) {
                  if (index < _pokemones.length) {
                    return PokemonCard(pokemon: _pokemones[index]);
                  } else {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
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
