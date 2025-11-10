# 🤖 Guía de Configuración de Google Gemini API

Esta guía te ayudará a configurar la API de Google Gemini en tu proyecto Flutter.

## 📝 Paso 1: Obtener tu API Key de Gemini

### 1. Accede a Google AI Studio

1. Ve a [Google AI Studio](https://makersuite.google.com/app/apikey) o [Google Cloud Console](https://console.cloud.google.com/)
2. Inicia sesión con tu cuenta de Google

### 2. Crear/Obtener API Key

**Opción A: Google AI Studio (Recomendado para desarrollo)**

1. En Google AI Studio, haz clic en **"Get API Key"**
2. Selecciona **"Create API key in new project"** o usa un proyecto existente
3. Copia tu API key (se verá algo como: `AIzaSyD...`)
4. **¡IMPORTANTE!**: Guarda esta key en un lugar seguro, no la compartas públicamente

**Opción B: Google Cloud Console (Para producción)**

1. Crea un nuevo proyecto o selecciona uno existente
2. Habilita la **Generative Language API**
3. Ve a **APIs & Services** > **Credentials**
4. Crea una **API Key**
5. (Recomendado) Restringe la API key a tu aplicación

### 3. Restricciones de la API Key (Opcional pero recomendado)

Para mayor seguridad:
1. En Google Cloud Console, edita tu API key
2. Agrega restricciones de aplicación (Android/iOS)
3. Restringe las APIs a solo "Generative Language API"

## 🔧 Paso 2: Configurar el archivo .env

1. Abre el archivo `.env` en la raíz de tu proyecto
2. Reemplaza `tu_gemini_api_key_aqui` con tu API key real:

```env
GEMINI_API_KEY=AIzaSyD-tu-api-key-real-aqui
```

3. Guarda el archivo

**Ejemplo:**
```env
GEMINI_API_KEY=AIzaSyDXVlWZ9TlwJfC3EZ8x9YGHfJk1mN0pQRs
```

## 📦 Paso 3: Instalar el paquete de Gemini

Agrega el paquete oficial de Google Generative AI a tu `pubspec.yaml`:

```bash
flutter pub add google_generative_ai
```

O manualmente en `pubspec.yaml`:

```yaml
dependencies:
  google_generative_ai: ^0.4.0
```

Luego ejecuta:

```bash
flutter pub get
```

## 💻 Paso 4: Implementar Gemini en tu proyecto

### Crear un servicio para Gemini

Crea o actualiza el archivo `lib/data/services/gemini_service.dart`:

```dart
import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GeminiService {
  late final GenerativeModel _model;
  
  GeminiService() {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('GEMINI_API_KEY no está configurada en el archivo .env');
    }
    
    // Inicializar el modelo Gemini Pro Vision para análisis de imágenes
    _model = GenerativeModel(
      model: 'gemini-1.5-flash', // o 'gemini-pro-vision'
      apiKey: apiKey,
    );
  }

  /// Analiza una imagen de un platillo y retorna sus ingredientes
  Future<Map<String, dynamic>> analyzeDishImage(File imageFile) async {
    try {
      // Leer la imagen como bytes
      final imageBytes = await imageFile.readAsBytes();
      
      // Crear el prompt
      final prompt = '''
Analiza esta imagen de comida y proporciona la siguiente información en formato JSON:
{
  "nombre_platillo": "nombre del platillo en español",
  "ingredientes": ["ingrediente1", "ingrediente2", "ingrediente3", ...]
}

Por favor, identifica el platillo y lista TODOS los ingredientes visibles que puedas identificar.
Responde ÚNICAMENTE con el JSON, sin texto adicional.
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
        throw Exception('No se recibió respuesta del modelo Gemini');
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
      final jsonResponse = json.decode(cleanedText);
      
      return {
        'dishName': jsonResponse['nombre_platillo'] ?? 'Platillo desconocido',
        'ingredients': (jsonResponse['ingredientes'] as List?)
            ?.map((e) => e.toString())
            .toList() ?? [],
      };
      
    } catch (e) {
      print('Error al analizar imagen con Gemini: $e');
      throw Exception('Error al analizar la imagen: $e');
    }
  }

  /// Método mock para pruebas sin consumir API
  Future<Map<String, dynamic>> analyzeDishImageMock(File imageFile) async {
    await Future.delayed(Duration(seconds: 2)); // Simular delay de API
    
    return {
      'dishName': 'Platillo de prueba (Mock)',
      'ingredients': [
        'Ingrediente 1',
        'Ingrediente 2',
        'Ingrediente 3',
        'Ingrediente 4',
      ],
    };
  }
}
```

### Actualizar el controlador

En `lib/presentation/controllers/dish_controller.dart`, actualiza el servicio para usar Gemini:

```dart
import 'package:get/get.dart';
import '../../data/services/gemini_service.dart'; // Cambia de ai_service a gemini_service

class DishController extends GetxController {
  final GeminiService _geminiService = GeminiService(); // Cambia de AIService a GeminiService
  
  // ... resto del código ...
  
  Future<void> analyzeDish() async {
    if (selectedImage.value == null) return;
    
    try {
      isAnalyzing.value = true;
      
      // Usar Gemini en lugar de OpenAI
      final result = await _geminiService.analyzeDishImage(selectedImage.value!);
      
      dishName.value = result['dishName'] ?? '';
      ingredients.value = List<String>.from(result['ingredients'] ?? []);
      
      Get.snackbar(
        'Análisis completado',
        'Platillo identificado exitosamente',
        snackPosition: SnackPosition.BOTTOM,
      );
      
    } catch (e) {
      Get.snackbar(
        'Error',
        'No se pudo analizar la imagen: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isAnalyzing.value = false;
    }
  }
}
```

## 🧪 Paso 5: Probar la configuración

### Verificar que la API Key está cargada

En `lib/main.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Cargar variables de entorno
  await dotenv.load(fileName: ".env");
  
  // Verificar que la API key existe (opcional, para debug)
  final geminiKey = dotenv.env['GEMINI_API_KEY'];
  if (geminiKey == null || geminiKey.isEmpty) {
    print('⚠️ ADVERTENCIA: GEMINI_API_KEY no está configurada');
  } else {
    print('✅ GEMINI_API_KEY cargada correctamente');
  }
  
  runApp(MyApp());
}
```

### Ejecutar la aplicación

```bash
flutter run
```

## 💰 Información de precios

### Gemini 1.5 Flash (Recomendado para este proyecto)
- **Entrada de texto**: GRATIS hasta 15 RPM (requests por minuto)
- **Entrada de imagen**: GRATIS hasta 15 RPM
- **Salida de texto**: GRATIS hasta 15 RPM
- Límite gratuito: 1,500 requests por día

### Gemini Pro Vision
- Similar a Flash pero con más capacidades
- También tiene nivel gratuito generoso

**Nota**: Para uso en producción, considera habilitar la facturación en Google Cloud Console.

## 🔒 Seguridad

### ⚠️ IMPORTANTE: Nunca subas tu API key a Git

1. El archivo `.env` ya está en `.gitignore`
2. Nunca hagas commit de tu `.env`
3. Usa `.env.example` como plantilla sin keys reales
4. En producción, usa variables de entorno del servidor

### Compartir el proyecto

Cuando compartas tu código:
1. Asegúrate de que `.env` no esté incluido
2. Incluye `.env.example` con valores de placeholder
3. Documenta cómo obtener las API keys

## 🆚 Gemini vs OpenAI

### Ventajas de Gemini:
- ✅ Mayor límite gratuito
- ✅ API más reciente de Google
- ✅ Mejor integración con Google Cloud
- ✅ Excelente para análisis de imágenes

### Ventajas de OpenAI:
- ✅ Más documentación y ejemplos
- ✅ Mayor comunidad
- ✅ GPT-4 Vision puede ser más preciso

## 🐛 Solución de problemas

### Error: "API key not valid"
- Verifica que copiaste la API key completa
- Asegúrate de que no hay espacios al inicio/final
- Verifica que la API está habilitada en Google Cloud

### Error: "Module not found: google_generative_ai"
```bash
flutter clean
flutter pub get
```

### Error: "GEMINI_API_KEY no está configurada"
- Verifica que el archivo `.env` existe en la raíz del proyecto
- Verifica que `.env` está en la lista de assets en `pubspec.yaml`
- Ejecuta `flutter clean` y `flutter run` de nuevo

### La API es muy lenta
- Usa `gemini-1.5-flash` en lugar de `gemini-pro-vision`
- Reduce el tamaño de las imágenes antes de enviarlas
- Considera implementar caché para imágenes analizadas recientemente

### Límite de requests excedido
- Implementa throttling en tu app
- Usa el método mock durante desarrollo
- Considera actualizar a un plan de pago si es necesario

## 📚 Recursos adicionales

- [Documentación oficial de Gemini](https://ai.google.dev/docs)
- [Google AI Studio](https://makersuite.google.com/)
- [Paquete google_generative_ai](https://pub.dev/packages/google_generative_ai)
- [Guía de mejores prácticas](https://ai.google.dev/docs/best_practices)

---

**¡Listo para usar Gemini! 🚀**
