import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../widgets/favorites_modal.dart';
import '../widgets/pokemon_region_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final List<String> regiones = [
    'kanto', 'johto', 'hoenn', 'sinnoh',
    'unova', 'kalos', 'alola', 'galar', 'paldea'
  ];

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: regiones.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _logout(BuildContext context) async {
    // Asegúrate de tener AuthService.logout() implementado correctamente
    await AuthService.logout();
    Navigator.pop(context); // Cierra el drawer
    Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pokémon por Región'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: regiones.map((r) => Tab(text: r.toUpperCase())).toList(),
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Text('Opciones', style: TextStyle(color: Colors.white, fontSize: 24)),
            ),
            ListTile(
              leading: const Icon(Icons.star),
              title: const Text('Ver favoritos'),
              onTap: () {
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (context) => const FavoritesModal(),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Cerrar sesión'),
              onTap: () => _logout(context),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: regiones.map((region) => PokemonRegionTab(region: region)).toList(),
      ),
    );
  }
}
