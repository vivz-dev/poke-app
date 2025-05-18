class Pokemon {
  final int id;
  final String nombre;
  final String imagen;
  final List<String> tipos;
  final List<String> habilidades;
  final Map<String, dynamic> estadisticas;

  Pokemon({
    required this.id,
    required this.nombre,
    required this.imagen,
    required this.tipos,
    required this.habilidades,
    required this.estadisticas,
  });

  factory Pokemon.fromJson(Map<String, dynamic> json) {
    return Pokemon(
      id: json['id'],
      nombre: json['nombre'],
      imagen: json['imagen'],
      tipos: List<String>.from(json['tipos']),
      habilidades: List<String>.from(json['habilidades']),
      estadisticas: Map<String, dynamic>.from(json['estadisticas']),
    );
  }
}
