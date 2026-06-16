CREATE OR ALTER PROCEDURE ImportarArchivoParqueCSV (@path varchar(255))
AS 
BEGIN

    DROP TABLE IF EXISTS #TempBaseCSV;

	CREATE TABLE #TempBaseCSV 
    (
        Forma VARCHAR(50),
        IdSitio INT,
        IdSitioPersistente VARCHAR(50),
        TipoSitio VARCHAR(10),
        NombreIngles VARCHAR(255),
        Nombre VARCHAR(255),
        Tipo VARCHAR(255),
        DesignacionIngles VARCHAR(255),
        TipoDesignacion VARCHAR(50),
        CategoriaIUCN VARCHAR(20),
        CriterioInternacional VARCHAR(100),
        Ambito VARCHAR(50),
        SuperficieMarReportada DECIMAL(12,3),
        SuperficieMarGIS DECIMAL(12,3),
        AreaReportada DECIMAL(12,3),
        SuperficieGIS DECIMAL(12,3),
        SinCaptura VARCHAR(50),
        AreaSinCaptura DECIMAL(12,3),
        Estado VARCHAR(50),
        AnioEstado SMALLINT,
        TipoGobierno VARCHAR(100),
        SubtipoGobierno VARCHAR(100),
        TipoPropiedad VARCHAR(100),
        SubtipoPropiedad VARCHAR(100),
        AutoridadGestion VARCHAR(255),
        PlanGestion VARCHAR(500),
        Verificacion VARCHAR(50),
        IdMetadato INT,
        ISO3Padre VARCHAR(10),
        ISO3 VARCHAR(10),
        InfoSupplementaria VARCHAR(500),
        ObjetivoConservacion VARCHAR(500),
        AguasInteriores VARCHAR(50),
        EvaluacionOECM VARCHAR(50)
    );

    DECLARE @SQL NVARCHAR(512);
    
    SET @sql = N'
    BULK INSERT #TempBaseCSV
    FROM ''' + @path + '''
    WITH
    (
        FIELDTERMINATOR = '','',
        ROWTERMINATOR = ''0x0a'', --Es lo mismo que \n, pero no sé por qué no funcionaba
        CODEPAGE = ''65001'',
        FIRSTROW = 2,
        FIELDQUOTE = ''"'',
        FORMAT = ''CSV''
    );';

    EXEC sp_executesql @sql;
    
    DELETE FROM Administracion.Parque;
    DBCC CHECKIDENT ('Administracion.Parque', RESEED, 0);
    DELETE FROM Administracion.TipoParque;
    DBCC CHECKIDENT ('Administracion.TipoParque', RESEED, 0);

    INSERT INTO Administracion.TipoParque(Descripcion)
    SELECT DISTINCT Tipo 
    FROM #TempBaseCSV WHERE Tipo LIKE '%Parque Nacional%' 
    COLLATE Modern_Spanish_CI_AI;


    INSERT INTO Administracion.Parque (Nombre, Ubicacion, Superficie, Descripcion, IdTipoParque)
    SELECT
        Nombre,
        Nombre,
        AreaReportada,
        PlanGestion,
        TP.IdTipoParque
    FROM #TempBaseCSV t
    INNER JOIN Administracion.TipoParque TP on TP.Descripcion = t.Tipo;

END

EXEC ImportarArchivoParqueCSV
'C:\Users\iviez\Documents\BDDA\TP\ParquesNacionales\0. Entradas\0. Parques.csv'


SELECT * FROM Administracion.Parque