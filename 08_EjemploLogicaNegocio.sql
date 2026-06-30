USE ParquesNacionalesDB;
GO

CREATE OR ALTER PROCEDURE Facturacion.RegistrarVenta
(
    @IdParque INT,
    @NumeroFactura VARCHAR(20),
    @PuntoDeVenta VARCHAR(50),
    @FechaEmision DATE,
    @FormaPago VARCHAR(20),
    @IdTipoVisitante INT,
    @CantidadEntrada INT,
    @FechaAcceso DATE,
    @IdActividad INT = NULL,
    @CantidadActividad INT = 0
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @PrecioUnitario DECIMAL(10,2);
    DECLARE @PrecioActividad DECIMAL(10,2) = 0;
    DECLARE @TotalCalculado DECIMAL(10,2) = 0;
    DECLARE @IdTicketFacturaGenerado INT;

    BEGIN TRY
        SELECT @PrecioUnitario = Precio
        FROM Facturacion.PrecioEntrada
        WHERE IdParque = @IdParque 
          AND IdTipoVisitante = @IdTipoVisitante
          AND VigenteDesde <= @FechaAcceso
          AND (VigenteHasta IS NULL OR VigenteHasta > @FechaAcceso);

        IF @PrecioUnitario IS NULL
            RAISERROR('Error: No se encontró un precio vigente para la entrada.', 16, 1);

        IF @IdActividad IS NOT NULL AND @CantidadActividad > 0
        BEGIN
            SELECT @PrecioActividad = ISNULL(Costo, 0)
            FROM Administracion.Actividad
            WHERE IdActividad = @IdActividad AND IdParque = @IdParque;

            IF @@ROWCOUNT = 0
                RAISERROR('Error: La actividad no existe en este parque.', 16, 1);
        END

        SET @TotalCalculado = (@CantidadEntrada * @PrecioUnitario) + (@CantidadActividad * @PrecioActividad);

        BEGIN TRAN;

        SELECT @IdTicketFacturaGenerado = IdTicketFactura
        FROM Facturacion.TicketFactura
        WHERE NumeroFactura = @NumeroFactura 
          AND PuntoDeVenta = @PuntoDeVenta
          AND IdParque = @IdParque;

        IF @IdTicketFacturaGenerado IS NOT NULL
        BEGIN
            UPDATE Facturacion.TicketFactura
            SET Total = Total + @TotalCalculado
            WHERE IdTicketFactura = @IdTicketFacturaGenerado;
        END
        ELSE
        BEGIN
            EXEC Facturacion.TicketFactura_Insertar
                @IdParque = @IdParque,
                @NumeroFactura = @NumeroFactura,
                @PuntoDeVenta = @PuntoDeVenta,
                @FechaEmision = @FechaEmision,
                @FormaPago = @FormaPago,
                @Total = @TotalCalculado,
                @IdTicketFactura = @IdTicketFacturaGenerado OUTPUT;
        END

        INSERT INTO Facturacion.TicketItemEntrada (IdTicketFactura, IdTipoVisitante, Cantidad, FechaAcceso, PrecioUnitario)
        VALUES (@IdTicketFacturaGenerado, @IdTipoVisitante, @CantidadEntrada, @FechaAcceso, @PrecioUnitario);

        IF @IdActividad IS NOT NULL AND @CantidadActividad > 0
        BEGIN
            INSERT INTO Facturacion.TicketItemActividad (IdTicketFactura, IdActividad, Cantidad, FechaActividad, Precio)
            VALUES (@IdTicketFacturaGenerado, @IdActividad, @CantidadActividad, @FechaAcceso, @PrecioActividad);
        END

        COMMIT TRAN;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRAN;
        THROW;
    END CATCH
END
GO



EXEC Facturacion.RegistrarVenta

    @IdParque = 1,
    @NumeroFactura = '0001-00003001',
    @PuntoDeVenta = 'Boletería Principal',
    @FechaEmision = '2026-06-01',
    @FormaPago = 'Efectivo',
    @IdTipoVisitante = 1,
    @CantidadEntrada = 3,
    @FechaAcceso = '2026-06-30',
    @IdActividad = 1,
    @CantidadActividad = 3;


EXEC Facturacion.RegistrarVenta
    @IdParque = 1,
    @NumeroFactura = '0001-00003001',
    @PuntoDeVenta = 'Boletería Principal',
    @FechaEmision = '2026-06-01',
    @FormaPago = 'Efectivo',
    @IdTipoVisitante = 2,
    @CantidadEntrada = 1,
    @FechaAcceso = '2026-06-30',
    @IdActividad = 1,
    @CantidadActividad = 1; 

SELECT * FROM Facturacion.TicketFactura
SELECT * FROM Administracion.Actividad