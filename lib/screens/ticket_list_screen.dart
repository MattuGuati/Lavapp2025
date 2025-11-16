import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/database_service.dart';
import '../services/api_service.dart';
import '../utils/logger.dart';
import '../models/user.dart';
import 'new_ticket_screen.dart';
import 'consult_tickets_screen.dart';
import 'reports_screen.dart';
import 'cost_screen.dart';
import 'clients_screen.dart';
import 'preferences_screen.dart';
import 'edit_ticket_screen.dart';
import 'users_screen.dart';

class TicketListScreen extends StatefulWidget {
  const TicketListScreen({super.key});

  @override
  State<TicketListScreen> createState() => _TicketListScreenState();
}

class _TicketListScreenState extends State<TicketListScreen> {
  List<Map<String, dynamic>> tickets = [];
  final DatabaseService dbService = DatabaseService();
  ApiService apiService = ApiService();
  int costPerBag = 500;
  bool isLoggedIn = false;
  String? currentUser;
  UserModel? currentUserData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    AppLogger.info('Initializing TicketListScreen');
    _checkSession();
  }

  Future<void> _checkSession() async {
    try {
      AppLogger.info('Checking session...');
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? savedUsername = prefs.getString('username');
      if (savedUsername != null) {
        AppLogger.info('Session found for user: $savedUsername');

        // Cargar datos del usuario desde Firestore
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(savedUsername)
            .get();

        if (userDoc.exists && userDoc.data() != null) {
          try {
            currentUserData = UserModel.fromMap(userDoc.data()!);
            AppLogger.info('User data loaded successfully for: $savedUsername');

            // Configurar API service con la API key del usuario si existe
            if (currentUserData!.whatsappApiKey != null &&
                currentUserData!.whatsappApiKey!.isNotEmpty) {
              apiService = ApiService(
                apiKey: currentUserData!.whatsappApiKey,
                countryCode: currentUserData!.countryCode,
              );
            }

            setState(() {
              isLoggedIn = true;
              currentUser = savedUsername;
              isLoading = false;
            });
            _loadPreferences();
          } catch (parseError, parseStackTrace) {
            // Error parseando los datos del usuario
            AppLogger.error('Error parsing user data for $savedUsername: $parseError', parseError, parseStackTrace);
            SharedPreferences prefs = await SharedPreferences.getInstance();
            await prefs.remove('username');
            setState(() {
              isLoading = false;
            });
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Error al cargar datos del usuario. Por favor, vuelva a iniciar sesión.')),
              );
            }
            _showLoginDialog();
          }
        } else {
          // Usuario en SharedPreferences pero no en Firestore
          AppLogger.error('User $savedUsername not found in Firestore');
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.remove('username');
          setState(() {
            isLoading = false;
          });
          _showLoginDialog();
        }
      } else {
        AppLogger.info('No session found, showing login dialog');
        setState(() {
          isLoading = false;
        });
        _showLoginDialog();
      }
    } catch (e, stackTrace) {
      print('Error checking session: $e\
$stackTrace'); // Usamos print en lugar de AppLogger.error
      setState(() {
        isLoading = false;
      });
      _showLoginDialog();
    }
  }

  void _showLoginDialog() {
    String username = '';
    String password = '';
    String? errorMessage;
    bool isPasswordVisible = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) => StatefulBuilder(
        builder: (BuildContext dialogContext, StateSetter setDialogState) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            elevation: 8,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white,
                    const Color(0xFFF5F7FA),
                  ],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2196F3).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person_outline,
                        size: 48,
                        color: Color(0xFF2196F3),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Bienvenido a LavApp',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Ingresa tus credenciales',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 32),
                    if (errorMessage != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline, color: Colors.red[700], size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                errorMessage!,
                                style: TextStyle(
                                  color: Colors.red[700],
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    TextField(
                      decoration: InputDecoration(
                        labelText: 'Usuario',
                        hintText: 'Ingresa tu usuario',
                        prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF2196F3)),
                      ),
                      onChanged: (value) {
                        username = value;
                        setDialogState(() {
                          errorMessage = null;
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      decoration: InputDecoration(
                        labelText: 'Contraseña',
                        hintText: 'Ingresa tu contraseña',
                        prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF2196F3)),
                        suffixIcon: IconButton(
                          icon: Icon(
                            isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                            color: Colors.grey[600],
                          ),
                          onPressed: () {
                            setDialogState(() {
                              isPasswordVisible = !isPasswordVisible;
                            });
                          },
                        ),
                      ),
                      obscureText: !isPasswordVisible,
                      onChanged: (value) {
                        password = value;
                        setDialogState(() {
                          errorMessage = null;
                        });
                      },
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2196F3),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        onPressed: () async {
                          if (username.isEmpty || password.isEmpty) {
                            setDialogState(() {
                              errorMessage = 'Por favor, complete todos los campos.';
                            });
                            return;
                          }

                      try {
                        AppLogger.info('Attempting login for user: $username');
                        final userDoc = await FirebaseFirestore.instance
                            .collection('users')
                            .doc(username)
                            .get();

                        if (userDoc.exists) {
                          final userData = userDoc.data();
                          if (userData == null) {
                            throw Exception('El documento del usuario existe pero los datos son null');
                          }
                          if (userData['password'] == password) {
                            AppLogger.info('Login successful for user: $username');

                            // Cargar datos completos del usuario
                            currentUserData = UserModel.fromMap(userData);

                            // Configurar API service con la API key del usuario si existe
                            if (currentUserData!.whatsappApiKey != null &&
                                currentUserData!.whatsappApiKey!.isNotEmpty) {
                              apiService = ApiService(
                                apiKey: currentUserData!.whatsappApiKey,
                                countryCode: currentUserData!.countryCode,
                              );
                            }

                            SharedPreferences prefs = await SharedPreferences.getInstance();
                            await prefs.setString('username', username);
                            setState(() {
                              isLoggedIn = true;
                              currentUser = username;
                            });
                            _loadPreferences();
                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext);
                            }
                          } else {
                            setDialogState(() {
                              errorMessage = 'Contraseña incorrecta.';
                            });
                          }
                        } else {
                          AppLogger.info('User not found, creating new user: $username');
                          await FirebaseFirestore.instance
                              .collection('users')
                              .doc(username)
                              .set(
                            {
                              'username': username,
                              'password': password,
                              'role': 'user',
                              'permissions': {
                                'preferences': false,
                                'consultTickets': true,
                                'reports': false,
                                'costs': false,
                                'clients': true,
                                'users': false,
                              },
                            },
                            SetOptions(merge: true),
                          );

                          // Cargar datos del usuario recién creado
                          final newUserDoc = await FirebaseFirestore.instance
                              .collection('users')
                              .doc(username)
                              .get();

                          if (newUserDoc.exists && newUserDoc.data() != null) {
                            currentUserData = UserModel.fromMap(newUserDoc.data()!);
                            AppLogger.info('Loaded data for newly created user: $username');

                            // Configurar API service si tiene whatsappApiKey
                            if (currentUserData!.whatsappApiKey != null &&
                                currentUserData!.whatsappApiKey!.isNotEmpty) {
                              apiService = ApiService(
                                apiKey: currentUserData!.whatsappApiKey,
                                countryCode: currentUserData!.countryCode,
                              );
                            }
                          }

                          SharedPreferences prefs = await SharedPreferences.getInstance();
                          await prefs.setString('username', username);
                          setState(() {
                            isLoggedIn = true;
                            currentUser = username;
                          });
                          _loadPreferences();
                          if (dialogContext.mounted) {
                            Navigator.pop(dialogContext);
                          }
                        }
                      } catch (e, stackTrace) {
                        print('Error during login: $e\
$stackTrace'); // Usamos print en lugar de AppLogger.error
                        setDialogState(() {
                          errorMessage = 'Error al iniciar sesión: $e';
                        });
                      }
                    },
                    child: const Text(
                      'Iniciar Sesión',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                ],
              ),
            ),
          ),
        );
        },
      ),
    );
  }

  Future<void> _loadPreferences() async {
    if (!isLoggedIn) {
      AppLogger.warning('Cannot load preferences: User not logged in');
      return;
    }
    try {
      AppLogger.info('Loading preferences via DatabaseService...');
      final prefs = await dbService.getPreferences();
      if (mounted) {
        setState(() {
          costPerBag = prefs?['costPerBag'] ?? 500;
        });
        AppLogger.info('Preferences loaded: costPerBag = $costPerBag');
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error loading preferences: $e', e, stackTrace);
    }
  }

  Future<void> _addNewTicket() async {
    if (!isLoggedIn) {
      AppLogger.warning('Cannot add new ticket: User not logged in');
      _showLoginDialog();
      return;
    }
    try {
      AppLogger.info('Navigating to NewTicketScreen to create a new ticket');
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const NewTicketScreen()),
      );
      if (result != null && result is Map<String, dynamic> && mounted) {
        AppLogger.info('New ticket data received: $result');
        if ((result['cantidadBolsas'] as int? ?? 0) <= 0 &&
            (result['extras']?.isEmpty ?? true) &&
            (result['counterExtras']?.isEmpty ?? true)) {
          AppLogger.warning('Validation failed: Ticket must have bags or extras');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Debe seleccionar al menos cantidad de bolsas o extras.')),
            );
          }
          return;
        }
        result['usuario'] = currentUser;
        result['timestamp'] = DateTime.now().toIso8601String();
        final docId = await dbService.insertTicket(result);
        if (docId.isNotEmpty) {
          AppLogger.info('Ticket inserted successfully with docId: $docId');
          result['docId'] = docId;
        } else {
          AppLogger.error('Error: docId is null or empty after insert for ticket: $result');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Error al crear el ticket: ID no generado')),
            );
          }
        }
      } else {
        AppLogger.info('No ticket data returned from NewTicketScreen');
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error adding new ticket: $e', e, stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al crear el ticket: $e')),
        );
      }
    }
  }

  Future<void> _editTicket(int index) async {
    if (!isLoggedIn || index >= tickets.length) {
      AppLogger.warning('Cannot edit ticket: User not logged in or invalid index');
      _showLoginDialog();
      return;
    }
    try {
      AppLogger.info('Editing ticket at index $index');
      final ticket = Map<String, dynamic>.from(tickets[index]);
      final docId = await _getDocIdFromIndex(index);
      if (docId.isNotEmpty && mounted) {
        AppLogger.info('Navigating to EditTicketScreen with ticket: $ticket');
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => EditTicketScreen(ticket: ticket)),
        );
        if (result != null && result is Map<String, dynamic> && mounted) {
          AppLogger.info('Updating ticket with docId $docId: $result');
          await dbService.updateTicket(docId, result);
        } else {
          AppLogger.info('No updated ticket data returned from EditTicketScreen');
        }
      } else {
        AppLogger.error('Error: Could not obtain docId for ticket: $ticket');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error al editar el ticket: No se pudo obtener el ID')),
          );
        }
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error editing ticket: $e', e, stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al editar el ticket: $e')),
        );
      }
    }
  }

  Future<void> _changeTicketStatus(int index) async {
    if (!isLoggedIn || index >= tickets.length) {
      AppLogger.warning('Cannot change ticket status: User not logged in or invalid index');
      _showLoginDialog();
      return;
    }
    try {
      AppLogger.info('Changing ticket status at index $index');
      final estados = ['En Proceso', 'Pendiente', 'Entregado'];
      final currentIndex = estados.indexOf(tickets[index]['estado']);
      final newIndex = (currentIndex + 1) % estados.length;
      final newStatus = estados[newIndex];

      setState(() {
        tickets[index]['estado'] = newStatus;
      });

      String? docId = tickets[index]['docId'] as String?;
      if (docId == null || docId.isEmpty) {
        docId = await _getDocIdFromIndex(index);
        if (docId.isNotEmpty) {
          tickets[index]['docId'] = docId;
        } else {
          AppLogger.error('Error: docId is null or empty for ticket: ${tickets[index]}');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Error al cambiar el estado: No se pudo obtener el ID')),
            );
          }
          return;
        }
      }

      AppLogger.info('Updating ticket status in Firestore: docId=$docId, newStatus=$newStatus');
      await dbService.updateTicketStatus(docId, newStatus, isArchived: false);

      if (newStatus == 'Entregado' && index < tickets.length) {
        AppLogger.info('Archiving ticket with docId: $docId');
        await dbService.archiveTicket(docId);
        if (mounted) {
          setState(() {
            tickets.removeAt(index);
          });
          _showRevertOption(index, estados[currentIndex]);
        }
      }

      if (index < tickets.length && tickets[index]['estado'] == 'Pendiente' && mounted) {
        AppLogger.info('Sending WhatsApp message for ticket at index $index');
        await _sendWhatsAppMessage(index);
      } else if (mounted && newStatus != 'Entregado') {
        AppLogger.info('Showing revert option for status change');
        _showRevertOption(index, estados[currentIndex]);
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error changing ticket status: $e', e, stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cambiar el estado del ticket: $e')),
        );
      }
    }
  }

  Future<void> _deleteTicket(int index) async {
    if (!isLoggedIn || index >= tickets.length) {
      AppLogger.warning('Cannot delete ticket: User not logged in or invalid index');
      _showLoginDialog();
      return;
    }
    try {
      AppLogger.info('Deleting ticket at index $index');
      String? docId = tickets[index]['docId'] as String?;
      if (docId == null || docId.isEmpty) {
        docId = await _getDocIdFromIndex(index);
      }
      if (docId.isNotEmpty) {
        AppLogger.info('Deleting ticket with docId: $docId');
        await dbService.deleteTicket(docId, isArchived: false);
      } else {
        AppLogger.error('Error: docId is null or empty for ticket at index $index');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error al eliminar el ticket: No se pudo obtener el ID')),
          );
        }
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error deleting ticket: $e', e, stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al eliminar el ticket: $e')),
        );
      }
    }
  }

  Future<String> _getDocIdFromIndex(int index) async {
    try {
      AppLogger.info('Getting docId for ticket at index $index');
      final ticket = tickets[index];

      // Si ya tiene docId, retornarlo directamente
      if (ticket['docId'] != null && (ticket['docId'] as String).isNotEmpty) {
        AppLogger.info('docId already present: ${ticket['docId']}');
        return ticket['docId'] as String;
      }

      // Buscar en la colección del usuario
      final isArchived = ticket['estado'] == 'Entregado';
      final collectionName = isArchived ? 'archivedTickets' : 'tickets';
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser)
          .collection(collectionName)
          .where('nombre', isEqualTo: ticket['nombre'])
          .where('celular', isEqualTo: ticket['celular'])
          .where('cantidadBolsas', isEqualTo: ticket['cantidadBolsas'])
          .where('estado', isEqualTo: ticket['estado'])
          .where('timestamp', isEqualTo: ticket['timestamp'])
          .limit(1)
          .get();
      if (querySnapshot.docs.isNotEmpty) {
        final docId = querySnapshot.docs.first.id;
        AppLogger.info('Found docId: $docId');
        return docId;
      } else {
        AppLogger.warning('No docId found for ticket at index $index');
        return '';
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error getting docId: $e', e, stackTrace);
      return '';
    }
  }

  void _showRevertOption(int index, String previousState) {
    AppLogger.info('Showing revert option for index $index, previous state: $previousState');
    final snackBar = SnackBar(
      content: const Text('¿Revertir estado?'),
      action: SnackBarAction(
        label: 'Revertir',
        textColor: Colors.blue,
        onPressed: () async {
          if (mounted && index < tickets.length) {
            try {
              AppLogger.info('Reverting ticket state to $previousState');
              setState(() {
                tickets[index]['estado'] = previousState;
              });
              final docId = await _getDocIdFromIndex(index);
              if (docId.isNotEmpty) {
                AppLogger.info('Updating ticket status to $previousState with docId: $docId');
                await dbService.updateTicketStatus(docId, previousState, isArchived: false);
              } else {
                AppLogger.error('Error: Could not obtain docId for revert');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Error al revertir el estado: No se pudo obtener el ID')),
                  );
                }
              }
            } catch (e, stackTrace) {
              AppLogger.error('Error reverting ticket status: $e', e, stackTrace);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error al revertir el estado: $e')),
                );
              }
            }
          }
        },
      ),
      duration: const Duration(seconds: 5),
      backgroundColor: Colors.grey[800],
    );
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(snackBar);
        }
      });
    }
  }

  Future<void> _sendWhatsAppMessage(int index) async {
    if (!isLoggedIn || index >= tickets.length) {
      AppLogger.warning('Cannot send WhatsApp message: User not logged in or invalid index');
      return;
    }
    try {
      AppLogger.info('Sending WhatsApp message for ticket at index $index');
      final ticket = tickets[index];
      final String phoneNumber = ticket['celular'] ?? '';
      if (phoneNumber.isEmpty) {
        AppLogger.error('Error: Phone number is empty for ticket at index $index');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error: Número de teléfono no especificado')),
          );
        }
        return;
      }
      AppLogger.info('Sending message to: $phoneNumber');
      final int cost = ((ticket['cantidadBolsas'] as int) * costPerBag +
          ((ticket['extras'] ?? <String, int>{}).values.fold(0, (total, price) => total + (price as int)))).toInt();

      // Obtener mensaje personalizado via DatabaseService
      const defaultMessage = '¡Hola {nombre} 👋! Ya podés pasar a retirar tu ropa 🧼✨. Costo: \${costo}. Si deseas transferir, podés hacerlo al alias: matteo.peirano.mp. ¡Gracias por elegirnos! 😊🙌';
      String messageTemplate = defaultMessage;

      try {
        final prefs = await dbService.getPreferences();
        if (prefs != null && prefs['whatsappMessage'] != null) {
          messageTemplate = prefs['whatsappMessage'];
        }
      } catch (e) {
        AppLogger.warning('Could not load custom message, using default: $e');
      }

      // Reemplazar variables en el mensaje
      final String message = messageTemplate
          .replaceAll('{nombre}', ticket['nombre'] ?? 'Cliente')
          .replaceAll('{costo}', cost.toString())
          .replaceAll('\${costo}', cost.toString());

      AppLogger.info('Message content: $message');
      await apiService.sendMessage(phoneNumber, message);
      AppLogger.info('WhatsApp message sent successfully');
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Mensaje enviado correctamente')),
            );
          }
        });
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error sending WhatsApp message: $e', e, stackTrace);
      if (mounted) {
        // Intentar parsear el error para mostrar un mensaje más amigable
        String errorMessage = 'Error al enviar mensaje: $e';

        try {
          final errorStr = e.toString();
          if (errorStr.contains('WhatsApp no conectado')) {
            // Extraer el API key del mensaje de error si está disponible
            final match = RegExp(r'/qr/([^"]+)').firstMatch(errorStr);
            final apiKey = match?.group(1) ?? currentUserData?.whatsappApiKey ?? 'desconocido';

            if (apiKey == 'default') {
              errorMessage = 'WhatsApp no conectado. Por favor, contacte al administrador para configurar su cuenta de WhatsApp.';
            } else if (currentUserData?.whatsappApiKey == null || currentUserData!.whatsappApiKey!.isEmpty) {
              errorMessage = 'WhatsApp no conectado. Su cuenta no tiene configurada una API key de WhatsApp. Contacte al administrador.';
            } else {
              errorMessage = 'WhatsApp no conectado. Escanee el código QR en https://lavapp.innovacore.ar/api/qr/$apiKey';
            }
          }
        } catch (parseError) {
          // Si falla el parseo, usar el mensaje original
          AppLogger.warning('Could not parse error message: $parseError');
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(errorMessage),
                duration: const Duration(seconds: 7),
              ),
            );
          }
        });
      }
    }
  }

  void _goToPreferences() {
    if (!isLoggedIn) {
      AppLogger.warning('Cannot navigate to Preferences: User not logged in');
      _showLoginDialog();
      return;
    }
    AppLogger.info('Navigating to PreferencesScreen');
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PreferencesScreen()),
    );
  }

  void _goToConsultTickets() {
    if (!isLoggedIn) {
      AppLogger.warning('Cannot navigate to ConsultTicketsScreen: User not logged in');
      _showLoginDialog();
      return;
    }
    AppLogger.info('Navigating to ConsultTicketsScreen');
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ConsultTicketsScreen()),
    ).then((_) {
      if (mounted) {
        AppLogger.info('Returned from ConsultTicketsScreen');
      }
    });
  }

  void _goToReports() {
    if (!isLoggedIn) {
      AppLogger.warning('Cannot navigate to ReportsScreen: User not logged in');
      _showLoginDialog();
      return;
    }
    AppLogger.info('Navigating to ReportsScreen');
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ReportsScreen()),
    );
  }

  void _goToCost() {
    if (!isLoggedIn) {
      AppLogger.warning('Cannot navigate to CostScreen: User not logged in');
      _showLoginDialog();
      return;
    }
    AppLogger.info('Navigating to CostScreen');
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CostScreen()),
    );
  }

  void _goToClients() {
    if (!isLoggedIn) {
      AppLogger.warning('Cannot navigate to ClientsScreen: User not logged in');
      _showLoginDialog();
      return;
    }
    AppLogger.info('Navigating to ClientsScreen');
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ClientsScreen()),
    );
  }

  void _goToUsers() {
    if (!isLoggedIn) {
      AppLogger.warning('Cannot navigate to UsersScreen: User not logged in');
      _showLoginDialog();
      return;
    }
    AppLogger.info('Navigating to UsersScreen');
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const UsersScreen()),
    );
  }

  Future<void> _logout() async {
    try {
      AppLogger.info('Logging out user: $currentUser');
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove('username');
      setState(() {
        isLoggedIn = false;
        currentUser = null;
        currentUserData = null;
        tickets.clear();
      });
      _showLoginDialog();
    } catch (e, stackTrace) {
      AppLogger.error('Error during logout: $e', e, stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cerrar sesión: $e')),
        );
      }
    }
  }

  Future<void> _showChangePasswordDialog() async {
    String currentPassword = '';
    String newPassword = '';
    String confirmPassword = '';
    String? errorMessage;
    bool isCurrentPasswordVisible = false;
    bool isNewPasswordVisible = false;
    bool isConfirmPasswordVisible = false;

    await showDialog(
      context: context,
      builder: (BuildContext dialogContext) => StatefulBuilder(
        builder: (BuildContext dialogContext, StateSetter setDialogState) {
          return AlertDialog(
            title: const Text('Cambiar Contraseña'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (errorMessage != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red[700], size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              errorMessage!,
                              style: TextStyle(color: Colors.red[700], fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Contraseña Actual',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          isCurrentPasswordVisible ? Icons.visibility_off : Icons.visibility,
                          color: Colors.grey[600],
                        ),
                        onPressed: () {
                          setDialogState(() {
                            isCurrentPasswordVisible = !isCurrentPasswordVisible;
                          });
                        },
                      ),
                    ),
                    obscureText: !isCurrentPasswordVisible,
                    onChanged: (value) {
                      currentPassword = value;
                      setDialogState(() {
                        errorMessage = null;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Nueva Contraseña',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          isNewPasswordVisible ? Icons.visibility_off : Icons.visibility,
                          color: Colors.grey[600],
                        ),
                        onPressed: () {
                          setDialogState(() {
                            isNewPasswordVisible = !isNewPasswordVisible;
                          });
                        },
                      ),
                    ),
                    obscureText: !isNewPasswordVisible,
                    onChanged: (value) {
                      newPassword = value;
                      setDialogState(() {
                        errorMessage = null;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Confirmar Nueva Contraseña',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          isConfirmPasswordVisible ? Icons.visibility_off : Icons.visibility,
                          color: Colors.grey[600],
                        ),
                        onPressed: () {
                          setDialogState(() {
                            isConfirmPasswordVisible = !isConfirmPasswordVisible;
                          });
                        },
                      ),
                    ),
                    obscureText: !isConfirmPasswordVisible,
                    onChanged: (value) {
                      confirmPassword = value;
                      setDialogState(() {
                        errorMessage = null;
                      });
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (currentPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty) {
                    setDialogState(() {
                      errorMessage = 'Por favor, complete todos los campos.';
                    });
                    return;
                  }

                  if (newPassword != confirmPassword) {
                    setDialogState(() {
                      errorMessage = 'Las contraseñas nuevas no coinciden.';
                    });
                    return;
                  }

                  if (newPassword.length < 6) {
                    setDialogState(() {
                      errorMessage = 'La contraseña debe tener al menos 6 caracteres.';
                    });
                    return;
                  }

                  try {
                    AppLogger.info('Changing password for user: $currentUser');

                    // Verificar contraseña actual
                    final userDoc = await FirebaseFirestore.instance
                        .collection('users')
                        .doc(currentUser)
                        .get();

                    if (!userDoc.exists) {
                      setDialogState(() {
                        errorMessage = 'Usuario no encontrado.';
                      });
                      return;
                    }

                    final userData = userDoc.data();
                    if (userData?['password'] != currentPassword) {
                      setDialogState(() {
                        errorMessage = 'Contraseña actual incorrecta.';
                      });
                      return;
                    }

                    // Actualizar contraseña
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(currentUser)
                        .update({'password': newPassword});

                    AppLogger.info('Password changed successfully for user: $currentUser');

                    if (dialogContext.mounted) {
                      Navigator.pop(dialogContext);
                    }

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Contraseña cambiada exitosamente'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e, stackTrace) {
                    AppLogger.error('Error changing password: $e', e, stackTrace);
                    setDialogState(() {
                      errorMessage = 'Error al cambiar la contraseña: $e';
                    });
                  }
                },
                child: const Text('Cambiar'),
              ),
            ],
          );
        },
      ),
    );
  }

  bool _hasPermission(String permission) {
    if (currentUserData == null) return false;
    if (currentUserData!.role == 'admin') return true;
    return currentUserData!.permissions[permission] ?? false;
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      AppLogger.info('Building: Showing loading indicator');
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (!isLoggedIn) {
      AppLogger.info('Building: User not logged in, showing empty container');
      return Container();
    }

    AppLogger.info('Building: Rendering ticket list for user $currentUser');
    return Scaffold(
      appBar: AppBar(
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'LavApp',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              currentUser ?? '',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        centerTitle: true,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.vpn_key, color: Colors.white),
            tooltip: 'Cambiar Contraseña',
            onPressed: _showChangePasswordDialog,
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Cerrar Sesión',
            onPressed: () async {
              final shouldLogout = await showDialog<bool>(
                context: context,
                builder: (BuildContext context) => AlertDialog(
                  title: const Text('Cerrar Sesión'),
                  content: const Text('¿Está seguro que desea cerrar sesión?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancelar'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Cerrar Sesión'),
                    ),
                  ],
                ),
              );

              if (shouldLogout == true) {
                _logout();
              }
            },
          ),
        ],
      ),
      drawer: Drawer(
        width: 280,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).primaryColor,
                    Theme.of(context).primaryColor.withOpacity(0.7),
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.white,
                        radius: 30,
                        child: Text(
                          (currentUser?.isNotEmpty ?? false) ? currentUser![0].toUpperCase() : 'U',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                      if (currentUserData?.role == 'admin')
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            Icons.admin_panel_settings,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    currentUser ?? "Usuario",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    currentUserData?.role == 'admin' ? 'Administrador' : 'Usuario',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'MENÚ PRINCIPAL',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            if (_hasPermission('preferences'))
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.settings, color: Colors.purple, size: 24),
                ),
                title: const Text('Preferencias'),
                onTap: () {
                  Navigator.pop(context);
                  _goToPreferences();
                },
              ),
            if (_hasPermission('consultTickets'))
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.search, color: Colors.blue, size: 24),
                ),
                title: const Text('Consultar Tickets'),
                onTap: () {
                  Navigator.pop(context);
                  _goToConsultTickets();
                },
              ),
            if (_hasPermission('reports'))
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.bar_chart, color: Colors.green, size: 24),
                ),
                title: const Text('Reportes'),
                onTap: () {
                  Navigator.pop(context);
                  _goToReports();
                },
              ),
            if (_hasPermission('costs'))
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.attach_money, color: Colors.orange, size: 24),
                ),
                title: const Text('Costos'),
                onTap: () {
                  Navigator.pop(context);
                  _goToCost();
                },
              ),
            if (_hasPermission('clients'))
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.teal.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.people, color: Colors.teal, size: 24),
                ),
                title: const Text('Clientes'),
                onTap: () {
                  Navigator.pop(context);
                  _goToClients();
                },
              ),
            if (_hasPermission('users'))
              const Divider(height: 32, indent: 16, endIndent: 16),
            if (_hasPermission('users'))
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Text(
                  'ADMINISTRACIÓN',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            if (_hasPermission('users'))
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.supervised_user_circle, color: Colors.red, size: 24),
                ),
                title: const Text(
                  'Gestión de Usuarios',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _goToUsers();
                },
              ),
          ],
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser)
            .collection('tickets')
            .where('estado', whereIn: ['En Proceso', 'Pendiente'])
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            AppLogger.info('StreamBuilder: Loading tickets...');
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            AppLogger.error('StreamBuilder: Error loading tickets: ${snapshot.error}', snapshot.error, snapshot.stackTrace);
            return Center(
              child: Text(
                'Error al cargar tickets: ${snapshot.error}',
                style: const TextStyle(color: Colors.red, fontSize: 16),
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            AppLogger.info('StreamBuilder: No tickets available');
            return const Center(
              child: Text(
                'No hay tickets disponibles',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            );
          }

          AppLogger.info('StreamBuilder: Tickets loaded, count: ${snapshot.data!.docs.length}');
          tickets = snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            data['docId'] = doc.id;
            return data;
          }).toList();

          return ListView.builder(
            itemCount: tickets.length,
            itemBuilder: (context, index) {
              final ticket = tickets[index];
              Color stateColor;
              switch (ticket['estado']) {
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
              int totalCost = (ticket['cantidadBolsas'] as int) * costPerBag;
              if (ticket['extras'] != null && ticket['extras'] is Map) {
                totalCost += (ticket['extras'] as Map).values.fold(0, (acc, p) => acc + (p as int));
              }
              return Card(
                margin: const EdgeInsets.all(8.0),
                child: ListTile(
                  title: Text("${ticket['nombre'] ?? 'Sin nombre'} #${ticket['celular'] ?? 'Sin celular'}"),
                  subtitle: Text("Costo: \$$totalCost"),
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
                          ticket['estado'],
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      PopupMenuButton(
                        onSelected: (value) {
                          if (value == 'edit') {
                            _editTicket(index);
                          } else if (value == 'delete') {
                            _deleteTicket(index);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(value: 'edit', child: Text('Editar')),
                          const PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                        ],
                      ),
                    ],
                  ),
                  onTap: () => _changeTicketStatus(index),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.lightBlue,
        onPressed: _addNewTicket,
        label: const Text("Crear Ticket", style: TextStyle(color: Colors.white)),
        icon: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}