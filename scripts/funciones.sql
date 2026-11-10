USE BDABD_BlackCatDB
GO

-- Calcular el saldo pendiente de un pedido
CREATE OR ALTER FUNCTION ufnObtenerSaldoPendientePedido (
    @IdPedido INT
)
RETURNS DECIMAL(12,2)
AS
BEGIN
    DECLARE @MontoTotal DECIMAL(12,2) = 0;
    DECLARE @TotalPagado DECIMAL(12,2) = 0;

    SELECT @MontoTotal = MontoTotal FROM Pedidos WHERE IdPedido = @IdPedido;

    SELECT @TotalPagado = ISNULL(SUM(Monto), 0) FROM Pagos
    WHERE IdPedido = @IdPedido AND Estado = 'REGISTRADO';

    RETURN ISNULL(@MontoTotal - @TotalPagado, 0);
END
GO

-- Calcular IGV
CREATE OR ALTER FUNCTION ufnCalcularIGV (
    @MontoBase DECIMAL(12,2)
)
RETURNS DECIMAL(12,2)
AS
BEGIN
    RETURN ROUND(ISNULL(@MontoBase, 0) * 0.18, 2);
END
GO

-- Calcular Subtotal
CREATE OR ALTER FUNCTION ufnCalcularSubtotal (
    @Cantidad INT,
    @PrecioUnitario DECIMAL(10,2)
)
RETURNS DECIMAL(10,2)
AS
BEGIN
    RETURN ROUND(ISNULL(@Cantidad, 0) * ISNULL(@PrecioUnitario, 0), 2);
END
GO

-- Calcular Total
CREATE OR ALTER FUNCTION ufnCalcularTotal (
    @IdCotizacion INT
)
RETURNS DECIMAL(10,2)
AS
BEGIN
    DECLARE @Total DECIMAL(10,2) = 0;

    SELECT @Total = ISNULL(SUM(dbo.ufnCalcularSubtotal(Cantidad, PrecioUnitario)), 0) FROM DetalleCotizaciones
    WHERE IdCotizacion = @IdCotizacion;

    RETURN @Total;
END
GO