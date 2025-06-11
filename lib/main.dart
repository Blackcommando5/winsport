import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/auth/splash_screen.dart';
import 'config/theme.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/cart/cart_screen.dart';
import 'admin/product_manager.dart';
import 'admin/payment_managment.dart';
import 'admin/profile.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sports Accessories Shop',
      theme: appThemeData,
      home: const SplashScreen(),
      routes: {
        '/signup': (context) => const SignupScreen(),
        '/login': (context) => const LoginScreen(),
        '/cart': (context) =>
            CartScreen(), // CartScreen manages Firestore directly
        // add more routes if needed
        '/product_management': (context) => const ProductManagement(),
        '/payment_management': (context) => const PaymentManagementScreen(),
        '/profile': (context) => const ProfileScreen(),
      },
    );
  }
}
