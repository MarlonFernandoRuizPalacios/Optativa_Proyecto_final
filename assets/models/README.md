# 🤖 Modelos de Machine Learning

Esta carpeta contiene los modelos de TensorFlow Lite para análisis local de platillos.

## 📁 Archivos requeridos

### Modelos TFLite (no incluidos - debes agregarlos)

1. **yolo_food_detector.tflite**
   - Modelo YOLO convertido a TensorFlow Lite
   - Detecta objetos/ingredientes en imágenes de comida
   - Tamaño de entrada: 640x640x3
   - Puedes entrenar tu propio modelo o usar uno pre-entrenado

2. **dish_classifier.tflite**
   - Clasificador de platillos (MobileNet, EfficientNet, etc.)
   - Clasifica el tipo de platillo en la imagen
   - Tamaño de entrada: 224x224x3
   - Entrenado con dataset de platillos mexicanos/internacionales

### Archivos de etiquetas (incluidos)

- **yolo_labels.txt**: Etiquetas de ingredientes detectables (50 ingredientes)
- **dish_labels.txt**: Etiquetas de platillos clasificables (50 platillos)

## 🎓 Cómo obtener/crear los modelos

### Opción 1: Usar modelos pre-entrenados

Puedes descargar modelos pre-entrenados de:
- **TensorFlow Hub**: https://tfhub.dev/
- **ONNX Model Zoo**: https://github.com/onnx/models (convertir a TFLite)
- **Roboflow Universe**: https://universe.roboflow.com/

### Opción 2: Entrenar tus propios modelos

#### YOLO Food Detector

```bash
# Usar YOLOv8 con Ultralytics
pip install ultralytics

# Entrenar con tu dataset
yolo detect train data=food_dataset.yaml model=yolov8n.pt epochs=100

# Exportar a TFLite
yolo export model=best.pt format=tflite
```

#### Dish Classifier

```python
# Usar TensorFlow/Keras
import tensorflow as tf
from tensorflow.keras.applications import MobileNetV2

# Crear modelo base
base_model = MobileNetV2(weights='imagenet', include_top=False)

# Agregar capas de clasificación
model = tf.keras.Sequential([
    base_model,
    tf.keras.layers.GlobalAveragePooling2D(),
    tf.keras.layers.Dense(50, activation='softmax')  # 50 clases
])

# Entrenar con tu dataset
model.compile(optimizer='adam', loss='categorical_crossentropy', metrics=['accuracy'])
model.fit(train_data, epochs=20, validation_data=val_data)

# Convertir a TFLite
converter = tf.lite.TFLiteConverter.from_keras_model(model)
converter.optimizations = [tf.lite.Optimize.DEFAULT]
tflite_model = converter.convert()

# Guardar
with open('dish_classifier.tflite', 'wb') as f:
    f.write(tflite_model)
```

### Opción 3: Usar datasets públicos

- **Food-101**: 101 categorías de comida (https://www.kaggle.com/datasets/dansbecker/food-101)
- **Open Images Food**: Subset de comida de Open Images
- **UEC FOOD-100/256**: Dataset japonés de comida
- **Recipe1M**: 1 millón de recetas con imágenes

## 📦 Integración en Flutter

Los modelos deben estar en `assets/models/` y ser declarados en `pubspec.yaml`:

```yaml
flutter:
  assets:
    - assets/models/yolo_food_detector.tflite
    - assets/models/dish_classifier.tflite
    - assets/models/yolo_labels.txt
    - assets/models/dish_labels.txt
```

## ⚙️ Configuración recomendada

### Para dispositivos móviles:
- Usar modelos cuantizados (INT8)
- Tamaño < 10MB por modelo
- YOLOv8n (nano) o YOLOv5s (small)
- MobileNetV2 o EfficientNetB0

### Optimizaciones:
- Post-training quantization
- Pruning (poda de conexiones)
- Knowledge distillation

## 🔄 Modo de respaldo

Si los modelos no están disponibles, la app usa:
1. Clasificación genérica basada en patrones visuales simples
2. Base de datos de ingredientes predefinidos
3. Fallback a Gemini API (si está configurada)

## 📊 Rendimiento esperado

- **YOLO Detector**: ~100-200ms por inferencia en móvil
- **Dish Classifier**: ~50-100ms por inferencia en móvil
- **Precisión**: 70-85% (depende del entrenamiento)
- **RAM**: ~100-200MB durante inferencia

## 🚀 Próximos pasos

1. Coloca tus archivos `.tflite` en esta carpeta
2. Actualiza las etiquetas si usas diferentes clases
3. Ajusta los tamaños de entrada en `local_ml_service.dart` si es necesario
4. Ejecuta `flutter pub get` y prueba la app

## 📝 Notas

- Los modelos NO están incluidos en el repositorio por su tamaño
- Debes entrenar o descargar modelos compatibles
- La app funcionará sin modelos usando clasificación básica
- Se recomienda validar modelos antes de producción
