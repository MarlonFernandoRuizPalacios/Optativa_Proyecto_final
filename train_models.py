#!/usr/bin/env python3
"""
Script para entrenar modelos YOLO y clasificadores de platillos
para FoodRecipeAI usando YOLOv8 y TensorFlow
"""

import os
import sys
import argparse
from pathlib import Path

def check_dependencies():
    """Verificar que las dependencias estén instaladas"""
    required = ['ultralytics', 'tensorflow', 'Pillow']
    missing = []
    
    for package in required:
        try:
            __import__(package)
        except ImportError:
            missing.append(package)
    
    if missing:
        print(f"❌ Faltan dependencias: {', '.join(missing)}")
        print(f"💡 Instala con: pip install {' '.join(missing)}")
        sys.exit(1)
    
    print("✅ Todas las dependencias están instaladas")

def train_yolo_detector(data_yaml, epochs=100, img_size=640):
    """Entrenar detector YOLO para ingredientes"""
    from ultralytics import YOLO
    
    print("🚀 Entrenando detector YOLO...")
    print(f"   Dataset: {data_yaml}")
    print(f"   Épocas: {epochs}")
    print(f"   Tamaño: {img_size}x{img_size}")
    
    # Cargar modelo base (YOLOv8 nano para móviles)
    model = YOLO('yolov8n.pt')
    
    # Entrenar
    results = model.train(
        data=data_yaml,
        epochs=epochs,
        imgsz=img_size,
        batch=16,
        device='cuda:0' if check_cuda() else 'cpu',
        project='yolo_training',
        name='food_detector',
        patience=20,  # Early stopping
        save=True,
        verbose=True
    )
    
    print("✅ Entrenamiento YOLO completado")
    
    # Exportar a TFLite
    print("📦 Exportando a TensorFlow Lite...")
    model_path = 'yolo_training/food_detector/weights/best.pt'
    export_yolo_to_tflite(model_path)
    
    return model

def export_yolo_to_tflite(model_path):
    """Exportar modelo YOLO a TFLite"""
    from ultralytics import YOLO
    
    model = YOLO(model_path)
    
    # Exportar a TFLite
    model.export(
        format='tflite',
        imgsz=640,
        int8=True,  # Cuantización INT8 para mejor rendimiento
    )
    
    tflite_path = model_path.replace('.pt', '_saved_model/best_int8.tflite')
    
    if os.path.exists(tflite_path):
        # Mover a carpeta de destino
        dest = '../assets/models/yolo_food_detector.tflite'
        os.makedirs(os.path.dirname(dest), exist_ok=True)
        os.rename(tflite_path, dest)
        print(f"✅ Modelo exportado a: {dest}")
    else:
        print(f"⚠️ No se encontró el modelo en: {tflite_path}")

def train_dish_classifier(data_dir, num_classes=50, epochs=20):
    """Entrenar clasificador de platillos con MobileNetV2"""
    import tensorflow as tf
    from tensorflow.keras.applications import MobileNetV2
    from tensorflow.keras.preprocessing.image import ImageDataGenerator
    
    print("🚀 Entrenando clasificador de platillos...")
    print(f"   Dataset: {data_dir}")
    print(f"   Clases: {num_classes}")
    print(f"   Épocas: {epochs}")
    
    # Data augmentation
    train_datagen = ImageDataGenerator(
        rescale=1./255,
        rotation_range=20,
        width_shift_range=0.2,
        height_shift_range=0.2,
        horizontal_flip=True,
        validation_split=0.2
    )
    
    train_generator = train_datagen.flow_from_directory(
        data_dir,
        target_size=(224, 224),
        batch_size=32,
        class_mode='categorical',
        subset='training'
    )
    
    validation_generator = train_datagen.flow_from_directory(
        data_dir,
        target_size=(224, 224),
        batch_size=32,
        class_mode='categorical',
        subset='validation'
    )
    
    # Crear modelo base
    base_model = MobileNetV2(
        weights='imagenet',
        include_top=False,
        input_shape=(224, 224, 3)
    )
    
    # Congelar capas base
    base_model.trainable = False
    
    # Agregar capas de clasificación
    model = tf.keras.Sequential([
        base_model,
        tf.keras.layers.GlobalAveragePooling2D(),
        tf.keras.layers.Dropout(0.2),
        tf.keras.layers.Dense(num_classes, activation='softmax')
    ])
    
    # Compilar
    model.compile(
        optimizer=tf.keras.optimizers.Adam(learning_rate=0.001),
        loss='categorical_crossentropy',
        metrics=['accuracy']
    )
    
    # Entrenar
    history = model.fit(
        train_generator,
        epochs=epochs,
        validation_data=validation_generator,
        callbacks=[
            tf.keras.callbacks.EarlyStopping(patience=5, restore_best_weights=True),
            tf.keras.callbacks.ReduceLROnPlateau(patience=3, factor=0.5)
        ]
    )
    
    print("✅ Entrenamiento completado")
    
    # Exportar a TFLite
    export_classifier_to_tflite(model, train_generator.class_indices)
    
    return model, history

def export_classifier_to_tflite(model, class_indices):
    """Exportar clasificador a TFLite"""
    import tensorflow as tf
    
    print("📦 Exportando clasificador a TensorFlow Lite...")
    
    # Convertir a TFLite con cuantización
    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    converter.optimizations = [tf.lite.Optimize.DEFAULT]
    
    # Cuantización INT8 (opcional, requiere dataset representativo)
    # converter.target_spec.supported_types = [tf.int8]
    
    tflite_model = converter.convert()
    
    # Guardar modelo
    dest = '../assets/models/dish_classifier.tflite'
    os.makedirs(os.path.dirname(dest), exist_ok=True)
    
    with open(dest, 'wb') as f:
        f.write(tflite_model)
    
    print(f"✅ Modelo exportado a: {dest}")
    
    # Guardar etiquetas
    labels = [k for k, v in sorted(class_indices.items(), key=lambda x: x[1])]
    labels_path = '../assets/models/dish_labels.txt'
    
    with open(labels_path, 'w', encoding='utf-8') as f:
        f.write('\n'.join(labels))
    
    print(f"✅ Etiquetas guardadas en: {labels_path}")

def check_cuda():
    """Verificar si CUDA está disponible"""
    try:
        import torch
        return torch.cuda.is_available()
    except ImportError:
        return False

def create_sample_dataset_structure():
    """Crear estructura de ejemplo para datasets"""
    print("\n📁 Estructura de dataset para YOLO:")
    print("""
food_dataset/
├── data.yaml
├── train/
│   ├── images/
│   │   ├── img1.jpg
│   │   └── img2.jpg
│   └── labels/
│       ├── img1.txt  # formato YOLO: class x y w h
│       └── img2.txt
└── val/
    ├── images/
    └── labels/

Archivo data.yaml:
---
train: ./train/images
val: ./val/images
nc: 50  # número de clases
names: ['Tomate', 'Lechuga', 'Queso', ...]
---
    """)
    
    print("\n📁 Estructura de dataset para clasificador:")
    print("""
dishes_dataset/
├── Pizza/
│   ├── pizza1.jpg
│   ├── pizza2.jpg
│   └── ...
├── Hamburguesa/
│   ├── burger1.jpg
│   └── ...
├── Tacos/
└── ...

(Una carpeta por clase de platillo)
    """)

def main():
    parser = argparse.ArgumentParser(
        description="Entrenar modelos para FoodRecipeAI"
    )
    
    parser.add_argument(
        'mode',
        choices=['yolo', 'classifier', 'both', 'info'],
        help='Tipo de entrenamiento'
    )
    
    parser.add_argument(
        '--data',
        help='Ruta al dataset (YAML para YOLO, directorio para clasificador)'
    )
    
    parser.add_argument(
        '--epochs',
        type=int,
        default=50,
        help='Número de épocas (default: 50)'
    )
    
    parser.add_argument(
        '--classes',
        type=int,
        default=50,
        help='Número de clases para clasificador (default: 50)'
    )
    
    args = parser.parse_args()
    
    if args.mode == 'info':
        create_sample_dataset_structure()
        return
    
    # Verificar dependencias
    check_dependencies()
    
    if args.mode == 'yolo':
        if not args.data:
            print("❌ Especifica --data con la ruta al archivo YAML")
            sys.exit(1)
        train_yolo_detector(args.data, epochs=args.epochs)
    
    elif args.mode == 'classifier':
        if not args.data:
            print("❌ Especifica --data con la ruta al directorio del dataset")
            sys.exit(1)
        train_dish_classifier(args.data, num_classes=args.classes, epochs=args.epochs)
    
    elif args.mode == 'both':
        if not args.data:
            print("❌ Especifica --data con las rutas separadas por coma: yolo.yaml,dishes_dir")
            sys.exit(1)
        
        paths = args.data.split(',')
        if len(paths) != 2:
            print("❌ Para 'both', usa: --data yolo.yaml,dishes_dir")
            sys.exit(1)
        
        train_yolo_detector(paths[0], epochs=args.epochs)
        train_dish_classifier(paths[1], num_classes=args.classes, epochs=args.epochs)
    
    print("\n✅ ¡Entrenamiento completado!")
    print("📱 Ahora puedes usar los modelos en tu app Flutter")
    print("💡 No olvides descomentar las líneas en pubspec.yaml")

if __name__ == '__main__':
    main()
