import 'dart:convert';
import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AIService {
  late final GenerativeModel _model;
  
  bool _geminiAvailable = false;
  
  AIService() {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    
    if (apiKey != null && apiKey.isNotEmpty) {
      // Initialize Gemini Flash model for image analysis
      _model = GenerativeModel(
        model: 'gemini-2.0-flash', 
        apiKey: apiKey,
      );
      _geminiAvailable = true;
      print('✅ Gemini API available');
    } else {
      print('⚠️ GEMINI_API_KEY not configured');
    }
  }

  Future<Map<String, dynamic>> analyzeDishImage(File imageFile) async {
    if (!_geminiAvailable) {
      return {
        'success': false,
        'error': 'No hay servicios de IA disponibles. Configura GEMINI_API_KEY en el archivo .env',
      };
    }
    
    return await _analyzeDishImageWithGemini(imageFile);
  }
  
  Future<Map<String, dynamic>> _analyzeDishImageWithGemini(File imageFile) async {
    try {
      print('☁️ Analyzing with Gemini API...');
      // Read image as bytes
      final imageBytes = await imageFile.readAsBytes();
      
      // Create the prompt
      final prompt = '''
Eres un asistente especializado en análisis de COMIDA y PLATILLOS.

PRIMERO: Determina si la imagen contiene COMIDA, un PLATILLO o ALIMENTOS.

Si la imagen NO contiene comida (por ejemplo: personas, animales, objetos, paisajes, etc.), responde ÚNICAMENTE con este JSON:
{
  "dish_name": "No es comida",
  "ingredients": [],
  "description": "No puedo analizar esta imagen porque no contiene comida o platillos. Por favor, toma una foto de un platillo o alimento."
}

Si la imagen SÍ contiene comida, analízala y responde en formato JSON con la siguiente estructura:
{
  "dish_name": "nombre del platillo en español",
  "ingredients": ["ingrediente1 en español", "ingrediente2 en español", "ingrediente3 en español", ...],
  "description": "descripción breve del platillo en español"
}

IMPORTANTE: 
- Solo analiza COMIDA, PLATILLOS o ALIMENTOS
- Identifica el platillo y lista TODOS los ingredientes visibles que puedas identificar
- TODOS los ingredientes deben estar en ESPAÑOL (ejemplo: "Tomate", "Lechuga", "Queso", etc.)
- La descripción debe estar en ESPAÑOL
- Responde ÚNICAMENTE con el JSON válido, sin texto adicional, sin bloques de código markdown
''';

      // Create content with text and image
      final content = [
        Content.multi([
          TextPart(prompt),
          DataPart('image/jpeg', imageBytes),
        ])
      ];

      // Generate response
      final response = await _model.generateContent(content);
      final text = response.text;
      
      if (text == null || text.isEmpty) {
        return {
          'success': false,
          'error': 'No se recibió respuesta del modelo Gemini',
        };
      }

      // Clean response (remove markdown if exists)
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

      // Parse JSON
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
        // If parsing fails, try to extract information manually
        return {
          'success': true,
          'dish_name': 'Platillo Identificado',
          'ingredients': ['Análisis en proceso'],
          'description': cleanedText,
          'source': 'gemini',
        };
      }
      
    } catch (e) {
      print('Error analyzing image with Gemini: $e');
      return {
        'success': false,
        'error': 'Error al analizar la imagen con Gemini: $e',
      };
    }
  }
  
  /// Check if Gemini is available
  bool get isGeminiAvailable => _geminiAvailable;

  // Alternative method using mock response for testing
  Future<Map<String, dynamic>> analyzeDishImageMock(File imageFile) async {
    // Simulate API delay
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
