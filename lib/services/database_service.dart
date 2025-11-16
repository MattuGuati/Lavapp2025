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
}