import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:developer' as developer;

class ApiService {
  final String baseUrl;
  final String? apiKey;
  final String? countryCode;

  ApiService({
    this.baseUrl = 'https://lavapp.innovacore.ar/api',
    this.apiKey,
    this.countryCode = '54', // Default Argentina
  });

  Future<void> sendMessage(String phoneNumber, String message) async {
    // Formatear número según código de país
    String formattedNumber = phoneNumber;
    final code = countryCode ?? '54';

    // Remover espacios y caracteres especiales
    formattedNumber = formattedNumber.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    // Si ya tiene el código de país completo, usarlo, sino agregarlo
    if (!formattedNumber.startsWith(code)) {
      // Para Argentina (54), agregar el 9 de móviles si no lo tiene
      if (code == '54' && !formattedNumber.startsWith('9')) {
        formattedNumber = "${code}9$formattedNumber";
      } else {
        formattedNumber = "$code$formattedNumber";
      }
    } else if (code == '54' && formattedNumber.startsWith('54') && !formattedNumber.startsWith('549')) {
      // Si ya tiene 54 pero le falta el 9, agregarlo
      formattedNumber = '549${formattedNumber.substring(2)}';
    }

    developer.log("Base URL configurada: $baseUrl");
    developer.log("Código de país: $code");
    developer.log("Intentando enviar mensaje a: $baseUrl/v1/messages");

    final headers = <String, String>{
      'Content-Type': 'application/json',
    };

    // Si hay API key, agregarla al header
    if (apiKey != null && apiKey!.isNotEmpty) {
      headers['X-API-Key'] = apiKey!;
      developer.log("Usando API Key personalizada");
    }

    final response = await http.post(
      Uri.parse('$baseUrl/v1/messages'),
      headers: headers,
      body: jsonEncode({
        'number': "$formattedNumber@s.whatsapp.net",
        'message': message,
      }),
    );

    if (response.statusCode == 200) {
      developer.log("✅ Mensaje enviado correctamente a +$formattedNumber");
    } else {
      developer.log("❌ Error al enviar mensaje: ${response.body}");
      throw Exception('Error al enviar mensaje: ${response.body}');
    }
  }

  Future<void> deleteWhatsappSession() async {
    developer.log("Intentando eliminar sesión de WhatsApp: $baseUrl/delete-session");

    final response = await http.post(
      Uri.parse('$baseUrl/delete-session'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      developer.log("✅ Sesión de WhatsApp eliminada correctamente");
    } else {
      developer.log("❌ Error al eliminar sesión: ${response.body}");
      throw Exception('Error al eliminar sesión: ${response.body}');
    }
  }
}