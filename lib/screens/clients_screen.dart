import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/logger.dart';

class ClientsScreen extends StatefulWidget {
  const ClientsScreen({super.key});

  @override
  State<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  List<Map<String, dynamic>> clients = [];
  bool isLoading = false;
  String? currentUser;

  @override
  void initState() {
    super.initState();
    AppLogger.info('Initializing ClientsScreen');
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? savedUsername = prefs.getString('username');
      if (savedUsername != null) {
        if (mounted) {
          setState(() {
            currentUser = savedUsername;
          });
        }
        await _loadClients();
      } else {
        AppLogger.warning('No user session found');
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error loading current user: $e', e, stackTrace);
    }
  }

  Future<void> _loadClients() async {
    try {
      if (currentUser == null) {
        AppLogger.warning('Cannot load clients: no user logged in');
        return;
      }

      AppLogger.info('Loading clients from Firestore for user: $currentUser');
      if (mounted) {
        setState(() => isLoading = true);
      }

      // Filtrar clientes por userId
      final snapshot = await FirebaseFirestore.instance
          .collection('clients')
          .where('userId', isEqualTo: currentUser)
          .get();

      if (mounted) {
        setState(() {
          clients = snapshot.docs.map((doc) => doc.data()..['id'] = doc.id).toList();
          isLoading = false;
        });
        AppLogger.info('Loaded ${clients.length} clients for user $currentUser');
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error loading clients: $e', e, stackTrace);
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar clientes: $e')),
        );
      }
    }
  }

  Future<void> _addClient() async {
    try {
      if (currentUser == null) {
        AppLogger.warning('Cannot add client: no user logged in');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error: Usuario no autenticado')),
          );
        }
        return;
      }

      if (_nameController.text.trim().isEmpty || _phoneController.text.trim().isEmpty) {
        AppLogger.warning('Validation failed: Name or phone is empty');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Por favor complete todos los campos')),
          );
        }
        return;
      }

      AppLogger.info('Adding new client: ${_nameController.text} for user: $currentUser');
      final client = {
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'userId': currentUser, // Agregar userId para filtrado
      };
      await FirebaseFirestore.instance.collection('clients').add(client);
      AppLogger.info('Client added successfully');

      _nameController.clear();
      _phoneController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cliente agregado correctamente')),
        );
        await _loadClients();
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error adding client: $e', e, stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al agregar cliente: $e')),
        );
      }
    }
  }

  Future<void> _deleteClient(String id) async {
    try {
      AppLogger.info('Deleting client with id: $id');
      await FirebaseFirestore.instance.collection('clients').doc(id).delete();
      AppLogger.info('Client deleted successfully');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cliente eliminado')),
        );
        await _loadClients();
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error deleting client: $e', e, stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al eliminar cliente: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    AppLogger.info('Building ClientsScreen');
    return Scaffold(
      appBar: AppBar(title: const Text('Clientes')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _phoneController,
                  decoration: const InputDecoration(labelText: 'Teléfono'),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: isLoading ? null : _addClient,
                  child: const Text('Agregar Cliente'),
                ),
              ],
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : clients.isEmpty
                    ? const Center(
                        child: Text(
                          'No hay clientes registrados',
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      )
                    : ListView.builder(
                        itemCount: clients.length,
                        itemBuilder: (context, index) {
                          final client = clients[index];
                          return ListTile(
                            title: Text(client['name'] ?? 'Sin nombre'),
                            subtitle: Text('Tel: ${client['phone'] ?? 'Sin teléfono'}'),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => _deleteClient(client['id']),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    AppLogger.info('Disposing ClientsScreen');
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}