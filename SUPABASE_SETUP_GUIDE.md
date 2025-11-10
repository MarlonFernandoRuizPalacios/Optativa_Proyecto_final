# 🔧 Configuración de Supabase - Guía Paso a Paso

## 1️⃣ Ejecutar el Script SQL

### Opción A: Desde el Editor SQL de Supabase
1. Ve a tu proyecto en [supabase.com](https://supabase.com)
2. En el menú lateral, selecciona **SQL Editor**
3. Haz clic en **+ New query**
4. Abre el archivo `supabase_setup.sql` de este proyecto
5. Copia TODO el contenido del archivo
6. Pégalo en el editor SQL de Supabase
7. Haz clic en **Run** (o presiona Ctrl/Cmd + Enter)
8. Deberías ver el mensaje "Success. No rows returned"

### Verificar que se creó correctamente
Ejecuta esta consulta en el SQL Editor:
```sql
SELECT * FROM pg_tables WHERE schemaname = 'public' AND tablename = 'dishes';
```
Deberías ver un resultado con la tabla `dishes`.

---

## 2️⃣ Crear el Bucket de Storage

1. En el menú lateral de Supabase, ve a **Storage**
2. Haz clic en **Create a new bucket**
3. Configura el bucket:
   - **Name**: `dishes`
   - **Public bucket**: ✅ **ACTIVAR** (muy importante)
   - **File size limit**: 5 MB (o el que prefieras)
   - **Allowed MIME types**: deja vacío para permitir todos
4. Haz clic en **Create bucket**

---

## 3️⃣ Configurar Políticas del Bucket

### Política 1: Permitir subir imágenes (INSERT)
1. En Storage, haz clic en el bucket **dishes**
2. Ve a la pestaña **Policies**
3. Haz clic en **New policy**
4. Selecciona **Create policy from scratch**
5. Configura:
   - **Policy name**: `Users can upload dish images`
   - **Allowed operation**: SELECT **INSERT**
   - **Target roles**: `authenticated`
   - **USING expression**: Deja vacío
   - **WITH CHECK expression**: 
   ```sql
   bucket_id = 'dishes' AND (storage.foldername(name))[1] = auth.uid()::text
   ```
6. Haz clic en **Review** y luego **Save policy**

### Política 2: Permitir eliminar imágenes (DELETE)
1. Haz clic nuevamente en **New policy**
2. Selecciona **Create policy from scratch**
3. Configura:
   - **Policy name**: `Users can delete their dish images`
   - **Allowed operation**: SELECT **DELETE**
   - **Target roles**: `authenticated`
   - **USING expression**: 
   ```sql
   bucket_id = 'dishes' AND (storage.foldername(name))[1] = auth.uid()::text
   ```
   - **WITH CHECK expression**: Deja vacío
4. Haz clic en **Review** y luego **Save policy**

### Política 3: Permitir ver imágenes (SELECT) - OPCIONAL
Si configuraste el bucket como privado, necesitas esta política:
1. Haz clic en **New policy**
2. Configura:
   - **Policy name**: `Users can view their dish images`
   - **Allowed operation**: SELECT **SELECT**
   - **Target roles**: `authenticated`
   - **USING expression**: 
   ```sql
   bucket_id = 'dishes' AND (storage.foldername(name))[1] = auth.uid()::text
   ```
3. Haz clic en **Review** y luego **Save policy**

**NOTA**: Si el bucket es público, esta política no es necesaria.

---

## 4️⃣ Obtener las Credenciales

1. En el menú lateral, ve a **Settings** (⚙️)
2. Selecciona **API**
3. Copia los siguientes valores:
   - **Project URL**: Tu URL de Supabase
   - **anon public**: Tu clave pública (anon key)

---

## 5️⃣ Actualizar el archivo .env

1. Abre el archivo `.env` en la raíz del proyecto Flutter
2. Reemplaza los valores:
```env
SUPABASE_URL=https://tu-proyecto.supabase.co
SUPABASE_ANON_KEY=tu-anon-key-aqui
OPENAI_API_KEY=tu-openai-api-key
```

---

## 6️⃣ Configurar OpenAI API (para análisis de IA)

1. Ve a [platform.openai.com](https://platform.openai.com/)
2. Inicia sesión o crea una cuenta
3. Ve a **API keys** en el menú
4. Haz clic en **Create new secret key**
5. Dale un nombre (ej: "FoodAI App")
6. Copia la clave y guárdala en el archivo `.env`

**⚠️ IMPORTANTE**: 
- La API de OpenAI es de pago (tiene un período de prueba con créditos)
- Revisa los precios en [openai.com/pricing](https://openai.com/pricing)
- El modelo `gpt-4o-mini` es más económico que `gpt-4-vision-preview`

### Alternativa: Usar el modo Mock (sin costo)
Si no quieres usar la API real, puedes usar respuestas simuladas:
1. Abre `lib/presentation/controllers/dish_controller.dart`
2. En la línea ~108, cambia:
```dart
final result = await _aiService.analyzeDishImage(selectedImage.value!);
// Por:
final result = await _aiService.analyzeDishImageMock(selectedImage.value!);
```

---

## ✅ Verificación Final

### Verificar la tabla
```sql
SELECT * FROM dishes LIMIT 5;
```
Debería devolver 0 filas (pero sin error).

### Verificar las políticas RLS
```sql
SELECT tablename, policyname, permissive, roles, cmd 
FROM pg_policies 
WHERE tablename = 'dishes';
```
Deberías ver 4 políticas (SELECT, INSERT, UPDATE, DELETE).

### Verificar el bucket
1. Ve a Storage > dishes
2. Debería estar marcado como "Public"
3. Deberías ver 2-3 políticas configuradas

---

## 🚨 Problemas Comunes

### Error: "new row violates row-level security policy"
- **Solución**: Verifica que ejecutaste TODO el script SQL, especialmente las políticas RLS

### Error: "Storage bucket not found"
- **Solución**: Crea el bucket `dishes` en Storage

### Error: "permission denied for bucket"
- **Solución**: Verifica que el bucket sea público O que hayas configurado las políticas correctamente

### Las imágenes no se muestran
- **Solución 1**: Verifica que el bucket sea público
- **Solución 2**: Verifica las URLs generadas en la consola de Flutter

### Error de OpenAI: "Invalid API key"
- **Solución**: Verifica que copiaste correctamente la API key en el `.env`
- **Solución 2**: Asegúrate de que el archivo `.env` esté en la raíz del proyecto

---

## 📋 Checklist Final

Antes de ejecutar la app, verifica:

- [ ] Script SQL ejecutado correctamente
- [ ] Tabla `dishes` creada
- [ ] 4 políticas RLS configuradas en la tabla
- [ ] Bucket `dishes` creado
- [ ] Bucket configurado como público
- [ ] 2-3 políticas de Storage configuradas
- [ ] SUPABASE_URL actualizada en `.env`
- [ ] SUPABASE_ANON_KEY actualizada en `.env`
- [ ] OPENAI_API_KEY configurada en `.env` (o usando modo mock)
- [ ] `flutter pub get` ejecutado

¡Listo! Ahora puedes ejecutar la aplicación con `flutter run` 🚀
