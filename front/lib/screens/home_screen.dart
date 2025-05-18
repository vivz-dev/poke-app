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
    await AuthService.logout();
    Navigator.pop(context);
    Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pokémon por Región'),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Text('Opciones',
                  style: TextStyle(color: Colors.white, fontSize: 24)),
            ),
            ListTile(
              leading: const Icon(Icons.star),
              title: const Text('Ver favoritos'),
              onTap: () async {
                Navigator.pop(context);
                final actualizado = await showDialog<bool>(
                  context: context,
                  builder: (context) => const FavoritesModal(),
                );

                if (actualizado == true) {
                  PokemonRegionTab.clearCache();
                  setState(() {}); // 🔁 fuerza reconstrucción del tab actual
                }
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
      body: Column(
        children: [
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 0, right: 12),
            child: Container(
              margin: const EdgeInsets.only(left: 12),
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Theme(
                data: Theme.of(context).copyWith(
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  indicatorColor: Colors.transparent,
                ),
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicatorPadding: const EdgeInsets.symmetric(vertical: 4),
                  labelPadding: const EdgeInsets.symmetric(horizontal: 16),
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    color: Colors.black,
                  ),
                  dividerColor: Colors.transparent,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.black,
                  tabs: regiones.map((r) => Tab(text: r.toUpperCase())).toList(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: regiones
                  .map((region) => PokemonRegionTab(region: region))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}
