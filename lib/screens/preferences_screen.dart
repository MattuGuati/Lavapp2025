import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../services/database_service.dart';
import '../utils/logger.dart';

class PreferencesScreen extends StatefulWidget {
  const PreferencesScreen({super.key});

  @override
  State<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends State<PreferencesScreen> {
  final DatabaseService _dbService = DatabaseService();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _costPerBagController = TextEditingController();
  final _whatsappMessageController = TextEditingController();
  bool hasCounter = false;
  List<Map<String, dynamic>> attributes = [];

  @override
  void initState() {
    super.initState();
    AppLogger.info('Initializing PreferencesScreen');
    _loadAttributes();
    _loadCostPerBag();
    _loadWhatsappMessage();
  }

  Future<void> _loadAttributes() async {
    try {
      AppLogger.info('Loading attributes from DatabaseService');
      final loadedAttributes = await _dbService.getAllAttributes();
      if (mounted) {
        setState(() {
          attributes = loadedAttributes;
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

  Future<void> _loadCostPerBag() async {
    try {
      AppLogger.info('Loading cost per bag from DatabaseService');
      final prefs = await _dbService.getPreferences();
      if (mounted) {
        setState(() {
          _costPerBagController.text = (prefs?['costPerBag'] ?? 500).toString();
          AppLogger.info('Cost per bag loaded: ${_costPerBagController.text}');
        });
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error loading cost per bag: $e', e, stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar costo por bolsa: $e')),
        );
      }
    }
  }

  Future<void> _loadWhatsappMessage() async {
    try {
      AppLogger.info('Loading WhatsApp message from DatabaseService');
      final prefs = await _dbService.getPreferences();
      const defaultMessage = '¡Hola {nombre} 👋! Ya podés pasar a retirar tu ropa 🧼✨. Costo: \${costo}. Si deseas transferir, podés hacerlo al alias: matteo.peirano.mp. ¡Gracias por elegirnos! 😊🙌';
      if (mounted) {
        setState(() {
          _whatsappMessageController.text = prefs?['whatsappMessage'] ?? defaultMessage;
          AppLogger.info('WhatsApp message loaded');
        });
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error loading WhatsApp message: $e', e, stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar mensaje de WhatsApp: $e')),
        );
      }
    }
  }

  void _addAttribute() async {
    try {
      AppLogger.info('Adding new attribute');
      if (_nameController.text.isEmpty || _priceController.text.isEmpty) {
        AppLogger.warning('Validation failed: Name or price is empty');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Complete todos los campos.')),
          );
        }
        return;
      }
      final price = int.tryParse(_priceController.text);
      if (price == null) {
        AppLogger.warning('Validation failed: Price is not a valid number');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('El precio debe ser un número válido.')),
          );
        }
        return;
      }
      final attribute = {
        'name': _nameController.text,
        'price': price,
        'hasCounter': hasCounter,
      };
      AppLogger.info('Adding attribute via DatabaseService: $attribute');
      final docId = await _dbService.insertAttribute(attribute);
      if (docId.isNotEmpty) {
        AppLogger.info('Attribute added successfully');
        _nameController.clear();
        _priceController.clear();
        if (mounted) {
          setState(() => hasCounter = false);
          _loadAttributes();
        }
      } else {
        AppLogger.error('Failed to add attribute: empty docId returned');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error al agregar atributo')),
          );
        }
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error in _addAttribute: $e', e, stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al agregar atributo: $e')),
        );
      }
    }
  }

  void _deleteAttribute(String id) async {
    try {
      AppLogger.info('Deleting attribute with id: $id');
      await _dbService.deleteAttribute(id);
      AppLogger.info('Attribute deleted successfully');
      if (mounted) {
        _loadAttributes();
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error in _deleteAttribute: $e', e, stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al eliminar atributo: $e')),
        );
      }
    }
  }

  void _saveCostPerBag() async {
    try {
      AppLogger.info('Saving cost per bag');
      final cost = int.tryParse(_costPerBagController.text);
      if (cost == null) {
        AppLogger.warning('Validation failed: Cost per bag is not a valid number');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('El costo debe ser un número válido.')),
          );
        }
        return;
      }
      AppLogger.info('Saving cost per bag via DatabaseService: $cost');
      await _dbService.updatePreferences({'costPerBag': cost});
      AppLogger.info('Cost per bag saved successfully');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Preferencias guardadas')),
        );
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error in _saveCostPerBag: $e', e, stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar costo por bolsa: $e')),
        );
      }
    }
  }

  void _saveWhatsappMessage() async {
    try {
      AppLogger.info('Saving WhatsApp message');
      final message = _whatsappMessageController.text.trim();
      if (message.isEmpty) {
        AppLogger.warning('Validation failed: WhatsApp message is empty');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('El mensaje no puede estar vacío.')),
          );
        }
        return;
      }
      AppLogger.info('Saving WhatsApp message via DatabaseService');
      await _dbService.updatePreferences({'whatsappMessage': message});
      AppLogger.info('WhatsApp message saved successfully');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mensaje de WhatsApp guardado')),
        );
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error in _saveWhatsappMessage: $e', e, stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar mensaje: $e')),
        );
      }
    }
  }

  Future<void> _changeWhatsappNumber() async {
    try {
      AppLogger.info('Showing WhatsApp number change confirmation dialog');
      final confirm = await showDialog<bool>(
        context: context,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: const Text('Cambiar Número de WhatsApp'),
            content: const Text('¿Desea eliminar la sesión actual de WhatsApp? Esto cerrará todas las sesiones activas y deberá escanear un nuevo código QR.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Eliminar Sesión'),
              ),
            ],
          );
        },
      );

      if (confirm == true) {
        AppLogger.info('User confirmed WhatsApp session deletion');

        // Obtener usuario actual para usar su API key
        SharedPreferences prefs = await SharedPreferences.getInstance();
        String? currentUsername = prefs.getString('username');
        String? apiKey;
        String? countryCode;

        if (currentUsername != null) {
          try {
            final userDoc = await FirebaseFirestore.instance
                .collection('users')
                .doc(currentUsername)
                .get();

            if (userDoc.exists && userDoc.data() != null) {
              apiKey = userDoc.data()!['whatsappApiKey'] as String?;
              countryCode = userDoc.data()!['countryCode'] as String?;
            }
          } catch (e) {
            AppLogger.warning('Could not load user API key: $e');
          }
        }

        final apiService = ApiService(
          apiKey: apiKey,
          countryCode: countryCode,
        );
        await apiService.deleteWhatsappSession();
        AppLogger.info('WhatsApp session deleted successfully');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sesión eliminada. Redirigiendo al QR...')),
          );

          // Abrir QR en navegador con el apiKey específico del usuario
          final userApiKey = apiKey ?? 'default';
          final qrUrl = Uri.parse('https://lavapp.innovacore.ar/api/qr/$userApiKey');
          AppLogger.info('Opening QR URL: $qrUrl');

          if (await canLaunchUrl(qrUrl)) {
            await launchUrl(qrUrl, mode: LaunchMode.externalApplication);
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('No se pudo abrir el QR. Visita: https://lavapp.innovacore.ar/api/qr/$userApiKey')),
              );
            }
          }
        }
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error changing WhatsApp number: $e', e, stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cambiar número: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    AppLogger.info('Building PreferencesScreen');
    return Scaffold(
      appBar: AppBar(
        title: const Text('Preferencias'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Card: Configuración de Costos
            _buildSectionCard(
              icon: Icons.attach_money,
              iconColor: Colors.green,
              title: 'Configuración de Costos',
              subtitle: 'Define el costo por bolsa',
              children: [
                TextField(
                  controller: _costPerBagController,
                  decoration: const InputDecoration(
                    labelText: 'Costo por Bolsa',
                    prefixIcon: Icon(Icons.monetization_on),
                    hintText: 'Ej: 500',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _saveCostPerBag,
                    icon: const Icon(Icons.save),
                    label: const Text('Guardar Costo'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Card: Mensaje de WhatsApp
            _buildSectionCard(
              icon: Icons.message,
              iconColor: Colors.blue,
              title: 'Mensaje de WhatsApp',
              subtitle: 'Personaliza el mensaje automático',
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Variables: {nombre}, {costo}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _whatsappMessageController,
                  decoration: const InputDecoration(
                    labelText: 'Mensaje',
                    prefixIcon: Icon(Icons.chat_bubble_outline),
                    hintText: 'Escribe tu mensaje aquí...',
                    alignLabelWithHint: true,
                  ),
                  maxLines: 5,
                  minLines: 3,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _saveWhatsappMessage,
                    icon: const Icon(Icons.save),
                    label: const Text('Guardar Mensaje'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Card: Configuración de WhatsApp
            _buildSectionCard(
              icon: Icons.phone_android,
              iconColor: Colors.orange,
              title: 'Configuración de WhatsApp',
              subtitle: 'Gestiona tu número de WhatsApp',
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _changeWhatsappNumber,
                    icon: const Icon(Icons.qr_code_scanner),
                    label: const Text('Cambiar Número de WhatsApp'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Elimina la sesión actual y escanea un nuevo código QR',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Card: Agregar Nuevo Atributo
            _buildSectionCard(
              icon: Icons.add_circle_outline,
              iconColor: Colors.purple,
              title: 'Agregar Nuevo Atributo',
              subtitle: 'Crea atributos personalizados para tus tickets',
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del Atributo',
                    prefixIcon: Icon(Icons.label),
                    hintText: 'Ej: Plancha, Secado, etc.',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _priceController,
                  decoration: const InputDecoration(
                    labelText: 'Precio',
                    prefixIcon: Icon(Icons.attach_money),
                    hintText: '0',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: CheckboxListTile(
                    title: const Text('Contador'),
                    subtitle: const Text('Permite especificar cantidad', style: TextStyle(fontSize: 12)),
                    value: hasCounter,
                    onChanged: (value) {
                      if (mounted) {
                        AppLogger.info('Toggling hasCounter: $hasCounter -> $value');
                        setState(() => hasCounter = value ?? false);
                      }
                    },
                    secondary: const Icon(Icons.numbers),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _addAttribute,
                    icon: const Icon(Icons.add),
                    label: const Text('Agregar Atributo'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Card: Atributos Existentes
            _buildSectionCard(
              icon: Icons.list_alt,
              iconColor: Colors.teal,
              title: 'Atributos Existentes',
              subtitle: 'Gestiona tus atributos',
              children: [
                if (attributes.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          Icon(Icons.inbox, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          Text(
                            'No hay atributos registrados',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: attributes.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final attribute = attributes[index];
                      return ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.purple.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.label, color: Colors.purple),
                        ),
                        title: Text(
                          attribute['name'] ?? 'Sin nombre',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Row(
                          children: [
                            Text('\$${attribute['price'] ?? 0}'),
                            if (attribute['hasCounter'] == true) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade100,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Contador',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.blue.shade700,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          color: Colors.red,
                          onPressed: () => _showDeleteAttributeDialog(attribute['id']),
                        ),
                      );
                    },
                  ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }

  void _showDeleteAttributeDialog(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: const Text('¿Está seguro que desea eliminar este atributo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteAttribute(id);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    AppLogger.info('Disposing PreferencesScreen');
    _nameController.dispose();
    _priceController.dispose();
    _costPerBagController.dispose();
    _whatsappMessageController.dispose();
    super.dispose();
  }
}