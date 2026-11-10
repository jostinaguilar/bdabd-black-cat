--------------------------------------------------------------------------------
-- SCRIPT DE SEGURIDAD DEL MOTOR: LOGINS, USUARIOS, ROLES Y PRIVILEGIOS
-- Base de Datos: BDABD_BlackCatDB
-- Normativas aplicadas:
--   1. Ley N.° 29733 (Protección de Datos Personales en Perú - Art. 11)
--   2. ISO/IEC 27001 (Mínimo privilegio, segregación e inmutabilidad de auditoría)
--------------------------------------------------------------------------------

USE master;
GO

-- 1. CREACIÓN DE LOGINS EN EL SERVIDOR (Nivel Motor)
IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'LoginAdmin')
    CREATE LOGIN LoginAdmin WITH PASSWORD = 'C0ntrasen@2026*', CHECK_POLICY = ON;

IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'LoginDisenadorGrafico')
    CREATE LOGIN LoginDisenadorGrafico WITH PASSWORD = 'C0ntrasen@2026*', CHECK_POLICY = ON;

IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'LoginDisenadorAudio')
    CREATE LOGIN LoginDisenadorAudio WITH PASSWORD = 'C0ntrasen@2026*', CHECK_POLICY = ON;

IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'LoginInstalador')
    CREATE LOGIN LoginInstalador WITH PASSWORD = 'C0ntrasen@2026*', CHECK_POLICY = ON;

IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'LoginAuditor')
    CREATE LOGIN LoginAuditor WITH PASSWORD = 'C0ntrasen@2026*', CHECK_POLICY = ON;

IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'LoginAnalista')
    CREATE LOGIN LoginAnalista WITH PASSWORD = 'C0ntrasen@2026*', CHECK_POLICY = ON;
GO

USE BDABD_BlackCatDB;
GO

-- 2. CREACIÓN DE ROLES DE BASE DE DATOS (Roles Técnicos Consolidados)
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'DbAdministrador' AND type = 'R')
    CREATE ROLE DbAdministrador;

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'DbDisenador' AND type = 'R')
    CREATE ROLE DbDisenador;

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'DbInstalador' AND type = 'R')
    CREATE ROLE DbInstalador;

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'DbAuditor' AND type = 'R')
    CREATE ROLE DbAuditor;

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'DbAnalista' AND type = 'R')
    CREATE ROLE DbAnalista;
GO

-- 3. ASIGNACIÓN DE PRIVILEGIOS POR ROL

-- Rol Administrador: Control de esquema y ejecución de procedimientos
GRANT CONTROL ON SCHEMA::dbo TO DbAdministrador;
GRANT EXECUTE TO DbAdministrador;

-- Roles de Producción (Diseñador e Instalador): Consulta operativa y avance de tareas
GRANT SELECT ON Tareas TO DbDisenador, DbInstalador;
GRANT SELECT ON Pedidos TO DbDisenador, DbInstalador;
GRANT SELECT ON DetalleCotizaciones TO DbDisenador, DbInstalador;
GRANT SELECT ON Revisiones TO DbDisenador, DbInstalador;
GRANT UPDATE ON Tareas TO DbDisenador, DbInstalador;

-- Rol Auditor (ISO 27001): Trazabilidad e inmutabilidad de logs forenses
GRANT SELECT ON AuditoriaLogs TO DbAuditor;
GRANT SELECT ON Usuarios TO DbAuditor;
GRANT SELECT ON Roles TO DbAuditor;
DENY INSERT, UPDATE, DELETE ON AuditoriaLogs TO DbAuditor; -- Inmutabilidad de auditoría
DENY SELECT ON Usuarios(Contrasena) TO DbAuditor;

-- Rol Analista (Ley N.° 29733 - Privacidad y Mínimo Privilegio)
GRANT SELECT ON Clientes TO DbAnalista;
GRANT SELECT ON Cotizaciones TO DbAnalista;
GRANT SELECT ON DetalleCotizaciones TO DbAnalista;
GRANT SELECT ON Pedidos TO DbAnalista;
GRANT SELECT ON Pagos TO DbAnalista;
GRANT SELECT ON Comprobantes TO DbAnalista;
GRANT SELECT ON Servicios TO DbAnalista;
GRANT SELECT ON Categorias TO DbAnalista;

-- Restricción de acceso a datos personales identificables (Art. 11 Ley 29733)
DENY SELECT ON Clientes(DniRuc, Telefono, Correo, Direccion) TO DbAnalista;
DENY SELECT ON Usuarios(Contrasena) TO DbAnalista;
GO

-- 4. CREACIÓN DE USUARIOS DE BASE DE DATOS Y ASOCIACIÓN A ROLES
-- Administrador
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'UsuarioAdmin')
    CREATE USER UsuarioAdmin FOR LOGIN LoginAdmin;
ALTER ROLE DbAdministrador ADD MEMBER UsuarioAdmin;

-- Diseñador Gráfico (Usuario individual para trazabilidad)
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'UsuarioDisenadorGrafico')
    CREATE USER UsuarioDisenadorGrafico FOR LOGIN LoginDisenadorGrafico;
ALTER ROLE DbDisenador ADD MEMBER UsuarioDisenadorGrafico;

-- Diseñador Audiovisual (Usuario individual para trazabilidad)
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'UsuarioDisenadorAudio')
    CREATE USER UsuarioDisenadorAudio FOR LOGIN LoginDisenadorAudio;
ALTER ROLE DbDisenador ADD MEMBER UsuarioDisenadorAudio;

-- Instalador
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'UsuarioInstalador')
    CREATE USER UsuarioInstalador FOR LOGIN LoginInstalador;
ALTER ROLE DbInstalador ADD MEMBER UsuarioInstalador;

-- Auditor
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'UsuarioAuditor')
    CREATE USER UsuarioAuditor FOR LOGIN LoginAuditor;
ALTER ROLE DbAuditor ADD MEMBER UsuarioAuditor;

-- Analista
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'UsuarioAnalista')
    CREATE USER UsuarioAnalista FOR LOGIN LoginAnalista;
ALTER ROLE DbAnalista ADD MEMBER UsuarioAnalista;
GO

PRINT '>> Script de Seguridad de Motor (roles.sql) ejecutado correctamente.';
GO
