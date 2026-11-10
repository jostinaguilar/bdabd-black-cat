USE master
GO

-- =================================================================================================
-- POLÍTICA DE RESPALDOS Y RECUPERACIÓN ANTE DESASTRES - BLACK CAT
-- Alineado a ISO 27001 (A.12.3 Respaldo de información) y Ley N.° 29733 (Art. 11 Medidas de seguridad técnica)
-- =================================================================================================
-- 1. ESTRATEGIA DE RESPALDO:
--    - Respaldo Completo (FULL): Semanal (domingos a las 00:00 h).
--    - Respaldo Diferencial (DIFF): Diario (lunes a sábado a las 20:00 h).
--
-- 2. MÉTRICAS DE CONTINUIDAD DEL NEGOCIO:
--    - RPO (Recovery Point Objective): Máximo 24 horas (pérdida máxima tolerable en caso de desastre).
--    - RTO (Recovery Time Objective): Menor a 15 minutos (restauración de 1 FULL + 1 DIFF más reciente).
-- =================================================================================================

-- -------------------------------------------------------------------------------------------------
-- FASE 1: GENERACIÓN DE RESPALDOS
-- -------------------------------------------------------------------------------------------------

-- 1. Respaldo Completo (FULL)
BACKUP DATABASE BDABD_BlackCatDB
TO DISK = 'D:\sistemas\2026-2\db_avanzadas_big_data\bdabd-black-cat\backups\BDABD_BlackCatDB_FULL.bak'
WITH INIT, 
     NAME = 'Respaldo Completo Semanal BlackCatDB',
     STATS = 10;
GO

-- 2. Respaldo Diferencial (DIFF)
BACKUP DATABASE BDABD_BlackCatDB	
TO DISK = 'D:\sistemas\2026-2\db_avanzadas_big_data\bdabd-black-cat\backups\BDABD_BlackCatDB_DIFF.bak'
WITH DIFFERENTIAL, 
     INIT,
     NAME = 'Respaldo Diferencial Diario BlackCatDB',
     STATS = 10;
GO

-- -------------------------------------------------------------------------------------------------
-- FASE 2: SCRIPT DE RESTAURACIÓN ANTE DESASTRE (PROBADO)
-- -------------------------------------------------------------------------------------------------
-- Escenario: Falla en el servidor o corrupción de datos. Se requiere volver al último punto consistente.

-- Paso 1: Poner la base de datos en modo usuario único cerrando transacciones activas
ALTER DATABASE BDABD_BlackCatDB SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
GO

-- Paso 2: Restaurar el FULL dejando la base de datos en estado de espera (NORECOVERY)
RESTORE DATABASE BDABD_BlackCatDB
FROM DISK = 'D:\sistemas\2026-2\db_avanzadas_big_data\bdabd-black-cat\backups\BDABD_BlackCatDB_FULL.bak'
WITH NORECOVERY, 
     REPLACE, 
     STATS = 10;
GO

-- Paso 3: Aplicar el respaldo DIFERENCIAL y finalizar la recuperación para dejar la BD operativa (RECOVERY)
RESTORE DATABASE BDABD_BlackCatDB
FROM DISK = 'D:\sistemas\2026-2\db_avanzadas_big_data\bdabd-black-cat\backups\BDABD_BlackCatDB_DIFF.bak'
WITH RECOVERY, 
     STATS = 10;
GO

-- Paso 4: Devolver la base de datos a modo multiusuario
ALTER DATABASE BDABD_BlackCatDB SET MULTI_USER;
GO