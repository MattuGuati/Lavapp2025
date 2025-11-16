import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:lavapp/screens/ticket_list_screen.dart';
import 'package:lavapp/screens/new_ticket_screen.dart';
import 'package:lavapp/screens/edit_ticket_screen.dart';
import 'package:lavapp/screens/consult_tickets_screen.dart';
import 'package:lavapp/screens/reports_screen.dart';
import 'package:lavapp/screens/cost_screen.dart';
import 'package:lavapp/screens/clients_screen.dart';
import 'package:lavapp/screens/preferences_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LavApp',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2196F3),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          shadowColor: Colors.black.withOpacity(0.1),
        ),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: true,
          backgroundColor: Color(0xFF2196F3),
          foregroundColor: Colors.white,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF2196F3), width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 2,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2196F3),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF121212),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          color: const Color(0xFF1E1E1E),
        ),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: true,
          backgroundColor: Color(0xFF1E1E1E),
        ),
      ),
      themeMode: ThemeMode.light,
      initialRoute: '/',
      routes: {
        '/': (context) => const TicketListScreen(),
        '/new': (context) => const NewTicketScreen(),
        '/consult': (context) => const ConsultTicketsScreen(),
        '/reports': (context) => const ReportsScreen(),
        '/cost': (context) => const CostScreen(),
        '/clients': (context) => const ClientsScreen(),
        '/preferences': (context) => const PreferencesScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/edit') {
          final args = settings.arguments as Map<String, dynamic>?;
          if (args != null && args.containsKey('ticket')) {
            return MaterialPageRoute(
              builder: (context) => EditTicketScreen(ticket: args['ticket']),
            );
          }
          return null;
        }
        return null;
      },
    );
  }
}