USE BDABD_BlackCatDB
GO

-- =================================================================================================
-- PASO 3: ANÁLISIS DE RENDIMIENTO, PLANES DE EJECUCIÓN E ÍNDICES
-- Caso de Negocio: Black Cat (Consultas Financiera y Operativa)
-- =================================================================================================
-- Guía de uso en SQL Server Management Studio (SSMS):
-- 1. Presionar Ctrl + M para activar "Include Actual Execution Plan" (Plan de ejecución real).
-- 2. Ejecutar cada consulta para capturar:
--    a) Operador utilizado (Clustered Index Scan vs Nonclustered Index Seek)
--    b) Estimated Subtree Cost (Costo relativo de la consulta)
--    c) Logical Reads (Lecturas lógicas en memoria reportadas en la pestaña 'Messages')
-- =================================================================================================

SET STATISTICS IO ON;
SET STATISTICS TIME ON;
GO

-- =================================================================================================
-- CASO 1: CONSULTA CRÍTICA FINANCIERA (Monitoreo de Pedidos Activos y Estado de Cobranzas)
-- Propósito: La gerencia consulta diariamente qué pedidos están en proceso o pendientes de anticipo,
-- cruzando el cliente, cotización, total del pedido y total recaudado a la fecha.
-- =================================================================================================

-- 1.1 Consulta Crítica Financiera
SELECT 
    p.IdPedido,
    c.NombreRazonSocial AS Cliente,
    cot.FechaEmision AS FechaCotizacion,
    p.FechaPedido,
    p.Estado AS EstadoPedido,
    p.MontoTotal AS MontoPedido,
    ISNULL(SUM(pag.Monto), 0) AS TotalCobrado,
    (p.MontoTotal - ISNULL(SUM(pag.Monto), 0)) AS SaldoPendiente
FROM Pedidos p
INNER JOIN Cotizaciones cot ON p.IdCotizacion = cot.IdCotizacion
INNER JOIN Clientes c ON cot.IdCliente = c.IdCliente
LEFT JOIN Pagos pag ON p.IdPedido = pag.IdPedido AND pag.Estado = 'REGISTRADO'
WHERE p.Estado IN ('PENDIENTE_ADELANTO', 'EN_PROCESO')
  AND p.FechaPedido >= DATEADD(MONTH, -6, SYSDATETIME())
GROUP BY p.IdPedido, c.NombreRazonSocial, cot.FechaEmision, p.FechaPedido, p.Estado, p.MontoTotal
ORDER BY p.FechaPedido DESC;
GO

-- 1.2 Implementación de Índices para Caso 1 (Índices No Agrupados Cubridores con INCLUDE)
-- Índice en Pedidos para acelerar el filtrado por Estado y FechaPedido sin escanear toda la tabla
CREATE NONCLUSTERED INDEX IX_Pedidos_Estado_FechaPedido
ON Pedidos (Estado, FechaPedido)
INCLUDE (IdCotizacion, MontoTotal);
GO

-- Índice en Pagos para acelerar el agrupamiento y suma de montos por Pedido y Estado
CREATE NONCLUSTERED INDEX IX_Pagos_IdPedido_Estado
ON Pagos (IdPedido, Estado)
INCLUDE (Monto);
GO

-- 1.3 Volver a ejecutar la Consulta 1.1 con los índices creados para comparar métricas


-- =================================================================================================
-- CASO 2: CONSULTA CRÍTICA OPERATIVA (Carga de Trabajo y Monitoreo de Tareas por Colaborador)
-- Propósito: Los líderes de equipo consultan las tareas en curso o pendientes asignadas a los
-- diseñadores e instaladores para balancear la carga y evitar retrasos en entregas.
-- =================================================================================================

-- 2.1 Consulta Crítica Operativa
SELECT 
    t.IdTarea,
    u.NombresCompletos AS Colaborador,
    t.Tipo AS TipoTarea,
    t.Descripcion,
    t.Estado AS EstadoTarea,
    t.FechaAsignacion,
    t.FechaEntrega,
    p.IdPedido,
    p.Estado AS EstadoPedido
FROM Tareas t
INNER JOIN Usuarios u ON t.IdUsuario = u.IdUsuario
INNER JOIN Pedidos p ON t.IdPedido = p.IdPedido
WHERE t.Estado IN ('PENDIENTE', 'EN_CURSO')
  AND t.FechaEntrega <= DATEADD(DAY, 7, SYSDATETIME())
ORDER BY t.FechaEntrega ASC;
GO

-- 2.2 Implementación de Índice para Caso 2 (Índice Compuesto Cubridor)
-- Acelera el filtrado por Estado y FechaEntrega e incluye los datos del colaborador y pedido
CREATE NONCLUSTERED INDEX IX_Tareas_Estado_FechaEntrega
ON Tareas (Estado, FechaEntrega)
INCLUDE (IdUsuario, IdPedido, Tipo, Descripcion, FechaAsignacion);
GO

-- 2.3 Volver a ejecutar la Consulta 2.1 con el índice creado para comparar métricas


-- =================================================================================================
-- LIMPIEZA DE ÍNDICES (Opcional, para repetir la prueba o reiniciar el entorno de pruebas)
-- =================================================================================================
/*
DROP INDEX IX_Pedidos_Estado_FechaPedido ON Pedidos;
DROP INDEX IX_Pagos_IdPedido_Estado ON Pagos;
DROP INDEX IX_Tareas_Estado_FechaEntrega ON Tareas;
*/
GO
