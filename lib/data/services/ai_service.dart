import 'dart:convert';
import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'local_ml_service.dart';

class AIService {
  late final GenerativeModel _model;
  final LocalMLService _localMLService = LocalMLService();
  
  bool _geminiAvailable = false;
  bool useLocalML = true; // Por defecto usar ML local
  
  AIService() {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    
    if (apiKey != null && apiKey.isNotEmpty) {
      // Inicializar el modelo Gemini Flash para análisis de imágenes
      _model = GenerativeModel(
        model: 'gemini-1.5-flash', 
        apiKey: apiKey,
      );
      _geminiAvailable = true;
      print('✅ Gemini API disponible como respaldo');
    } else {
      print('⚠️ GEMINI_API_KEY no configurada - solo ML local disponible');
    }
    
    // Inicializar ML local
    _initializeLocalML();
  }
  
  Future<void> _initializeLocalML() async {
    try {
      await _localMLService.initialize();
      print('✅ ML local inicializado correctamente');
    } catch (e) {
      print('⚠️ Error al inicializar ML local: $e');
    }
  }

  Future<Map<String, dynamic>> analyzeDishImage(File imageFile, {bool forceGemini = false}) async {
    // Estrategia: Intentar ML local primero, luego Gemini si falla o se fuerza
    
    // 1. Intentar con ML local (si está habilitado y no se fuerza Gemini)
    if (useLocalML && !forceGemini) {
      try {
        print('🤖 Analizando con ML local...');
        final result = await _localMLService.analyzeDishImage(imageFile);
        
        if (result['success'] == true) {
          print('✅ Análisis local exitoso');
          return result;
        } else {
          print('⚠️ ML local falló, intentando con Gemini...');
        }
      } catch (e) {
        print('⚠️ Error en ML local: $e, intentando con Gemini...');
      }
    }
    
    // 2. Fallback a Gemini (si está disponible)
    if (_geminiAvailable) {
      return await _analyzeDishImageWithGemini(imageFile);
    }
    
    // 3. Si nada funciona, retornar error
    return {
      'success': false,
      'error': 'No hay servicios de IA disponibles. Configura GEMINI_API_KEY o agrega modelos TFLite.',
    };
  }
  
  Future<Map<String, dynamic>> _analyzeDishImageWithGemini(File imageFile) async {
    try {
      print('☁️ Analizando con Gemini API...');
      // Leer la imagen como bytes
      final imageBytes = await imageFile.readAsBytes();
      
      // Crear el prompt
      final prompt = '''
Analiza esta imagen de comida y responde ÚNICAMENTE en formato JSON con la siguiente estructura:
{
  "dish_name": "nombre del platillo en español",
  "ingredients": ["ingrediente1", "ingrediente2", "ingrediente3", ...],
  "description": "breve descripción del platillo"
}

Identifica el platillo y lista TODOS los ingredientes visibles que puedas identificar.
Responde ÚNICAMENTE con el JSON válido, sin texto adicional, sin bloques de código markdown.
''';

      // Crear el contenido con texto e imagen
      final content = [
        Content.multi([
          TextPart(prompt),
          DataPart('image/jpeg', imageBytes),
        ])
      ];

      // Generar respuesta
      final response = await _model.generateContent(content);
      final text = response.text;
      
      if (text == null || text.isEmpty) {
        return {
          'success': false,
          'error': 'No se recibió respuesta del modelo Gemini',
        };
      }

      // Limpiar la respuesta (remover markdown si existe)
      String cleanedText = text.trim();
      if (cleanedText.startsWith('```json')) {
        cleanedText = cleanedText.substring(7);
      }
      if (cleanedText.startsWith('```')) {
        cleanedText = cleanedText.substring(3);
      }
      if (cleanedText.endsWith('```')) {
        cleanedText = cleanedText.substring(0, cleanedText.length - 3);
      }
      cleanedText = cleanedText.trim();

      // Parsear JSON
      try {
        final jsonResponse = json.decode(cleanedText);
        return {
          'success': true,
          'dish_name': jsonResponse['dish_name'] ?? 'Platillo Desconocido',
          'ingredients': (jsonResponse['ingredients'] as List?)
              ?.map((e) => e.toString())
              .toList() ?? [],
          'description': jsonResponse['description'] ?? '',
          'source': 'gemini',
        };
      } catch (e) {
        // Si falla el parsing, intentar extraer información manualmente
        return {
          'success': true,
          'dish_name': 'Platillo Identificado',
          'ingredients': ['Análisis en proceso'],
          'description': cleanedText,
          'source': 'gemini',
        };
      }
      
    } catch (e) {
      print('Error al analizar imagen con Gemini: $e');
      return {
        'success': false,
        'error': 'Error al analizar la imagen con Gemini: $e',
      };
    }
  }
  
  /// Cambiar entre ML local y Gemini
  void setUseLocalML(bool value) {
    useLocalML = value;
    print('🔄 Modo cambiado a: ${value ? "ML Local" : "Gemini API"}');
  }
  
  /// Verificar si Gemini está disponible
  bool get isGeminiAvailable => _geminiAvailable;
  
  /// Liberar recursos
  void dispose() {
    _localMLService.dispose();
  }

  // Método alternativo usando respuesta mock para pruebas
  Future<Map<String, dynamic>> analyzeDishImageMock(File imageFile) async {
    // Simular delay de API
    await Future.delayed(const Duration(seconds: 2));

    return {
      'success': true,
      'dish_name': 'Pizza Margarita',
      'ingredients': [
        'Masa de pizza',
        'Salsa de tomate',
        'Queso mozzarella',
        'Albahaca fresca',
        'Aceite de oliva',
        'Sal',
      ],
      'description':
          'Una clásica pizza italiana con ingredientes simples y frescos.',
    };
  }
}
