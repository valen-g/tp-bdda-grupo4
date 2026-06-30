/*
================================================================================
# Universidad: Universidad Nacional de La Matanza
# Materia: 3641 - Bases de Datos Aplicada
# Grupo: Grupo 4
# Integrantes:
- Belloni, Nicolas
- Bernardo, Ivan
- Gonzalez, Agustin
- Gallo, Valentina

# Fecha: 20/06/2026
--------------------------------------------------------------------------------
    Script          : 06_ReportesXML.sql
    Objetivo        : Crear los Stored Procedures de reportes (Entrega 7):
                       visitas por semana/mes/año, ingresos por parque,
                       deudores de concesiones, matriz de visitas (Pivot)
                       y parques con concesiones anidadas. Todos retornan
                       el resultado en formato XML.
================================================================================
*/

USE ParquesNacionalesDB;
GO

-- REPORTE 1A: Cantidad de visitas x semana
------------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE Facturacion.ReporteVisitasPorSemanaXML
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        P.Nombre AS [@Parque],
        YEAR(E.FechaAcceso) AS [Anio],
        CHOOSE(MONTH(E.FechaAcceso), 
            'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio', 
            'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre') AS [Mes],
        ((DAY(E.FechaAcceso) - 1) / 7) + 1 AS [SemanaDelMes],
        SUM(E.Cantidad) AS [TotalVisitantes]
    FROM Facturacion.TicketItemEntrada E
    INNER JOIN Facturacion.TicketFactura F ON E.IdTicketFactura = F.IdTicketFactura
    INNER JOIN Administracion.Parque P ON F.IdParque = P.IdParque
    GROUP BY 
        P.Nombre, 
        YEAR(E.FechaAcceso), 
        MONTH(E.FechaAcceso),
        ((DAY(E.FechaAcceso) - 1) / 7) + 1
    ORDER BY 
        P.Nombre, 
        YEAR(E.FechaAcceso), 
        MONTH(E.FechaAcceso), 
        [SemanaDelMes]
    FOR XML PATH('VisitaSemanal'), ROOT('ReporteVisitasSemanales');
END;
GO

-- REPORTE 1b: Cantidad de visitas por mes
---------------------------------------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE Facturacion.ReporteVisitasPorMesXML
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        P.Nombre AS [@Parque],
        YEAR(E.FechaAcceso) AS [Anio],
        CHOOSE(MONTH(E.FechaAcceso), 
            'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio', 
            'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre') AS [Mes],
        SUM(E.Cantidad) AS [TotalVisitantes]
    FROM Facturacion.TicketItemEntrada E
    INNER JOIN Facturacion.TicketFactura F ON E.IdTicketFactura = F.IdTicketFactura
    INNER JOIN Administracion.Parque P ON F.IdParque = P.IdParque
    GROUP BY P.Nombre, YEAR(E.FechaAcceso), MONTH(E.FechaAcceso)
    ORDER BY P.Nombre, YEAR(E.FechaAcceso), MONTH(E.FechaAcceso)
    FOR XML PATH('VisitaMensual'), ROOT('ReporteVisitasMensuales');
END;
GO


-- REPORTE 1C: Cantidad de visitas x añoo
--------------------------------------------
CREATE OR ALTER PROCEDURE Facturacion.ReporteVisitasPorAnioXML
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        P.Nombre AS [@Parque],
        YEAR(E.FechaAcceso) AS [Anio],
        SUM(E.Cantidad) AS [TotalVisitantes]
    FROM Facturacion.TicketItemEntrada E
    INNER JOIN Facturacion.TicketFactura F ON E.IdTicketFactura = F.IdTicketFactura
    INNER JOIN Administracion.Parque P ON F.IdParque = P.IdParque
    GROUP BY P.Nombre, YEAR(E.FechaAcceso)
    ORDER BY P.Nombre, YEAR(E.FechaAcceso)
    FOR XML PATH('VisitaAnual'), ROOT('ReporteVisitasAnuales');
END;
GO

-- REPORTE 2: Ingresos temporales detallados por parque
------------------------------------------------------------------
CREATE OR ALTER PROCEDURE Facturacion.ReporteIngresosTotalesXML
AS
BEGIN
    SET NOCOUNT ON;

    WITH IngresosUnificados AS (
        SELECT 
            F.IdParque,
            E.FechaAcceso AS Fecha,
            (E.Cantidad * E.PrecioUnitario) AS MontoEntradas,
            0 AS MontoActividades,
            0 AS MontoConcesiones
        FROM Facturacion.TicketItemEntrada E
        INNER JOIN Facturacion.TicketFactura F ON E.IdTicketFactura = F.IdTicketFactura

        UNION ALL

        SELECT 
            F.IdParque,
            A.FechaActividad AS Fecha,
            0 AS MontoEntradas,
            (A.Cantidad * A.Precio) AS MontoActividades,
            0 AS MontoConcesiones
        FROM Facturacion.TicketItemActividad A
        INNER JOIN Facturacion.TicketFactura F ON A.IdTicketFactura = F.IdTicketFactura

        UNION ALL

        SELECT 
            C.IdParque,
            PC.FechaPago AS Fecha,
            0 AS MontoEntradas,
            0 AS MontoActividades,
            PC.Monto AS MontoConcesiones
        FROM Facturacion.PagoCanon PC
        INNER JOIN Administracion.Concesion C ON PC.IdConcesion = C.IdConcesion
        WHERE PC.Estado = 'Pagado'
    )
    SELECT 
        P.Nombre AS [@Parque],
        YEAR(I.Fecha) AS [Anio],
        MONTH(I.Fecha) AS [Mes],
        DATEPART(WEEK, I.Fecha) AS [SemanaCorrelativa],
        SUM(I.MontoEntradas) AS [IngresosEntradas],
        SUM(I.MontoActividades) AS [IngresosActividades],
        SUM(I.MontoConcesiones) AS [IngresosConcesiones],
        SUM(I.MontoEntradas + I.MontoActividades + I.MontoConcesiones) AS [IngresoTotal]
    FROM IngresosUnificados I
    INNER JOIN Administracion.Parque P ON I.IdParque = P.IdParque
    GROUP BY P.Nombre, YEAR(I.Fecha), MONTH(I.Fecha), DATEPART(WEEK, I.Fecha)
    ORDER BY P.Nombre, YEAR(I.Fecha), MONTH(I.Fecha), DATEPART(WEEK, I.Fecha)
    FOR XML PATH('IngresoTemporal'), ROOT('ReporteIngresosTotales');
END;
GO


-- REPORTE 3: Deudores de Concesiones 
--------------------------------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE Facturacion.ReporteDeudoresConcesionesXML
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        E.RazonSocial AS [@Empresa],
        P.Nombre AS [@Parque],
        PC.PeriodoMesPago AS [MesAdeudado],
        PC.PeriodoAñoPago AS [AnioAdeudado],
        PC.Monto AS [MontoPendiente],
        PC.Estado AS [EstadoPago]
    FROM Facturacion.PagoCanon PC
    INNER JOIN Administracion.Concesion C ON PC.IdConcesion = C.IdConcesion
    INNER JOIN Administracion.EmpresaConcesionaria E ON C.IdEmpresaConcesionaria = E.CUIT
    INNER JOIN Administracion.Parque P ON C.IdParque = P.IdParque
    WHERE PC.Estado = 'Impago' OR PC.Estado = 'Atrasado' OR PC.Estado = 'Vencida'
    FOR XML PATH('Deuda'), ROOT('ReporteDeudores');
END;
GO

-- REPORTE 4: Matriz de visitas
---------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE Facturacion.MatrizVisitasPivotXML
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        Parque AS [@Parque], 
        ISNULL([1], 0) AS [Enero], 
        ISNULL([2], 0) AS [Febrero], 
        ISNULL([3], 0) AS [Marzo], 
        ISNULL([4], 0) AS [Abril], 
        ISNULL([5], 0) AS [Mayo], 
        ISNULL([6], 0) AS [Junio], 
        ISNULL([7], 0) AS [Julio], 
        ISNULL([8], 0) AS [Agosto], 
        ISNULL([9], 0) AS [Septiembre], 
        ISNULL([10], 0) AS [Octubre], 
        ISNULL([11], 0) AS [Noviembre], 
        ISNULL([12], 0) AS [Diciembre]
    FROM 
    (
        SELECT 
            P.Nombre AS Parque,
            MONTH(E.FechaAcceso) AS Mes,
            YEAR(E.FechaAcceso) AS Anio,
            E.Cantidad
        FROM Facturacion.TicketItemEntrada E
        INNER JOIN Facturacion.TicketFactura F ON E.IdTicketFactura = F.IdTicketFactura
        INNER JOIN Administracion.Parque P ON F.IdParque = P.IdParque
    ) AS SourceTable
    PIVOT
    (
        SUM(Cantidad)
        FOR Mes IN ([1], [2], [3], [4], [5], [6], [7], [8], [9], [10], [11], [12])
    ) AS PivotTable
    ORDER BY Parque
    FOR XML PATH('DistribucionMensual'), ROOT('MatrizVisitasAnual');
END;
GO

--
-- REPORTE 5: Estructura jerárquica de parques y concesiones anidadas 
---------------------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE Administracion.ParquesYConcesionesAnidadasXML
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        P.IdParque AS [@IdParque],
        P.Nombre AS [NombreParque],
        P.Ubicacion AS [Ubicacion],
        (
            SELECT 
                C.FechaInicio AS [FechaInicio],
                C.FechaFin AS [FechaFin],
                EC.RazonSocial AS [Titular],
                C.TipoDeActividad AS [ServicioPrestado],
                C.Canon AS [CanonMensual]
            FROM Administracion.Concesion C
            INNER JOIN Administracion.EmpresaConcesionaria EC ON C.IdEmpresaConcesionaria = EC.CUIT
            WHERE C.IdParque = P.IdParque
            FOR XML PATH('Concesion'), TYPE
        ) AS [Concesiones]
    FROM Administracion.Parque P
    FOR XML PATH('Parque'), ROOT('ReporteParquesYConcesiones');
END;
GO

USE ParquesNacionalesDB;
GO

-- ============================================================================
-- EJECUCIÓN DE PRUEBAS - REPORTES EN FORMATO XML
-- ============================================================================

-- Reporte 1A: Cantidad de visitas por semana de cada mes
EXEC Facturacion.ReporteVisitasPorSemanaXML;

-- Reporte 1B: Cantidad de visitas por cada mes del año
EXEC Facturacion.ReporteVisitasPorMesXML;

-- Reporte 1C: Cantidad de visitas por año
EXEC Facturacion.ReporteVisitasPorAnioXML;

-- Reporte 2: Ingresos temporales detallados por parque
EXEC Facturacion.ReporteIngresosTotalesXML;

-- Reporte 3: Deudores de Concesiones atrasadas/impagas
EXEC Facturacion.ReporteDeudoresConcesionesXML;

-- Reporte 4: Matriz de visitas en formato PIVOT mensual
EXEC Facturacion.MatrizVisitasPivotXML;

-- Reporte 5: Estructura jerárquica de parques y concesiones anidadas
EXEC Administracion.ParquesYConcesionesAnidadasXML;