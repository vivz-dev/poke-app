import 'package:flutter/material.dart';

class EvolutionChain extends StatelessWidget {
  final List<Map<String, dynamic>> chain;

  const EvolutionChain({super.key, required this.chain});

  @override
  Widget build(BuildContext context) {
    if (chain.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        const Text(
          'Cadena evolutiva:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(chain.length, (index) {
              final stage = chain[index];

              final imagen = stage['imagen'];
              final nombre = stage['nombre'] ?? '???';
              final tipos = (stage['tipos'] as List?) ?? [];
              final nivelMinimo = stage['nivel_minimo'];

              return Row(
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (imagen != null && imagen is String)
                        Image.network(
                          imagen,
                          height: 40,
                          errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.image_not_supported),
                        )
                      else
                        const Icon(Icons.image_not_supported, size: 60),
                      const SizedBox(height: 4),
                      Text(
                        nombre.toString().toUpperCase(),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                  if (index < chain.length - 1)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(Icons.arrow_forward, size: 18),
                    ),
                ],

              );
            }),
          ),
        ),
      ],
    );
  }
}
