# 🍽️ FoodAI - Analizador de Platillos con IA

Una aplicación Flutter que utiliza Inteligencia Artificial para identificar ingredientes de platillos a través de fotografías. Construida con Clean Architecture, Supabase y OpenAI Vision API.

## 📋 Características

- 📸 **Captura de fotos**: Toma fotos directamente desde la cámara o selecciona de la galería
- 🤖 **Análisis con IA**: Identifica automáticamente el nombre del platillo e ingredientes usando OpenAI Vision
- 💾 **Almacenamiento en la nube**: Guarda platillos e imágenes en Supabase
- 📱 **Interfaz moderna**: UI/UX limpia y responsive con Material Design
- 🔐 **Autenticación**: Login seguro con Supabase Auth
- 🏗️ **Clean Architecture**: Código organizado, mantenible y escalable

## 🛠️ Tecnologías

- **Flutter** - Framework UI multiplataforma
- **GetX** - Gestión de estado y navegación
- **Supabase** - Backend as a Service (Base de datos + Storage + Auth)
- **OpenAI Vision API** - Análisis de imágenes con IA
- **Image Picker** - Captura de fotos
- **Clean Architecture** - Arquitectura en capas

## 📦 Estructura del Proyecto

```
lib/
├── core/
│   ├── config/          # Configuraciones (Supabase)
│   └── constants/       # Constantes (Colores, etc)
├── data/
│   ├── models/          # Modelos de datos
│   ├── repositories/    # Implementación de repositorios
│   └── services/        # Servicios (AI, Storage)
├── domain/
│   ├── entities/        # Entidades de dominio
│   └── repositories/    # Interfaces de repositorios
└── presentation/
    ├── controllers/     # Controladores GetX
    ├── pages/           # Pantallas
    └── widgets/         # Widgets reutilizables
```

## 🚀 Configuración

### 1. Clonar el repositorio

```bash
git clone <repository-url>
cd todo_flutter
```

### 2. Instalar dependencias

```bash
flutter pub get
```

### 3. Configurar Supabase

#### A. Crear proyecto en Supabase

1. Ve a [supabase.com](https://supabase.com) y crea un nuevo proyecto
2. Espera a que se complete la inicialización

#### B. Configurar la base de datos

1. En el panel de Supabase, ve a **SQL Editor**
2. Abre el archivo `supabase_setup.sql` de este proyecto
3. Copia y pega el contenido en el SQL Editor
4. Ejecuta el script (esto creará la tabla `dishes` con todas sus políticas)

#### C. Configurar Storage

1. Ve a **Storage** en el panel de Supabase
2. Crea un nuevo bucket llamado `dishes`
3. Configura el bucket como **público**
4. Ve a **Policies** del bucket y agrega las siguientes políticas:

**Policy 1: Subir imágenes**
- Name: `Users can upload dish images`
- Definition: 
```sql
bucket_id = 'dishes' AND (storage.foldername(name))[1] = auth.uid()::text
```

**Policy 2: Eliminar imágenes**
- Name: `Users can delete their dish images`
- Definition:
```sql
bucket_id = 'dishes' AND (storage.foldername(name))[1] = auth.uid()::text
```

#### D. Obtener credenciales

1. Ve a **Settings** > **API**
2. Copia tu `URL` y `anon public` key
3. Actualiza el archivo `.env`:

```env
SUPABASE_URL=tu_supabase_url
SUPABASE_ANON_KEY=tu_supabase_anon_key
OPENAI_API_KEY=tu_openai_api_key
```

### 4. Configurar OpenAI API

1. Ve a [platform.openai.com](https://platform.openai.com/)
2. Crea una cuenta o inicia sesión
3. Ve a **API Keys** y crea una nueva key
4. Copia la key y agrégala al archivo `.env`

**Nota**: La API de OpenAI tiene costo. Asegúrate de revisar los precios en su sitio web.

### 5. Configurar permisos (Android)

Agrega los siguientes permisos en `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.INTERNET"/>
```

### 6. Configurar permisos (iOS)

Agrega las siguientes claves en `ios/Runner/Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>Necesitamos acceso a la cámara para tomar fotos de platillos</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Necesitamos acceso a la galería para seleccionar fotos</string>
```

## ▶️ Ejecutar la aplicación

```bash
flutter run
```

## 🧪 Modo de prueba (sin API de OpenAI)

Si quieres probar la app sin configurar la API de OpenAI, puedes usar el método mock:

En `lib/presentation/controllers/dish_controller.dart`, línea ~108, cambia:

```dart
// De:
final result = await _aiService.analyzeDishImage(selectedImage.value!);

// A:
final result = await _aiService.analyzeDishImageMock(selectedImage.value!);
```

## 📱 Uso de la aplicación

1. **Registro/Login**: Crea una cuenta o inicia sesión
2. **Capturar foto**: Presiona el botón flotante "Tomar Foto"
3. **Tomar/Seleccionar imagen**: Usa la cámara o selecciona de la galería
4. **Análisis automático**: La IA analizará la imagen automáticamente
5. **Revisar resultados**: Verifica el nombre del platillo e ingredientes detectados
6. **Guardar**: Presiona "Guardar Platillo" para almacenarlo
7. **Ver lista**: Los platillos guardados aparecerán en la lista principal

## 🔧 Personalización

### Cambiar el modelo de IA

En `lib/data/services/ai_service.dart`, puedes cambiar el modelo:

```dart
'model': 'gpt-4o-mini',  // Cambia a 'gpt-4-vision-preview' para mejor precisión
```

### Ajustar la calidad de las imágenes

En `lib/presentation/controllers/dish_controller.dart`:

```dart
imageQuality: 80,  // Ajusta entre 0-100
```

## 🐛 Solución de problemas

### Error: "Storage bucket not found"
- Verifica que creaste el bucket `dishes` en Supabase Storage
- Asegúrate de que el bucket sea público

### Error: "Row Level Security policy violation"
- Verifica que ejecutaste el script SQL completo
- Revisa que las políticas RLS estén habilitadas

### La IA no funciona
- Verifica tu OPENAI_API_KEY en el archivo `.env`
- Asegúrate de tener créditos en tu cuenta de OpenAI
- Usa el método mock para probar sin API

### Problemas con la cámara
- Verifica los permisos en AndroidManifest.xml (Android)
- Verifica los permisos en Info.plist (iOS)
- Prueba en un dispositivo real (algunos emuladores tienen problemas con la cámara)

## 📄 Licencia

Este proyecto es de código abierto y está disponible bajo la licencia MIT.

## 👨‍💻 Autor

Desarrollado siguiendo los principios de Clean Architecture y mejores prácticas de Flutter.

---

**¡Disfruta analizando tus platillos con IA! 🍕🤖**
