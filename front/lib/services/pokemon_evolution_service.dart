import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/pokemon.dart';
import '../config.dart';

class EvolutionResult {
  final bool evolucionado;
  final Pokemon? nuevoPokemon;
  final String? mensaje;

  EvolutionResult({
    required this.evolucionado,
    this.nuevoPokemon,
    this.mensaje,
  });
}

class PokemonEvolutionService {
  static Future<EvolutionResult> evolucionarPokemon(int id) async {
    try {
      final url = Uri.parse('${AppConfig.baseUrl}/pokemons/evolucionarPokemon/$id');
      final response = await http.post(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['evolucionado'] == true && data['pokemon'] != null) {
          final nuevo = Pokemon.fromJson(data['pokemon']);
          return EvolutionResult(evolucionado: true, nuevoPokemon: nuevo);
        } else {
          return EvolutionResult(evolucionado: false, mensaje: data['mensaje'] ?? 'No puede evolucionar');
        }
      } else {
        return EvolutionResult(
          evolucionado: false,
          mensaje: 'Error del servidor: ${response.statusCode}',
        );
      }
    } catch (e) {
      return EvolutionResult(
        evolucionado: false,
        mensaje: 'Falla de red o error inesperado: $e',
      );
    }
  }
}
