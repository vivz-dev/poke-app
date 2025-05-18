import 'package:flutter/material.dart';
import '../models/pokemon.dart';

class PokemonCard extends StatelessWidget {
  final Pokemon pokemon;

  const PokemonCard({super.key, required this.pokemon});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.network(pokemon.imagen, height: 100, fit: BoxFit.contain),
            const SizedBox(height: 8),
            Text(
              pokemon.nombre.toUpperCase(),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Wrap(
              spacing: 8,
              children: pokemon.tipos
                  .map((tipo) => Chip(label: Text(tipo)))
                  .toList(),
            ),
            const SizedBox(height: 6),
            Text('Habilidades: ${pokemon.habilidades.join(', ')}'),
            const SizedBox(height: 6),
            ...pokemon.estadisticas.entries.map((entry) => Text(
              '${entry.key}: ${entry.value}',
              style: const TextStyle(fontSize: 12),
            )),
          ],
        ),
      ),
    );
  }
}
