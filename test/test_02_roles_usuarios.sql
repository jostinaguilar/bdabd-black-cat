USE BDABD_BlackCatDB;
GO

SET NOCOUNT ON;

PRINT '==================================================';
PRINT '   INSERCIÓN DE ROLES Y USUARIOS - BLACK CAT';
PRINT '==================================================';

--------------------------------------------------------------------------------
-- 1. REGISTRO DE ROLES EN LA TABLA Roles (Idempotente)
--------------------------------------------------------------------------------
-- Se definen los perfiles de la agencia Black Cat
DECLARE @RolesTable TABLE (Nombre VARCHAR(50));

INSERT INTO @RolesTable (Nombre) VALUES
('Administrador'),
('Diseñador Gráfico'),
('Diseñador Audiovisual'),
('Instalador'),
('Auditor'),
('Analista');

INSERT INTO Roles (Nombre)
SELECT rt.Nombre
FROM @RolesTable rt
WHERE NOT EXISTS (
    SELECT 1 FROM Roles r WHERE r.Nombre = rt.Nombre
);

PRINT '>> Roles de negocio verificados/insertados exitosamente.';
GO

--------------------------------------------------------------------------------
-- 2. REGISTRO DE USUARIOS OPERATIVOS DE BLACK CAT (Idempotente)
--------------------------------------------------------------------------------
DECLARE @RolAdmin INT = (SELECT IdRol FROM Roles WHERE Nombre = 'Administrador');
DECLARE @RolDisenoGrafico INT = (SELECT IdRol FROM Roles WHERE Nombre = 'Diseñador Gráfico');
DECLARE @RolDisenoAudio INT = (SELECT IdRol FROM Roles WHERE Nombre = 'Diseñador Audiovisual');
DECLARE @RolInstalador INT = (SELECT IdRol FROM Roles WHERE Nombre = 'Instalador');

DECLARE @UsuariosTable TABLE (
    NombresCompletos NVARCHAR(150),
    NombreUsuario VARCHAR(50),
    IdRol INT,
    Contrasena VARCHAR(255),
    Telefono VARCHAR(20),
    Correo VARCHAR(100),
    Activo BIT
);

-- Para fines de seguridad y buenas prácticas, simulamos hash SHA2_256 estándar:
-- Contraseña base: BlackCat2026* (hash: 0x8D969EEF6ECAD3C29A3A629280E686CF0C3F5D5A86AFF3CA12020C923ADC6C92)
DECLARE @HashPwdDefault VARCHAR(255) = CONVERT(VARCHAR(255), HASHBYTES('SHA2_256', 'BlackCat2026*'), 2);

INSERT INTO @UsuariosTable (NombresCompletos, NombreUsuario, IdRol, Contrasena, Telefono, Correo, Activo) VALUES
-- 1. Administrador General (Gestión integral, cotizaciones, aprobación y finanzas)
(N'Renzo Aguilar Morales', 'admin.aguilar', @RolAdmin, @HashPwdDefault, '987654321', 'raguilar@blackcat.pe', 1),

-- 2. Diseñadora Gráfica Senior (Identidad corporativa, packaging, editorial, redes)
(N'Valeria Mendoza Solís', 'valeria.diseno', @RolDisenoGrafico, @HashPwdDefault, '981234567', 'vmendoza@blackcat.pe', 1),

-- 3. Diseñador y Productor Audiovisual (Spots, reels, motion graphics, fotografía)
(N'Carlos Huamán Rivas', 'carlos.audio', @RolDisenoAudio, @HashPwdDefault, '982345678', 'chuaman@blackcat.pe', 1),

-- 4. Técnico de Instalaciones y Acabados de Campo (Gigantografías, viniles, letreros)
(N'Jorge Quispe Tello', 'jorge.instalador', @RolInstalador, @HashPwdDefault, '983456789', 'jquispe@blackcat.pe', 1);

-- Inserción idempotente evaluando NombreUsuario (columna UNIQUE)
INSERT INTO Usuarios (NombresCompletos, NombreUsuario, IdRol, Contrasena, Telefono, Correo, Activo)
SELECT 
    ut.NombresCompletos,
    ut.NombreUsuario,
    ut.IdRol,
    ut.Contrasena,
    ut.Telefono,
    ut.Correo,
    ut.Activo
FROM @UsuariosTable ut
WHERE NOT EXISTS (
    SELECT 1 FROM Usuarios u WHERE u.NombreUsuario = ut.NombreUsuario
);

PRINT '>> Usuarios operativos verificados/insertados exitosamente.';
GO

--------------------------------------------------------------------------------
-- 3. CONSULTA DE VALIDACIÓN Y PRUEBA (VERIFICACIÓN)
--------------------------------------------------------------------------------
-- Conteo de usuarios asignados por rol
SELECT 
    r.Nombre AS Rol,
    COUNT(u.IdUsuario) AS CantidadUsuarios
FROM Roles r
LEFT JOIN Usuarios u ON r.IdRol = u.IdRol
GROUP BY r.IdRol, r.Nombre
ORDER BY r.IdRol;

-- Detalle del personal operativo registrado
SELECT 
    u.IdUsuario,
    u.NombresCompletos,
    u.NombreUsuario,
    r.Nombre AS RolAsignado,
    u.Telefono,
    u.Correo,
    CASE WHEN u.Activo = 1 THEN 'ACTIVO' ELSE 'INACTIVO' END AS Estado
FROM Usuarios u
INNER JOIN Roles r ON u.IdRol = r.IdRol
ORDER BY u.IdUsuario ASC;
GO
