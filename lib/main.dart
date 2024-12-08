import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
// Import your app screens
import 'package:maincitylink/phone_login.dart';
import 'package:maincitylink/otp.dart';
import 'package:maincitylink/user_detail.dart';
import 'package:maincitylink/dashboard.dart';
import 'package:maincitylink/complain.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MainCityLinkApp());
}

class MainCityLinkApp extends StatelessWidget {
  const MainCityLinkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/phone': (context) => const myPhone(),
        '/otp': (context) => const MyOtp(),
        '/dashboard': (context) => const DashboardScreen(),
        '/user_detail': (context) => const UserDetailsScreen(),
        '/complaint_box': (context) => const ComplaintBoxScreen(),
        // '/notifications': (context) => NotificationsScreen(),
        // '/profile': (context) => ProfileScreen(),
        // '/news_feed': (context) => NewsFeedScreen(),
        // '/history': (context) => HistoryScreen(),
      },
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Future.delayed(const Duration(seconds: 2), () async {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // User is logged in, navigate to Dashboard
        Navigator.pushReplacementNamed(context, '/dashboard');
      } else {
        // Navigate to Phone Login
        Navigator.pushReplacementNamed(context, '/phone');
      }
    });

    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(), // Add your custom splash screen design here
      ),
    );
  }
}
