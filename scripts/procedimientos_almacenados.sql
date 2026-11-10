USE BDABD_BlackCatDB
GO

CREATE OR ALTER PROCEDURE uspRegistrarCliente (
    @TipoCliente VARCHAR(10),
    @NombreRazonSocial VARCHAR(150),
    @DniRuc VARCHAR(11),
    @Telefono VARCHAR(20),
    @Correo VARCHAR(100),
    @Direccion NVARCHAR(200)
)
AS
BEGIN
    INSERT INTO Clientes (TipoCliente, NombreRazonSocial, DniRuc, Telefono, Correo, Direccion) VALUES
    (@TipoCliente, @NombreRazonSocial, @DniRuc, @Telefono, @Correo, @Direccion)

    SELECT * FROM Clientes WHERE IdCliente = SCOPE_IDENTITY()
END
GO

CREATE OR ALTER PROCEDURE uspRegistrarUsuario (
    @NombresCompletos NVARCHAR(150),
    @NombreUsuario VARCHAR(50),
    @IdRol INT,
    @Contrasena VARCHAR(255),
    @Telefono VARCHAR(20),
    @Correo VARCHAR(100)
)
AS
BEGIN
    INSERT INTO Usuarios (NombresCompletos, NombreUsuario, IdRol, Contrasena, Telefono, Correo) VALUES
    (@NombresCompletos, @NombreUsuario, @IdRol, @Contrasena, @Telefono, @Correo)

    SELECT * FROM Usuarios WHERE IdUsuario = SCOPE_IDENTITY()
END
GO

CREATE OR ALTER PROCEDURE uspCrearCategoria (
    @Nombre NVARCHAR(100)
)
AS
BEGIN
    INSERT INTO Categorias (Nombre) VALUES (@Nombre)

    SELECT * FROM Categorias WHERE IdCategoria = SCOPE_IDENTITY()
END
GO

CREATE OR ALTER PROCEDURE uspCrearRol (
    @Nombre VARCHAR(50)
)
AS
BEGIN
    INSERT INTO Roles (Nombre) VALUES (@Nombre)

    SELECT * FROM Roles WHERE IdRol = SCOPE_IDENTITY()
END
GO

CREATE OR ALTER PROCEDURE uspCrearTarea (
    @IdPedido INT,
    @IdDetalle INT,
    @IdRevision INT,
    @IdUsuario INT,
    @Tipo VARCHAR(10),
    @Descripcion NVARCHAR(500),
    @FechaAsignacion DATETIME,
    @FechaEntrega DATETIME
)
AS
BEGIN
    INSERT INTO Tareas (IdPedido, IdDetalle, IdRevision, IdUsuario, Tipo, Descripcion, FechaAsignacion, FechaEntrega) VALUES
    (@IdPedido, @IdDetalle, @IdRevision, @IdUsuario, @Tipo, @Descripcion, @FechaAsignacion, @FechaEntrega)

    SELECT * FROM Tareas WHERE IdTarea = SCOPE_IDENTITY()
END
GO

-- Procedimiento almacenado para registrar una cotización

-- Definir una estructura para pasar varios items a la cotizacion
CREATE TYPE typeDetalleCotizacion AS TABLE(
    IdServicio INT NOT NULL,
    Cantidad INT NOT NULL,
    PrecioUnitario DECIMAL(10, 2) NOT NULL,
    Subtotal DECIMAL(10, 2) NOT NULL,
    Especificaciones NVARCHAR(MAX) NULL
)
GO

CREATE OR ALTER PROCEDURE uspCrearCotizacionConDetalle (
    @IdCliente INT,
    @IdUsuario INT,
    @FechaVigencia DATETIME,
    @Detalles typeDetalleCotizacion READONLY
)
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION

        -- 1. Validar que la cotización contenga al menos un detalle
        IF NOT EXISTS (SELECT 1 FROM @Detalles)
        BEGIN
            RAISERROR('La cotización debe contener al menos un detalle de servicio.', 16, 1)
        END

        -- 2. Calcular el MontoTotal automáticamente a partir de los ítems con ufnCalcularSubtotal
        DECLARE @MontoTotalCalculado DECIMAL(10, 2)
        SELECT @MontoTotalCalculado = ISNULL(SUM(dbo.ufnCalcularSubtotal(Cantidad, PrecioUnitario)), 0)
        FROM @Detalles

        IF @MontoTotalCalculado <= 0
        BEGIN
            RAISERROR('El monto total de la cotización debe ser mayor a 0.', 16, 1)
        END

        -- 3. Insertar la cotización con el monto calculado
        INSERT INTO Cotizaciones (IdCliente, IdUsuario, FechaEmision, FechaVigencia, MontoTotal, Estado) VALUES
        (@IdCliente, @IdUsuario, SYSDATETIME(), @FechaVigencia, @MontoTotalCalculado, 'BORRADOR')

        DECLARE @IdCotizacionCreado INT = SCOPE_IDENTITY()

        -- 4. Insertar los detalles calculando el subtotal de cada ítem con ufnCalcularSubtotal
        INSERT INTO DetalleCotizaciones (IdCotizacion, IdServicio, Cantidad, PrecioUnitario, Subtotal, Especificaciones)
        SELECT @IdCotizacionCreado, IdServicio, Cantidad, PrecioUnitario, dbo.ufnCalcularSubtotal(Cantidad, PrecioUnitario), Especificaciones 
        FROM @Detalles

        SAVE TRANSACTION LogAuditoria

        BEGIN TRY
            INSERT INTO AuditoriaLogs (TablaAfectada, Operacion, IdRegistro, IdUsuario, FechaEvento) VALUES
            ('Cotizaciones', 'INSERT', @IdCotizacionCreado, @IdUsuario, SYSDATETIME())
        END TRY
        BEGIN CATCH
            ROLLBACK TRANSACTION LogAuditoria
        END CATCH

        COMMIT TRANSACTION

        SELECT * FROM Cotizaciones WHERE IdCotizacion = @IdCotizacionCreado
    
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
        BEGIN
            ROLLBACK TRANSACTION
        END

        PRINT 'ERROR: ' + ERROR_MESSAGE()
    END CATCH
END
GO

-- Procedimiento almacenado para registrar pagos
CREATE OR ALTER PROCEDURE uspRegistrarPagoConComprobante (
    @IdPedido INT,
    @Descripcion NVARCHAR(200),
    @TipoPago VARCHAR(10),
    @Monto DECIMAL(12, 2),
    @MetodoPago VARCHAR(30),
    @TipoComprobante VARCHAR(15),
    @NumeroComprobante VARCHAR(20),
    @IdUsuario INT
)
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION

        -- 1. Validar existencia y estado del pedido
        DECLARE @SaldoActual DECIMAL(12, 2) = dbo.ufnObtenerSaldoPendientePedido(@IdPedido)
        DECLARE @MontoTotalPedido DECIMAL(10, 2)
        DECLARE @EstadoPedido VARCHAR(20)

        SELECT @MontoTotalPedido = MontoTotal, @EstadoPedido = Estado 
        FROM Pedidos WHERE IdPedido = @IdPedido

        IF @EstadoPedido IS NULL
        BEGIN
            RAISERROR('El pedido especificado no existe.', 16, 1)
        END

        IF @EstadoPedido IN ('CERRADO', 'CANCELADO')
        BEGIN
            RAISERROR('No se pueden registrar pagos a un pedido cerrado o cancelado.', 16, 1)
        END

        IF @Monto <= 0
        BEGIN
            RAISERROR('El monto del pago debe ser mayor a 0.', 16, 1)
        END

        IF @Monto > @SaldoActual
        BEGIN
            RAISERROR('El monto a pagar no puede superar el saldo pendiente del pedido.', 16, 1)
        END

        -- 2. Registrar el pago
        INSERT INTO Pagos (IdPedido, Descripcion, TipoPago, Monto, MetodoPago, FechaPago, Estado) VALUES
        (@IdPedido, @Descripcion, @TipoPago, @Monto, @MetodoPago, SYSDATETIME(), 'REGISTRADO')

        DECLARE @IdPagoRegistrado INT = SCOPE_IDENTITY()

        -- 3. Registrar el comprobante o recibo
        IF @TipoComprobante = 'RECIBO'
        BEGIN
            INSERT INTO Recibos (IdPago, NumeroRecibo, FechaEmision) VALUES
            (@IdPagoRegistrado, @NumeroComprobante, SYSDATETIME())
        END
        ELSE IF @TipoComprobante IN ('BOLETA', 'FACTURA')
        BEGIN
            DECLARE @ValorVenta DECIMAL(12, 2) = ROUND(@Monto / 1.18, 2)
            DECLARE @IGV DECIMAL(12, 2) = dbo.ufnCalcularIGV(@ValorVenta)

            INSERT INTO Comprobantes (IdPedido, TipoComprobante, NumeroComprobante, FechaEmision, ValorVenta, Igv, MontoTotal) VALUES
            (@IdPedido, @TipoComprobante, @NumeroComprobante, SYSDATETIME(), @ValorVenta, @IGV, @Monto)
        END

        -- 4. Evaluar si con este pago se cubre al menos el 50% de anticipo para iniciar el trabajo
        DECLARE @NuevoSaldo DECIMAL(12, 2) = dbo.ufnObtenerSaldoPendientePedido(@IdPedido)
        DECLARE @TotalPagadoAcumulado DECIMAL(12, 2) = @MontoTotalPedido - @NuevoSaldo

        IF @TotalPagadoAcumulado >= (@MontoTotalPedido * 0.50) AND @EstadoPedido = 'PENDIENTE_ADELANTO'
        BEGIN
            UPDATE Pedidos SET Estado = 'EN_PROCESO' WHERE IdPedido = @IdPedido
        END

        SAVE TRANSACTION LogAuditoria
        
        BEGIN TRY
            INSERT INTO AuditoriaLogs (TablaAfectada, Operacion, IdRegistro, IdUsuario, FechaEvento) VALUES
            ('Pagos', 'INSERT', @IdPagoRegistrado, @IdUsuario, SYSDATETIME())
        END TRY
        BEGIN CATCH
            ROLLBACK TRANSACTION LogAuditoria
        END CATCH

        COMMIT TRANSACTION

        SELECT * FROM Pagos WHERE IdPago = @IdPagoRegistrado

    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
        BEGIN
            ROLLBACK TRANSACTION
        END

        PRINT 'ERROR: ' + ERROR_MESSAGE()

    END CATCH
END
GO

-- procedimiento para aprobar cotizacion y generar pedido
CREATE OR ALTER PROCEDURE uspAprobarCotizacionYConvertirAPedido (
    @IdCotizacion INT,
    @NumeroOrdenCompra VARCHAR(50),
    @IdUsuario INT
)
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION

        DECLARE @MontoTotalCotizacion DECIMAL(10, 2)
        DECLARE @EstadoActual VARCHAR(10)

        SELECT @MontoTotalCotizacion = MontoTotal, @EstadoActual = Estado FROM Cotizaciones WHERE IdCotizacion = @IdCotizacion

        IF @EstadoActual IS NULL
        BEGIN
            RAISERROR('La cotización no existe.', 16, 1)
        END

        IF @EstadoActual in ('APROBADA', 'ANULADA', 'RECHAZADA', 'VENCIDA')
        BEGIN
            RAISERROR('La cotizacion no tiene un estado valido para ser aprobada.', 16, 1)
        END

        UPDATE Cotizaciones SET Estado = 'APROBADA' WHERE IdCotizacion = @IdCotizacion

        INSERT INTO Pedidos (IdCotizacion, FechaPedido, NumeroOrdenCompra, MontoTotal, Estado) VALUES
        (@IdCotizacion, SYSDATETIME(), @NumeroOrdenCompra, @MontoTotalCotizacion, 'PENDIENTE_ADELANTO')

        DECLARE @IdPedidoConvertido INT = SCOPE_IDENTITY()

        SAVE TRANSACTION LogAuditoria

        BEGIN TRY
            INSERT INTO AuditoriaLogs (TablaAfectada, Operacion, IdRegistro, IdUsuario, FechaEvento) VALUES
            ('Pedidos', 'INSERT', @IdPedidoConvertido, @IdUsuario, SYSDATETIME())
        END TRY
        BEGIN CATCH
            ROLLBACK TRANSACTION LogAuditoria
        END CATCH

        COMMIT TRANSACTION

        SELECT * FROM Pedidos WHERE IdPedido = @IdPedidoConvertido
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
        BEGIN
            ROLLBACK TRANSACTION
        END

        PRINT 'ERROR: ' + ERROR_MESSAGE()

    END CATCH
END
GO

-- SP para agregar servicios
CREATE OR ALTER PROCEDURE uspAgregarServicio (
    @Nombre NVARCHAR(150),
    @IdCategoria INT,
    @Precio DECIMAL(10, 2),
    @IdUsuario INT
)
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION

        IF @Precio <= 0
        BEGIN
            RAISERROR('El precio debe ser mayor a 0.', 16, 1)
        END

        IF NOT EXISTS (SELECT 1 FROM Categorias WHERE IdCategoria = @IdCategoria)
        BEGIN
            RAISERROR('La categoría no existe.', 16, 1)
        END

        INSERT INTO Servicios (Nombre, IdCategoria, Precio, Activo) VALUES
        (@Nombre, @IdCategoria, @Precio, 1)

        DECLARE @IdServicioAgregado INT = SCOPE_IDENTITY()

        SAVE TRANSACTION LogAuditoria

        BEGIN TRY
            INSERT INTO AuditoriaLogs (TablaAfectada, Operacion, IdRegistro, IdUsuario, FechaEvento) VALUES
            ('Servicios', 'INSERT', @IdServicioAgregado, @IdUsuario, SYSDATETIME())
        END TRY
        BEGIN CATCH
            ROLLBACK TRANSACTION LogAuditoria
        END CATCH

        COMMIT TRANSACTION
        
        SELECT * FROM Servicios WHERE IdServicio = @IdServicioAgregado
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
        BEGIN
            ROLLBACK TRANSACTION
        END

        PRINT 'ERROR: ' + ERROR_MESSAGE()

    END CATCH
END
GO

-- Procedimiento almacenado para cerrar un pedido (validando 100% de pago, tareas y revisiones)
CREATE OR ALTER PROCEDURE uspCerrarPedido (
    @IdPedido INT,
    @IdUsuario INT
)
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION

        -- 1. Verificar existencia y estado actual
        DECLARE @EstadoActual VARCHAR(20)
        SELECT @EstadoActual = Estado FROM Pedidos WHERE IdPedido = @IdPedido

        IF @EstadoActual IS NULL
        BEGIN
            RAISERROR('El pedido no existe.', 16, 1)
        END

        IF @EstadoActual = 'CERRADO'
        BEGIN
            RAISERROR('El pedido ya se encuentra cerrado.', 16, 1)
        END

        IF @EstadoActual = 'CANCELADO'
        BEGIN
            RAISERROR('No se puede cerrar un pedido que ha sido cancelado.', 16, 1)
        END

        -- 2. Validar que no tenga saldo pendiente (100% pagado)
        IF dbo.ufnObtenerSaldoPendientePedido(@IdPedido) > 0
        BEGIN
            RAISERROR('No se puede cerrar el pedido porque aún mantiene saldo pendiente de pago.', 16, 1)
        END

        -- 3. Validar que no existan tareas pendientes o en curso
        IF EXISTS (SELECT 1 FROM Tareas WHERE IdPedido = @IdPedido AND Estado IN ('PENDIENTE', 'EN_CURSO'))
        BEGIN
            RAISERROR('No se puede cerrar el pedido porque existen tareas pendientes o en curso.', 16, 1)
        END

        -- 4. Validar revisiones (si existen revisiones, todas deben estar aprobadas)
        IF EXISTS (SELECT 1 FROM Revisiones WHERE IdPedido = @IdPedido AND (Aprobada = 0 OR Aprobada IS NULL))
        BEGIN
            RAISERROR('No se puede cerrar el pedido porque existen revisiones no aprobadas por el cliente.', 16, 1)
        END

        -- 5. Actualizar estado y fecha de cierre
        UPDATE Pedidos 
        SET Estado = 'CERRADO', FechaCierre = SYSDATETIME() 
        WHERE IdPedido = @IdPedido

        -- 6. Auditoría con Savepoint
        SAVE TRANSACTION LogAuditoria
        BEGIN TRY
            INSERT INTO AuditoriaLogs (TablaAfectada, Operacion, IdRegistro, ValorAnterior, ValorNuevo, IdUsuario, FechaEvento)
            VALUES ('Pedidos', 'UPDATE', @IdPedido, @EstadoActual, 'CERRADO', @IdUsuario, SYSDATETIME())
        END TRY
        BEGIN CATCH
            ROLLBACK TRANSACTION LogAuditoria
        END CATCH

        COMMIT TRANSACTION

        SELECT * FROM Pedidos WHERE IdPedido = @IdPedido
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
        BEGIN
            ROLLBACK TRANSACTION
        END

        PRINT 'ERROR: ' + ERROR_MESSAGE()
    END CATCH
END
GO