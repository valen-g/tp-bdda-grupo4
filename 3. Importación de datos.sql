USE ParquesNacionalesDB;
GO

CREATE OR ALTER PROCEDURE ImportarArchivoParqueCSV
(
    @path VARCHAR(255)
)
AS
BEGIN

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
        PlanGestion VARCHAR(128),
        Verificacion VARCHAR(100),
        IdMetadato VARCHAR(100),
        ISO3Padre VARCHAR(128),
        ISO3 VARCHAR(20),
        InfoSupplementaria VARCHAR(128),
        ObjetivoConservacion VARCHAR(128),
        AguasInteriores VARCHAR(100),
        EvaluacionOECM VARCHAR(100)
    );

    DECLARE @SQL NVARCHAR(512);

    SET @SQL = N'
    BULK INSERT #TempBaseCSV
    FROM ''' + @path + '''
    WITH
    (
        FIRSTROW = 2,
        FIELDTERMINATOR = '','',
        ROWTERMINATOR = ''0x0a'',
        CODEPAGE = ''65001'',
        FORMAT = ''CSV''
    );';

    EXEC sp_executesql @SQL;

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

    INSERT INTO Administracion.Parque
    (
        Nombre,
        Ubicacion,
        Superficie,
        Descripcion,
        IdTipoParque
    )
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

END
GO


EXEC ImportarArchivoParqueCSV
'C:\Users\iviez\Documents\BDDA\TP\ParquesNacionales\0. Entradas\0. Parques.csv'


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

CREATE OR ALTER PROCEDURE ImportarArchivoPersonal (@path varchar(255))
AS 
BEGIN
      
    DROP TABLE IF EXISTS #TempPersonalCSV;

	CREATE TABLE #TempPersonalCSV 
    (
        DNI VARCHAR(32),
        ApeNom VARCHAR(128),
        escalafon VARCHAR(255),
        tipo_contratacion VARCHAR(255),
        organismo VARCHAR(255),
        tipo_administracion VARCHAR(32),
        telefono VARCHAR(32),
        periodo VARCHAR(16)
    );

    DECLARE @SQL NVARCHAR(512);
    
    SET @sql = N'
    BULK INSERT #TempPersonalCSV
    FROM ''' + @path + '''
    WITH
    (
        FIELDTERMINATOR = '';'',
        ROWTERMINATOR = ''0x0a'', --Es lo mismo que \n, pero no sé por qué no funcionaba
        CODEPAGE = ''65001'',
        FIRSTROW = 2,
        FIELDQUOTE = ''"'',
        FORMAT = ''CSV''
    );';

    EXEC sp_executesql @sql;
    
    SELECT * FROM #TempPersonalCSV

    DELETE FROM Administracion.Personal;
    
    INSERT INTO Administracion.Personal 
    (
        DNI, 
        NombreApellido, 
        Telefono, 
        TipoPersonal,
        EsActivo,
        FechaNacimiento,
        Email,
        IdHabilitacion,
        IdAsignacion
    )
    SELECT 
        TRY_CAST(REPLACE(csv.DNI, '.', '') AS INT),
        csv.ApeNom,
        TRY_CAST(TelefonoFinal.TelefonoSinCaracteres AS BIGINT),
        
        CASE 
            WHEN TRIM(csv.escalafon) LIKE '%GUARDAPARQUES%' 
            THEN 'Guardaparques' 
            ELSE 'Guia' 
        END,
        
        1 AS EsActivo, 
        NULL AS FechaNacimiento,
        NULL AS Email,
        
        Hab.IdHabilitacion,
        Asig.IdAsignacion
        
    FROM #TempPersonalCSV csv

    CROSS APPLY (
        SELECT CASE 
            WHEN CHARINDEX('/', csv.telefono) > 0 
            THEN LEFT(csv.telefono, CHARINDEX('/', csv.telefono) - 1)
            ELSE csv.telefono 
        END AS TelefonoCortado
    ) PrimeraParteTelefono
    -- esto lo hacemos asi porque en el archivo CSV que encontramos 
    --hay telefonos que son del estilo 4317-6000 / 6005
    -- entonces nos quedamos solo con la primer parte de este

    CROSS APPLY (
        SELECT REPLACE(REPLACE(PrimeraParteTelefono.TelefonoCortado, '-', ''), ' ', '') AS TelefonoSinCaracteres
    ) TelefonoFinal
    
    CROSS APPLY (
        SELECT TOP 1 IdHabilitacion 
        FROM Administracion.Habilitacion 
        WHERE csv.DNI = csv.DNI
        ORDER BY NEWID()
    ) Hab
    
    CROSS APPLY (
        SELECT TOP 1 IdAsignacion 
        FROM Administracion.AsignacionParque 
        WHERE csv.DNI = csv.DNI
        ORDER BY NEWID()
    ) Asig
    
    WHERE csv.DNI IS NOT NULL AND TRIM(csv.DNI) <> '' AND UPPER(csv.organismo) LIKE '%PARQUES NACIONALES%';
END

EXEC ImportarArchivoPersonal
'C:\Users\iviez\Documents\BDDA\TP\ParquesNacionales\0. Entradas\2. Personal.csv'
