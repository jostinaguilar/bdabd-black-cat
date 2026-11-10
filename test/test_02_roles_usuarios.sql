USE BDABD_BlackCatDB;
GO

SET NOCOUNT ON;

PRINT '==================================================';
PRINT '   INSERCIÓN DE ROLES Y USUARIOS - BLACK CAT';
PRINT '==================================================';

--------------------------------------------------------------------------------
-- 1. REGISTRO DIRECTO DE ROLES EN LA TABLA Roles
--------------------------------------------------------------------------------
INSERT INTO Roles (Nombre) VALUES
('Administrador'),
('Diseñador Gráfico'),
('Diseñador Audiovisual'),
('Instalador'),
('Auditor'),
('Analista');

PRINT '>> Roles de negocio insertados exitosamente.';
GO

--------------------------------------------------------------------------------
-- 2. REGISTRO DE USUARIOS OPERATIVOS DE BLACK CAT
--------------------------------------------------------------------------------
DECLARE @RolAdmin INT = (SELECT IdRol FROM Roles WHERE Nombre = 'Administrador');
DECLARE @RolDisenoGrafico INT = (SELECT IdRol FROM Roles WHERE Nombre = 'Diseñador Gráfico');
DECLARE @RolDisenoAudiovisual INT = (SELECT IdRol FROM Roles WHERE Nombre = 'Diseñador Audiovisual');
DECLARE @RolInstalador INT = (SELECT IdRol FROM Roles WHERE Nombre = 'Instalador');

-- Hash SHA2_256 de contraseña base (BlackCat2026*)
DECLARE @HashPwdDefault VARCHAR(255) = CONVERT(VARCHAR(255), HASHBYTES('SHA2_256', 'BlackCat2026*'), 2);

INSERT INTO Usuarios (NombresCompletos, NombreUsuario, IdRol, Contrasena, Telefono, Correo, Activo) VALUES
-- 1. Administrador General
(N'Renzo Aguilar Morales', 'admin.aguilar', @RolAdmin, @HashPwdDefault, '987654321', 'raguilar@blackcat.pe', 1),

-- 2. Diseñadora Gráfica Senior
(N'Valeria Mendoza Solís', 'valeria.diseno', @RolDisenoGrafico, @HashPwdDefault, '981234567', 'vmendoza@blackcat.pe', 1),

-- 3. Diseñador y Productor Audiovisual (Audiovisual completo)
(N'Carlos Huamán Rivas', 'carlos.audiovisual', @RolDisenoAudiovisual, @HashPwdDefault, '982345678', 'chuaman@blackcat.pe', 1),

-- 4. Técnico de Instalaciones de Campo
(N'Jorge Quispe Tello', 'jorge.instalador', @RolInstalador, @HashPwdDefault, '983456789', 'jquispe@blackcat.pe', 1);

PRINT '>> Usuarios operativos insertados exitosamente.';
GO

--------------------------------------------------------------------------------
-- 3. CONSULTA DE VALIDACIÓN Y PRUEBA (VERIFICACIÓN)
--------------------------------------------------------------------------------
-- Conteo de usuarios por rol:
SELECT 
    r.Nombre AS Rol,
    COUNT(u.IdUsuario) AS CantidadUsuarios
FROM Roles r
LEFT JOIN Usuarios u ON r.IdRol = u.IdRol
GROUP BY r.IdRol, r.Nombre
ORDER BY r.IdRol;

-- Detalle del personal operativo registrado:
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
