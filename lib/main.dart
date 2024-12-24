import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter_app_mercado/screens/auth.dart';
import 'package:flutter_app_mercado/screens/loading.dart';
import 'package:flutter_app_mercado/screens/lista_compras.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FlutterAppCompras',
      theme: _buildLightTheme(),
      darkTheme: _buildDarkTheme(),
      themeMode: ThemeMode.system,
      home: StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SplashScreen();
          }
          if (snapshot.hasData) {
            return const ShoppingListScreen();
          }
          return const AuthScreen();
        },
      ),
    );
  }

  ThemeData _buildLightTheme() {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: Colors.red.shade700,
      scaffoldBackgroundColor: Colors.yellow.shade50,
      colorScheme: ColorScheme.light(
        primary: Colors.red.shade700,
        secondary: Colors.amber.shade600,
        surface: Colors.yellow.shade100,
        onPrimary: Colors.black,
        onSurface: Colors.black,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Colors.black, fontSize: 16),
        bodyMedium: TextStyle(color: Colors.black, fontSize: 14),
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: Colors.red.shade900,
      scaffoldBackgroundColor: Colors.black87,
      colorScheme: ColorScheme.dark(
        primary: Colors.red.shade900,
        secondary: Colors.amber.shade800,
        surface: Colors.grey.shade800,
        onPrimary: Colors.white,
        onSurface: Colors.white,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Colors.white, fontSize: 16),
        bodyMedium: TextStyle(color: Colors.white, fontSize: 14),
      ),
    );
  }
}
