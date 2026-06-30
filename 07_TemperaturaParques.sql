
/*
# Universidad: Universidad Nacional de La Matanza
# Materia: 3641 - Bases de Datos Aplicada
# Grupo: Grupo 4
# Integrantes:
- Belloni, Nicolas
- Bernardo, Ivan
- Gonzalez, Agustin
- Gallo, Valentina

# Fecha: 26/06/2026

# Objetivo:
    Conexion con APIS para mostrar temperatura del parque (OpenMeteo).
*/

USE ParquesNacionalesDB;
GO

CREATE OR ALTER PROCEDURE Administracion.UbicacionTemperatura
    @Localidad VARCHAR(100),
    @Temp DECIMAL(4,2) OUT
AS
BEGIN
    SET NOCOUNT ON;

    -- Variables para la API de Geocodificación
    DECLARE @URL_Geo VARCHAR(1024);
    DECLARE @Response_Geo VARCHAR(1024);
    DECLARE @Latitud VARCHAR(20);
    DECLARE @Longitud VARCHAR(20);
    DECLARE @NombreEncontrado VARCHAR(100);

    -- Variables para la API de Clima
    DECLARE @URL_Clima VARCHAR(1024);
    DECLARE @Response_Clima VARCHAR(1024);

    -- Variables de control OLE
    CREATE TABLE #ResponseTable 
    (
        JsonData VARCHAR(1024)
    );
    DECLARE @Objeto INT;
    DECLARE @Respuesta INT;

    -- Para la URL
    DECLARE @LocalidadFormateada VARCHAR(100) = REPLACE(TRIM(@Localidad), ' ', '+');

    -- Consulta coordenadas a la API de geocodificacion
    SET @URL_Geo = CONCAT('https://geocoding-api.open-meteo.com/v1/search?name=', @LocalidadFormateada, '&count=1&language=es&format=json');

    EXEC @Respuesta = sp_OACreate 'MSXML2.ServerXMLHTTP', @Objeto OUT;
    IF @Respuesta <> 0 BEGIN RAISERROR('Error al crear el objeto HTTP.', 16, 1); RETURN; END

    EXEC @Respuesta = sp_OAMethod @Objeto, 'open', NULL, 'GET', @URL_Geo, 'false';
    EXEC @Respuesta = sp_OAMethod @Objeto, 'send';

    INSERT INTO #ResponseTable (JsonData) 
    EXEC sp_OAGetProperty @Objeto, 'responseText';
    
    SELECT @Response_Geo = JsonData FROM #ResponseTable;
    EXEC sp_OADestroy @Objeto;

    -- Validar respuesta de geocodificación
    IF @Response_Geo IS NULL OR ISJSON(@Response_Geo) = 0
    BEGIN
        RAISERROR('Error en el servicio de geocodificación.', 16, 1);
        RETURN;
    END

    -- Extraer coordenadas del primer elemento del array "results"
    SELECT 
        @Latitud = JSON_VALUE(@Response_Geo, '$.results[0].latitude'),
        @Longitud = JSON_VALUE(@Response_Geo, '$.results[0].longitude'),
        @NombreEncontrado = JSON_VALUE(@Response_Geo, '$.results[0].name');

    IF @Latitud IS NULL OR @Longitud IS NULL
    BEGIN
        RAISERROR('No se encontraron coordenadas para la localidad especificada.', 16, 1);
        RETURN;
    END

    -- PASO 2: Consultar la temperatura con las coordenadas obtenidas
    DELETE FROM #ResponseTable;
    SET @URL_Clima = CONCAT('https://api.open-meteo.com/v1/forecast?latitude=', @Latitud, '&longitude=', @Longitud, '&current=temperature_2m');

    EXEC @Respuesta = sp_OACreate 'MSXML2.ServerXMLHTTP', @Objeto OUT;
    EXEC @Respuesta = sp_OAMethod @Objeto, 'open', NULL, 'GET', @URL_Clima, 'false';
    EXEC @Respuesta = sp_OAMethod @Objeto, 'send';

    INSERT INTO #ResponseTable (JsonData) EXEC sp_OAGetProperty @Objeto, 'responseText';
    SELECT @Response_Clima = JsonData FROM #ResponseTable;
    EXEC sp_OADestroy @Objeto; -- Liberamos memoria de la segunda petición

    -- PASO 3: Procesar y retornar los resultados combinados
    SET @Temp =  TRY_CAST(JSON_VALUE(@Response_Clima, '$.current.temperature_2m') AS DECIMAL(4,2));
END
GO

CREATE OR ALTER PROCEDURE Administracion.MostrarTemperaturaParque
@NombreParque VARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;

    -- 1. Crear tabla temporal para almacenar el reporte final
    CREATE TABLE #ReporteClima (
        -- Asumo que tu tabla tiene una columna Nombre o ID. Si se llama distinto, cambialo acá.
        NombreParque VARCHAR(100), 
        Ubicacion VARCHAR(100),
        Temperatura DECIMAL(4,1)
    );

    -- Variables para leer los datos fila por fila
    DECLARE @NombreActual VARCHAR(100);
    DECLARE @UbicacionActual VARCHAR(100);
    DECLARE @TemperaturaObtenida DECIMAL(4,1);

    -- 2. Declarar el Cursor: Esto es como una lista de tareas que el SP va a recorrer
    DECLARE CursorParques CURSOR FOR
    SELECT TOP(10)
        Nombre, -- Cambiá esto por el nombre de la columna que identifica a tu parque
        Ubicacion
    FROM Administracion.Parque
    WHERE @NombreParque = Nombre
    GROUP BY Nombre,Ubicacion; -- Evitamos procesar filas vacías

    -- 3. Abrir el cursor y leer la primera fila
    OPEN CursorParques;
    FETCH NEXT FROM CursorParques INTO @NombreActual, @UbicacionActual;

    -- 4. Bucle principal: se ejecuta mientras sigan quedando filas por leer
    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Limpiamos la variable de temperatura antes de cada intento por seguridad
        SET @TemperaturaObtenida = NULL; 

        -- Llamamos a tu SP dinámico. Usamos TRY/CATCH por si alguna API falla, 
        -- así no se corta el proceso de los demás parques.
        BEGIN TRY
            EXEC Administracion.UbicacionTemperatura 
                @Localidad = @UbicacionActual, 
                @Temp = @TemperaturaObtenida OUTPUT;
        END TRY
        BEGIN CATCH
            -- Si ocurre un error (ej. la localidad no existe), dejamos que siga, pero insertará NULL
            PRINT 'Error obteniendo clima para: ' + ISNULL(@UbicacionActual, 'Desconocida');
        END CATCH

        -- Insertamos el resultado de esta vuelta en nuestra tabla temporal
        INSERT INTO #ReporteClima (NombreParque, Ubicacion, Temperatura)
        VALUES (@NombreActual, @UbicacionActual, @TemperaturaObtenida);

        -- Pasamos a la siguiente fila de la tabla
        FETCH NEXT FROM CursorParques INTO @NombreActual, @UbicacionActual;
    END;

    -- 5. Cerrar y liberar el cursor de la memoria
    CLOSE CursorParques;
    DEALLOCATE CursorParques;

    -- 6. Mostrar el resultado final a modo de grilla (como un SELECT normal)
    SELECT 
        NombreParque, 
        Ubicacion, 
        Temperatura AS Temperatura_Celsius 
    FROM #ReporteClima;

    -- 7. Limpiar la tabla temporal
    DROP TABLE #ReporteClima;
END;
GO

--API wikipedia

USE ParquesNacionalesDB;
GO

CREATE OR ALTER PROCEDURE Administracion.ObtenerDescripcionWikipedia
(
    @NombreParque VARCHAR(100),
    @Descripcion NVARCHAR(MAX) OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @URL NVARCHAR(1000);
    DECLARE @Response NVARCHAR(MAX);

    CREATE TABLE #Response
    (
        JsonData NVARCHAR(MAX)
    );

    DECLARE @Objeto INT;
    DECLARE @Respuesta INT;

    -- Adaptar el nombre para la URL
    DECLARE @Busqueda NVARCHAR(200);

    SET @Busqueda = TRIM(@NombreParque);

    -- Quitamos " - "
    SET @Busqueda = REPLACE(@Busqueda, ' - ', ' ');

    -- Reemplazamos espacios por _
    SET @Busqueda = REPLACE(@Busqueda, ' ', '_');

    SET @URL =
        'https://es.wikipedia.org/api/rest_v1/page/summary/' +
        @Busqueda;

    EXEC @Respuesta = sp_OACreate 'MSXML2.ServerXMLHTTP', @Objeto OUT;

    IF @Respuesta <> 0
    BEGIN
        RAISERROR('No se pudo crear el objeto HTTP.',16,1);
        RETURN;
    END

    EXEC sp_OAMethod @Objeto,
        'open',
        NULL,
        'GET',
        @URL,
        'false';

    EXEC sp_OAMethod @Objeto,'send';

    INSERT INTO #Response
    EXEC sp_OAGetProperty @Objeto,'responseText';

    SELECT @Response = JsonData
    FROM #Response;

    EXEC sp_OADestroy @Objeto;

    IF ISJSON(@Response)=0
    BEGIN
        RAISERROR('La respuesta de Wikipedia no es válida.',16,1);
        RETURN;
    END

    SET @Descripcion =
        JSON_VALUE(@Response,'$.extract');

    DROP TABLE #Response;

END
GO

--Procedimiento para ver la descripcion, para que este relacionado al parque

CREATE OR ALTER PROCEDURE Administracion.VerDescripcionParqueAPI
(
    @IdParque INT
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Ubicacion VARCHAR(100);
    DECLARE @Descripcion NVARCHAR(1024);

    SELECT @Ubicacion = Ubicacion
    FROM Administracion.Parque
    WHERE IdParque = @IdParque;

    IF @Ubicacion IS NULL
    BEGIN
        RAISERROR('El parque no existe.',16,1);
        RETURN;
    END

    EXEC Administracion.ObtenerDescripcionWikipedia
        @NombreParque = @Ubicacion,
        @Descripcion = @Descripcion OUTPUT;

    SELECT
        @Ubicacion AS Ubicacion,
        @Descripcion AS Descripcion;
END
GO

EXEC Administracion.VerDescripcionParqueAPI
    @IdParque = 2;
