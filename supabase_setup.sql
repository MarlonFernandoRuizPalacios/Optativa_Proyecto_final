-- ============================================
-- CONFIGURACIÓN DE SUPABASE PARA FOODAI APP
-- ============================================

-- 1. Crear tabla de platillos (dishes)
CREATE TABLE IF NOT EXISTS public.dishes (
    id TEXT PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    ingredients TEXT[] NOT NULL DEFAULT '{}',
    image_url TEXT NOT NULL,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- 2. Crear índice para mejorar las consultas por usuario
CREATE INDEX IF NOT EXISTS idx_dishes_user_id ON public.dishes(user_id);
CREATE INDEX IF NOT EXISTS idx_dishes_created_at ON public.dishes(created_at DESC);

-- 3. Habilitar Row Level Security (RLS)
ALTER TABLE public.dishes ENABLE ROW LEVEL SECURITY;

-- 4. Crear políticas de seguridad
-- Política para SELECT: los usuarios solo pueden ver sus propios platillos
CREATE POLICY "Users can view their own dishes"
ON public.dishes
FOR SELECT
USING (auth.uid() = user_id);

-- Política para INSERT: los usuarios solo pueden insertar sus propios platillos
CREATE POLICY "Users can insert their own dishes"
ON public.dishes
FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- Política para UPDATE: los usuarios solo pueden actualizar sus propios platillos
CREATE POLICY "Users can update their own dishes"
ON public.dishes
FOR UPDATE
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- Política para DELETE: los usuarios solo pueden eliminar sus propios platillos
CREATE POLICY "Users can delete their own dishes"
ON public.dishes
FOR DELETE
USING (auth.uid() = user_id);

-- ============================================
-- CONFIGURACIÓN DE STORAGE
-- ============================================

-- NOTA: Los siguientes pasos deben realizarse en la interfaz de Supabase:

-- 1. Crear bucket "dishes":
--    - Ir a Storage en el panel de Supabase
--    - Crear un nuevo bucket llamado "dishes"
--    - Configurar como PÚBLICO (public: true)

-- 2. Configurar políticas de Storage:

-- Política para subir imágenes (INSERT)
-- En Storage > dishes > Policies > New Policy
-- Policy name: "Users can upload dish images"
-- Policy definition:
-- bucket_id = 'dishes' AND (storage.foldername(name))[1] = auth.uid()::text

-- Política para ver imágenes (SELECT) - Solo si el bucket es privado
-- Policy name: "Users can view their dish images"
-- Policy definition:
-- bucket_id = 'dishes' AND (storage.foldername(name))[1] = auth.uid()::text

-- Política para eliminar imágenes (DELETE)
-- Policy name: "Users can delete their dish images"
-- Policy definition:
-- bucket_id = 'dishes' AND (storage.foldername(name))[1] = auth.uid()::text

-- ============================================
-- VERIFICACIÓN
-- ============================================

-- Verificar que la tabla se creó correctamente
SELECT table_name, column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'dishes';

-- Verificar las políticas
SELECT * FROM pg_policies WHERE tablename = 'dishes';
