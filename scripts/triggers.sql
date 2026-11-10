USE BDABD_BlackCatDB
GO

-- TRIGGER: Auditar cambios en la tabla clientes

CREATE OR ALTER TRIGGER trgAuditoriaClientes 
ON Clientes
AFTER UPDATE, DELETE
AS
BEGIN

    IF EXISTS (SELECT 1 FROM deleted) AND NOT EXISTS (SELECT 1 FROM inserted)
    BEGIN
        INSERT INTO AuditoriaLogs (TablaAfectada, Operacion, IdRegistro, ValorAnterior, ValorNuevo, UsuarioBd, FechaEvento)
        SELECT 'Clientes', 'DELETE', d.IdCliente, CONCAT(d.NombreRazonSocial, '|', d.DniRuc), NULL, SUSER_SNAME(), SYSDATETIME()
        FROM deleted d;
    END

    IF EXISTS (SELECT 1 FROM deleted) AND EXISTS (SELECT 1 FROM inserted)
    BEGIN
        INSERT INTO AuditoriaLogs (TablaAfectada, Operacion, IdRegistro, ValorAnterior, ValorNuevo, UsuarioBd, FechaEvento)
        SELECT 'Clientes', 'UPDATE', i.IdCliente, CONCAT(d.Telefono, '|', d.Direccion), CONCAT(i.Telefono, '|', i.Direccion), SUSER_SNAME(), SYSDATETIME()
        FROM inserted i INNER JOIN deleted d ON i.IdCliente = d.IdCliente;
    END
END
GO

-- TRIGGER: Impedir anular un pagos si el pedido ya está cerrado
CREATE OR ALTER TRIGGER trgRevertirAnulacionPagoEnPedidoCerrado
ON Pagos
AFTER UPDATE
AS
BEGIN

    IF UPDATE(Estado)
    BEGIN
        IF EXISTS (SELECT 1 FROM inserted i INNER JOIN deleted d ON i.IdPago = d.IdPago INNER JOIN Pedidos p ON i.IdPedido = p.IdPedido
            WHERE i.Estado = 'ANULADO' AND d.Estado <> 'ANULADO' AND p.Estado IN ('COMPLETADO', 'CERRADO'))
        BEGIN
            INSERT INTO AuditoriaLogs (TablaAfectada, Operacion, IdRegistro, ValorAnterior, ValorNuevo, UsuarioBd, FechaEvento)
            SELECT 'Pagos', 'UPDATE', i.IdPago, 'REGISTRADO', 'INTENTO_ANULACION_FALLIDO_PEDIDO_CERRADO', SUSER_SNAME(), SYSDATETIME()
            FROM inserted i;

            RAISERROR('No se puede anular un pago de un pedido que ya se encuentra COMPLETADO o CERRADO.', 16, 1);
            ROLLBACK TRANSACTION;
        END
    END
END
GO

-- TRIGGER: Integridad para impedir cerrar un pedido con saldo pendiente o tareas incompletas (Defensa en profundidad)
CREATE OR ALTER TRIGGER trgValidarCierrePedido
ON Pedidos
AFTER UPDATE
AS
BEGIN
    IF UPDATE(Estado)
    BEGIN
        -- Verificar si se intentó pasar a 'CERRADO' teniendo saldo pendiente
        IF EXISTS (
            SELECT 1 
            FROM inserted i 
            INNER JOIN deleted d ON i.IdPedido = d.IdPedido
            WHERE i.Estado = 'CERRADO' AND d.Estado <> 'CERRADO'
              AND dbo.ufnObtenerSaldoPendientePedido(i.IdPedido) > 0
        )
        BEGIN
            INSERT INTO AuditoriaLogs (TablaAfectada, Operacion, IdRegistro, ValorAnterior, ValorNuevo, UsuarioBd, FechaEvento)
            SELECT 'Pedidos', 'UPDATE', i.IdPedido, d.Estado, 'INTENTO_CIERRE_FALLIDO_CON_SALDO', SUSER_SNAME(), SYSDATETIME()
            FROM inserted i INNER JOIN deleted d ON i.IdPedido = d.IdPedido
            WHERE i.Estado = 'CERRADO' AND dbo.ufnObtenerSaldoPendientePedido(i.IdPedido) > 0;

            RAISERROR('Integridad violada: No es posible cerrar un pedido que aún mantiene saldo pendiente de pago.', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Verificar si se intentó pasar a 'CERRADO' con tareas no completadas
        IF EXISTS (
            SELECT 1 
            FROM inserted i 
            INNER JOIN deleted d ON i.IdPedido = d.IdPedido
            INNER JOIN Tareas t ON t.IdPedido = i.IdPedido
            WHERE i.Estado = 'CERRADO' AND d.Estado <> 'CERRADO'
              AND t.Estado IN ('PENDIENTE', 'EN_CURSO')
        )
        BEGIN
            INSERT INTO AuditoriaLogs (TablaAfectada, Operacion, IdRegistro, ValorAnterior, ValorNuevo, UsuarioBd, FechaEvento)
            SELECT 'Pedidos', 'UPDATE', i.IdPedido, d.Estado, 'INTENTO_CIERRE_FALLIDO_TAREAS_PENDIENTES', SUSER_SNAME(), SYSDATETIME()
            FROM inserted i INNER JOIN deleted d ON i.IdPedido = d.IdPedido;

            RAISERROR('Integridad violada: No es posible cerrar un pedido con tareas pendientes o en curso.', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END
    END
END
GO