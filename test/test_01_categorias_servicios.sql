USE BDABD_BlackCatDB;
GO

SET NOCOUNT ON;

PRINT '==================================================';
PRINT '   INSERCIÓN DE CATEGORÍAS Y SERVICIOS - BLACK CAT';
PRINT '==================================================';

--------------------------------------------------------------------------------
-- 1. REGISTRO DIRECTO DE CATEGORÍAS
--------------------------------------------------------------------------------
INSERT INTO Categorias (Nombre) VALUES
(N'Impresión Publicitaria'),
(N'Producción Audiovisual'),
(N'Diseño Gráfico'),
(N'Merchandising');

PRINT '>> Categorías insertadas exitosamente.';
GO

--------------------------------------------------------------------------------
-- 2. REGISTRO DIRECTO DE SERVICIOS CON PRECIOS BASE (PEN S/.)
--------------------------------------------------------------------------------
DECLARE @CatImpresion INT = (SELECT IdCategoria FROM Categorias WHERE Nombre = N'Impresión Publicitaria');
DECLARE @CatAudiovisual INT = (SELECT IdCategoria FROM Categorias WHERE Nombre = N'Producción Audiovisual');
DECLARE @CatDiseno INT = (SELECT IdCategoria FROM Categorias WHERE Nombre = N'Diseño Gráfico');
DECLARE @CatMerch INT = (SELECT IdCategoria FROM Categorias WHERE Nombre = N'Merchandising');

INSERT INTO Servicios (Nombre, IdCategoria, Precio, Activo) VALUES
-- =============================================================================
-- Categoría 1: Impresión Publicitaria
-- =============================================================================
(N'Banner y Gigantografías en Lona Frontlit (m2)', @CatImpresion, 25.00, 1),
(N'Lonas Publicitarias y Backings para Prensa', @CatImpresion, 180.00, 1),
(N'Roll Up Publicitario con Estructura de Aluminio (85x200cm)', @CatImpresion, 95.00, 1),
(N'Impresión en Vinil Adhesivo Brillante/Mate (m2)', @CatImpresion, 35.00, 1),
(N'Stickers Publicitarios Troquelados (Pliego 1x1m)', @CatImpresion, 45.00, 1),
(N'Vinil Microperforado para Ventanas y Vehículos (m2)', @CatImpresion, 42.00, 1),
(N'Vinil Arenado / Frost para Mamparas (m2)', @CatImpresion, 50.00, 1),
(N'Etiquetas Adhesivas Personalizadas en Rollo (Millar)', @CatImpresion, 120.00, 1),
(N'Tarjetas de Presentación en Couché con Plastificado Mate (Millar)', @CatImpresion, 65.00, 1),
(N'Brochures y Dípticos/Trípticos Publicitarios (Ciento)', @CatImpresion, 110.00, 1),
(N'Credenciales y Fotochecks Corporativos en PVC (Unidad)', @CatImpresion, 12.00, 1),
(N'Catálogos Corporativos Anillados / Encolados (Ciento)', @CatImpresion, 450.00, 1),
(N'Señaléticas Corporativas y de Seguridad en Celtex (Unidad)', @CatImpresion, 28.00, 1),
(N'Paneles Publicitarios con Bastidor Metálico', @CatImpresion, 320.00, 1),
(N'Material POP en Acrílico y Foamboard', @CatImpresion, 85.00, 1),
(N'Letreros Corpóreos con Iluminación LED', @CatImpresion, 850.00, 1),

-- =============================================================================
-- Categoría 2: Producción Audiovisual
-- =============================================================================
(N'Video Corporativo e Institucional Full HD / 4K', @CatAudiovisual, 1200.00, 1),
(N'Videos Promocionales y Spots Publicitarios', @CatAudiovisual, 850.00, 1),
(N'Pack de 5 Reels / TikToks para Redes Sociales', @CatAudiovisual, 450.00, 1),
(N'Fotografía Profesional de Producto para Catálogo / E-commerce', @CatAudiovisual, 350.00, 1),
(N'Sesión Fotográfica Empresarial y Retrato Corporativo', @CatAudiovisual, 400.00, 1),
(N'Cobertura Audiovisual de Inauguraciones y Eventos', @CatAudiovisual, 650.00, 1),
(N'Transmisión en Vivo Multicámara (Live Streaming)', @CatAudiovisual, 950.00, 1),
(N'Edición de Video y Postproducción Digital', @CatAudiovisual, 300.00, 1),
(N'Motion Graphics y Animación Publicitaria 2D', @CatAudiovisual, 500.00, 1),
(N'Colorización y Tratamiento de Color Profesional (Color Grading)', @CatAudiovisual, 280.00, 1),

-- =============================================================================
-- Categoría 3: Diseño Gráfico
-- =============================================================================
(N'Diseño de Logotipo y Naming Comercial', @CatDiseno, 400.00, 1),
(N'Manual de Marca e Identidad Visual Completa', @CatDiseno, 900.00, 1),
(N'Diseño de Papelería Corporativa (Hojas, Sobres, Folders)', @CatDiseno, 220.00, 1),
(N'Diseño Publicitario para Flyers y Folletos', @CatDiseno, 120.00, 1),
(N'Diseño de Banners y Arte para Campañas Publicitarias', @CatDiseno, 150.00, 1),
(N'Pack Mensual de Piezas Gráficas para Redes (12 Posts + Historias)', @CatDiseno, 600.00, 1),
(N'Diseño de Portadas y Cabeceras para Plataformas Digitales', @CatDiseno, 90.00, 1),
(N'Diseño y Maquetación de Catálogos / Revistas Digitales (por pliego)', @CatDiseno, 250.00, 1),
(N'Diseño de Packaging y Empaques Personalizados', @CatDiseno, 480.00, 1),
(N'Renderizado de Mockups y Retoque Fotográfico Publicitario', @CatDiseno, 180.00, 1),

-- =============================================================================
-- Categoría 4: Merchandising
-- =============================================================================
(N'Llaveros Publicitarios en Acrílico / Metal (Ciento)', @CatMerch, 140.00, 1),
(N'Lanyards Personalizados con Porta Fotocheck (Ciento)', @CatMerch, 180.00, 1),
(N'Pines Metálicos Resinados Publicitarios (Ciento)', @CatMerch, 160.00, 1),
(N'Bolsas Ecológicas en Notex Estampadas (Ciento)', @CatMerch, 220.00, 1),
(N'Polos Publicitarios en Algodón con Estampado Serigráfico (Docena)', @CatMerch, 260.00, 1),
(N'Gorros y Gorras Bordadas Publicitarias (Docena)', @CatMerch, 190.00, 1),
(N'Chalecos Institucionales con Cintas Reflectivas y Bordado (Docena)', @CatMerch, 480.00, 1),
(N'Uniformes Corporativos / Cuello Camisero (Docena)', @CatMerch, 550.00, 1),
(N'Lapiceros Publicitarios con Impresión Tampográfica (Ciento)', @CatMerch, 85.00, 1),
(N'Agendas Corporativas Personalizadas en Biocuero (Ciento)', @CatMerch, 1800.00, 1),
(N'Cuadernos Corporativos Anillados (Ciento)', @CatMerch, 650.00, 1),
(N'Mouse Pads Publicitarios Ergonómicos (Ciento)', @CatMerch, 380.00, 1),
(N'Tazas Personalizadas de Cerámica / Mágicas (Docena)', @CatMerch, 120.00, 1),
(N'Termos Metálicos Personalizados con Grabado Láser (Docena)', @CatMerch, 300.00, 1),
(N'Tomatodos Publicitarios de Aluminio / Plástico (Docena)', @CatMerch, 150.00, 1),
(N'Exhibidores y Portafolletos Acrílicos de Mostrador', @CatMerch, 65.00, 1);

PRINT '>> Servicios insertados exitosamente.';
GO

--------------------------------------------------------------------------------
-- 3. CONSULTAS DE VALIDACIÓN Y VERIFICACIÓN
--------------------------------------------------------------------------------
-- Resumen por Categoría con métricas de precios:
SELECT 
    c.Nombre AS Categoria,
    COUNT(s.IdServicio) AS TotalServicios,
    MIN(s.Precio) AS PrecioMinimo_Soles,
    MAX(s.Precio) AS PrecioMaximo_Soles,
    CAST(AVG(s.Precio) AS DECIMAL(10,2)) AS PrecioPromedio_Soles
FROM Categorias c
LEFT JOIN Servicios s ON c.IdCategoria = s.IdCategoria
GROUP BY c.IdCategoria, c.Nombre
ORDER BY c.IdCategoria;

-- Listado detallado de servicios:
SELECT 
    s.IdServicio,
    c.Nombre AS Categoria,
    s.Nombre AS Servicio,
    s.Precio AS Precio_PEN,
    CASE WHEN s.Activo = 1 THEN 'ACTIVO' ELSE 'INACTIVO' END AS Estado
FROM Servicios s
INNER JOIN Categorias c ON s.IdCategoria = c.IdCategoria
ORDER BY c.IdCategoria, s.Precio ASC;
GO