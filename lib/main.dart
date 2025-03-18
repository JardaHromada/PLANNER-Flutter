import 'package:flutter/material.dart';

import 'package:flutter_localizations/flutter_localizations.dart';

import 'screens/auth_page.dart';
import 'screens/settings_screen.dart';
import 'screens/home_screen.dart'; 
import 'screens/sign_in_screen.dart'; 
import 'screens/login_screen.dart';
import 'screens/mytasks_screen.dart';
import 'screens/groups_screen.dart';
import 'screens/goals_screen.dart';
import 'screens/todo_screen.dart';
import 'screens/about_app_screen.dart';
import 'screens/group_screen.dart';
import 'screens/group_info_screen.dart';

import 'package:firebase_core/firebase_core.dart'; 
import 'firebase_options.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PLLNR' ,
      locale: const Locale('cs'), // Set the locale to Czech
      supportedLocales: const [
        Locale('en'), 
        Locale('cs'), 
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color.fromARGB(255, 18, 32, 47),
      ),
      debugShowCheckedModeBanner: false,
      home: const AuthPage(),
      routes: {
        '/signIn': (context) => SignInScreen(),
        '/login': (context) => LoginScreen(),
        '/home': (context) => const HomeScreen(),
        '/auth': (context) => const AuthPage(),
        '/mytasks': (context) => const MyTaskScreen(),
        '/groups': (context) => const GroupsScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/todo': (context) => ToDoScreen(),
        '/goals': (context) => const GoalsScreen(),
        '/aboutapp': (context) => const AboutAppScreen(),
        '/groupDetail': (context) => const GroupDetailScreen(),
        '/groupInfo': (context) => const GroupInfoScreen(),

      },
    );
  }
}
