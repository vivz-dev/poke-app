import 'package:flutter/material.dart';
import 'routes/app_routes.dart';
import 'package:provider/provider.dart';
import 'providers/favorites_provider.dart';
// import 'screens/home_screen.dart';
import 'package:google_fonts/google_fonts.dart';

// import 'app.dart';


void main() {
  final favoritesProvider = FavoritesProvider();

  runApp(
    ChangeNotifierProvider<FavoritesProvider>(
      create: (_) {
        favoritesProvider.fetchFavoritesFromBackend(); // Carga desde el backend al arrancar
        return favoritesProvider;
      },
      child: MyApp(),
    ),
  );
}


class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Login App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
          textTheme: GoogleFonts.fredokaTextTheme(
            Theme.of(context).textTheme,
          ),
          primarySwatch: Colors.red
      ),
      initialRoute: '/',
      routes: appRoutes,
    );
  }
}
