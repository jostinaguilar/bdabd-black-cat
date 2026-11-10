USE BDABD_BlackCatDB
GO

DECLARE @IdCotizacion INT;
DECLARE @FechaVigencia DATETIME;
DECLARE @ContadorActualizados INT = 0;

DECLARE cursorVencerCotizaciones CURSOR FOR
    SELECT IdCotizacion, FechaVigencia FROM Cotizaciones
    WHERE Estado IN ('BORRADOR', 'ENVIADA') AND FechaVigencia < CAST(SYSDATETIME() AS DATE)

OPEN cursorVencerCotizaciones;
FETCH NEXT FROM cursorVencerCotizaciones INTO @IdCotizacion, @FechaVigencia;

WHILE @@FETCH_STATUS = 0
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @EstadoAnterior VARCHAR(10)

        SELECT @EstadoAnterior = Estado FROM Cotizaciones WHERE IdCotizacion = @IdCotizacion

        UPDATE Cotizaciones SET Estado = 'VENCIDA' WHERE IdCotizacion = @IdCotizacion;

        INSERT INTO AuditoriaLogs (TablaAfectada, Operacion, IdRegistro, ValorAnterior, ValorNuevo, UsuarioBd, FechaEvento)
        VALUES ('Cotizaciones', 'UPDATE', @IdCotizacion, @EstadoAnterior, 'VENCIDA', SUSER_SNAME(), SYSDATETIME())

        COMMIT TRANSACTION;
        SET @ContadorActualizados = @ContadorActualizados + 1;

    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
        BEGIN
            ROLLBACK TRANSACTION;
        END
        
        PRINT CONCAT('Error al procesar la cotización ID: ', @IdCotizacion, ' - ', ERROR_MESSAGE());
    END CATCH;

    FETCH NEXT FROM cursorVencerCotizaciones INTO @IdCotizacion, @FechaVigencia;
END

CLOSE cursorVencerCotizaciones;
DEALLOCATE cursorVencerCotizaciones;

PRINT CONCAT('Proceso finalizado. Total de cotizaciones marcadas como VENCIDA: ', @ContadorActualizados);
GO