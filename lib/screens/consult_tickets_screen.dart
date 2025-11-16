import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../utils/logger.dart';

class ConsultTicketsScreen extends StatefulWidget {
  const ConsultTicketsScreen({super.key});

  @override
  State<ConsultTicketsScreen> createState() => _ConsultTicketsScreenState();
}

class _ConsultTicketsScreenState extends State<ConsultTicketsScreen> {
  final DatabaseService dbService = DatabaseService();
  List<Map<String, dynamic>> tickets = [];
  List<Map<String, dynamic>> filteredTickets = [];
  String searchQuery = '';
  bool showAll = false;
  String selectedFilter = 'Todos'; // Filtro seleccionado

  @override
  void initState() {
    super.initState();
    AppLogger.info('Initializing ConsultTicketsScreen');
    _loadTickets();
  }

  Future<void> _loadTickets() async {
    try {
      AppLogger.info('Loading tickets');
      final activeTickets = await dbService.getAllTickets();
      final archivedTickets = await dbService.getAllArchivedTickets();
      if (mounted) {
        setState(() {
          tickets = [...activeTickets, ...archivedTickets];
          filteredTickets = tickets.where((t) {
            final estado = t['estado'] as String?;
            return estado != null && (showAll || estado != 'Entregado');
          }).toList();
          AppLogger.info('Loaded ${tickets.length} tickets, filtered: ${filteredTickets.length}');
        });
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error loading tickets: $e', e, stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar tickets: $e')),
        );
      }
    }
  }

  void _restoreTicket(String docId) {
    try {
      AppLogger.info('Restoring ticket with docId: $docId');
      dbService.restoreTicket(docId).then((_) {
        AppLogger.info('Ticket restored successfully');
        _loadTickets();
      }).catchError((e, stackTrace) {
        AppLogger.error('Error restoring ticket: $e', e, stackTrace);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al restaurar ticket: $e')),
          );
        }
      });
    } catch (e, stackTrace) {
      AppLogger.error('Error in _restoreTicket: $e', e, stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al restaurar ticket: $e')),
        );
      }
    }
  }

  void _deleteTicket(String docId, bool isArchived) {
    try {
      AppLogger.info('Deleting ticket with docId: $docId');
      dbService.deleteTicket(docId, isArchived: isArchived).then((_) {
        AppLogger.info('Ticket deleted successfully');
        _loadTickets();
      }).catchError((e, stackTrace) {
        AppLogger.error('Error deleting ticket: $e', e, stackTrace);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al eliminar ticket: $e')),
          );
        }
      });
    } catch (e, stackTrace) {
      AppLogger.error('Error in _deleteTicket: $e', e, stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al eliminar ticket: $e')),
        );
      }
    }
  }

  void _searchTickets(String query) {
    AppLogger.info('Searching tickets with query: $query');
    setState(() {
      searchQuery = query.toLowerCase();
      filteredTickets = tickets.where((ticket) {
        final estado = ticket['estado'] as String?;
        final nombre = ticket['nombre'] as String? ?? '';
        final celular = ticket['celular'] as String? ?? '';
        return (showAll || estado != 'Entregado') &&
            (nombre.toLowerCase().contains(searchQuery) || celular.toLowerCase().contains(searchQuery));
      }).toList();
      AppLogger.info('Filtered tickets: ${filteredTickets.length}');
    });
  }

  Future<void> _refresh() async {
    AppLogger.info('Refreshing tickets');
    await _loadTickets();
  }

  List<Map<String, dynamic>> _filterByDate(List<Map<String, dynamic>> ticketsToFilter) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekAgo = today.subtract(const Duration(days: 7));
    final threeDaysAgo = now.subtract(const Duration(days: 3));

    return ticketsToFilter.where((ticket) {
      try {
        final timestampStr = ticket['timestamp'] as String?;
        if (timestampStr == null) return selectedFilter == 'Todos';

        final ticketDate = DateTime.parse(timestampStr);

        switch (selectedFilter) {
          case 'Hoy':
            final ticketDay = DateTime(ticketDate.year, ticketDate.month, ticketDate.day);
            return ticketDay.isAtSameMomentAs(today);
          case 'Esta Semana':
            return ticketDate.isAfter(weekAgo);
          case 'Vencidos':
            return ticketDate.isBefore(threeDaysAgo);
          case 'Todos':
          default:
            return true;
        }
      } catch (e) {
        AppLogger.error('Error parsing ticket timestamp: $e');
        return selectedFilter == 'Todos';
      }
    }).toList();
  }

  Widget _buildFilterButton(String filter) {
    final isSelected = selectedFilter == filter;
    return ElevatedButton(
      onPressed: () {
        setState(() {
          selectedFilter = filter;
          _searchTickets(searchQuery);
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.blue : Colors.grey[300],
        foregroundColor: isSelected ? Colors.white : Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      child: Text(filter),
    );
  }

  @override
  Widget build(BuildContext context) {
    AppLogger.info('Building ConsultTicketsScreen');
    return Scaffold(
      appBar: AppBar(
        title: const Text('Consultar Tickets', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: 'Buscar por nombre o celular',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                    onChanged: _searchTickets,
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _refresh,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Checkbox(
                  value: showAll,
                  onChanged: (value) {
                    AppLogger.info('Toggling showAll: $showAll -> $value');
                    setState(() {
                      showAll = value ?? false;
                      _searchTickets(searchQuery);
                    });
                  },
                ),
                const Text('Mostrar tickets entregados'),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refresh,
                child: ListView.builder(
                  itemCount: filteredTickets.length,
                  itemBuilder: (context, index) {
                    final ticket = filteredTickets[index];
                    final estado = ticket['estado'] as String?;
                    Color stateColor;
                    switch (estado) {
                      case 'En Proceso':
                        stateColor = Colors.red;
                        break;
                      case 'Pendiente':
                        stateColor = const Color.fromARGB(255, 210, 190, 7);
                        break;
                      case 'Entregado':
                        stateColor = Colors.green;
                        break;
                      default:
                        stateColor = Colors.grey;
                    }
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4.0),
                      child: ListTile(
                        title: Text('${ticket['nombre'] ?? 'Sin nombre'} #${ticket['celular'] ?? 'Sin celular'}'),
                        subtitle: Text('Estado: ${ticket['estado'] ?? 'Desconocido'}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: stateColor,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                ticket['estado'] ?? 'Desconocido',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            if (estado == 'Entregado')
                              IconButton(
                                icon: const Icon(Icons.restore, color: Colors.blue),
                                onPressed: () => _restoreTicket(ticket['docId'] as String),
                              ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteTicket(
                                ticket['docId'] as String,
                                estado == 'Entregado',
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}