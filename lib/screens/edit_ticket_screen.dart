import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';

class EditTicketScreen extends StatefulWidget {
  final Map<String, dynamic> ticket;
  const EditTicketScreen({super.key, required this.ticket});

  @override
  State<EditTicketScreen> createState() => _EditTicketScreenState();
}

class _EditTicketScreenState extends State<EditTicketScreen> {
  late String name;
  late String phone;
  late int bagCount;
  late Map<String, int> extras;
  late Map<String, int> counterExtras;
  late String state;
  final dbService = DatabaseService();
  List<Map<String, dynamic>> attributes = [];
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  DateTime? fechaEntrega; // Fecha programada de entrega

  @override
  void initState() {
    super.initState();
    name = widget.ticket['nombre'] ?? '';
    phone = widget.ticket['celular'] ?? '';
    bagCount = widget.ticket['cantidadBolsas'] ?? 0;
    final extrasData = widget.ticket['extras'] ?? <String, dynamic>{};
    // Construcción segura de mapas - necesitamos cargar attributes primero
    extras = {};
    counterExtras = {};
    // Guardamos temporalmente todos los extras
    for (var entry in extrasData.entries) {
      if (entry.key is String && entry.value is int) {
        extras[entry.key as String] = entry.value as int;
      }
    }
    state = widget.ticket['estado'] ?? 'En Proceso';
    _nameController.text = name;
    _phoneController.text = phone;
    // Cargar fecha de entrega si existe
    if (widget.ticket['fechaEntrega'] != null) {
      try {
        fechaEntrega = DateTime.parse(widget.ticket['fechaEntrega'] as String);
      } catch (e) {
        debugPrint('Error parsing fechaEntrega: $e');
        fechaEntrega = null;
      }
    }
    _loadAttributes();
  }

  void _loadAttributes() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('attributes').get();
      if (mounted) {
        setState(() {
          attributes = snapshot.docs.map((doc) => doc.data()..['id'] = doc.id).toList();

          // Ahora clasificamos los extras basándonos en los atributos cargados
          final Map<String, int> tempExtras = {};
          final Map<String, int> tempCounterExtras = {};

          for (var entry in extras.entries) {
            final attr = attributes.firstWhere(
              (a) => a['name'] == entry.key,
              orElse: () => <String, dynamic>{},
            );

            if (attr.isEmpty) {
              // Atributo no encontrado, lo ignoramos o lo tratamos como extra simple
              continue;
            }

            if (attr['hasCounter'] == true) {
              // Es un counterExtra, necesitamos calcular la cantidad
              final price = attr['price'] as int? ?? 1;
              final quantity = (entry.value / price).round();
              tempCounterExtras[entry.key] = quantity;
            } else {
              // Es un extra simple
              tempExtras[entry.key] = entry.value;
            }
          }

          extras = tempExtras;
          counterExtras = tempCounterExtras;
        });
      }
    } catch (e) {
      // Manejo de error silencioso, pero registramos el error
      debugPrint('Error loading attributes: $e');
    }
  }

  void _incrementBags() => setState(() => bagCount++);
  void _decrementBags() => setState(() => bagCount > 0 ? bagCount-- : bagCount = 0);

  void _incrementCounterExtra(String name, int price) => setState(() {
        counterExtras[name] = (counterExtras[name] ?? 0) + 1;
      });
  void _decrementCounterExtra(String name, int price) => setState(() {
        if (counterExtras[name] != null && counterExtras[name]! > 0) {
          counterExtras[name] = counterExtras[name]! - 1;
          if (counterExtras[name] == 0) counterExtras.remove(name);
        }
      });

  void _toggleExtra(String name, int price, bool hasCounter) {
    setState(() {
      if (hasCounter) {
        if (!counterExtras.containsKey(name)) counterExtras[name] = 0;
      } else {
        if (extras.containsKey(name)) {
          extras.remove(name);
        } else {
          extras[name] = price;
        }
      }
    });
  }

  Future<void> _selectFechaEntrega() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: fechaEntrega ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('es', 'ES'),
      helpText: 'Seleccionar fecha de entrega',
      cancelText: 'Cancelar',
      confirmText: 'Confirmar',
    );
    if (picked != null && picked != fechaEntrega) {
      setState(() {
        fechaEntrega = picked;
      });
    }
  }

  void _saveTicket() {
    final updatedTicket = {
      'nombre': _nameController.text,
      'celular': _phoneController.text,
      'cantidadBolsas': bagCount,
      'extras': {
        ...extras,
        ...counterExtras.map((k, v) => MapEntry(k, v * (attributes.firstWhere((attr) => attr['name'] == k)['price'] as int)))
      },
      'estado': state,
      'fechaEntrega': fechaEntrega?.toIso8601String(),
      'usuario': widget.ticket['usuario'],
      'timestamp': widget.ticket['timestamp'],
      'docId': widget.ticket['docId'],
    };
    Navigator.pop(context, updatedTicket);
  }

  void _cancel() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Editar Ticket', style: TextStyle(color: Colors.white))),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Nombre',
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
              ElevatedButton.icon(
                onPressed: _selectFechaEntrega,
                icon: const Icon(Icons.calendar_today),
                label: Text(
                  fechaEntrega != null
                      ? 'Fecha de entrega: ${DateFormat('dd/MM/yyyy').format(fechaEntrega!)}'
                      : 'Seleccionar fecha de entrega',
                  style: const TextStyle(fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: fechaEntrega != null ? Colors.green[100] : Colors.grey[200],
                  foregroundColor: Colors.black87,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(icon: Icon(Icons.remove), onPressed: _decrementBags),
                  Text('$bagCount'),
                  IconButton(icon: Icon(Icons.add), onPressed: _incrementBags),
                  const SizedBox(width: 8),
                  const Text('Cantidad de bolsas'),
                ],
              ),
              const SizedBox(height: 15),
              DropdownButton<String>(
                value: state,
                hint: Text('Selecciona estado'),
                items: ['En Proceso', 'Pendiente', 'Entregado'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (newValue) {
                  if (newValue != null) {
                    setState(() {
                      state = newValue;
                    });
                  }
                },
              ),
              const SizedBox(height: 15),
              ...attributes.map((attr) => attr['hasCounter'] == true
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Checkbox(
                            value: counterExtras.containsKey(attr['name']),
                            onChanged: (value) => _toggleExtra(attr['name'], attr['price'] as int, true),
                          ),
                          Text('${attr['name']} (\$${attr['price']})'),
                          IconButton(icon: Icon(Icons.remove), onPressed: () => _decrementCounterExtra(attr['name'], attr['price'] as int)),
                          Text('${counterExtras[attr['name']] ?? 0}'),
                          IconButton(icon: Icon(Icons.add), onPressed: () => _incrementCounterExtra(attr['name'], attr['price'] as int)),
                        ],
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: CheckboxListTile(
                        title: Text('${attr['name']} (\$${attr['price']})'),
                        value: extras.containsKey(attr['name']),
                        onChanged: (value) => _toggleExtra(attr['name'], attr['price'] as int, false),
                      ),
                    )),
              const SizedBox(height: 20), // Reemplazamos Spacer por SizedBox para evitar el error de flex
              Padding(
                padding: const EdgeInsets.only(top: 20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: _saveTicket,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.lightBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text('Guardar'),
                    ),
                    ElevatedButton(
                      onPressed: _cancel,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.lightBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text('Cancelar'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}