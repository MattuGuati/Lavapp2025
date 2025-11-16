import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CostScreen extends StatefulWidget {
  const CostScreen({super.key});

  @override
  State<CostScreen> createState() => _CostScreenState();
}

class _CostScreenState extends State<CostScreen> {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  List<Map<String, dynamic>> costs = [];

  @override
  void initState() {
    super.initState();
    _loadCosts();
  }

  Future<void> _loadCosts() async {
    final snapshot = await FirebaseFirestore.instance.collection('costs').get();
    setState(() {
      costs = snapshot.docs.map((doc) => doc.data()..['id'] = doc.id).toList();
    });
  }

  void _addCost() {
    if (_nameController.text.isNotEmpty && _priceController.text.isNotEmpty) {
      final cost = {
        'name': _nameController.text,
        'price': int.parse(_priceController.text),
        'timestamp': DateTime.now().toIso8601String(),
      };
      FirebaseFirestore.instance.collection('costs').add(cost);
      _nameController.clear();
      _priceController.clear();
      _loadCosts();
    }
  }

  void _deleteCost(String id) {
    FirebaseFirestore.instance.collection('costs').doc(id).delete();
    _loadCosts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Costos')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Nombre del Gasto'),
                ),
                TextField(
                  controller: _priceController,
                  decoration: const InputDecoration(labelText: 'Precio'),
                  keyboardType: TextInputType.number,
                ),
                ElevatedButton(onPressed: _addCost, child: const Text('Agregar Gasto')),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: costs.length,
              itemBuilder: (context, index) {
                final cost = costs[index];
                return ListTile(
                  title: Text(cost['name']),
                  subtitle: Text('\$${cost['price']} - ${cost['timestamp']}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _deleteCost(cost['id']),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}