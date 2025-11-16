import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';
import '../utils/logger.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  List<UserModel> users = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    AppLogger.info('Initializing UsersScreen');
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      AppLogger.info('Loading users from Firestore');
      if (mounted) setState(() => isLoading = true);

      final snapshot = await FirebaseFirestore.instance.collection('users').get();
      if (mounted) {
        setState(() {
          users = snapshot.docs
              .map((doc) => UserModel.fromMap(doc.data()))
              .toList();
          isLoading = false;
        });
        AppLogger.info('Loaded ${users.length} users');
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error loading users: $e', e, stackTrace);
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar usuarios: $e')),
        );
      }
    }
  }

  Future<void> _showUserDialog({UserModel? user}) async {
    final isEdit = user != null;
    final usernameController = TextEditingController(text: user?.username ?? '');
    final passwordController = TextEditingController(text: user?.password ?? '');
    final phoneController = TextEditingController(text: user?.phone ?? '');
    final apiKeyController = TextEditingController(text: user?.whatsappApiKey ?? '');
    final countryCodeController = TextEditingController(text: user?.countryCode ?? '54');

    String selectedRole = user?.role ?? 'user';
    Map<String, bool> permissions = Map.from(user?.permissions ?? {
      'preferences': false,
      'consultTickets': true,
      'reports': false,
      'costs': false,
      'clients': true,
      'users': false,
    });

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(isEdit ? 'Editar Usuario' : 'Nuevo Usuario'),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 500,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Username
                  TextField(
                    controller: usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Usuario',
                      border: OutlineInputBorder(),
                    ),
                    enabled: !isEdit,
                  ),
                  const SizedBox(height: 16),

                  // Password
                  TextField(
                    controller: passwordController,
                    decoration: InputDecoration(
                      labelText: isEdit ? 'Nueva Contraseña (dejar vacío para mantener)' : 'Contraseña',
                      border: const OutlineInputBorder(),
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 16),

                  // Phone
                  TextField(
                    controller: phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Teléfono de Contacto',
                      border: OutlineInputBorder(),
                      hintText: 'Ej: 3468599350',
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),

                  // Country Code
                  TextField(
                    controller: countryCodeController,
                    decoration: const InputDecoration(
                      labelText: 'Código de País (sin +)',
                      border: OutlineInputBorder(),
                      hintText: '54 para Argentina, 1 para USA, 52 para México',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),

                  // WhatsApp API Key
                  TextField(
                    controller: apiKeyController,
                    decoration: const InputDecoration(
                      labelText: 'API Key de WhatsApp (opcional)',
                      border: OutlineInputBorder(),
                      hintText: 'Para vincular número propio de WhatsApp',
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Role
                  DropdownButtonFormField<String>(
                    value: selectedRole,
                    decoration: const InputDecoration(
                      labelText: 'Rol',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'user', child: Text('Usuario')),
                      DropdownMenuItem(value: 'admin', child: Text('Administrador')),
                    ],
                    onChanged: (value) {
                      setDialogState(() {
                        selectedRole = value!;
                        if (selectedRole == 'admin') {
                          permissions = UserModel.adminPermissions();
                        } else {
                          permissions = {
                            'preferences': false,
                            'consultTickets': true,
                            'reports': false,
                            'costs': false,
                            'clients': true,
                            'users': false,
                          };
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Permissions
                  const Text(
                    'Permisos de Acceso:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),

                  CheckboxListTile(
                    title: const Text('Preferencias'),
                    subtitle: const Text('Configurar costos, mensajes, atributos'),
                    value: permissions['preferences'] ?? false,
                    enabled: selectedRole != 'admin',
                    onChanged: (value) {
                      setDialogState(() {
                        permissions['preferences'] = value ?? false;
                      });
                    },
                  ),
                  CheckboxListTile(
                    title: const Text('Consultar Tickets'),
                    subtitle: const Text('Ver historial de todos los tickets'),
                    value: permissions['consultTickets'] ?? false,
                    enabled: selectedRole != 'admin',
                    onChanged: (value) {
                      setDialogState(() {
                        permissions['consultTickets'] = value ?? false;
                      });
                    },
                  ),
                  CheckboxListTile(
                    title: const Text('Reportes'),
                    subtitle: const Text('Ver estadísticas y ganancias'),
                    value: permissions['reports'] ?? false,
                    enabled: selectedRole != 'admin',
                    onChanged: (value) {
                      setDialogState(() {
                        permissions['reports'] = value ?? false;
                      });
                    },
                  ),
                  CheckboxListTile(
                    title: const Text('Costos'),
                    subtitle: const Text('Gestionar gastos'),
                    value: permissions['costs'] ?? false,
                    enabled: selectedRole != 'admin',
                    onChanged: (value) {
                      setDialogState(() {
                        permissions['costs'] = value ?? false;
                      });
                    },
                  ),
                  CheckboxListTile(
                    title: const Text('Clientes'),
                    subtitle: const Text('Gestionar base de clientes'),
                    value: permissions['clients'] ?? false,
                    enabled: selectedRole != 'admin',
                    onChanged: (value) {
                      setDialogState(() {
                        permissions['clients'] = value ?? false;
                      });
                    },
                  ),
                  if (selectedRole == 'admin')
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Los administradores tienen todos los permisos',
                              style: TextStyle(color: Colors.blue, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  if (usernameController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('El usuario es requerido')),
                    );
                    return;
                  }

                  if (!isEdit && passwordController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('La contraseña es requerida')),
                    );
                    return;
                  }

                  final userData = {
                    'username': usernameController.text.trim(),
                    'role': selectedRole,
                    'phone': phoneController.text.trim(),
                    'whatsappApiKey': apiKeyController.text.trim(),
                    'countryCode': countryCodeController.text.trim(),
                    'permissions': permissions,
                  };

                  if (isEdit) {
                    // Solo actualizar password si se ingresó uno nuevo
                    if (passwordController.text.trim().isNotEmpty) {
                      userData['password'] = passwordController.text.trim();
                    }

                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.username)
                        .update(userData);

                    AppLogger.info('User updated: ${user.username}');
                  } else {
                    userData['password'] = passwordController.text.trim();
                    userData['createdAt'] = FieldValue.serverTimestamp();

                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(usernameController.text.trim())
                        .set(userData);

                    AppLogger.info('User created: ${usernameController.text}');
                  }

                  if (mounted) {
                    Navigator.pop(dialogContext);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(isEdit ? 'Usuario actualizado' : 'Usuario creado'),
                      ),
                    );
                    _loadUsers();
                  }
                } catch (e, stackTrace) {
                  AppLogger.error('Error saving user: $e', e, stackTrace);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              },
              child: Text(isEdit ? 'Actualizar' : 'Crear'),
            ),
          ],
        ),
      ),
    );

    usernameController.dispose();
    passwordController.dispose();
    phoneController.dispose();
    apiKeyController.dispose();
    countryCodeController.dispose();
  }

  Future<void> _deleteUser(UserModel user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text('¿Está seguro de eliminar al usuario "${user.username}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.username)
            .delete();

        AppLogger.info('User deleted: ${user.username}');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Usuario eliminado')),
          );
          _loadUsers();
        }
      } catch (e, stackTrace) {
        AppLogger.error('Error deleting user: $e', e, stackTrace);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al eliminar: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Usuarios', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : users.isEmpty
              ? const Center(
                  child: Text(
                    'No hay usuarios registrados',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: user.role == 'admin'
                              ? Colors.orange
                              : Colors.blue,
                          child: Icon(
                            user.role == 'admin'
                                ? Icons.admin_panel_settings
                                : Icons.person,
                            color: Colors.white,
                          ),
                        ),
                        title: Text(
                          user.username,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Rol: ${user.role == 'admin' ? 'Administrador' : 'Usuario'}'),
                            if (user.phone != null && user.phone!.isNotEmpty)
                              Text('Tel: +${user.countryCode} ${user.phone}'),
                            if (user.whatsappApiKey != null && user.whatsappApiKey!.isNotEmpty)
                              const Text(
                                'WhatsApp vinculado ✓',
                                style: TextStyle(color: Colors.green, fontSize: 12),
                              ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _showUserDialog(user: user),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteUser(user),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showUserDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Usuario'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
    );
  }
}
