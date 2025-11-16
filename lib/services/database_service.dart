import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/logger.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> insertTicket(Map<String, dynamic> ticket) async {
    try {
      AppLogger.info('Inserting ticket: $ticket');
      final docRef = await _firestore.collection('tickets').add(ticket);
      AppLogger.info('Ticket inserted with docId: ${docRef.id}');
      return docRef.id;
    } catch (e, stackTrace) {
      AppLogger.error('Error inserting ticket: $e', e, stackTrace);
      return '';
    }
  }

  Future<void> updateTicket(String docId, Map<String, dynamic> ticket) async {
    try {
      AppLogger.info('Updating ticket with docId $docId: $ticket');
      await _firestore.collection('tickets').doc(docId).update(ticket);
      AppLogger.info('Ticket updated successfully');
    } catch (e, stackTrace) {
      AppLogger.error('Error updating ticket: $e', e, stackTrace);
      rethrow;
    }
  }

  Future<void> updateTicketStatus(String docId, String status, {bool isArchived = false}) async {
    try {
      final collection = isArchived ? _firestore.collection('archivedTickets') : _firestore.collection('tickets');
      AppLogger.info('Updating ticket status for docId $docId to $status');
      await collection.doc(docId).update({'estado': status});
      AppLogger.info('Ticket status updated successfully');
    } catch (e, stackTrace) {
      AppLogger.error('Error updating ticket status: $e', e, stackTrace);
      rethrow;
    }
  }

  Future<void> restoreTicket(String docId) async {
    try {
      AppLogger.info('Restoring ticket with docId: $docId');
      final ticketDoc = await _firestore.collection('archivedTickets').doc(docId).get();
      if (ticketDoc.exists) {
        await _firestore.collection('tickets').doc(docId).set(ticketDoc.data()!);
        await _firestore.collection('archivedTickets').doc(docId).delete();
        AppLogger.info('Ticket restored successfully');
      } else {
        AppLogger.warning('Error: Archived ticket with docId $docId does not exist');
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error restoring ticket: $e', e, stackTrace);
      rethrow;
    }
  }

  Future<void> archiveTicket(String docId) async {
    try {
      AppLogger.info('Archiving ticket with docId: $docId');
      final ticketDoc = await _firestore.collection('tickets').doc(docId).get();
      if (ticketDoc.exists) {
        await _firestore.collection('archivedTickets').doc(docId).set(ticketDoc.data()!);
        await _firestore.collection('tickets').doc(docId).delete();
        AppLogger.info('Ticket archived successfully');
      } else {
        AppLogger.warning('Error: Ticket with docId $docId does not exist');
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error archiving ticket: $e', e, stackTrace);
      rethrow;
    }
  }

  Future<void> deleteTicket(String docId, {bool isArchived = false}) async {
    try {
      final collection = isArchived ? _firestore.collection('archivedTickets') : _firestore.collection('tickets');
      AppLogger.info('Deleting ticket with docId $docId from collection ${isArchived ? 'archivedTickets' : 'tickets'}');
      await collection.doc(docId).delete();
      AppLogger.info('Ticket deleted successfully');
    } catch (e, stackTrace) {
      AppLogger.error('Error deleting ticket: $e', e, stackTrace);
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getAllTickets() async {
    try {
      AppLogger.info('Fetching all tickets');
      final snapshot = await _firestore.collection('tickets').get();
      final tickets = snapshot.docs.map((doc) => doc.data()..['docId'] = doc.id).toList();
      AppLogger.info('Fetched ${tickets.length} tickets');
      return tickets;
    } catch (e, stackTrace) {
      AppLogger.error('Error getting tickets: $e', e, stackTrace);
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getAllArchivedTickets() async {
    try {
      AppLogger.info('Fetching all archived tickets');
      final snapshot = await _firestore.collection('archivedTickets').get();
      final tickets = snapshot.docs.map((doc) => doc.data()..['docId'] = doc.id).toList();
      AppLogger.info('Fetched ${tickets.length} archived tickets');
      return tickets;
    } catch (e, stackTrace) {
      AppLogger.error('Error getting archived tickets: $e', e, stackTrace);
      return [];
    }
  }

  // Métodos de preferencias y atributos
  Future<Map<String, dynamic>> getPreferences() async {
    try {
      AppLogger.info('Fetching preferences from Firestore');
      final doc = await _firestore.collection('preferences').doc('settings').get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        AppLogger.info('Preferences loaded: $data');
        return data;
      }

      // Retornar valores por defecto si no existe el documento
      AppLogger.info('No preferences found, returning defaults');
      final defaults = {
        'costPerBag': 500,
        'whatsappMessage': '¡Hola {nombre} 👋! Ya podés pasar a retirar tu ropa 🧼✨. Costo: \${costo}. Si deseas transferir, podés hacerlo al alias: matteo.peirano.mp. ¡Gracias por elegirnos! 😊🙌',
      };
      return defaults;
    } catch (e, stackTrace) {
      AppLogger.error('Error getting preferences: $e', e, stackTrace);
      // Retornar defaults en caso de error
      return {
        'costPerBag': 500,
        'whatsappMessage': '¡Hola {nombre} 👋! Ya podés pasar a retirar tu ropa 🧼✨. Costo: \${costo}. Si deseas transferir, podés hacerlo al alias: matteo.peirano.mp. ¡Gracias por elegirnos! 😊🙌',
      };
    }
  }

  Future<void> updatePreferences(Map<String, dynamic> data) async {
    try {
      AppLogger.info('Updating preferences in Firestore: $data');
      await _firestore.collection('preferences').doc('settings').set(
        data,
        SetOptions(merge: true),
      );
      AppLogger.info('Preferences updated successfully');
    } catch (e, stackTrace) {
      AppLogger.error('Error updating preferences: $e', e, stackTrace);
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getAllAttributes() async {
    try {
      AppLogger.info('Fetching all attributes from Firestore');
      final snapshot = await _firestore.collection('attributes').orderBy('name').get();
      final attributes = snapshot.docs
          .map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          })
          .toList();
      AppLogger.info('Fetched ${attributes.length} attributes');
      return attributes;
    } catch (e, stackTrace) {
      AppLogger.error('Error getting attributes: $e', e, stackTrace);
      return [];
    }
  }

  Future<String> insertAttribute(Map<String, dynamic> attribute) async {
    try {
      AppLogger.info('Inserting attribute into Firestore: $attribute');

      // Validar datos antes de insertar
      if (!attribute.containsKey('name') || !attribute.containsKey('price')) {
        AppLogger.error('Invalid attribute data: missing name or price');
        return '';
      }

      final docRef = await _firestore.collection('attributes').add(attribute);
      AppLogger.info('Attribute inserted successfully with ID: ${docRef.id}');
      return docRef.id;
    } catch (e, stackTrace) {
      AppLogger.error('Error inserting attribute: $e', e, stackTrace);
      return '';
    }
  }

  Future<void> deleteAttribute(String id) async {
    try {
      AppLogger.info('Deleting attribute with id: $id from Firestore');
      await _firestore.collection('attributes').doc(id).delete();
      AppLogger.info('Attribute deleted successfully');
    } catch (e, stackTrace) {
      AppLogger.error('Error deleting attribute: $e', e, stackTrace);
      rethrow;
    }
  }
}