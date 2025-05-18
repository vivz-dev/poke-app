import 'package:flutter/material.dart';
import '../models/pokemon.dart';
import '../services/pokemon_evolution_service.dart';
import '../widgets/pokemon_card.dart';

void showEvolutionModal(BuildContext context, Pokemon pokemon) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => EvolutionModal(pokemon: pokemon),
  );
}

class EvolutionModal extends StatefulWidget {
  final Pokemon pokemon;

  const EvolutionModal({super.key, required this.pokemon});

  @override
  State<EvolutionModal> createState() => _EvolutionModalState();
}

class _EvolutionModalState extends State<EvolutionModal> {
  bool _isLoading = true;
  bool _evolucionado = false;
  String? _mensaje;
  Pokemon? _nuevoPokemon;

  @override
  void initState() {
    super.initState();
    _iniciarEvolucion();
  }

  Future<void> _iniciarEvolucion() async {
    final result = await PokemonEvolutionService.evolucionarPokemon(widget.pokemon.id);

    await Future.delayed(const Duration(seconds: 2)); // para que se vea la animación

    setState(() {
      _isLoading = false;
      _evolucionado = result.evolucionado;
      _nuevoPokemon = result.nuevoPokemon;
      _mensaje = result.mensaje;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Evolución'),
      content: SizedBox(
        width: 300,
        child: _isLoading
            ? Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/animations/evolution.gif',
              height: 120,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 12),
            const Text('Evolucionando...'),
          ],
        )
            : _evolucionado && _nuevoPokemon != null
            ? Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('¡Tu Pokémon ha evolucionado!'),
            const SizedBox(height: 12),
            PokemonCard(pokemon: _nuevoPokemon!),
          ],
        )
            : Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.info_outline, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text(_mensaje ?? 'Este Pokémon no puede evolucionar.'),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cerrar'),
        ),
      ],
    );
  }
}
