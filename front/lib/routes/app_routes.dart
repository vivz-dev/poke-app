import 'package:flutter/material.dart';
import '../screens/login_screen.dart';
import '../screens/home_screen.dart';
import '../screens/register_screen.dart';
import '../screens/favorites_screen.dart';

final Map<String, WidgetBuilder> appRoutes = {
  '/': (_) => LoginScreen(),
  '/home': (_) => HomeScreen(),
  '/register': (_) => RegisterScreen(),
  '/favorites': (_) => FavoritesScreen(),
};
