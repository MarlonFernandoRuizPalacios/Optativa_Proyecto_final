# 🎓 Guía de Entrenamiento de Modelos para FoodRecipeAI

Este script te ayuda a entrenar modelos personalizados de YOLO y clasificadores de platillos.

## 📋 Requisitos

```bash
pip install ultralytics tensorflow Pillow numpy
```

## 🚀 Uso

### Ver información de datasets:

```bash
python train_models.py info
```

### Entrenar detector YOLO:

```bash
python train_models.py yolo --data food_dataset/data.yaml --epochs 100
```

### Entrenar clasificador de platillos:

```bash
python train_models.py classifier --data dishes_dataset/ --classes 50 --epochs 20
```

### Entrenar ambos:

```bash
python train_models.py both --data food_dataset/data.yaml,dishes_dataset/ --epochs 50
```

## 📁 Estructura de Datasets

### Para YOLO (Detección de Ingredientes)

```
food_dataset/
├── data.yaml
├── train/
│   ├── images/
│   │   ├── img1.jpg
│   │   └── img2.jpg
│   └── labels/
│       ├── img1.txt  # formato: class_id x_center y_center width height
│       └── img2.txt
└── val/
    ├── images/
    └── labels/
```

**data.yaml:**
```yaml
train: ./train/images
val: ./val/images
nc: 50  # número de clases
names: ['Tomate', 'Lechuga', 'Queso', 'Carne', ...]
```

**Formato de labels (img1.txt):**
```
0 0.5 0.5 0.3 0.4  # class_id x_center y_center width height (normalizados 0-1)
1 0.3 0.7 0.2 0.2
```

### Para Clasificador (Clasificación de Platillos)

```
dishes_dataset/
├── Pizza Margarita/
│   ├── pizza1.jpg
│   ├── pizza2.jpg
│   └── pizza3.jpg
├── Tacos de Carne/
│   ├── taco1.jpg
│   └── taco2.jpg
├── Hamburguesa/
└── ... (una carpeta por clase)
```

## 🌐 Obtener Datasets

### Datasets Públicos:

1. **Food-101**: 101,000 imágenes de 101 categorías
   - https://www.kaggle.com/datasets/dansbecker/food-101

2. **Open Images (Food)**: Subset de comida de Google
   - https://storage.googleapis.com/openimages/web/index.html

3. **UEC FOOD-256**: 256 categorías de comida
   - http://foodcam.mobi/dataset256.html

4. **Recipe1M**: 1 millón de recetas con imágenes
   - http://pic2recipe.csail.mit.edu/

### Crear tu propio dataset:

1. **Roboflow**: Herramienta para anotar y entrenar
   - https://roboflow.com/
   - Sube imágenes, anota, exporta en formato YOLO

2. **Label Studio**: Open source para anotación
   - https://labelstud.io/

3. **CVAT**: Computer Vision Annotation Tool
   - https://cvat.org/

## ⚙️ Parámetros de Entrenamiento

### YOLO:

- `--epochs`: Número de épocas (default: 100)
- `--data`: Ruta al archivo data.yaml
- Modelo base: YOLOv8n (nano) para móviles
- Cuantización: INT8 automática

### Clasificador:

- `--epochs`: Número de épocas (default: 20)
- `--classes`: Número de clases (default: 50)
- `--data`: Ruta al directorio del dataset
- Modelo base: MobileNetV2
- Optimización: TFLite con cuantización

## 📊 Resultados Esperados

### YOLO Detector:
- Tamaño: ~5-10 MB
- Precisión: 70-85% mAP
- Velocidad: 100-200ms en móvil
- Clases: 50 ingredientes

### Dish Classifier:
- Tamaño: ~4-8 MB
- Precisión: 75-90% accuracy
- Velocidad: 50-100ms en móvil
- Clases: 50 platillos

## 🐛 Solución de Problemas

### CUDA out of memory:
```bash
# Reducir batch size o usar CPU
--batch 8  # en lugar de 16
```

### Dataset muy pequeño:
```bash
# Usar data augmentation y transfer learning
# Ya incluido en el script
```

### Overfitting:
```bash
# Agregar más dropout o early stopping
# Ya configurado en el script
```

## 📱 Integración en Flutter

1. Los modelos se exportan automáticamente a `assets/models/`
2. Descomenta las líneas en `pubspec.yaml`:
   ```yaml
   - assets/models/yolo_food_detector.tflite
   - assets/models/dish_classifier.tflite
   ```
3. Ejecuta: `flutter pub get`
4. ¡Listo! La app usará tus modelos

## 🎯 Tips para Mejor Precisión

1. **Más datos**: Mínimo 100 imágenes por clase
2. **Variedad**: Diferentes ángulos, iluminación, fondos
3. **Calidad**: Imágenes claras y bien enfocadas
4. **Balance**: Igual cantidad de imágenes por clase
5. **Validación**: Separar 20% para validación
6. **Augmentation**: Rotación, flip, zoom automáticos

## 📚 Referencias

- YOLOv8 Docs: https://docs.ultralytics.com/
- TFLite Guide: https://www.tensorflow.org/lite
- MobileNetV2: https://arxiv.org/abs/1801.04381
- Food-101 Paper: https://data.vision.ee.ethz.ch/cvl/datasets_extra/food-101/

## ✅ Checklist de Entrenamiento

- [ ] Instalar dependencias
- [ ] Preparar dataset (mínimo 2000 imágenes)
- [ ] Anotar imágenes (solo para YOLO)
- [ ] Entrenar modelo
- [ ] Validar precisión (>70%)
- [ ] Exportar a TFLite
- [ ] Integrar en Flutter
- [ ] Probar en dispositivo real
- [ ] Optimizar si es necesario

¡Buena suerte con tu entrenamiento! 🚀
