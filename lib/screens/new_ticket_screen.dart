import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/database_service.dart';
import '../utils/logger.dart';

class NewTicketScreen extends StatefulWidget {
  const NewTicketScreen({super.key});

  @override
  State<NewTicketScreen> createState() => _NewTicketScreenState();
}

class _NewTicketScreenState extends State<NewTicketScreen> {
  final DatabaseService dbService = DatabaseService();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  int bagCount = 0;
  Map<String, int> extras = {};
  Map<String, int> counterExtras = {};
  List<Map<String, dynamic>> clients = [];
  List<Map<String, dynamic>> suggestions = [];
  List<Map<String, dynamic>> attributes = [];

  @override
  void initState() {
    super.initState();
    AppLogger.info('Initializing NewTicketScreen');
    _loadClients();
    _loadAttributes();
    _nameController.addListener(_onNameChanged);
  }

  Future<void> _loadClients() async {
    try {
      AppLogger.info('Loading clients from Firestore');
      final snapshot = await FirebaseFirestore.instance.collection('clients').get();
      if (mounted) {
        setState(() {
          clients = snapshot.docs.map((doc) => doc.data()..['id'] = doc.id).toList();
          AppLogger.info('Loaded ${clients.length} clients');
        });
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error loading clients: $e', e, stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar clientes: $e')),
        );
      }
    }
  }

  Future<void> _loadAttributes() async {
    try {
      AppLogger.info('Loading attributes from Firestore');
      final snapshot = await FirebaseFirestore.instance.collection('attributes').get();
      if (mounted) {
        setState(() {
          attributes = snapshot.docs.map((doc) => doc.data()..['id'] = doc.id).toList();
          AppLogger.info('Loaded ${attributes.length} attributes');
        });
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error loading attributes: $e', e, stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar atributos: $e')),
        );
      }
    }
  }

  void _onNameChanged() {
    final query = _nameController.text.toLowerCase();
    if (query.isNotEmpty) {
      AppLogger.info('Searching for clients matching: $query');
      setState(() {
        suggestions = clients
            .where((client) => client['name'].toString().toLowerCase().contains(query))
            .toList();
        AppLogger.info('Found ${suggestions.length} suggestions');
      });
    } else {
      AppLogger.info('Clearing suggestions');
      setState(() {
        suggestions = [];
      });
    }
  }

  void _incrementBags() {
    AppLogger.info('Incrementing bag count: $bagCount -> ${bagCount + 1}');
    setState(() => bagCount++);
  }

  void _decrementBags() {
    AppLogger.info('Decrementing bag count: $bagCount -> ${bagCount > 0 ? bagCount - 1 : 0}');
    setState(() => bagCount > 0 ? bagCount-- : bagCount = 0);
  }

  void _incrementCounterExtra(String name, int price) {
    AppLogger.info('Incrementing counter extra $name: ${counterExtras[name] ?? 0} -> ${(counterExtras[name] ?? 0) + 1}');
    setState(() {
      counterExtras[name] = (counterExtras[name] ?? 0) + 1;
    });
  }

  void _decrementCounterExtra(String name, int price) {
    AppLogger.info('Decrementing counter extra $name: ${counterExtras[name] ?? 0} -> ${(counterExtras[name] ?? 0) - 1}');
    setState(() {
      if (counterExtras[name] != null && counterExtras[name]! > 0) {
        counterExtras[name] = counterExtras[name]! - 1;
        if (counterExtras[name] == 0) {
          counterExtras.remove(name);
          AppLogger.info('Removed counter extra $name (count reached 0)');
        }
      }
    });
  }

  void _toggleExtra(String name, int price, bool hasCounter) {
    AppLogger.info('Toggling extra $name (hasCounter: $hasCounter)');
    setState(() {
      if (hasCounter) {
        if (!counterExtras.containsKey(name)) {
          counterExtras[name] = 0;
          AppLogger.info('Added counter extra $name with count 0');
        }
      } else {
        if (extras.containsKey(name)) {
          extras.remove(name);
          AppLogger.info('Removed extra $name');
        } else {
          extras[name] = price;
          AppLogger.info('Added extra $name with price $price');
        }
      }
    });
  }

  void _createTicket() {
    try {
      AppLogger.info('Creating ticket...');
      if (_nameController.text.isEmpty || _phoneController.text.isEmpty) {
        AppLogger.warning('Validation failed: Name or phone number is empty');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor, ingrese el nombre y el número de teléfono.')),
        );
        return;
      }