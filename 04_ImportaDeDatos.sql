USE ParquesNacionalesDB;
GO

CREATE OR ALTER PROCEDURE ImportarArchivoParqueCSV
(
    @path VARCHAR(255)
)
AS
BEGIN

    SET NOCOUNT ON;

    DROP TABLE IF EXISTS #TempBaseCSV;

    CREATE TABLE #TempBaseCSV
    (
        Forma VARCHAR(100),
        IdSitio VARCHAR(100),
        IdSitioPersistente VARCHAR(100),
        TipoSitio VARCHAR(100),
        NombreIngles VARCHAR(255),
        Nombre VARCHAR(255),
        Tipo VARCHAR(255),
        DesignacionIngles VARCHAR(255),
        TipoDesignacion VARCHAR(100),
        CategoriaIUCN VARCHAR(100),
        CriterioInternacional VARCHAR(255),
        Ambito VARCHAR(100),
        SuperficieMarReportada VARCHAR(100),
        SuperficieMarGIS VARCHAR(100),
        AreaReportada VARCHAR(100),
        SuperficieGIS VARCHAR(100),
        SinCaptura VARCHAR(100),
        AreaSinCaptura VARCHAR(100),
        Estado VARCHAR(100),
        AnioEstado VARCHAR(100),
        TipoGobierno VARCHAR(255),
        SubtipoGobierno VARCHAR(255),
        TipoPropiedad VARCHAR(255),
        SubtipoPropiedad VARCHAR(255),
        AutoridadGestion VARCHAR(500),
        PlanGestion VARCHAR(MAX),
        Verificacion VARCHAR(100),
        IdMetadato VARCHAR(100),
        ISO3Padre VARCHAR(20),
        ISO3 VARCHAR(20),
        InfoSupplementaria VARCHAR(MAX),
        ObjetivoConservacion VARCHAR(MAX),
        AguasInteriores VARCHAR(100),
        EvaluacionOECM VARCHAR(100)
    );

    DECLARE @SQL NVARCHAR(MAX);

    SET @SQL = N'
    BULK INSERT #TempBaseCSV
    FROM ''' + @path + '''
    WITH
    (
        FIRSTROW = 2,
        FIELDTERMINATOR = '';'',
        ROWTERMINATOR = ''0x0a'',
        CODEPAGE = ''65001''
    );';

    EXEC sp_executesql @SQL;

    ------------------------------------------------------------------
    -- TIPOS DE PARQUE NUEVOS
    ------------------------------------------------------------------

    INSERT INTO Administracion.TipoParque (Descripcion)
    SELECT DISTINCT TRIM(T.Tipo)
    FROM #TempBaseCSV T
    WHERE T.Tipo IS NOT NULL
      AND TRIM(T.Tipo) <> ''
      AND NOT EXISTS
      (
          SELECT 1
          FROM Administracion.TipoParque TP
          WHERE TRIM(TP.Descripcion) = TRIM(T.Tipo)
      );

    ------------------------------------------------------------------
    -- ACTUALIZAR PARQUES EXISTENTES
    ------------------------------------------------------------------

    UPDATE P
    SET
        P.Nombre =
            LEFT(
                TRIM(T.Tipo) + ' - ' + TRIM(T.Nombre),
                100
            ),
        P.Superficie =
            ISNULL(TRY_CAST(T.AreaReportada AS DECIMAL(12,2)), 0),
        P.Descripcion =
            LEFT(ISNULL(T.PlanGestion, ''), 100),
        P.IdTipoParque =
            TP.IdTipoParque
    FROM Administracion.Parque P
    INNER JOIN #TempBaseCSV T
        ON TRIM(P.Ubicacion) = TRIM(T.Nombre)
    INNER JOIN Administracion.TipoParque TP
        ON TRIM(TP.Descripcion) = TRIM(T.Tipo);

    ------------------------------------------------------------------
    -- INSERTAR PARQUES NUEVOS USANDO EL ABM
    ------------------------------------------------------------------

    DECLARE @Nombre VARCHAR(100);
    DECLARE @Ubicacion VARCHAR(200);
    DECLARE @Superficie DECIMAL(12,2);
    DECLARE @Descripcion VARCHAR(100);
    DECLARE @IdTipoParque INT;
    DECLARE @IdParque INT;

    DECLARE CurParques CURSOR FOR

    SELECT
        LEFT(
            TRIM(T.Tipo) + ' - ' + TRIM(T.Nombre),
            100
        ),
        T.Nombre,
        ISNULL(TRY_CAST(T.AreaReportada AS DECIMAL(12,2)), 0),
        LEFT(ISNULL(T.PlanGestion, ''), 100),
        TP.IdTipoParque
    FROM #TempBaseCSV T
    INNER JOIN Administracion.TipoParque TP
        ON TRIM(TP.Descripcion) = TRIM(T.Tipo)
    WHERE NOT EXISTS
    (
        SELECT 1
        FROM Administracion.Parque P
        WHERE TRIM(P.Ubicacion) = TRIM(T.Nombre)
    );

    OPEN CurParques;

    FETCH NEXT FROM CurParques
    INTO
        @Nombre,
        @Ubicacion,
        @Superficie,
        @Descripcion,
        @IdTipoParque;

    WHILE @@FETCH_STATUS = 0
    BEGIN

        EXEC Administracion.Parque_Insertar
            @Nombre = @Nombre,
            @Ubicacion = @Ubicacion,
            @Superficie = @Superficie,
            @Descripcion = @Descripcion,
            @IdTipoParque = @IdTipoParque,
            @EsActivo = 1,
            @IdParque = @IdParque OUTPUT;

        FETCH NEXT FROM CurParques
        INTO
            @Nombre,
            @Ubicacion,
            @Superficie,
            @Descripcion,
            @IdTipoParque;

    END

    CLOSE CurParques;
    DEALLOCATE CurParques;

END
GO


EXEC ImportarArchivoParqueCSV
'C:\temp\parque.csv'


SELECT * FROM Administracion.Parque;
SELECT * FROM Administracion.TipoParque;


----------------------------------------------------------------------------------

/*
Hardcodeado, no creo que este bien
(Es una tabla chica, se puede insertar solo con los SP de insert, pero quiero confirmar)
*/

   
IF OBJECT_ID('Administracion.CargarTiposVisitante', 'P') IS NOT NULL
    DROP PROCEDURE Administracion.CargarTiposVisitante;
GO

CREATE PROCEDURE Administracion.CargarTiposVisitante
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @IdTipoVisitante INT;

    EXEC Administracion.TipoVisitante_Insertar
        @Descripcion = 'General',
        @EsActivo = 1,
        @IdTipoVisitante = @IdTipoVisitante OUTPUT;

    EXEC Administracion.TipoVisitante_Insertar
        @Descripcion = 'Nacional',
        @EsActivo = 1,
        @IdTipoVisitante = @IdTipoVisitante OUTPUT;

    EXEC Administracion.TipoVisitante_Insertar
        @Descripcion = 'ResidentesProvinciales',
        @EsActivo = 1,
        @IdTipoVisitante = @IdTipoVisitante OUTPUT;

    EXEC Administracion.TipoVisitante_Insertar
        @Descripcion = 'Estudiantes',
        @EsActivo = 1,
        @IdTipoVisitante = @IdTipoVisitante OUTPUT;

    EXEC Administracion.TipoVisitante_Insertar
        @Descripcion = 'Exentos',
        @EsActivo = 1,
        @IdTipoVisitante = @IdTipoVisitante OUTPUT;

END
GO

EXEC Administracion.CargarTiposVisitante;

---

CREATE OR ALTER PROCEDURE ImportarArchivoTarifaCSV
(
    @Path VARCHAR(255)
)
AS
BEGIN

    SET NOCOUNT ON;

    DROP TABLE IF EXISTS #TempTarifas;

    CREATE TABLE #TempTarifas
    (
        Parque VARCHAR(200),
        General VARCHAR(50),
        Nacional VARCHAR(50),
        ResidentesProvinciales VARCHAR(50),
        Estudiantes VARCHAR(50),
        Exentos VARCHAR(50)
    );

    DECLARE @SQL NVARCHAR(512);

    SET @SQL = N'
    BULK INSERT #TempTarifas
    FROM ''' + @Path + '''
    WITH
    (
        FIRSTROW = 2,
        FIELDTERMINATOR = '','',
        ROWTERMINATOR = ''0x0a''
    );';

    EXEC sp_executesql @SQL;

    DELETE FROM Facturacion.PrecioEntrada;
    DBCC CHECKIDENT ('Facturacion.PrecioEntrada', RESEED, 0);

    DECLARE @IdParque INT;
    DECLARE @IdTipoVisitante INT;
    DECLARE @Precio DECIMAL(10,2);
    DECLARE @IdPrecio INT;
    DECLARE @Hoy DATE;

    SET @Hoy = CAST(GETDATE() AS DATE);

    DECLARE CurTarifas CURSOR FOR
    SELECT
        P.IdParque,
        TV.IdTipoVisitante,
        CAST(U.Precio AS DECIMAL(10,2))
    FROM
    (
        SELECT
            Parque,
            TipoVisitante,
            Precio
        FROM #TempTarifas
        UNPIVOT
        (
            Precio FOR TipoVisitante IN
            (
                General,
                Nacional,
                ResidentesProvinciales,
                Estudiantes,
                Exentos
            )
        ) U
    ) U
    INNER JOIN Administracion.Parque P
        ON TRIM(P.Ubicacion) = TRIM(U.Parque)
    INNER JOIN Administracion.TipoVisitante TV
        ON TV.Descripcion = U.TipoVisitante;

    OPEN CurTarifas;

    FETCH NEXT FROM CurTarifas
    INTO @IdParque, @IdTipoVisitante, @Precio;

    WHILE @@FETCH_STATUS = 0
    BEGIN

        EXEC Facturacion.PrecioEntrada_Insertar
            @IdParque = @IdParque,
            @IdTipoVisitante = @IdTipoVisitante,
            @Precio = @Precio,
            @VigenteDesde = @Hoy,
            @VigenteHasta = NULL,
            @IdPrecio = @IdPrecio OUTPUT;

        FETCH NEXT FROM CurTarifas
        INTO @IdParque, @IdTipoVisitante, @Precio;

    END

    CLOSE CurTarifas;
    DEALLOCATE CurTarifas;

END
GO

EXEC ImportarArchivoTarifaCSV
    'C:\Users\aguse\Documents\temp\tarifasParques.csv';

SELECT * FROM Facturacion.PrecioEntrada;
