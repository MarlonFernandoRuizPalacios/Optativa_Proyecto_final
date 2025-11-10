import 'dart:io';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

/// Servicio para Machine Learning local usando TensorFlow Lite y YOLO
/// Este servicio detecta objetos de comida y clasifica platillos completamente offline
class LocalMLService {
  Interpreter? _objectDetector; // YOLO para detección de objetos
  Interpreter? _dishClassifier; // Clasificador de platillos
  
  List<String> _objectLabels = [];
  List<String> _dishLabels = [];
  
  bool _isInitialized = false;
  
  // Configuración del modelo YOLO
  static const int yoloInputSize = 640; // YOLOv8 usa 640x640
  static const double confidenceThreshold = 0.5;
  static const double iouThreshold = 0.45;
  
  // Configuración del clasificador
  static const int classifierInputSize = 224; // MobileNet/EfficientNet
  
  /// Inicializar modelos de ML
  Future<bool> initialize() async {
    if (_isInitialized) return true;
    
    try {
      print('🤖 Inicializando modelos de ML local...');
      
      // Cargar modelo YOLO para detección de objetos
      try {
        _objectDetector = await Interpreter.fromAsset('assets/models/yolo_food_detector.tflite');
        _objectLabels = await _loadLabels('assets/models/yolo_labels.txt');
        print('✅ YOLO detector cargado: ${_objectLabels.length} clases');
      } catch (e) {
        print('⚠️ No se pudo cargar YOLO detector: $e');
        print('📝 Usando modo de respaldo sin detección de objetos');
      }
      
      // Cargar clasificador de platillos
      try {
        _dishClassifier = await Interpreter.fromAsset('assets/models/dish_classifier.tflite');
        _dishLabels = await _loadLabels('assets/models/dish_labels.txt');
        print('✅ Clasificador de platillos cargado: ${_dishLabels.length} clases');
      } catch (e) {
        print('⚠️ No se pudo cargar clasificador: $e');
        print('📝 Usando clasificación genérica');
      }
      
      _isInitialized = true;
      return true;
    } catch (e) {
      print('❌ Error al inicializar ML local: $e');
      return false;
    }
  }
  
  /// Cargar etiquetas desde archivo de texto
  Future<List<String>> _loadLabels(String path) async {
    try {
      final labelsData = await rootBundle.loadString(path);
      return labelsData.split('\n').where((line) => line.trim().isNotEmpty).toList();
    } catch (e) {
      print('⚠️ No se pudieron cargar labels de $path: $e');
      return [];
    }
  }
  
  /// Analizar imagen de platillo con ML local
  Future<Map<String, dynamic>> analyzeDishImage(File imageFile) async {
    try {
      // Asegurar inicialización
      if (!_isInitialized) {
        await initialize();
      }
      
      // Leer y procesar imagen
      final imageBytes = await imageFile.readAsBytes();
      img.Image? image = img.decodeImage(imageBytes);
      
      if (image == null) {
        return _createErrorResponse('No se pudo decodificar la imagen');
      }
      
      // 1. Detectar objetos de comida con YOLO (si está disponible)
      List<DetectedObject> detectedObjects = [];
      if (_objectDetector != null && _objectLabels.isNotEmpty) {
        detectedObjects = await _detectObjects(image);
        print('🔍 Objetos detectados: ${detectedObjects.length}');
      }
      
      // 2. Clasificar el platillo principal
      String dishName = 'Platillo Desconocido';
      double confidence = 0.0;
      
      if (_dishClassifier != null && _dishLabels.isNotEmpty) {
        final classification = await _classifyDish(image);
        dishName = classification['name'] ?? dishName;
        confidence = classification['confidence'] ?? 0.0;
        print('🍽️ Platillo clasificado: $dishName (${(confidence * 100).toStringAsFixed(1)}%)');
      }
      
      // 3. Extraer ingredientes de los objetos detectados
      List<String> ingredients = _extractIngredients(detectedObjects, dishName);
      
      // 4. Generar descripción
      String description = _generateDescription(dishName, confidence, detectedObjects.length);
      
      return {
        'success': true,
        'dish_name': dishName,
        'ingredients': ingredients,
        'description': description,
        'confidence': confidence,
        'detected_objects': detectedObjects.length,
        'source': 'local_ml',
      };
      
    } catch (e) {
      print('❌ Error en análisis local: $e');
      return _createErrorResponse('Error al analizar imagen: $e');
    }
  }
  
  /// Detectar objetos de comida usando YOLO
  Future<List<DetectedObject>> _detectObjects(img.Image image) async {
    if (_objectDetector == null) return [];
    
    try {
      // Preprocesar imagen para YOLO (640x640)
      final input = _preprocessImageForYOLO(image);
      
      // Preparar salida (YOLO output: [1, 25200, 85] para COCO)
      // Para modelo de comida personalizado puede variar
      final outputShape = _objectDetector!.getOutputTensor(0).shape;
      final output = List.generate(
        outputShape[0],
        (_) => List.generate(
          outputShape[1],
          (_) => List.filled(outputShape[2], 0.0),
        ),
      );
      
      // Ejecutar inferencia
      _objectDetector!.run(input, output);
      
      // Post-procesar detecciones
      return _processYOLOOutput(output);
      
    } catch (e) {
      print('⚠️ Error en detección YOLO: $e');
      return [];
    }
  }
  
  /// Clasificar platillo principal
  Future<Map<String, dynamic>> _classifyDish(img.Image image) async {
    if (_dishClassifier == null || _dishLabels.isEmpty) {
      return {'name': 'Platillo Desconocido', 'confidence': 0.0};
    }
    
    try {
      // Preprocesar imagen para clasificador (224x224)
      final input = _preprocessImageForClassifier(image);
      
      // Preparar salida
      final outputShape = _dishClassifier!.getOutputTensor(0).shape;
      final output = List.filled(outputShape[1], 0.0).reshape([1, outputShape[1]]);
      
      // Ejecutar inferencia
      _dishClassifier!.run(input, output);
      
      // Obtener clase con mayor probabilidad
      final probabilities = output[0] as List<double>;
      int maxIndex = 0;
      double maxProb = probabilities[0];
      
      for (int i = 1; i < probabilities.length; i++) {
        if (probabilities[i] > maxProb) {
          maxProb = probabilities[i];
          maxIndex = i;
        }
      }
      
      return {
        'name': maxIndex < _dishLabels.length ? _dishLabels[maxIndex] : 'Platillo Desconocido',
        'confidence': maxProb,
      };
      
    } catch (e) {
      print('⚠️ Error en clasificación: $e');
      return {'name': 'Platillo Desconocido', 'confidence': 0.0};
    }
  }
  
  /// Preprocesar imagen para YOLO (640x640, normalizada)
  List<List<List<List<double>>>> _preprocessImageForYOLO(img.Image image) {
    // Redimensionar a 640x640
    final resized = img.copyResize(image, width: yoloInputSize, height: yoloInputSize);
    
    // Convertir a formato [1, 640, 640, 3]
    final input = List.generate(
      1,
      (_) => List.generate(
        yoloInputSize,
        (y) => List.generate(
          yoloInputSize,
          (x) {
            final pixel = resized.getPixel(x, y);
            return [
              pixel.r / 255.0,
              pixel.g / 255.0,
              pixel.b / 255.0,
            ];
          },
        ),
      ),
    );
    
    return input;
  }
  
  /// Preprocesar imagen para clasificador (224x224, normalizada)
  List<List<List<List<double>>>> _preprocessImageForClassifier(img.Image image) {
    // Redimensionar a 224x224
    final resized = img.copyResize(image, width: classifierInputSize, height: classifierInputSize);
    
    // Convertir a formato [1, 224, 224, 3] con normalización ImageNet
    final input = List.generate(
      1,
      (_) => List.generate(
        classifierInputSize,
        (y) => List.generate(
          classifierInputSize,
          (x) {
            final pixel = resized.getPixel(x, y);
            // Normalización ImageNet: (pixel/255 - mean) / std
            return [
              (pixel.r / 255.0 - 0.485) / 0.229,
              (pixel.g / 255.0 - 0.456) / 0.224,
              (pixel.b / 255.0 - 0.406) / 0.225,
            ];
          },
        ),
      ),
    );
    
    return input;
  }
  
  /// Procesar salida de YOLO y aplicar NMS (Non-Maximum Suppression)
  List<DetectedObject> _processYOLOOutput(List<List<List<double>>> output) {
    List<DetectedObject> detections = [];
    
    // Procesar cada detección
    for (var detection in output[0]) {
      if (detection.length < 5) continue;
      
      final confidence = detection[4];
      if (confidence < confidenceThreshold) continue;
      
      // Obtener clase con mayor probabilidad
      int classId = 0;
      double maxClassProb = detection[5];
      for (int i = 6; i < detection.length; i++) {
        if (detection[i] > maxClassProb) {
          maxClassProb = detection[i];
          classId = i - 5;
        }
      }
      
      final totalConfidence = confidence * maxClassProb;
      if (totalConfidence < confidenceThreshold) continue;
      
      detections.add(DetectedObject(
        label: classId < _objectLabels.length ? _objectLabels[classId] : 'Objeto $classId',
        confidence: totalConfidence,
        bbox: [detection[0], detection[1], detection[2], detection[3]],
      ));
    }
    
    // Aplicar NMS para eliminar detecciones duplicadas
    return _applyNMS(detections);
  }
  
  /// Aplicar Non-Maximum Suppression
  List<DetectedObject> _applyNMS(List<DetectedObject> detections) {
    if (detections.isEmpty) return [];
    
    // Ordenar por confianza
    detections.sort((a, b) => b.confidence.compareTo(a.confidence));
    
    List<DetectedObject> selected = [];
    List<bool> suppressed = List.filled(detections.length, false);
    
    for (int i = 0; i < detections.length; i++) {
      if (suppressed[i]) continue;
      
      selected.add(detections[i]);
      
      for (int j = i + 1; j < detections.length; j++) {
        if (suppressed[j]) continue;
        
        double iou = _calculateIOU(detections[i].bbox, detections[j].bbox);
        if (iou > iouThreshold) {
          suppressed[j] = true;
        }
      }
    }
    
    return selected;
  }
  
  /// Calcular Intersection over Union
  double _calculateIOU(List<double> box1, List<double> box2) {
    final x1 = box1[0].max(box2[0]);
    final y1 = box1[1].max(box2[1]);
    final x2 = (box1[0] + box1[2]).min(box2[0] + box2[2]);
    final y2 = (box1[1] + box1[3]).min(box2[1] + box2[3]);
    
    final intersection = (x2 - x1).max(0) * (y2 - y1).max(0);
    final area1 = box1[2] * box1[3];
    final area2 = box2[2] * box2[3];
    final union = area1 + area2 - intersection;
    
    return intersection / union;
  }
  
  /// Extraer ingredientes basados en objetos detectados
  List<String> _extractIngredients(List<DetectedObject> objects, String dishName) {
    Set<String> ingredients = {};
    
    // Agregar objetos detectados como ingredientes
    for (var obj in objects) {
      ingredients.add(_translateToSpanish(obj.label));
    }
    
    // Si no hay objetos detectados, usar ingredientes genéricos basados en el platillo
    if (ingredients.isEmpty) {
      ingredients.addAll(_getGenericIngredientsForDish(dishName));
    }
    
    return ingredients.toList();
  }
  
  /// Generar descripción del análisis
  String _generateDescription(String dishName, double confidence, int objectsDetected) {
    if (confidence > 0.8) {
      return 'Identificado con alta confianza. Se detectaron $objectsDetected elementos en la imagen.';
    } else if (confidence > 0.5) {
      return 'Posible $dishName. Se detectaron $objectsDetected elementos. Verifica los ingredientes.';
    } else {
      return 'Análisis con confianza media. Se detectaron $objectsDetected elementos en la imagen.';
    }
  }
  
  /// Obtener ingredientes genéricos para platillos conocidos
  List<String> _getGenericIngredientsForDish(String dishName) {
    // Base de datos simple de ingredientes por platillo
    final dishIngredients = {
      'Pizza': ['Masa', 'Salsa de tomate', 'Queso', 'Pepperoni'],
      'Hamburguesa': ['Pan', 'Carne', 'Lechuga', 'Tomate', 'Queso', 'Cebolla'],
      'Ensalada': ['Lechuga', 'Tomate', 'Pepino', 'Cebolla', 'Aderezo'],
      'Pasta': ['Pasta', 'Salsa', 'Queso parmesano'],
      'Tacos': ['Tortilla', 'Carne', 'Cebolla', 'Cilantro', 'Limón'],
      'Sushi': ['Arroz', 'Alga nori', 'Pescado', 'Aguacate'],
      'Paella': ['Arroz', 'Mariscos', 'Pollo', 'Azafrán', 'Verduras'],
      'Ceviche': ['Pescado', 'Limón', 'Cebolla', 'Cilantro', 'Ají'],
    };
    
    // Buscar coincidencia parcial
    for (var entry in dishIngredients.entries) {
      if (dishName.toLowerCase().contains(entry.key.toLowerCase())) {
        return entry.value;
      }
    }
    
    return ['Ingredientes variados', 'Condimentos', 'Especias'];
  }
  
  /// Traducir etiquetas de inglés a español
  String _translateToSpanish(String label) {
    final translations = {
      'tomato': 'Tomate',
      'lettuce': 'Lechuga',
      'cheese': 'Queso',
      'meat': 'Carne',
      'chicken': 'Pollo',
      'beef': 'Res',
      'pork': 'Cerdo',
      'fish': 'Pescado',
      'shrimp': 'Camarón',
      'bread': 'Pan',
      'rice': 'Arroz',
      'pasta': 'Pasta',
      'onion': 'Cebolla',
      'garlic': 'Ajo',
      'pepper': 'Pimiento',
      'carrot': 'Zanahoria',
      'potato': 'Papa',
      'egg': 'Huevo',
      'milk': 'Leche',
      'butter': 'Mantequilla',
    };
    
    return translations[label.toLowerCase()] ?? label;
  }
  
  /// Crear respuesta de error
  Map<String, dynamic> _createErrorResponse(String message) {
    return {
      'success': false,
      'error': message,
      'dish_name': 'Error',
      'ingredients': [],
      'description': message,
    };
  }
  
  /// Liberar recursos
  void dispose() {
    _objectDetector?.close();
    _dishClassifier?.close();
    _isInitialized = false;
    print('🗑️ Modelos de ML liberados');
  }
}

/// Clase para representar un objeto detectado
class DetectedObject {
  final String label;
  final double confidence;
  final List<double> bbox; // [x, y, width, height]
  
  DetectedObject({
    required this.label,
    required this.confidence,
    required this.bbox,
  });
  
  @override
  String toString() => '$label (${(confidence * 100).toStringAsFixed(1)}%)';
}

/// Extensión para operaciones numéricas
extension NumExtension on num {
  num max(num other) => this > other ? this : other;
  num min(num other) => this < other ? this : other;
}
