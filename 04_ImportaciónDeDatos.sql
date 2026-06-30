/*
# Universidad: Universidad Nacional de La Matanza
# Materia: 3641 - Bases de Datos Aplicada
# Grupo: Grupo 4
# Integrantes:
- Belloni, Nicolas
- Bernardo, Ivan
- Gonzalez, Agustin
- Gallo, Valentina

# Fecha: 05/06/2026
--------------------------------------------------------------------------------
    Script          : 04_ImportaciónDeDatos.sql
    Objetivo        : Importa los datos provenientes de distintas 
                      fuentes en formato de CSV.
================================================================================
*/

USE ParquesNacionalesDB;
GO 

--SP para importar los datos desde parques.csv

CREATE OR ALTER PROCEDURE Administracion.ImportarArchivoParqueCSV
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

    DECLARE
    @Nombre VARCHAR(100),
    @Ubicacion VARCHAR(200),
    @Superficie DECIMAL(12,2),
    @Descripcion VARCHAR(100),
    @IdTipoParque INT,
    @SQL NVARCHAR(512),
    @EsActivo VARCHAR(100),
    @EsActivoBit BIT;

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

    UPDATE #TempBaseCSV
    SET
    Nombre = REPLACE(REPLACE(REPLACE(TRIM(Nombre), CHAR(13), ''), CHAR(10), ''), '"', ''),
    Tipo   = REPLACE(REPLACE(REPLACE(TRIM(Tipo),   CHAR(13), ''), CHAR(10), ''), '"', '');

    -- ==============================================================
    -- 1. CURSOR PARA TIPOS DE PARQUE
    -- ==============================================================
    DECLARE @DescripcionTipo VARCHAR(100);
    DECLARE @IdTipoParqueNuevo INT;

    DECLARE CurTipos CURSOR FOR
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

    OPEN CurTipos;
    FETCH NEXT FROM CurTipos INTO @DescripcionTipo;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        BEGIN TRY
            BEGIN TRAN
                EXEC Administracion.TipoParque_Insertar
                    @Descripcion = @DescripcionTipo,
                    @IdTipoParque = @IdTipoParqueNuevo OUTPUT;
            COMMIT TRAN 
        END TRY
        BEGIN CATCH
            IF @@TRANCOUNT > 0 ROLLBACK TRAN;
            INSERT INTO Administracion.LogRegistros(NumeroRegistroError,Descripcion)
            VALUES (
                ERROR_NUMBER(), 
                LEFT('Tipo: ' + @DescripcionTipo + ' - '+  ERROR_MESSAGE(), 255)
            );
        END CATCH 

        FETCH NEXT FROM CurTipos INTO @DescripcionTipo;
    END
    CLOSE CurTipos;
    DEALLOCATE CurTipos;

    -- ==============================================================
    -- 2. CURSOR PARA ACTUALIZAR PARQUES EXISTENTES
    -- ==============================================================
    DECLARE @IdParqueActualizar INT;

    DECLARE CurActualizar CURSOR FOR
    SELECT
        P.IdParque,
        LEFT(TRIM(T.Tipo) + ' - ' + TRIM(T.Nombre), 100),
        P.Ubicacion,
        ISNULL(TRY_CAST(T.AreaReportada AS INT), 0),
        LEFT(ISNULL(T.PlanGestion, ''), 100),
        TP.IdTipoParque,
        T.Estado
    FROM Administracion.Parque P
    INNER JOIN #TempBaseCSV T
        ON TRIM(P.Ubicacion) = TRIM(T.Nombre)
    INNER JOIN Administracion.TipoParque TP
        ON TRIM(TP.Descripcion) = TRIM(T.Tipo);

    OPEN CurActualizar;

    FETCH NEXT FROM CurActualizar
    INTO
        @IdParqueActualizar,
        @Nombre,
        @Ubicacion,
        @Superficie,
        @Descripcion,
        @IdTipoParque,
        @EsActivo;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        BEGIN TRY
            BEGIN TRAN
                
                IF @EsActivo IS NULL OR TRIM(@EsActivo) = '' 
                    SET @EsActivoBit = 0;
                ELSE 
                    SET @EsActivoBit = 1;

                EXEC Administracion.Parque_Actualizar
                    @IdParque = @IdParqueActualizar,
                    @Nombre = @Nombre,
                    @Ubicacion = @Ubicacion,
                    @Superficie = @Superficie,
                    @Descripcion = @Descripcion,
                    @IdTipoParque = @IdTipoParque,
                    @EsActivo = @EsActivoBit; 

            COMMIT TRAN
        END TRY
        BEGIN CATCH
            IF @@TRANCOUNT > 0 ROLLBACK TRAN;
            INSERT INTO Administracion.LogRegistros(NumeroRegistroError,Descripcion)
            VALUES (
                ERROR_NUMBER(),
                LEFT('ParqueID: ' + ISNULL(CAST(@IdParqueActualizar AS VARCHAR), 'N/A') + ' - ' + ERROR_MESSAGE(), 255)
            );
        END CATCH

        FETCH NEXT FROM CurActualizar
        INTO
            @IdParqueActualizar,
            @Nombre,
            @Ubicacion,
            @Superficie,
            @Descripcion,
            @IdTipoParque,
            @EsActivo;
    END

    CLOSE CurActualizar;
    DEALLOCATE CurActualizar;

    -- ==============================================================
    -- 3. CURSOR PARA INSERTAR NUEVOS PARQUES
    -- ==============================================================
    DECLARE CurParques CURSOR FOR
    SELECT
        LEFT(TRIM(T.Tipo) + ' - ' + TRIM(T.Nombre), 100),
        T.Nombre,
        ISNULL(TRY_CAST(T.AreaReportada AS DECIMAL(12,2)), 0),
        LEFT(ISNULL(T.PlanGestion, ''), 100),
        TP.IdTipoParque,
        T.Estado
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
        @IdTipoParque,
        @EsActivo;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        BEGIN TRY
            BEGIN TRAN
                
                IF @EsActivo IS NULL OR TRIM(@EsActivo) = '' 
                    SET @EsActivoBit = 0;
                ELSE 
                    SET @EsActivoBit = 1;

                EXEC Administracion.Parque_Insertar
                    @Nombre = @Nombre,
                    @Ubicacion = @Ubicacion,
                    @Superficie = @Superficie,
                    @Descripcion = @Descripcion,
                    @IdTipoParque = @IdTipoParque,
                    @EsActivo = @EsActivoBit;
                
            COMMIT TRAN
        END TRY
        BEGIN CATCH
            IF @@TRANCOUNT > 0 ROLLBACK TRAN;
            INSERT INTO Administracion.LogRegistros(NumeroRegistroError,Descripcion)
            VALUES(
                ERROR_NUMBER(),
                LEFT('Nombre: ' + ISNULL(@Nombre, 'N/A') + ' - ' + ERROR_MESSAGE(), 255)
            );
        END CATCH

        FETCH NEXT FROM CurParques
        INTO
            @Nombre,
            @Ubicacion,
            @Superficie,
            @Descripcion,
            @IdTipoParque,
            @EsActivo;
    END

    CLOSE CurParques;
    DEALLOCATE CurParques;

END
GO

EXEC Administracion.ImportarArchivoParqueCSV
'C:\Users\iviez\Documents\BDDA\TP Gestión de Parques Nacionales\ParquesNacionales\0. Entradas\0. Parques.csv'
GO

CREATE OR ALTER PROCEDURE Administracion.CargarTiposVisitante
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @IdTipoVisitante INT;

    EXEC Administracion.TipoVisitante_Insertar
        @Descripcion = 'General',
        @EsActivo = 1,
        @IdTipoVisitante = @IdTipoVisitante ;

    EXEC Administracion.TipoVisitante_Insertar
        @Descripcion = 'Nacional',
        @EsActivo = 1,
        @IdTipoVisitante = @IdTipoVisitante ;

    EXEC Administracion.TipoVisitante_Insertar
        @Descripcion = 'ResidentesProvinciales',
        @EsActivo = 1,
        @IdTipoVisitante = @IdTipoVisitante ;

    EXEC Administracion.TipoVisitante_Insertar
        @Descripcion = 'Estudiantes',
        @EsActivo = 1,
        @IdTipoVisitante = @IdTipoVisitante ;

    EXEC Administracion.TipoVisitante_Insertar
        @Descripcion = 'Exentos',
        @EsActivo = 1,
        @IdTipoVisitante = @IdTipoVisitante ;

END
GO

EXEC Administracion.CargarTiposVisitante;
GO

CREATE OR ALTER PROCEDURE Administracion.ImportarArchivoTarifaCSV
(
    @Path VARCHAR(255)
)
AS
BEGIN

    SET NOCOUNT ON;

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
        FIELDTERMINATOR = '';'',
        ROWTERMINATOR = ''0x0a''
    );';

    EXEC sp_executesql @SQL;
    
    DECLARE @IdParque INT;
    DECLARE @IdTipoVisitante INT;
    DECLARE @Precio DECIMAL(10,2);
    DECLARE @IdPrecio INT;
    DECLARE @Hoy DATE = CAST(GETDATE() AS DATE);

    DECLARE CurTarifas CURSOR FOR
    SELECT
        P.IdParque,
        TV.IdTipoVisitante,
        TRY_CAST(
            REPLACE(
                REPLACE(
                    REPLACE(
                        REPLACE(U.Precio, '$', ''), 
                    ' ', ''), 
                CHAR(13), ''), 
            ',', '.') 
        AS DECIMAL(10,2))
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
        BEGIN TRY
            BEGIN TRAN
                DECLARE @IdPrecioVigente INT = NULL;
                DECLARE @PrecioVigente DECIMAL(10,2) = NULL;
                DECLARE @VigenteDesdeActual DATE = NULL;

                SELECT TOP 1 
                    @IdPrecioVigente = IdPrecio, 
                    @PrecioVigente = Precio,
                    @VigenteDesdeActual = VigenteDesde
                FROM Facturacion.PrecioEntrada
                WHERE IdParque = @IdParque 
                  AND IdTipoVisitante = @IdTipoVisitante 
                  AND VigenteHasta IS NULL
                ORDER BY IdPrecio DESC;

                IF @IdPrecioVigente IS NULL
                BEGIN
                    EXEC Facturacion.PrecioEntrada_Insertar
                        @IdParque = @IdParque,
                        @IdTipoVisitante = @IdTipoVisitante,
                        @Precio = @Precio,
                        @VigenteDesde = @Hoy,
                        @VigenteHasta = NULL,
                        @IdPrecio = @IdPrecio OUTPUT;
                END
                ELSE IF @PrecioVigente <> @Precio
                BEGIN
                    EXEC Facturacion.PrecioEntrada_Actualizar 
                        @IdPrecio = @IdPrecioVigente, 
                        @Precio = @PrecioVigente, 
                        @VigenteDesde = @VigenteDesdeActual, 
                        @VigenteHasta = @Hoy;

                    EXEC Facturacion.PrecioEntrada_Insertar
                        @IdParque = @IdParque,
                        @IdTipoVisitante = @IdTipoVisitante,
                        @Precio = @Precio,
                        @VigenteDesde = @Hoy,
                        @VigenteHasta = NULL,
                        @IdPrecio = @IdPrecio OUTPUT;

                END
                COMMIT TRAN
            END TRY
            BEGIN CATCH
            IF @@TRANCOUNT > 0 ROLLBACK TRAN;
                INSERT INTO Administracion.LogRegistros (NumeroRegistroError, Descripcion)
                VALUES (
                    ERROR_NUMBER(), 
                    'Precio error: ' + ISNULL(CAST(@Precio AS VARCHAR), 'N/A') + ' - ' + ERROR_MESSAGE()
                );
            END CATCH

                FETCH NEXT FROM CurTarifas
                INTO @IdParque, @IdTipoVisitante, @Precio
    END

    CLOSE CurTarifas;
    DEALLOCATE CurTarifas;


    DECLARE CurFaltantes CURSOR FOR
    SELECT P.IdParque, TV.IdTipoVisitante
    FROM Administracion.Parque P
    CROSS JOIN Administracion.TipoVisitante TV
    WHERE NOT EXISTS (
        SELECT 1 FROM Facturacion.PrecioEntrada PE 
        WHERE PE.IdParque = P.IdParque
        AND PE.IdTipoVisitante = TV.IdTipoVisitante);

    OPEN CurFaltantes;
    FETCH NEXT FROM CurFaltantes INTO @IdParque, @IdTipoVisitante;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        BEGIN TRY
            BEGIN TRAN;
            
            DECLARE @PrecioPorDefecto DECIMAL(10,2) = 30000.00;
            DECLARE @IdPrecioGeneradoDefecto INT;

            EXEC Facturacion.PrecioEntrada_Insertar
                @IdParque = @IdParque,
                @IdTipoVisitante = @IdTipoVisitante,
                @Precio = @PrecioPorDefecto,
                @VigenteDesde = @Hoy,
                @VigenteHasta = NULL,
                @IdPrecio = @IdPrecioGeneradoDefecto OUTPUT;

            COMMIT TRAN;
        END TRY
        BEGIN CATCH
            IF @@TRANCOUNT > 0 ROLLBACK TRAN;
            INSERT INTO Administracion.LogRegistros (NumeroRegistroError, Descripcion)
            VALUES (
                ERROR_NUMBER(),
                LEFT('Error Precio Defecto ParqueID ' + ISNULL(CAST(@IdParque AS VARCHAR), 'N/A') + ': ' + ERROR_MESSAGE(), 255)
            );
        END CATCH
        
        FETCH NEXT FROM CurFaltantes INTO @IdParque, @IdTipoVisitante;
    END
    
    CLOSE CurFaltantes;
    DEALLOCATE CurFaltantes;

END
GO

EXEC Administracion.ImportarArchivoTarifaCSV
    'C:\Users\iviez\Documents\BDDA\TP Gestión de Parques Nacionales\ParquesNacionales\0. Entradas\1. Tarifas.csv';
GO

CREATE OR ALTER PROCEDURE Administracion.ImportarArchivoPersonal
(
    @path VARCHAR(255)
)
AS
BEGIN
       
    SET NOCOUNT ON;
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
        periodo VARCHAR(16),
        Descripcion VARCHAR(100),
        FechaOtorgamiento VARCHAR(128),
        FechaVencimiento VARCHAR(128),
        NombreParque VARCHAR(100)
    );

    DECLARE @SQL NVARCHAR(512);

    SET @SQL = N'
    BULK INSERT #TempPersonalCSV
    FROM ''' + @path + '''
    WITH
    (
        FIELDTERMINATOR = '';'',
        ROWTERMINATOR = ''0x0a'',
        CODEPAGE = ''1252''
    );'

    --1252 porque soporta la ñ

    EXEC sp_executesql @SQL;

    DECLARE
        @DNI INT,                            
        @NombreApe VARCHAR(128),            
        @Telefono BIGINT,                    
        @TipoPersonal VARCHAR(20),          
        @IdHabilitacion INT,
        @Descripcion VARCHAR(100),          
        @FechaOtorgamiento DATE,            
        @FechaVencimiento DATE,
        @IdParque INT;

    DECLARE CurPersonal CURSOR FOR
    SELECT
        CAST(csv.ApeNom AS VARCHAR(128)),
        TRY_CAST(REPLACE(csv.DNI, '.', '') AS INT),
        TRY_CAST
        (
            REPLACE
            (
                REPLACE
                (
                    CASE
                        WHEN CHARINDEX('/', csv.telefono) > 0
                        THEN LEFT(csv.telefono, CHARINDEX('/', csv.telefono) - 1)
                        ELSE csv.telefono
                    END,
                    '-',
                    ''
                ),
                ' ',
                ''
            ) AS BIGINT
        ),
        CAST(
            CASE
                WHEN UPPER(TRIM(csv.escalafon)) LIKE '%GUARDAPARQUES%'
                THEN 'Guardaparques'
                ELSE 'Guia'
            END AS VARCHAR(20)
        ),
        CAST(csv.Descripcion AS VARCHAR(100)),
        TRY_CONVERT(DATE, csv.FechaOtorgamiento, 103),
        TRY_CONVERT(DATE, csv.FechaVencimiento, 103),
        p.IdParque

    FROM #TempPersonalCSV csv
    LEFT JOIN Administracion.Parque p
    ON UPPER(TRIM(REPLACE(p.Nombre,CHAR(13), '')))
     = UPPER(TRIM(REPLACE(csv.NombreParque,CHAR(13), '')))
    WHERE csv.DNI IS NOT NULL
      AND TRIM(csv.DNI) <> ''
      AND UPPER(csv.organismo) LIKE '%PARQUES NACIONALES%';

    OPEN CurPersonal;

    FETCH NEXT FROM CurPersonal
    INTO
        @NombreApe,
        @DNI,
        @Telefono,
        @TipoPersonal,
        @Descripcion,
        @FechaOtorgamiento,
        @FechaVencimiento,
        @IdParque;
    
    WHILE @@FETCH_STATUS = 0
    BEGIN
        BEGIN TRY
            BEGIN TRAN 
        
                SET @IdHabilitacion = NULL;
                DECLARE @IdAsignacion INT = NULL;
                DECLARE @FechaEgreso DATE = NULL; 

                DECLARE @IdHabilitacionActual INT = NULL;
                DECLARE @DescActual VARCHAR(100) = NULL;
                DECLARE @FecOtorgActual DATE = NULL;
                DECLARE @FecVencActual DATE = NULL;
        
                IF @FechaOtorgamiento IS NOT NULL AND @FechaVencimiento IS NOT NULL
                BEGIN
                    SELECT @IdHabilitacionActual = IdHabilitacion 
                    FROM Administracion.Personal 
                    WHERE DNI = @DNI;

                    IF @IdHabilitacionActual IS NOT NULL
                    BEGIN
                        SELECT 
                            @DescActual = Descripcion,
                            @FecOtorgActual = FechaOtorgamiento,
                            @FecVencActual = FechaVencimiento
                        FROM Administracion.Habilitacion
                        WHERE IdHabilitacion = @IdHabilitacionActual;
                    END

                    IF @IdHabilitacionActual IS NULL
                    BEGIN
                        EXEC Administracion.Habilitacion_Insertar
                            @Descripcion       = @Descripcion,
                            @FechaOtorgamiento = @FechaOtorgamiento,
                            @FechaVencimiento  = @FechaVencimiento,
                            @IdHabilitacion    = @IdHabilitacion OUTPUT;
                    END
                    ELSE IF (@DescActual <> @Descripcion 
                          OR @FecOtorgActual <> @FechaOtorgamiento 
                          OR @FecVencActual <> @FechaVencimiento)
                    BEGIN
                        DECLARE @FechaCierre DATE = GETDATE();

                        EXEC Administracion.Habilitacion_Actualizar
                            @IdHabilitacion    = @IdHabilitacionActual,
                            @Descripcion       = @DescActual,
                            @FechaOtorgamiento = @FecOtorgActual,
                            @FechaVencimiento  = @FechaCierre;

                        EXEC Administracion.Habilitacion_Insertar
                            @Descripcion       = @Descripcion,
                            @FechaOtorgamiento = @FechaOtorgamiento,
                            @FechaVencimiento  = @FechaVencimiento,
                            @IdHabilitacion    = @IdHabilitacion OUTPUT;
                    END
                    ELSE
                    BEGIN
                        SET @IdHabilitacion = @IdHabilitacionActual;
                    END
                END
                ELSE
                BEGIN
                    SELECT @IdHabilitacion = IdHabilitacion 
                    FROM Administracion.Personal 
                    WHERE DNI = @DNI;
                END

                -- =========================================================
                -- 2. Lógica Asignación con Historial
                -- =========================================================
                DECLARE @IdAsignacionActual INT = NULL;
                DECLARE @IdParqueActual INT = NULL;
                DECLARE @FechaIngresoPrevia DATE = NULL;
        
                SELECT @IdAsignacionActual = IdAsignacion 
                FROM Administracion.Personal 
                WHERE DNI = @DNI;

                IF @IdAsignacionActual IS NOT NULL
                BEGIN
                    SELECT @IdParqueActual = IdParque, @FechaIngresoPrevia = FechaIngreso
                    FROM Administracion.AsignacionParque 
                    WHERE IdAsignacion = @IdAsignacionActual;
                END

                IF @IdParque IS NOT NULL
                BEGIN
                    IF @IdAsignacionActual IS NULL OR @IdParqueActual IS NULL
                    BEGIN
                        EXEC Administracion.AsignacionParque_Insertar
                            @IdParque     = @IdParque,
                            @FechaEgreso  = @FechaEgreso,   
                            @IdAsignacion = @IdAsignacion OUTPUT;
                    END
                    ELSE IF @IdParqueActual <> @IdParque
                    BEGIN
                        DECLARE @FechaBaja DATE = GETDATE(); 

                        EXEC Administracion.AsignacionParque_Actualizar
                            @IdAsignacion = @IdAsignacionActual,
                            @IdParque     = @IdParqueActual,
                            @FechaIngreso = @FechaIngresoPrevia,
                            @FechaEgreso  = @FechaBaja, 
                            @MotivoEgreso = 'Reasignación por importación';

                        EXEC Administracion.AsignacionParque_Insertar
                            @IdParque     = @IdParque,
                            @FechaEgreso  = @FechaEgreso,   
                            @IdAsignacion = @IdAsignacion OUTPUT;
                    END
                    ELSE
                    BEGIN
                        SET @IdAsignacion = @IdAsignacionActual;
                    END
                END
                ELSE
                BEGIN
                    SET @IdAsignacion = @IdAsignacionActual;
                END

                IF EXISTS (SELECT 1 FROM Administracion.Personal WHERE DNI = @DNI)
                BEGIN
                    EXEC Administracion.Personal_Actualizar
                        @DNI             = @DNI,
                        @NombreApellido  = @NombreApe,
                        @FechaNacimiento = NULL,
                        @Email           = NULL,
                        @Telefono        = @Telefono,
                        @TipoPersonal    = @TipoPersonal,
                        @EsActivo        = 1,
                        @IdHabilitacion  = @IdHabilitacion,
                        @IdAsignacion    = @IdAsignacion;
                END
                ELSE
                BEGIN
                    EXEC Administracion.Personal_Insertar
                        @NombreApellido  = @NombreApe,
                        @DNI             = @DNI,
                        @FechaNacimiento = NULL,
                        @Email           = NULL,
                        @Telefono        = @Telefono,
                        @TipoPersonal    = @TipoPersonal,
                        @EsActivo        = 1,
                        @IdHabilitacion  = @IdHabilitacion,
                        @IdAsignacion    = @IdAsignacion; 
            END

            COMMIT TRAN
        END TRY
        BEGIN CATCH
            IF @@TRANCOUNT > 0 ROLLBACK TRAN;
                INSERT INTO Administracion.LogRegistros (NumeroRegistroError, Descripcion)
                VALUES (
                    ERROR_NUMBER(), 
                   'DNI: ' + ISNULL(CAST(@DNI AS VARCHAR), 'N/A') + ' - ' + ERROR_MESSAGE()
                );
            END CATCH

        FETCH NEXT FROM CurPersonal
        INTO @NombreApe, @DNI, @Telefono, @TipoPersonal,
             @Descripcion, @FechaOtorgamiento, @FechaVencimiento, @IdParque;
    END

    CLOSE CurPersonal;
    DEALLOCATE CurPersonal;

END
GO

EXEC Administracion.ImportarArchivoPersonal
    'C:\Users\iviez\Documents\BDDA\TP Gestión de Parques Nacionales\ParquesNacionales\0. Entradas\2. Personal.csv'