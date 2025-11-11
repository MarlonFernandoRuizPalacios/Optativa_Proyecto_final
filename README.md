# 🍽️ FoodAI - Analizador de Platillos con IA

Una aplicación Flutter que utiliza Inteligencia Artificial para identificar ingredientes de platillos a través de fotografías. Construida con Clean Architecture, Supabase y Google Gemini AI.

## 📋 Características

- 📸 **Captura de fotos**: Toma fotos directamente desde la cámara o selecciona de la galería
- 🤖 **Análisis con IA**: Identifica automáticamente el nombre del platillo e ingredientes usando Google Gemini AI
- 💾 **Almacenamiento en la nube**: Guarda platillos e imágenes en Supabase
- 📱 **Interfaz moderna**: UI/UX limpia y responsive con Material Design
- 🔐 **Autenticación**: Login seguro con Supabase Auth
- 🏗️ **Clean Architecture**: Código organizado, mantenible y escalable
- 💿 **Sincronización Offline**: Base de datos local SQLite con sincronización automática
- ✅ **Validación de comida**: Detecta automáticamente si la imagen contiene comida

## 🛠️ Tecnologías

- **Flutter** - Framework UI multiplataforma
- **Dart** - Lenguaje de programación (^3.9.0)
- **GetX** - Gestión de estado y navegación
- **Supabase** - Backend as a Service (Base de datos + Storage + Auth)
- **Google Gemini AI** - Análisis de imágenes con IA (gemini-1.5-flash)
- **SQLite** - Base de datos local con sincronización offline-first
- **Image Picker** - Captura de fotos
- **Clean Architecture** - Arquitectura en capas

## 📦 Paquetes Utilizados

```yaml
dependencies:
  get: ^4.6.6                      # State management
  supabase_flutter: ^2.5.6         # Backend as a Service
  google_generative_ai: ^0.4.7     # Google Gemini AI
  sqflite: ^2.4.2                  # Local database
  flutter_dotenv: ^5.1.0           # Environment variables
  image_picker: ^1.0.7             # Image capture
  http: ^1.2.0                     # HTTP client
  path_provider: ^2.1.2            # File system paths
  permission_handler: ^11.3.0      # Device permissions
  intl: ^0.19.0                    # Internationalization
```

## 📦 Estructura del Proyecto (Clean Architecture)

```
lib/
├── core/
│   ├── config/          # Configuraciones (Supabase)
│   │   └── supabase_config.dart
│   └── constants/       # Constantes (Colores, etc)
│       └── app_colors.dart
├── data/
│   ├── repositories/    # Implementación de repositorios
│   │   └── dish_repository_impl.dart
│   └── services/        # Servicios (AI, Storage, DB Local)
│       ├── ai_service.dart
│       ├── storage_service.dart
│       └── local_database_service.dart
├── domain/
│   ├── entities/        # Entidades de dominio
│   │   └── dish_entity.dart
│   └── repositories/    # Interfaces de repositorios
│       └── dish_repository.dart
└── presentation/
    ├── controllers/     # Controladores GetX
    │   ├── dish_controller.dart
    │   └── auth_controller.dart
    ├── pages/           # Pantallas
    │   ├── auth_page.dart
    │   ├── auth_gate.dart
    │   ├── home_menu_page.dart
    │   ├── capture_dish_page.dart
    │   ├── dishes_list_page.dart
    │   └── dish_detail_page.dart
    └── widgets/         # Widgets reutilizables
        ├── image_preview_widget.dart
        ├── action_button_widget.dart
        ├── loading_card_widget.dart
        ├── error_card_widget.dart
        ├── dish_card_widget.dart
        └── ingredients_list_widget.dart
```

## 🚀 Configuración

### 1. Clonar el repositorio

```bash
git clone https://github.com/MarlonFernandoRuizPalacios/Optativa_Proyecto_final.git
cd Optativa_Proyecto_final
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
2. Crea un nuevo bucket llamado `dishes` (lowercase)
3. Configura el bucket como **público**

Las políticas RLS ya están incluidas en el script SQL.

#### D. Obtener credenciales

1. Ve a **Settings** > **API**
2. Copia tu `URL` y `anon public` key

### 4. Configurar Google Gemini API

1. Ve a [Google AI Studio](https://makersuite.google.com/app/apikey)
2. Crea una cuenta o inicia sesión
3. Crea una API Key
4. Copia la key

**Nota**: Gemini AI tiene un tier gratuito generoso. Revisa los límites en [ai.google.dev](https://ai.google.dev/pricing)

### 5. Crear archivo .env

Crea un archivo `.env` en la raíz del proyecto:

```env
SUPABASE_URL=tu_supabase_url
SUPABASE_ANON_KEY=tu_supabase_anon_key
GEMINI_API_KEY=tu_gemini_api_key
```

### 6. Configurar permisos (Android)

Los permisos ya están configurados en `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.INTERNET"/>
```

### 7. Configurar permisos (iOS)

Los permisos ya están en `ios/Runner/Info.plist`:

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

## 📱 Uso de la aplicación

1. **Registro/Login**: Crea una cuenta o inicia sesión
2. **Capturar foto**: Presiona el botón "Tomar Foto"
3. **Tomar/Seleccionar imagen**: Usa la cámara o selecciona de la galería
4. **Análisis automático**: La IA analizará la imagen automáticamente
5. **Revisar resultados**: Verifica el nombre del platillo e ingredientes detectados
6. **Guardar**: Presiona "Guardar Platillo" para almacenarlo
7. **Ver lista**: Los platillos guardados aparecerán en la lista principal

## 🏗️ Arquitectura Implementada

### Clean Architecture - Separación de Capas

```
┌─────────────────────────────────────────────────────────┐
│                    PRESENTATION                          │
│  ┌──────────┐  ┌──────────┐  ┌─────────────────────┐  │
│  │  Pages   │  │ Widgets  │  │ Controllers (GetX)  │  │
│  └──────────┘  └──────────┘  └─────────────────────┘  │
└─────────────────────────────────────────────────────────┘
                         ▼
┌─────────────────────────────────────────────────────────┐
│                     DOMAIN                               │
│  ┌──────────────┐  ┌─────────────────────────────┐     │
│  │  Entities    │  │ Repository Interfaces       │     │
│  └──────────────┘  └─────────────────────────────┘     │
└─────────────────────────────────────────────────────────┘
                         ▼
┌─────────────────────────────────────────────────────────┐
│                      DATA                                │
│  ┌──────────────┐  ┌─────────────────┐                 │
│  │ Repositories │  │    Services     │                 │
│  └──────────────┘  └─────────────────┘                 │
│                     │                                    │
│   ┌─────────────────┼────────────────┐                 │
│   │                 │                │                 │
│ ┌─▼────┐     ┌──────▼───┐   ┌──────▼───┐             │
│ │ Supabase│   │  SQLite  │   │ Gemini AI│             │
│ │(Cloud) │   │ (Local)  │   │  (API)   │             │
│ └────────┘   └──────────┘   └──────────┘             │
└─────────────────────────────────────────────────────────┘
```

### Capas del Proyecto

**PRESENTATION (UI)**
- **Pages**: Pantallas de la aplicación
- **Widgets**: Componentes reutilizables
- **Controllers**: Lógica de presentación con GetX

**DOMAIN (Reglas de Negocio)**
- **Entities**: Modelos de dominio puro
- **Repositories**: Interfaces (contratos)

**DATA (Acceso a Datos)**
- **Repositories**: Implementaciones de interfaces
- **Services**: Servicios externos (IA, Storage, DB)

## 🔧 Funcionalidades Implementadas

### ✅ Widgets Reutilizables (6)
- ImagePreviewWidget
- ActionButtonWidget
- LoadingCardWidget
- ErrorCardWidget
- DishCardWidget
- IngredientsListWidget

### ✅ Clean Architecture
- Separación de capas (Presentation/Domain/Data)
- Inyección de dependencias
- Código mantenible y escalable

### ✅ Supabase
- Autenticación (Auth)
- Base de datos PostgreSQL (dishes table)
- Storage (dishes bucket)
- Row Level Security (RLS)

### ✅ Base de Datos Locales
- SQLite (sqflite)
- Sincronización offline-first
- Cache local de datos
- Trabajo sin conexión

### ✅ Integración con IA
- Google Gemini AI (gemini-1.5-flash)
- Análisis de imágenes
- Identificación de platillos
- Extracción de ingredientes
- Validación de comida

### ✅ Manejo de Estado Global
- GetX (State Management)
- Variables reactivas (.obs)
- Controladores globales
- Navegación declarativa

## 🐛 Solución de problemas

### Error: "Storage bucket not found"
- Verifica que creaste el bucket `dishes` en Supabase Storage
- Asegúrate de que el bucket sea público

### Error: "Row Level Security policy violation"
- Verifica que ejecutaste el script SQL completo
- Revisa que las políticas RLS estén habilitadas

### La IA no funciona
- Verifica tu GEMINI_API_KEY en el archivo `.env`
- Asegúrate de tener acceso a Gemini API
- Revisa los límites de uso gratuito

### Problemas con la cámara
- Verifica los permisos en AndroidManifest.xml (Android)
- Verifica los permisos en Info.plist (iOS)
- Prueba en un dispositivo real

## 📚 Documentación Adicional

- `FOODAI_README.md` - Documentación específica de FoodAI
- `GEMINI_SETUP_GUIDE.md` - Guía de configuración de Gemini AI
- `SUPABASE_SETUP_GUIDE.md` - Guía de configuración de Supabase
- `VERIFICACION_REQUISITOS.md` - Verificación de requisitos del proyecto
- `VERIFICACION_FINAL.md` - Verificación final completa

## 📄 Licencia

Este proyecto es de código abierto y está disponible bajo la licencia MIT.

## 👨‍💻 Autor

Desarrollado siguiendo los principios de Clean Architecture y mejores prácticas de Flutter.

**Repositorio:** https://github.com/MarlonFernandoRuizPalacios/Optativa_Proyecto_final

---

**¡Disfruta analizando tus platillos con IA! 🍕🤖**
