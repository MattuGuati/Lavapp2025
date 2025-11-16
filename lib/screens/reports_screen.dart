import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/database_service.dart';
import '../utils/logger.dart';
import 'package:intl/intl.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final DatabaseService dbService = DatabaseService();
  List<Map<String, dynamic>> tickets = [];
  List<Map<String, dynamic>> costs = [];
  int enProceso = 0;
  int pendiente = 0;
  int entregado = 0;
  int dailyProfit = 0;
  int monthlyProfit = 0;
  int yearlyProfit = 0;
  int costPerBag = 500;
  String? currentUser;
  final currencyFormat = NumberFormat.currency(locale: 'es_AR', symbol: '\$', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    AppLogger.info('Initializing ReportsScreen');
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
        await _loadData();
      } else {
        AppLogger.warning('No user session found');
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error loading current user: $e', e, stackTrace);
    }
  }

  Future<void> _loadData() async {
    try {
      if (currentUser == null) {
        AppLogger.warning('Cannot load data: no user logged in');
        return;
      }

      AppLogger.info('Loading data for reports for user: $currentUser');

      // Cargar tickets activos filtrados por usuario
      final activeSnapshot = await FirebaseFirestore.instance
          .collection('tickets')
          .where('usuario', isEqualTo: currentUser)
          .get();
      final ticketSnapshot = activeSnapshot.docs
          .map((doc) => doc.data()..['docId'] = doc.id)
          .toList();

      // Cargar tickets archivados filtrados por usuario
      final archivedSnapshotData = await FirebaseFirestore.instance
          .collection('archivedTickets')
          .where('usuario', isEqualTo: currentUser)
          .get();
      final archivedSnapshot = archivedSnapshotData.docs
          .map((doc) => doc.data()..['docId'] = doc.id)
          .toList();

      final costSnapshot = await FirebaseFirestore.instance.collection('costs').get();
      final preferencesDoc = await FirebaseFirestore.instance.collection('preferences').doc('settings').get();
      if (mounted) {
        setState(() {
          costPerBag = preferencesDoc.data()?['costPerBag'] ?? 500;
          tickets = [...ticketSnapshot, ...archivedSnapshot];
          costs = costSnapshot.docs.map((doc) => doc.data()..['id'] = doc.id).toList();
          enProceso = tickets.where((t) => t['estado'] == 'En Proceso').length;
          pendiente = tickets.where((t) => t['estado'] == 'Pendiente').length;
          entregado = tickets.where((t) => t['estado'] == 'Entregado').length;
          final now = DateTime.now();
          dailyProfit = _calculateProfit(now, const Duration(days: 1));
          monthlyProfit = _calculateProfit(now, const Duration(days: 30));
          yearlyProfit = _calculateProfit(now, const Duration(days: 365));
          AppLogger.info('Data loaded for user $currentUser: enProceso=$enProceso, pendiente=$pendiente, entregado=$entregado');
          AppLogger.info('Profits: daily=$dailyProfit, monthly=$monthlyProfit, yearly=$yearlyProfit');
        });
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error loading reports: $e', e, stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar reportes: $e')),
        );
      }
    }
  }

  int _calculateProfit(DateTime now, Duration period) {
    try {
      AppLogger.info('Calculating profit for period: $period');
      final start = now.subtract(period);
      int ticketRevenue = 0;
      for (final t in tickets) {
        final timestamp = t['timestamp'] != null ? DateTime.tryParse(t['timestamp'] as String) : null;
        if (timestamp != null && timestamp.isAfter(start) && t['estado'] == 'Entregado') {
          final bags = (t['cantidadBolsas'] as int?) ?? 0;
          int extraCost = 0;
          if (t['extras'] != null && t['extras'] is Map) {
            extraCost = (t['extras'] as Map).values.fold(0, (acc, p) {
              return acc + (p is num ? p.toInt() : (p as int));
            });
          }
          ticketRevenue += (bags * costPerBag) + extraCost;
        }
      }
      int costTotal = 0;
      for (final c in costs) {
        final timestamp = c['timestamp'] != null ? DateTime.tryParse(c['timestamp'] as String) : null;
        if (timestamp != null && timestamp.isAfter(start)) {
          costTotal += (c['price'] is num ? (c['price'] as num).toInt() : (c['price'] as int));
        }
      }
      final profit = ticketRevenue - costTotal;
      AppLogger.info('Calculated profit: $profit (revenue=$ticketRevenue, costs=$costTotal)');
      return profit;
    } catch (e, stackTrace) {
      AppLogger.error('Error calculating profit: $e', e, stackTrace);
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    AppLogger.info('Building ReportsScreen');
    final total = enProceso + pendiente + entregado;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportes y Estadísticas'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con título
            const Text(
              'Dashboard de Reportes',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Resumen de actividad y ganancias',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 32),

            // Cards de ganancias
            Row(
              children: [
                Expanded(
                  child: _buildProfitCard(
                    'Hoy',
                    dailyProfit,
                    Icons.today,
                    const Color(0xFF2196F3),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildProfitCard(
                    'Este Mes',
                    monthlyProfit,
                    Icons.calendar_month,
                    const Color(0xFF4CAF50),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildProfitCard(
                    'Este Año',
                    yearlyProfit,
                    Icons.calendar_today,
                    const Color(0xFFFF9800),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Gráfico mejorado
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Distribución de Tickets',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Total de tickets: $total',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 32),

                  if (total > 0) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Gráfico de dona
                        Expanded(
                          flex: 2,
                          child: SizedBox(
                            height: 280,
                            child: PieChart(
                              PieChartData(
                                sections: [
                                  PieChartSectionData(
                                    color: const Color(0xFFFF9800),
                                    value: enProceso.toDouble(),
                                    title: '${((enProceso / total) * 100).toStringAsFixed(0)}%',
                                    radius: 80,
                                    titleStyle: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  PieChartSectionData(
                                    color: const Color(0xFFF44336),
                                    value: pendiente.toDouble(),
                                    title: '${((pendiente / total) * 100).toStringAsFixed(0)}%',
                                    radius: 80,
                                    titleStyle: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  PieChartSectionData(
                                    color: const Color(0xFF4CAF50),
                                    value: entregado.toDouble(),
                                    title: '${((entregado / total) * 100).toStringAsFixed(0)}%',
                                    radius: 80,
                                    titleStyle: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                                sectionsSpace: 4,
                                centerSpaceRadius: 60,
                                centerSpaceColor: const Color(0xFFF5F7FA),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 32),

                        // Leyenda
                        Expanded(
                          flex: 1,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildLegendItem(
                                'En Proceso',
                                enProceso,
                                const Color(0xFFFF9800),
                              ),
                              const SizedBox(height: 20),
                              _buildLegendItem(
                                'Pendiente',
                                pendiente,
                                const Color(0xFFF44336),
                              ),
                              const SizedBox(height: 20),
                              _buildLegendItem(
                                'Entregado',
                                entregado,
                                const Color(0xFF4CAF50),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          children: [
                            Icon(
                              Icons.inbox_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No hay tickets registrados',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfitCard(String label, int amount, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color,
            color.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const Spacer(),
              Icon(
                amount >= 0 ? Icons.trending_up : Icons.trending_down,
                color: Colors.white,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            currencyFormat.format(amount),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, int count, Color color) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$count tickets',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}