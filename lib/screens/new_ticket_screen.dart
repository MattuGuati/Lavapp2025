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
      if (bagCount <= 0 && extras.isEmpty && counterExtras.isEmpty) {
        AppLogger.warning('Validation failed: No bags or extras selected');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Debe seleccionar al menos cantidad de bolsas o extras.')),
        );
        return;
      }
      final ticket = {
        'nombre': _nameController.text,
        'celular': _phoneController.text,
        'cantidadBolsas': bagCount,
        'extras': {
          ...extras,
          ...counterExtras.map((k, v) {
            final attr = attributes.firstWhere((attr) => attr['name'] == k);
            return MapEntry(k, v * (attr['price'] as int));
          }),
        },
        'estado': 'En Proceso',
      };
      AppLogger.info('Ticket data to be created: $ticket');
      Navigator.pop(context, ticket);
    } catch (e, stackTrace) {
      AppLogger.error('Error creating ticket: $e', e, stackTrace);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al crear el ticket: $e')),
      );
    }
  }

  void _cancel() {
    AppLogger.info('Cancelling ticket creation');
    Navigator.pop(context);
  }

  @override
  void dispose() {
    AppLogger.info('Disposing NewTicketScreen');
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    AppLogger.info('Building NewTicketScreen');
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuevo Ticket', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Nombre',
                  suffixIcon: suggestions.isNotEmpty
                      ? PopupMenuButton<Map<String, dynamic>>(
                          icon: const Icon(Icons.arrow_drop_down),
                          onSelected: (client) {
                            AppLogger.info('Selected client from suggestions: ${client['name']}');
                            _nameController.text = client['name'];
                            _phoneController.text = client['phone'];
                            setState(() => suggestions = []);
                          },
                          itemBuilder: (context) => suggestions.map((client) {
                            return PopupMenuItem(
                              value: client,
                              child: ListTile(
                                title: Text(client['name']),
                                subtitle: Text('Tel: ${client['phone']}'),
                              ),
                            );
                          }).toList(),
                        )
                      : null,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'Teléfono',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(icon: const Icon(Icons.remove), onPressed: _decrementBags),
                  Text('$bagCount', style: const TextStyle(fontSize: 16)),
                  IconButton(icon: const Icon(Icons.add), onPressed: _incrementBags),
                  const SizedBox(width: 8),
                  const Text('Cantidad de bolsas', style: TextStyle(fontSize: 16)),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'Extras (seleccione los que apliquen)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...attributes.where((attr) => (attr['hasCounter'] ?? false) == false).map((attr) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: CheckboxListTile(
                      title: Text('${attr['name']} (\$${attr['price']})', style: const TextStyle(fontSize: 16)),
                      value: extras.containsKey(attr['name']),
                      onChanged: (value) => _toggleExtra(attr['name'], attr['price'] as int, false),
                      contentPadding: EdgeInsets.zero,
                    ),
                  )),
              const SizedBox(height: 20),
              const Text(
                'Extras con Contador',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              ...attributes.where((attr) => (attr['hasCounter'] ?? false) == true).map((attr) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${attr['name']} (\$${attr['price']})', style: const TextStyle(fontSize: 16)),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove),
                              onPressed: () => _decrementCounterExtra(attr['name'], attr['price'] as int),
                            ),
                            Text('${counterExtras[attr['name']] ?? 0}', style: const TextStyle(fontSize: 16)),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () => _incrementCounterExtra(attr['name'], attr['price'] as int),
                            ),
                            Checkbox(
                              value: counterExtras.containsKey(attr['name']),
                              onChanged: (value) => _toggleExtra(attr['name'], attr['price'] as int, true),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: _createTicket,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.lightBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Crear Ticket'),
                  ),
                  ElevatedButton(
                    onPressed: _cancel,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.lightBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Cancelar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}