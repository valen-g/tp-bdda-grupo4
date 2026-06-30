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

# Fecha: 05/06/2026
--------------------------------------------------------------------------------
    Script          : 03_StoredProcedures_ABM.sql
    Objetivo        : Crear los Stored Procedures de Alta, Baja, Modificación
                       y Listado (ABM) para cada tabla del sistema.
================================================================================
*/

USE ParquesNacionalesDB;
GO

-- ============================================================================
-- TABLA: Administracion.TipoParque
-- ============================================================================

-- ----------------------------------------------------------------------------
-- TipoParque_Insertar
-- ----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE Administracion.TipoParque_Insertar
(
    @Descripcion VARCHAR(100),
    @IdTipoParque INT OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (SELECT 1 FROM Administracion.TipoParque WHERE Descripcion = @Descripcion)
    BEGIN
        RAISERROR('Ya existe un tipo de parque con esa descripción.', 16, 1);
        RETURN;
    END

    INSERT INTO Administracion.TipoParque (Descripcion)
    VALUES (@Descripcion);

    SET @IdTipoParque = SCOPE_IDENTITY();
END
GO

-- ----------------------------------------------------------------------------
-- TipoParque_Actualizar
-- ----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE Administracion.TipoParque_Actualizar
(
    @IdTipoParque INT,
    @Descripcion VARCHAR(100)
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Errores VARCHAR(255) = '';

    IF NOT EXISTS (SELECT 1 FROM Administracion.TipoParque WHERE IdTipoParque = @IdTipoParque)
        SET @Errores += 'No existe un tipo de parque con el Id indicado. ';

    IF EXISTS (SELECT 1 FROM Administracion.TipoParque WHERE Descripcion = @Descripcion AND IdTipoParque <> @IdTipoParque)
        SET @Errores += 'Ya existe otro tipo de parque con esa descripción. ';

    IF @Errores <> ''
    BEGIN
        RAISERROR(@Errores, 16, 1);
        RETURN;
    END

    UPDATE Administracion.TipoParque
    SET Descripcion = @Descripcion
    WHERE IdTipoParque = @IdTipoParque;
END
GO

-- ----------------------------------------------------------------------------
-- TipoParque_Eliminar
-- ----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE Administracion.TipoParque_Eliminar
(
    @IdTipoParque INT
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Errores VARCHAR(255) = '';

    IF NOT EXISTS (SELECT 1 FROM Administracion.TipoParque WHERE IdTipoParque = @IdTipoParque)
        SET @Errores += 'No existe un tipo de parque con el Id indicado. ';

    IF EXISTS (SELECT 1 FROM Administracion.Parque WHERE IdTipoParque = @IdTipoParque)
        SET @Errores += 'No se puede eliminar: existen parques que utilizan este tipo de parque. ';

    IF @Errores <> ''
    BEGIN
        RAISERROR(@Errores, 16, 1);
        RETURN;
    END

    DELETE FROM Administracion.TipoParque
    WHERE IdTipoParque = @IdTipoParque;
END
GO

-- ----------------------------------------------------------------------------
-- TipoParque_Listar
-- ----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE Administracion.TipoParque_Listar
(
    @IdTipoParque INT = NULL
)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT IdTipoParque, Descripcion
    FROM Administracion.TipoParque
    WHERE (@IdTipoParque IS NULL OR IdTipoParque = @IdTipoParque)
    ORDER BY Descripcion;
END
GO

-- ============================================================================
-- TABLA: Administracion.Parque
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Parque_Insertar
-- ----------------------------------------------------------------------------

CREATE OR ALTER PROCEDURE Administracion.Parque_Insertar
(
    @Nombre VARCHAR(100),
    @Ubicacion VARCHAR(200),
    @Superficie DECIMAL(12,2),
    @Descripcion VARCHAR(100) = NULL,
    @IdTipoParque INT OUTPUT = NULL,
    @EsActivo BIT = 1
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Errores VARCHAR(128) = '';

    IF @Nombre IS NULL OR LTRIM(RTRIM(@Nombre)) = ''
        SET @Errores += 'El nombre del parque es obligatorio. ';

    IF @Ubicacion IS NULL OR LTRIM(RTRIM(@Ubicacion)) = ''
        SET @Errores += 'La ubicación del parque es obligatoria. ';

    IF @Superficie IS NULL OR @Superficie < 0
        SET @Errores += 'La superficie debe ser un valor mayor a 0. ';

    IF @IdTipoParque IS NOT NULL AND NOT EXISTS (SELECT 1 FROM Administracion.TipoParque WHERE IdTipoParque = @IdTipoParque)
        SET @Errores += 'El tipo de parque indicado no existe. ';

    IF EXISTS (SELECT 1 FROM Administracion.Parque p WHERE @Nombre = p.nombre AND p.EsActivo = 1)
        SET @Errores += 'Ya existe parque con ese nombre. ';

    IF @Errores <> ''
    BEGIN
        RAISERROR(@Errores, 16, 1);
        RETURN;
    END

    INSERT INTO Administracion.Parque (Nombre, Ubicacion, Superficie, Descripcion, IdTipoParque, EsActivo)
    VALUES (@Nombre, @Ubicacion, @Superficie, @Descripcion, @IdTipoParque, @EsActivo);

END
GO

-- ----------------------------------------------------------------------------
-- Parque_Actualizar
-- ----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE Administracion.Parque_Actualizar
(
    @IdParque INT,
    @Nombre VARCHAR(100),
    @Ubicacion VARCHAR(200),
    @Superficie INT,
    @Descripcion VARCHAR(100) = NULL,
    @IdTipoParque INT = NULL,
    @EsActivo BIT = 1
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Errores VARCHAR(255) = '';

    IF NOT EXISTS (SELECT 1 FROM Administracion.Parque WHERE IdParque = @IdParque)
        SET @Errores += 'No existe un parque con el Id indicado. ';

    IF @Nombre IS NULL OR LTRIM(RTRIM(@Nombre)) = ''
        SET @Errores += 'El nombre del parque es obligatorio. ';

    IF @Ubicacion IS NULL OR LTRIM(RTRIM(@Ubicacion)) = ''
        SET @Errores += 'La ubicación del parque es obligatoria. ';

    IF @Superficie IS NULL OR @Superficie < 0
        SET @Errores += 'La superficie debe ser un valor mayor a 0. ';

    IF @IdTipoParque IS NOT NULL AND NOT EXISTS (SELECT 1 FROM Administracion.TipoParque WHERE IdTipoParque = @IdTipoParque)
        SET @Errores += 'El tipo de parque indicado no existe. ';

    IF @Errores <> ''
    BEGIN
        RAISERROR(@Errores, 16, 1);
        RETURN;
    END

    UPDATE Administracion.Parque
    SET Nombre = @Nombre,
        Ubicacion = @Ubicacion,
        Superficie = @Superficie,
        Descripcion = @Descripcion,
        IdTipoParque = @IdTipoParque,
        EsActivo = @EsActivo
    WHERE IdParque = @IdParque;
END
GO

-- ----------------------------------------------------------------------------
-- Parque_Eliminar
-- ----------------------------------------------------------------------------
-- BAJA LOGICA
CREATE OR ALTER PROCEDURE Administracion.Parque_Eliminar
(
    @IdParque INT
)
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM Administracion.Parque WHERE IdParque = @IdParque)
    BEGIN
        RAISERROR('No existe un parque con el Id indicado.', 16, 1);
        RETURN;
    END

    UPDATE Administracion.Parque
    SET EsActivo = 0
    WHERE IdParque = @IdParque;
END
GO

-- ----------------------------------------------------------------------------
-- Parque_Listar
-- ----------------------------------------------------------------------------

CREATE OR ALTER PROCEDURE Administracion.Parque_Listar
(
    @IdParque INT = NULL,
    @IdTipoParque INT = NULL,
    @SoloActivos BIT = NULL
)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT p.IdParque, p.Nombre, p.Ubicacion, p.Superficie, p.Descripcion,
           p.IdTipoParque, tp.Descripcion AS TipoParque, p.EsActivo
    FROM Administracion.Parque p
    LEFT JOIN Administracion.TipoParque tp ON tp.IdTipoParque = p.IdTipoParque
    WHERE (@IdParque IS NULL OR p.IdParque = @IdParque)
      AND (@IdTipoParque IS NULL OR p.IdTipoParque = @IdTipoParque)
      AND (@SoloActivos IS NULL OR p.EsActivo = @SoloActivos)
    ORDER BY p.Nombre;
END
GO

-- ----------------------------------------------------------------------------
-- Parque_Listar_App
-- ----------------------------------------------------------------------------

CREATE OR ALTER PROCEDURE Administracion.Parque_ListarApp
(
    @Nombre VARCHAR(100) = NULL,
    @IdParque INT = NULL
)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        p.IdParque,
        p.Nombre,
        p.Ubicacion,
        p.Superficie,
        p.Descripcion,
        p.IdTipoParque,
        tp.Descripcion AS TipoParque,
        p.EsActivo
    FROM Administracion.Parque p
    LEFT JOIN Administracion.TipoParque tp
        ON tp.IdTipoParque = p.IdTipoParque
    WHERE p.EsActivo = 1
      AND (@IdParque IS NULL OR p.IdParque = @IdParque)
      AND (@Nombre IS NULL OR p.Nombre COLLATE Latin1_General_CI_AI
                              LIKE '%' + @Nombre + '%' COLLATE Latin1_General_CI_AI)
    ORDER BY p.Nombre;
END
GO



-- ============================================================================
-- TABLA: Administracion.AsignacionParque
-- ============================================================================

-- ----------------------------------------------------------------------------
-- AsignacionParque_Insertar
-- ----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE Administracion.AsignacionParque_Insertar
(
    @IdParque INT,
    @FechaIngreso DATE = NULL,
    @FechaEgreso DATE = NULL,
    @MotivoEgreso VARCHAR(100) = NULL,
    @IdAsignacion INT OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Errores VARCHAR(255) = '';

    IF NOT EXISTS (SELECT 1 FROM Administracion.Parque WHERE IdParque = @IdParque)
        SET @Errores += 'El parque indicado no existe. ';

    IF @FechaEgreso IS NOT NULL AND @FechaIngreso IS NOT NULL AND @FechaEgreso < @FechaIngreso
        SET @Errores += 'La fecha de egreso no puede ser anterior a la fecha de ingreso. ';

    IF @Errores <> ''
    BEGIN
        RAISERROR(@Errores, 16, 1);
        RETURN;
    END

    INSERT INTO Administracion.AsignacionParque (IdParque, FechaIngreso, FechaEgreso, MotivoEgreso)
    VALUES (@IdParque, ISNULL(@FechaIngreso, GETDATE()), @FechaEgreso, @MotivoEgreso);

    SET @IdAsignacion = SCOPE_IDENTITY();
END
GO

-- ----------------------------------------------------------------------------
-- AsignacionParque_Actualizar
-- ----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE Administracion.AsignacionParque_Actualizar
(
    @IdAsignacion INT,
    @IdParque INT,
    @FechaIngreso DATE,
    @FechaEgreso DATE = NULL,
    @MotivoEgreso VARCHAR(100) = NULL
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Errores VARCHAR(255) = '';

    IF NOT EXISTS (SELECT 1 FROM Administracion.AsignacionParque WHERE IdAsignacion = @IdAsignacion)
        SET @Errores += 'No existe una asignación con el Id indicado. ';

    IF NOT EXISTS (SELECT 1 FROM Administracion.Parque WHERE IdParque = @IdParque)
        SET @Errores += 'El parque indicado no existe. ';

    IF @FechaEgreso IS NOT NULL AND @FechaEgreso < @FechaIngreso
        SET @Errores += 'La fecha de egreso no puede ser anterior a la fecha de ingreso. ';

    IF @Errores <> ''
    BEGIN
        RAISERROR(@Errores, 16, 1);
        RETURN;
    END

    UPDATE Administracion.AsignacionParque
    SET IdParque = @IdParque,
        FechaIngreso = @FechaIngreso,
        FechaEgreso = @FechaEgreso,
        MotivoEgreso = @MotivoEgreso
    WHERE IdAsignacion = @IdAsignacion;
END
GO

-- ----------------------------------------------------------------------------
-- AsignacionParque_Eliminar
-- ----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE Administracion.AsignacionParque_Eliminar
(
    @IdAsignacion INT
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Errores VARCHAR(255) = '';

    IF NOT EXISTS (SELECT 1 FROM Administracion.AsignacionParque WHERE IdAsignacion = @IdAsignacion)
        SET @Errores += 'No existe una asignación con el Id indicado. ';

    IF EXISTS (SELECT 1 FROM Administracion.Personal WHERE IdAsignacion = @IdAsignacion)
        SET @Errores += 'No se puede eliminar: existe personal vinculado a esta asignación. ';

    IF @Errores <> ''
    BEGIN
        RAISERROR(@Errores, 16, 1);
        RETURN;
    END

    DELETE FROM Administracion.AsignacionParque
    WHERE IdAsignacion = @IdAsignacion;
END
GO

-- ----------------------------------------------------------------------------
-- AsignacionParque_Listar
-- ----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE Administracion.AsignacionParque_Listar
(
    @IdAsignacion INT = NULL,
    @IdParque INT = NULL
)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT a.IdAsignacion, a.IdParque, p.Nombre AS NombreParque,
           a.FechaIngreso, a.FechaEgreso, a.MotivoEgreso
    FROM Administracion.AsignacionParque a
    INNER JOIN Administracion.Parque p ON p.IdParque = a.IdParque
    WHERE (@IdAsignacion IS NULL OR a.IdAsignacion = @IdAsignacion)
      AND (@IdParque IS NULL OR a.IdParque = @IdParque)
    ORDER BY a.FechaIngreso DESC;
END
GO


-- ============================================================================
-- TABLA: Administracion.Habilitacion
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Habilitacion_Insertar
-- ----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE Administracion.Habilitacion_Insertar
(
    @Descripcion VARCHAR(100),
    @FechaOtorgamiento DATE,
    @FechaVencimiento DATE,
    @IdHabilitacion INT OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Errores VARCHAR(255) = '';

    IF @Descripcion IS NULL OR LTRIM(RTRIM(@Descripcion)) = ''
        SET @Errores += 'La descripción de la habilitación es obligatoria. ';

    IF @FechaOtorgamiento IS NULL
        SET @Errores += 'La fecha de otorgamiento es obligatoria. ';

    IF @FechaVencimiento IS NULL
        SET @Errores += 'La fecha de vencimiento es obligatoria. ';

    IF @FechaOtorgamiento IS NOT NULL AND @FechaVencimiento IS NOT NULL AND @FechaVencimiento <= @FechaOtorgamiento
        SET @Errores += 'La fecha de vencimiento debe ser posterior a la fecha de otorgamiento. ';

    IF @Errores <> ''
    BEGIN
        RAISERROR(@Errores, 16, 1);
        RETURN;
    END

    INSERT INTO Administracion.Habilitacion (Descripcion, FechaOtorgamiento, FechaVencimiento)
    VALUES (@Descripcion, @FechaOtorgamiento, @FechaVencimiento);

    SET @IdHabilitacion = SCOPE_IDENTITY();
END
GO

-- ----------------------------------------------------------------------------
-- Habilitacion_Actualizar
-- ----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE Administracion.Habilitacion_Actualizar
(
    @IdHabilitacion INT,
    @Descripcion VARCHAR(100),
    @FechaOtorgamiento DATE,
    @FechaVencimiento DATE
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Errores VARCHAR(255) = '';

    IF NOT EXISTS (SELECT 1 FROM Administracion.Habilitacion WHERE IdHabilitacion = @IdHabilitacion)
        SET @Errores += 'No existe una habilitación con el Id indicado. ';

    IF @Descripcion IS NULL OR LTRIM(RTRIM(@Descripcion)) = ''
        SET @Errores += 'La descripción de la habilitación es obligatoria. ';

    IF @FechaVencimiento <= @FechaOtorgamiento
        SET @Errores += 'La fecha de vencimiento debe ser posterior a la fecha de otorgamiento. ';

    IF @Errores <> ''
    BEGIN
        RAISERROR(@Errores, 16, 1);
        RETURN;
    END

    UPDATE Administracion.Habilitacion
    SET Descripcion = @Descripcion,
        FechaOtorgamiento = @FechaOtorgamiento,
        FechaVencimiento = @FechaVencimiento
    WHERE IdHabilitacion = @IdHabilitacion;
END
GO

-- ----------------------------------------------------------------------------
-- Habilitacion_Eliminar
-- ----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE Administracion.Habilitacion_Eliminar
(
    @IdHabilitacion INT
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Errores VARCHAR(255) = '';

    IF NOT EXISTS (SELECT 1 FROM Administracion.Habilitacion WHERE IdHabilitacion = @IdHabilitacion)
        SET @Errores += 'No existe una habilitación con el Id indicado. ';

    IF EXISTS (SELECT 1 FROM Administracion.Personal WHERE IdHabilitacion = @IdHabilitacion)
        SET @Errores += 'No se puede eliminar: existe personal vinculado a esta habilitación. ';

    IF @Errores <> ''
    BEGIN
        RAISERROR(@Errores, 16, 1);
        RETURN;
    END

    DELETE FROM Administracion.Habilitacion
    WHERE IdHabilitacion = @IdHabilitacion;
END
GO

-- ----------------------------------------------------------------------------
-- Habilitacion_Listar
-- ----------------------------------------------------------------------------

CREATE OR ALTER PROCEDURE Administracion.Habilitacion_Listar
(
    @IdHabilitacion INT = NULL
)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT IdHabilitacion, Descripcion, FechaOtorgamiento, FechaVencimiento
    FROM Administracion.Habilitacion
    WHERE (@IdHabilitacion IS NULL OR IdHabilitacion = @IdHabilitacion)
    ORDER BY FechaVencimiento;
END
GO

-- ============================================================================
-- TABLA: Administracion.Personal
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Personal_Insertar
-- ----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE Administracion.Personal_Insertar
(
    @NombreApellido VARCHAR(128),
    @DNI INT,
    @FechaNacimiento DATE = NULL,
    @Email VARCHAR(50) = NULL,
    @Telefono BIGINT = NULL,
    @TipoPersonal VARCHAR(20),
    @EsActivo BIT = 1,
    @IdHabilitacion INT = NULL,
    @IdAsignacion INT = NULL
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Errores VARCHAR(255) = '';

    IF @DNI IS NULL
        SET @Errores += 'El DNI es obligatorio. ';
    ELSE IF EXISTS
    (
        SELECT 1
        FROM Administracion.Personal
        WHERE DNI = @DNI
    )
        SET @Errores += 'Ya existe una persona registrada con ese DNI. ';

    IF @NombreApellido IS NULL OR TRIM(@NombreApellido) = ''
        SET @Errores += 'El nombre y apellido son obligatorios. ';

    IF @TipoPersonal IS NULL OR TRIM(@TipoPersonal) = ''
        SET @Errores += 'El tipo de personal es obligatorio. ';

    IF @IdHabilitacion IS NOT NULL
       AND NOT EXISTS
       (
           SELECT 1
           FROM Administracion.Habilitacion
           WHERE IdHabilitacion = @IdHabilitacion
       )
        SET @Errores += 'La habilitación indicada no existe. ';

    IF @IdAsignacion IS NOT NULL
       AND NOT EXISTS
       (
           SELECT 1
           FROM Administracion.AsignacionParque
           WHERE IdAsignacion = @IdAsignacion
       )
        SET @Errores += 'La asignación indicada no existe. ';

    IF @Errores <> ''
    BEGIN
        RAISERROR(@Errores, 16, 1);
        RETURN;
    END

    INSERT INTO Administracion.Personal
    (
        NombreApellido,
        DNI,
        FechaNacimiento,
        Email,
        Telefono,
        TipoPersonal,
        EsActivo,
        IdHabilitacion,
        IdAsignacion
    )
    VALUES
    (
        @NombreApellido,
        @DNI,
        @FechaNacimiento,
        @Email,
        @Telefono,
        @TipoPersonal,
        @EsActivo,
        @IdHabilitacion,
        @IdAsignacion
    );
END
GO

-- ----------------------------------------------------------------------------
-- Personal_Actualizar
-- ----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE Administracion.Personal_Actualizar
(
    @DNI INT,
    @NombreApellido VARCHAR(128),
    @FechaNacimiento DATE = NULL,
    @Email VARCHAR(50) = NULL,
    @Telefono BIGINT = NULL,
    @TipoPersonal VARCHAR(20),
    @EsActivo BIT,
    @IdHabilitacion INT = NULL,
    @IdAsignacion INT = NULL
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Errores VARCHAR(255) = '';

    IF NOT EXISTS
    (
        SELECT 1
        FROM Administracion.Personal
        WHERE DNI = @DNI
    )
        SET @Errores += 'No existe personal registrado con ese DNI. ';

    IF @NombreApellido IS NULL OR TRIM(@NombreApellido) = ''
        SET @Errores += 'El nombre y apellido son obligatorios. ';

    IF @TipoPersonal IS NULL OR TRIM(@TipoPersonal) = ''
        SET @Errores += 'El tipo de personal es obligatorio. ';

    IF @IdHabilitacion IS NOT NULL
       AND NOT EXISTS
       (
           SELECT 1
           FROM Administracion.Habilitacion
           WHERE IdHabilitacion = @IdHabilitacion
       )
        SET @Errores += 'La habilitación indicada no existe. ';

    IF @IdAsignacion IS NOT NULL
       AND NOT EXISTS
       (
           SELECT 1
           FROM Administracion.AsignacionParque
           WHERE IdAsignacion = @IdAsignacion
       )
        SET @Errores += 'La asignación de parque indicada no existe. ';

    IF @Errores <> ''
    BEGIN
        RAISERROR(@Errores, 16, 1);
        RETURN;
    END

    UPDATE Administracion.Personal
    SET
        NombreApellido = @NombreApellido,
        FechaNacimiento = @FechaNacimiento,
        Email = @Email,
        Telefono = @Telefono,
        TipoPersonal = @TipoPersonal,
        EsActivo = @EsActivo,
        IdHabilitacion = @IdHabilitacion,
        IdAsignacion = @IdAsignacion
    WHERE DNI = @DNI;
END
GO

-- ----------------------------------------------------------------------------
-- Personal_Eliminar
-- ----------------------------------------------------------------------------
-- BAJA LOGICA
CREATE OR ALTER PROCEDURE Administracion.Personal_Eliminar
(
    @DNI INT
)
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM Administracion.Personal WHERE DNI = @DNI)
    BEGIN
        RAISERROR('No existe personal registrado con ese DNI.', 16, 1);
        RETURN;
    END

    UPDATE Administracion.Personal
    SET EsActivo = 0
    WHERE DNI = @DNI;
END
GO

-- ----------------------------------------------------------------------------
-- Personal_Listar
-- ----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE Administracion.Personal_Listar
(
    @DNI INT = NULL,
    @TipoPersonal VARCHAR(20) = NULL,
    @SoloActivos BIT = NULL
)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT pe.DNI, pe.NombreApellido, pe.FechaNacimiento, pe.Email, pe.Telefono,
           pe.TipoPersonal, pe.EsActivo,
           pe.IdHabilitacion, h.Descripcion AS Habilitacion, h.FechaVencimiento AS HabilitacionVencimiento,
           pe.IdAsignacion, ap.IdParque, pq.Nombre AS ParqueAsignado
    FROM Administracion.Personal pe
    LEFT JOIN Administracion.Habilitacion h ON h.IdHabilitacion = pe.IdHabilitacion
    LEFT JOIN Administracion.AsignacionParque ap ON ap.IdAsignacion = pe.IdAsignacion
    LEFT JOIN Administracion.Parque pq ON pq.IdParque = ap.IdParque
    WHERE (@DNI IS NULL OR pe.DNI = @DNI)
      AND (@TipoPersonal IS NULL OR pe.TipoPersonal = @TipoPersonal)
      AND (@SoloActivos IS NULL OR pe.EsActivo = @SoloActivos)
    ORDER BY pe.NombreApellido;
END
GO

-- ============================================================================
-- TABLA: Administracion.Actividad
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Actividad_Insertar
-- ----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE Administracion.Actividad_Insertar
(
    @IdParque INT,
    @Nombre VARCHAR(150),
    @Tipo VARCHAR(50),
    @Descripcion VARCHAR(100) = NULL,
    @Costo DECIMAL(10,2),
    @DuracionMinutos INT,
    @CupoMaximo INT,
    @EsActivo BIT = 1,
    @IdActividad INT OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Errores VARCHAR(255) = '';

    IF @IdParque IS NULL OR NOT EXISTS (SELECT 1 FROM Administracion.Parque WHERE IdParque = @IdParque)
        SET @Errores += 'El parque indicado no existe. ';

    IF @Nombre IS NULL OR LTRIM(RTRIM(@Nombre)) = ''
        SET @Errores += 'El nombre de la actividad es obligatorio. ';

    IF @Tipo IS NULL OR LTRIM(RTRIM(@Tipo)) = ''
        SET @Errores += 'El tipo de actividad es obligatorio. ';

    IF @Costo IS NULL OR @Costo <= 0
        SET @Errores += 'El costo debe ser mayor a 0. ';

    IF @DuracionMinutos IS NULL OR @DuracionMinutos <= 0
        SET @Errores += 'La duración en minutos debe ser mayor a 0. ';

    IF @CupoMaximo IS NULL OR @CupoMaximo <= 0
        SET @Errores += 'El cupo máximo debe ser mayor a 0. ';

    IF @Errores <> ''
    BEGIN
        RAISERROR(@Errores, 16, 1);
        RETURN;
    END

    INSERT INTO Administracion.Actividad
        (IdParque, Nombre, Tipo, Descripcion, Costo, DuracionMinutos, CupoMaximo, EsActivo)
    VALUES
        (@IdParque, @Nombre, @Tipo, @Descripcion, @Costo, @DuracionMinutos, @CupoMaximo, @EsActivo);

    SET @IdActividad = SCOPE_IDENTITY();
END
GO

-- ----------------------------------------------------------------------------
-- Actividad_Actualizar
-- ----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE Administracion.Actividad_Actualizar
(
    @IdActividad INT,
    @IdParque INT,
    @Nombre VARCHAR(150),
    @Tipo VARCHAR(50),
    @Descripcion VARCHAR(100) = NULL,
    @Costo DECIMAL(10,2),
    @DuracionMinutos INT,
    @CupoMaximo INT,
    @EsActivo BIT
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Errores VARCHAR(255) = '';

    IF NOT EXISTS (SELECT 1 FROM Administracion.Actividad WHERE IdActividad = @IdActividad)
        SET @Errores += 'No existe una actividad con el Id indicado. ';

    IF NOT EXISTS (SELECT 1 FROM Administracion.Parque WHERE IdParque = @IdParque)
        SET @Errores += 'El parque indicado no existe. ';

    IF @Nombre IS NULL OR LTRIM(RTRIM(@Nombre)) = ''
        SET @Errores += 'El nombre de la actividad es obligatorio. ';

    IF @Costo IS NULL OR @Costo <= 0
        SET @Errores += 'El costo debe ser mayor a 0. ';

    IF @DuracionMinutos IS NULL OR @DuracionMinutos <= 0
        SET @Errores += 'La duración en minutos debe ser mayor a 0. ';

    IF @CupoMaximo IS NULL OR @CupoMaximo <= 0
        SET @Errores += 'El cupo máximo debe ser mayor a 0. ';

    IF @Errores <> ''
    BEGIN
        RAISERROR(@Errores, 16, 1);
        RETURN;
    END

    UPDATE Administracion.Actividad
    SET IdParque = @IdParque,
        Nombre = @Nombre,
        Tipo = @Tipo,
        Descripcion = @Descripcion,
        Costo = @Costo,
        DuracionMinutos = @DuracionMinutos,
        CupoMaximo = @CupoMaximo,
        EsActivo = @EsActivo
    WHERE IdActividad = @IdActividad;
END
GO

-- ----------------------------------------------------------------------------
-- Actividad_Eliminar
-- ----------------------------------------------------------------------------
-- BAJA LOGICA
CREATE OR ALTER PROCEDURE Administracion.Actividad_Eliminar
(
    @IdActividad INT
)
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM Administracion.Actividad WHERE IdActividad = @IdActividad)
    BEGIN
        RAISERROR('No existe una actividad con el Id indicado.', 16, 1);
        RETURN;
    END

    UPDATE Administracion.Actividad
    SET EsActivo = 0
    WHERE IdActividad = @IdActividad;
END
GO

-- ----------------------------------------------------------------------------
-- Actividad_Listar
-- ----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE Administracion.Actividad_Listar
(
    @IdActividad INT = NULL,
    @IdParque INT = NULL,
    @SoloActivas BIT = NULL
)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT a.IdActividad, a.IdParque, pq.Nombre AS NombreParque, a.Nombre, a.Tipo,
           a.Descripcion, a.Costo, a.DuracionMinutos, a.CupoMaximo, a.EsActivo
    FROM Administracion.Actividad a
    INNER JOIN Administracion.Parque pq ON pq.IdParque = a.IdParque
    WHERE (@IdActividad IS NULL OR a.IdActividad = @IdActividad)
      AND (@IdParque IS NULL OR a.IdParque = @IdParque)
      AND (@SoloActivas IS NULL OR a.EsActivo = @SoloActivas)
    ORDER BY a.Nombre;
END
GO


-- ============================================================================
-- TABLA: Administracion.ActividadGuia
-- ============================================================================

-- ---------------------------------------------------------------------------
-- ActividadGuia_Insertar
-- ----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE Administracion.ActividadGuia_Insertar
(
    @DniPersonal INT,
    @IdActividad INT,
    @FechaDesde DATE,
    @FechaHasta DATE = NULL
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Errores VARCHAR(255) = '';

    IF NOT EXISTS (SELECT 1 FROM Administracion.Personal WHERE DNI = @DniPersonal)
        SET @Errores += 'El DNI de personal indicado no existe. ';

    IF NOT EXISTS (SELECT 1 FROM Administracion.Actividad WHERE IdActividad = @IdActividad)
        SET @Errores += 'La actividad indicada no existe. ';

    IF EXISTS (SELECT 1 FROM Administracion.ActividadGuia WHERE DniPersonal = @DniPersonal AND IdActividad = @IdActividad)
        SET @Errores += 'Ya existe un registro de este guía para esta actividad. ';

    IF @FechaDesde IS NULL
        SET @Errores += 'La fecha desde es obligatoria. ';

    IF @FechaHasta IS NOT NULL AND @FechaDesde IS NOT NULL AND @FechaHasta < @FechaDesde
        SET @Errores += 'La fecha hasta no puede ser anterior a la fecha desde. ';

    IF @Errores <> ''
    BEGIN
        RAISERROR(@Errores, 16, 1);
        RETURN;
    END

    INSERT INTO Administracion.ActividadGuia (DniPersonal, IdActividad, FechaDesde, FechaHasta)
    VALUES (@DniPersonal, @IdActividad, @FechaDesde, @FechaHasta);
END
GO

-- ----------------------------------------------------------------------------
-- ActividadGuia_Actualizar
-- ----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE Administracion.ActividadGuia_Actualizar
(
    @DniPersonal INT,
    @IdActividad INT,
    @FechaDesde DATE,
    @FechaHasta DATE = NULL
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Errores VARCHAR(255) = '';

    IF NOT EXISTS (SELECT 1 FROM Administracion.ActividadGuia WHERE DniPersonal = @DniPersonal AND IdActividad = @IdActividad)
        SET @Errores += 'No existe un registro de este guía para esta actividad. ';

    IF @FechaDesde IS NULL
        SET @Errores += 'La fecha desde es obligatoria. ';

    IF @FechaHasta IS NOT NULL AND @FechaDesde IS NOT NULL AND @FechaHasta < @FechaDesde
        SET @Errores += 'La fecha hasta no puede ser anterior a la fecha desde. ';

    IF @Errores <> ''
    BEGIN
        RAISERROR(@Errores, 16, 1);
        RETURN;
    END

    UPDATE Administracion.ActividadGuia
    SET FechaDesde = @FechaDesde,
        FechaHasta = @FechaHasta
    WHERE DniPersonal = @DniPersonal AND IdActividad = @IdActividad;
END
GO

-- ----------------------------------------------------------------------------
-- ActividadGuia_Eliminar
-- ----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE Administracion.ActividadGuia_Eliminar
(
    @DniPersonal INT,
    @IdActividad INT
)
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM Administracion.ActividadGuia WHERE DniPersonal = @DniPersonal AND IdActividad = @IdActividad)
    BEGIN
        RAISERROR('No existe un registro de este guía para esta actividad.', 16, 1);
        RETURN;
    END

    DELETE FROM Administracion.ActividadGuia
    WHERE DniPersonal = @DniPersonal AND IdActividad = @IdActividad;
END
GO

-- ----------------------------------------------------------------------------
-- ActividadGuia_Listar
-- ----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE Administracion.ActividadGuia_Listar
(
    @DniPersonal INT = NULL,
    @IdActividad INT = NULL
)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT ag.DniPersonal, pe.NombreApellido, ag.IdActividad, ac.Nombre AS NombreActividad,
           ag.FechaDesde, ag.FechaHasta
    FROM Administracion.ActividadGuia ag
    INNER JOIN Administracion.Personal pe ON pe.DNI = ag.DniPersonal
    INNER JOIN Administracion.Actividad ac ON ac.IdActividad = ag.IdActividad
    WHERE (@DniPersonal IS NULL OR ag.DniPersonal = @DniPersonal)
      AND (@IdActividad IS NULL OR ag.IdActividad = @IdActividad)
    ORDER BY ag.FechaDesde DESC;
END
GO

-- ============================================================================
-- TABLA: Administracion.TipoVisitante
-- ============================================================================
-- ----------------------------------------------------------------------------
-- TipoVisitante_Insertar
-- ----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE Administracion.TipoVisitante_Insertar
(
    @Descripcion VARCHAR(100),
    @EsActivo BIT = 1,
    @IdTipoVisitante INT OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Errores VARCHAR(255) = '';

    IF @Descripcion IS NULL OR LTRIM(RTRIM(@Descripcion)) = ''
        SET @Errores += 'La descripción del tipo de visitante es obligatoria. ';
    ELSE IF EXISTS (SELECT 1 FROM Administracion.TipoVisitante WHERE Descripcion = @Descripcion)
        SET @Errores += 'Ya existe un tipo de visitante con esa descripción. ';

    IF @Errores <> ''
    BEGIN
        RAISERROR(@Errores, 16, 1);
        RETURN;
    END

    INSERT INTO Administracion.TipoVisitante (Descripcion, EsActivo)
    VALUES (@Descripcion, @EsActivo);

    SET @IdTipoVisitante = SCOPE_IDENTITY();
END
GO

-- ----------------------------------------------------------------------------
-- TipoVisitante_Actualizar
-- ----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE Administracion.TipoVisitante_Actualizar
(
    @IdTipoVisitante INT,
    @Descripcion VARCHAR(100),
    @EsActivo BIT
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Errores VARCHAR(255) = '';

    IF NOT EXISTS (SELECT 1 FROM Administracion.TipoVisitante WHERE IdTipoVisitante = @IdTipoVisitante)
        SET @Errores += 'No existe un tipo de visitante con el Id indicado. ';

    IF @Descripcion IS NULL OR LTRIM(RTRIM(@Descripcion)) = ''
        SET @Errores += 'La descripción del tipo de visitante es obligatoria. ';
    ELSE IF EXISTS (SELECT 1 FROM Administracion.TipoVisitante WHERE Descripcion = @Descripcion AND IdTipoVisitante <> @IdTipoVisitante)
        SET @Errores += 'Ya existe otro tipo de visitante con esa descripción. ';

    IF @Errores <> ''
    BEGIN
        RAISERROR(@Errores, 16, 1);
        RETURN;
    END

    UPDATE Administracion.TipoVisitante
    SET Descripcion = @Descripcion,
        EsActivo = @EsActivo
    WHERE IdTipoVisitante = @IdTipoVisitante;
END
GO

-- ----------------------------------------------------------------------------
-- TipoVisitante_Eliminar
-- ----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE Administracion.TipoVisitante_Eliminar
(
    @IdTipoVisitante INT
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Errores VARCHAR(255) = '';

    IF NOT EXISTS (SELECT 1 FROM Administracion.TipoVisitante WHERE IdTipoVisitante = @IdTipoVisitante)
        SET @Errores += 'No existe un tipo de visitante con el Id indicado. ';

    IF EXISTS (SELECT 1 FROM Facturacion.PrecioEntrada WHERE IdTipoVisitante = @IdTipoVisitante)
        SET @Errores += 'No se puede eliminar: existen precios de entrada vinculados a este tipo de visitante. ';

    IF EXISTS (SELECT 1 FROM Facturacion.TicketItemEntrada WHERE IdTipoVisitante = @IdTipoVisitante)
        SET @Errores += 'No se puede eliminar: existen ítems de entrada vendidos para este tipo de visitante. ';

    IF @Errores <> ''
    BEGIN
        RAISERROR(@Errores, 16, 1);
        RETURN;
    END

    DELETE FROM Administracion.TipoVisitante
    WHERE IdTipoVisitante = @IdTipoVisitante;
END
GO

-- ----------------------------------------------------------------------------
-- TipoVisitante_Listar
-- ----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE Administracion.TipoVisitante_Listar
(
    @IdTipoVisitante INT = NULL,
    @SoloActivos BIT = NULL
)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT IdTipoVisitante, Descripcion, EsActivo
    FROM Administracion.TipoVisitante
    WHERE (@IdTipoVisitante IS NULL OR IdTipoVisitante = @IdTipoVisitante)
      AND (@SoloActivos IS NULL OR EsActivo = @SoloActivos)
    ORDER BY Descripcion;
END
GO


-- ============================================================================
-- TABLA: Administracion.EmpresaConcesionaria
-- ============================================================================

-- ----------------------------------------------------------------------------
-- EmpresaConcesionaria_Insertar
-- ----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE Administracion.EmpresaConcesionaria_Insertar
(
    @CUIT INT,
    @RazonSocial VARCHAR(50),
    @Email VARCHAR(50) = NULL,
    @Telefono INT = NULL
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Errores VARCHAR(255) = '';

    IF @CUIT IS NULL
        SET @Errores += 'El CUIT es obligatorio. ';
    ELSE IF EXISTS (SELECT 1 FROM Administracion.EmpresaConcesionaria WHERE CUIT = @CUIT)
        SET @Errores += 'Ya existe una empresa registrada con ese CUIT. ';

    IF @RazonSocial IS NULL OR LTRIM(RTRIM(@RazonSocial)) = ''
        SET @Errores += 'La razón social es obligatoria. ';
    ELSE IF EXISTS (SELECT 1 FROM Administracion.EmpresaConcesionaria WHERE RazonSocial = @RazonSocial)
        SET @Errores += 'Ya existe una empresa registrada con esa razón social. ';

    IF @Errores <> ''
    BEGIN
        RAISERROR(@Errores, 16, 1);
        RETURN;
    END

    INSERT INTO Administracion.EmpresaConcesionaria (CUIT, RazonSocial, Email, Telefono)
    VALUES (@CUIT, @RazonSocial, @Email, @Telefono);
END
GO

-- ----------------------------------------------------------------------------
-- EmpresaConcesionaria_Actualizar
-- ----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE Administracion.EmpresaConcesionaria_Actualizar
(
    @CUIT INT,
    @RazonSocial VARCHAR(50),
    @Email VARCHAR(50) = NULL,
    @Telefono INT = NULL
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Errores VARCHAR(255) = '';

    IF NOT EXISTS (SELECT 1 FROM Administracion.EmpresaConcesionaria WHERE CUIT = @CUIT)
        SET @Errores += 'No existe una empresa registrada con ese CUIT. ';

    IF @RazonSocial IS NULL OR LTRIM(RTRIM(@RazonSocial)) = ''
        SET @Errores += 'La razón social es obligatoria. ';
    ELSE IF EXISTS (SELECT 1 FROM Administracion.EmpresaConcesionaria WHERE RazonSocial = @RazonSocial AND CUIT <> @CUIT)
        SET @Errores += 'Ya existe otra empresa registrada con esa razón social. ';

    IF @Errores <> ''
    BEGIN
        RAISERROR(@Errores, 16, 1);
        RETURN;
    END

    UPDATE Administracion.EmpresaConcesionaria
    SET RazonSocial = @RazonSocial,
        Email = @Email,
        Telefono = @Telefono
    WHERE CUIT = @CUIT;
END
GO

-- ----------------------------------------------------------------------------
-- EmpresaConcesionaria_Eliminar
-- ----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE Administracion.EmpresaConcesionaria_Eliminar
(
    @CUIT INT
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Errores VARCHAR(255) = '';

    IF NOT EXISTS (SELECT 1 FROM Administracion.EmpresaConcesionaria WHERE CUIT = @CUIT)
        SET @Errores += 'No existe una empresa registrada con ese CUIT. ';

    IF EXISTS (SELECT 1 FROM Administracion.Concesion WHERE IdEmpresaConcesionaria = @CUIT)
        SET @Errores += 'No se puede eliminar: la empresa tiene concesiones registradas. ';

    IF @Errores <> ''
    BEGIN
        RAISERROR(@Errores, 16, 1);
        RETURN;
    END

    DELETE FROM Administracion.EmpresaConcesionaria
    WHERE CUIT = @CUIT;
END
GO

-- ----------------------------------------------------------------------------
-- EmpresaConcesionaria_Listar
-- ----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE Administracion.EmpresaConcesionaria_Listar
(
    @CUIT INT = NULL,
    @RazonSocial VARCHAR(50) = NULL
)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT CUIT, RazonSocial, Email, Telefono
    FROM Administracion.EmpresaConcesionaria
    WHERE (@CUIT IS NULL OR CUIT = @CUIT)
      AND (@RazonSocial IS NULL OR RazonSocial LIKE '%' + @RazonSocial + '%')
    ORDER BY RazonSocial;
END
GO


-- ============================================================================
-- TABLA: Administracion.Concesion
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Concesion_Insertar
-- ----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE Administracion.Concesion_Insertar
(
    @IdEmpresaConcesionaria INT,
    @IdParque INT,
    @TipoDeActividad VARCHAR(30),
    @FechaInicio DATE,
    @FechaFin DATE,
    @Canon DECIMAL(10,2),
    @Estado VARCHAR(20),
    @IdConcesion INT OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Errores VARCHAR(255) = '';

    IF NOT EXISTS (SELECT 1 FROM Administracion.EmpresaConcesionaria WHERE CUIT = @IdEmpresaConcesionaria)
        SET @Errores += 'La empresa concesionaria indicada no existe. ';

    IF NOT EXISTS (SELECT 1 FROM Administracion.Parque WHERE IdParque = @IdParque)
        SET @Errores += 'El parque indicado no existe. ';

    IF @TipoDeActividad IS NULL OR LTRIM(RTRIM(@TipoDeActividad)) = ''
        SET @Errores += 'El tipo de actividad de la concesión es obligatorio. ';

    IF @Canon IS NULL OR @Canon < 0
        SET @Errores += 'El canon debe ser un valor mayor o igual a 0. ';

    IF @FechaInicio IS NOT NULL AND @FechaFin IS NOT NULL AND @FechaInicio >= @FechaFin
        SET @Errores += 'La fecha de inicio debe ser anterior a la fecha de fin. ';

    IF @Estado IS NULL OR LTRIM(RTRIM(@Estado)) = ''
        SET @Errores += 'El estado de la concesión es obligatorio. ';

    IF @Errores <> ''
    BEGIN
        RAISERROR(@Errores, 16, 1);
        RETURN;
    END

    INSERT INTO Administracion.Concesion
        (IdEmpresaConcesionaria, IdParque, TipoDeActividad, FechaInicio, FechaFin, Canon, Estado)
    VALUES
        (@IdEmpresaConcesionaria, @IdParque, @TipoDeActividad, @FechaInicio, @FechaFin, @Canon, @Estado);

    SET @IdConcesion = SCOPE_IDENTITY();
END
GO

-- ----------------------------------------------------------------------------
-- Concesion_Actualizar
-- ----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE Administracion.Concesion_Actualizar
(
    @IdConcesion INT,
    @IdEmpresaConcesionaria INT,
    @IdParque INT,
    @TipoDeActividad VARCHAR(30),
    @FechaInicio DATE,
    @FechaFin DATE,
    @Canon DECIMAL(10,2),
    @Estado VARCHAR(20)
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Errores VARCHAR(255) = '';

    IF NOT EXISTS (SELECT 1 FROM Administracion.Concesion WHERE IdConcesion = @IdConcesion)
        SET @Errores += 'No existe una concesión con el Id indicado. ';

    IF NOT EXISTS (SELECT 1 FROM Administracion.EmpresaConcesionaria WHERE CUIT = @IdEmpresaConcesionaria)
        SET @Errores += 'La empresa concesionaria indicada no existe. ';

    IF NOT EXISTS (SELECT 1 FROM Administracion.Parque WHERE IdParque = @IdParque)
        SET @Errores += 'El parque indicado no existe. ';

    IF @Canon IS NULL OR @Canon < 0
        SET @Errores += 'El canon debe ser un valor mayor o igual a 0. ';

    IF @FechaInicio IS NOT NULL AND @FechaFin IS NOT NULL AND @FechaInicio >= @FechaFin
        SET @Errores += 'La fecha de inicio debe ser anterior a la fecha de fin. ';

    IF @Estado IS NULL OR LTRIM(RTRIM(@Estado)) = ''
        SET @Errores += 'El estado de la concesión es obligatorio. ';

    IF @Errores <> ''
    BEGIN
        RAISERROR(@Errores, 16, 1);
        RETURN;
    END

    UPDATE Administracion.Concesion
    SET IdEmpresaConcesionaria = @IdEmpresaConcesionaria,
        IdParque = @IdParque,
        TipoDeActividad = @TipoDeActividad,
        FechaInicio = @FechaInicio,
        FechaFin = @FechaFin,
        Canon = @Canon,
        Estado = @Estado
    WHERE IdConcesion = @IdConcesion;
END
GO

-- ----------------------------------------------------------------------------
-- Concesion_Eliminar
-- ----------------------------------------------------------------------------
-- BAJA LOGICA
CREATE OR ALTER PROCEDURE Administracion.Concesion_Eliminar
(
    @IdConcesion INT
)
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM Administracion.Concesion WHERE IdConcesion = @IdConcesion)
    BEGIN
        RAISERROR('No existe una concesión con el Id indicado.', 16, 1);
        RETURN;
    END

    UPDATE Administracion.Concesion
    SET Estado = 'Cancelada'
    WHERE IdConcesion = @IdConcesion;
END
GO

-- ----------------------------------------------------------------------------
-- Concesion_Listar
-- ----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE Administracion.Concesion_Listar
(
    @IdConcesion INT = NULL,
    @IdParque INT = NULL,
    @Estado VARCHAR(20) = NULL
)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT c.IdConcesion, c.IdEmpresaConcesionaria, ec.RazonSocial, c.IdParque, pq.Nombre AS NombreParque,
           c.TipoDeActividad, c.FechaInicio, c.FechaFin, c.Canon, c.Estado
    FROM Administracion.Concesion c
    INNER JOIN Administracion.EmpresaConcesionaria ec ON ec.CUIT = c.IdEmpresaConcesionaria
    INNER JOIN Administracion.Parque pq ON pq.IdParque = c.IdParque
    WHERE (@IdConcesion IS NULL OR c.IdConcesion = @IdConcesion)
      AND (@IdParque IS NULL OR c.IdParque = @IdParque)
      AND (@Estado IS NULL OR c.Estado = @Estado)
    ORDER BY c.FechaFin;
END
GO


-- ============================================================================
-- TABLA: Facturacion.TicketFactura
-- ============================================================================

-- ----------------------------------------------------------------------------
-- TicketFactura_Insertar
-- ----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE Facturacion.TicketFactura_Insertar
(
    @IdParque INT,
    @NumeroFactura VARCHAR(20),
    @PuntoDeVenta VARCHAR(50),
    @FechaEmision DATE,
    @FormaPago VARCHAR(20),
    @Total DECIMAL(10,2),
    @IdTicketFactura INT OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Errores VARCHAR(255) = '';

    IF @IdParque IS NULL OR NOT EXISTS (SELECT 1 FROM Administracion.Parque WHERE IdParque = @IdParque)
        SET @Errores += 'El parque indicado no existe. ';

    IF @NumeroFactura IS NULL OR LTRIM(RTRIM(@NumeroFactura)) = ''
        SET @Errores += 'El número de factura es obligatorio. ';

    IF @PuntoDeVenta IS NULL OR LTRIM(RTRIM(@PuntoDeVenta)) = ''
        SET @Errores += 'El punto de venta es obligatorio. ';

    IF EXISTS (SELECT 1 FROM Facturacion.TicketFactura WHERE PuntoDeVenta = @PuntoDeVenta AND NumeroFactura = @NumeroFactura)
        SET @Errores += 'Ya existe una factura con ese número para ese punto de venta. ';

    IF @FormaPago IS NULL OR LTRIM(RTRIM(@FormaPago)) = ''
        SET @Errores += 'La forma de pago es obligatoria. ';

    IF @Total IS NULL OR @Total < 0
        SET @Errores += 'El total debe ser un valor mayor o igual a 0. ';

    IF @Errores <> ''
    BEGIN
        RAISERROR(@Errores, 16, 1);
        RETURN;
    END

    INSERT INTO Facturacion.TicketFactura
        (IdParque, NumeroFactura, PuntoDeVenta, FechaEmision, FormaPago, Total)
    VALUES
        (@IdParque, @NumeroFactura, @PuntoDeVenta, @FechaEmision, @FormaPago, @Total);

    SET @IdTicketFactura = SCOPE_IDENTITY();
END
GO

-- ----------------------------------------------------------------------------
-- TicketFactura_Actualizar
-- ----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE Facturacion.TicketFactura_Actualizar
(
    @IdTicketFactura INT,
    @FormaPago VARCHAR(20)
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Errores VARCHAR(255) = '';

    IF NOT EXISTS (SELECT 1 FROM Facturacion.TicketFactura WHERE IdTicketFactura = @IdTicketFactura)
        SET @Errores += 'No existe un ticket/factura con el Id indicado. ';

    IF @FormaPago IS NULL OR LTRIM(RTRIM(@FormaPago)) = ''
        SET @Errores += 'La forma de pago es obligatoria. ';

    IF @Errores <> ''
    BEGIN
        RAISERROR(@Errores, 16, 1);
        RETURN;
    END

    UPDATE Facturacion.TicketFactura
    SET FormaPago = @FormaPago
    WHERE IdTicketFactura = @IdTicketFactura;
END
GO

-- ----------------------------------------------------------------------------
-- TicketFactura_Eliminar
-- ----------------------------------------------------------------------------
-- Nota: un comprobante fiscal emitido no debería eliminarse físicamente.
CREATE OR ALTER PROCEDURE Facturacion.TicketFactura_Eliminar
(
    @IdTicketFactura INT
)
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM Facturacion.TicketFactura WHERE IdTicketFactura = @IdTicketFactura)
    BEGIN
        RAISERROR('No existe un ticket/factura con el Id indicado.', 16, 1);
        RETURN;
    END

    RAISERROR('No se permite eliminar comprobantes fiscales. Utilice el proceso de anulación correspondiente.', 16, 1);
END
GO

-- ----------------------------------------------------------------------------
-- TicketFactura_Listar
-- ----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE Facturacion.TicketFactura_Listar
(
    @IdTicketFactura INT = NULL,
    @IdParque INT = NULL,
    @FechaDesde DATE = NULL,
    @FechaHasta DATE = NULL
)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT tf.IdTicketFactura, tf.IdParque, pq.Nombre AS NombreParque, tf.NumeroFactura,
           tf.PuntoDeVenta, tf.FechaEmision, tf.FormaPago, tf.Total
    FROM Facturacion.TicketFactura tf
    INNER JOIN Administracion.Parque pq ON pq.IdParque = tf.IdParque
    WHERE (@IdTicketFactura IS NULL OR tf.IdTicketFactura = @IdTicketFactura)
      AND (@IdParque IS NULL OR tf.IdParque = @IdParque)
      AND (@FechaDesde IS NULL OR tf.FechaEmision >= @FechaDesde)
      AND (@FechaHasta IS NULL OR tf.FechaEmision <= @FechaHasta)
    ORDER BY tf.FechaEmision DESC;
END
GO


-- ============================================================================
-- TABLA: Facturacion.TicketItemActividad
-- ============================================================================

-- ----------------------------------------------------------------------------
-- TicketItemActividad_Insertar
-- ----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE Facturacion.TicketItemActividad_Insertar
(
    @IdTicketFactura INT,
    @IdActividad INT,
    @Cantidad INT,
    @FechaActividad DATE,
    @Precio DECIMAL(10,2),
    @IdItemActividad INT OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Errores VARCHAR(255) = '';

    IF NOT EXISTS (SELECT 1 FROM Facturacion.TicketFactura WHERE IdTicketFactura = @IdTicketFactura)
        SET @Errores += 'El ticket/factura indicado no existe. ';

    IF NOT EXISTS (SELECT 1 FROM Administracion.Actividad WHERE IdActividad = @IdActividad)
        SET @Errores += 'La actividad indicada no existe. ';

    IF @Cantidad IS NULL OR @Cantidad <= 0
        SET @Errores += 'La cantidad debe ser mayor a 0. ';

    IF @Precio IS NULL OR @Precio < 0
        SET @Errores += 'El precio debe ser mayor o igual a 0. ';

    IF @FechaActividad IS NULL
        SET @Errores += 'La fecha de la actividad es obligatoria. ';

    IF @Errores <> ''
    BEGIN
        RAISERROR(@Errores, 16, 1);
        RETURN;
    END

    INSERT INTO Facturacion.TicketItemActividad
        (IdTicketFactura, IdActividad, Cantidad, FechaActividad, Precio)
    VALUES
        (@IdTicketFactura, @IdActividad, @Cantidad, @FechaActividad, @Precio);

    SET @IdItemActividad = SCOPE_IDENTITY();
END
GO

-- ----------------------------------------------------------------------------
-- TicketItemActividad_Actualizar
-- ----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE Facturacion.TicketItemActividad_Actualizar
(
    @IdItemActividad INT,
    @Cantidad INT,
    @FechaActividad DATE,
    @Precio DECIMAL(10,2)
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Errores VARCHAR(255) = '';

    IF NOT EXISTS (SELECT 1 FROM Facturacion.TicketItemActividad WHERE IdItemActividad = @IdItemActividad)
        SET @Errores += 'No existe un ítem de actividad con el Id indicado. ';

    IF @Cantidad IS NULL OR @Cantidad <= 0
        SET @Errores += 'La cantidad debe ser mayor a 0. ';

    IF @Precio IS NULL OR @Precio < 0
        SET @Errores += 'El precio debe ser mayor o igual a 0. ';

    IF @Errores <> ''
    BEGIN
        RAISERROR(@Errores, 16, 1);
        RETURN;
    END

    UPDATE Facturacion.TicketItemActividad
    SET Cantidad = @Cantidad,
        FechaActividad = @FechaActividad,
        Precio = @Precio
    WHERE IdItemActividad = @IdItemActividad;
END
GO

-- ----------------------------------------------------------------------------
-- TicketItemActividad_Eliminar
-- ----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE Facturacion.TicketItemActividad_Eliminar
(
    @IdItemActividad INT
)
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM Facturacion.TicketItemActividad WHERE IdItemActividad = @IdItemActividad)
    BEGIN
        RAISERROR('No existe un ítem de actividad con el Id indicado.', 16, 1);
        RETURN;
    END

    DELETE FROM Facturacion.TicketItemActividad
    WHERE IdItemActividad = @IdItemActividad;
END
GO

-- ----------------------------------------------------------------------------
-- TicketItemActividad_Listar
-- ----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE Facturacion.TicketItemActividad_Listar
(
    @IdItemActividad INT = NULL,
    @IdTicketFactura INT = NULL
)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT ti.IdItemActividad, ti.IdTicketFactura, ti.IdActividad, ac.Nombre AS NombreActividad,
           ti.Cantidad, ti.FechaActividad, ti.Precio
    FROM Facturacion.TicketItemActividad ti
    INNER JOIN Administracion.Actividad ac ON ac.IdActividad = ti.IdActividad
    WHERE (@IdItemActividad IS NULL OR ti.IdItemActividad = @IdItemActividad)
      AND (@IdTicketFactura IS NULL OR ti.IdTicketFactura = @IdTicketFactura)
    ORDER BY ti.FechaActividad DESC;
END
GO


-- ============================================================================
-- TABLA: Facturacion.TicketItemEntrada
-- ============================================================================

-- ----------------------------------------------------------------------------
-- TicketItemEntrada_Insertar
-- ----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE Facturacion.TicketItemEntrada_Insertar
(
    @IdTicketFactura INT,
    @IdTipoVisitante INT,
    @Cantidad INT,
    @FechaAcceso DATE,
    @PrecioUnitario DECIMAL(10,2),
    @IdItemEntrada INT OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Errores VARCHAR(255) = '';

    IF @IdTicketFactura IS NULL OR NOT EXISTS (SELECT 1 FROM Facturacion.TicketFactura WHERE IdTicketFactura = @IdTicketFactura)
        SET @Errores += 'El ticket/factura indicado no existe. ';

    IF @IdTipoVisitante IS NULL OR NOT EXISTS (SELECT 1 FROM Administracion.TipoVisitante WHERE IdTipoVisitante = @IdTipoVisitante)
        SET @Errores += 'El tipo de visitante indicado no existe. ';

    IF @Cantidad IS NULL OR @Cantidad <= 0
        SET @Errores += 'La cantidad debe ser mayor a 0. ';

    IF @FechaAcceso IS NULL
        SET @Errores += 'La fecha de acceso es obligatoria. ';

    IF @PrecioUnitario IS NULL OR @PrecioUnitario < 0
        SET @Errores += 'El precio unitario debe ser mayor o igual a 0. ';

    IF @Errores <> ''
    BEGIN
        RAISERROR(@Errores, 16, 1);
        RETURN;
    END

    INSERT INTO Facturacion.TicketItemEntrada
        (IdTicketFactura, IdTipoVisitante, Cantidad, FechaAcceso, PrecioUnitario)
    VALUES
        (@IdTicketFactura, @IdTipoVisitante, @Cantidad, @FechaAcceso, @PrecioUnitario);

    SET @IdItemEntrada = SCOPE_IDENTITY();
END
GO

-- ----------------------------------------------------------------------------
-- TicketItemEntrada_Actualizar
-- ----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE Facturacion.TicketItemEntrada_Actualizar
(
    @IdItemEntrada INT,
    @IdTipoVisitante INT,
    @Cantidad INT,
    @FechaAcceso DATE,
    @PrecioUnitario DECIMAL(10,2)
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Errores VARCHAR(255) = '';

    IF NOT EXISTS (SELECT 1 FROM Facturacion.TicketItemEntrada WHERE IdItemEntrada = @IdItemEntrada)
        SET @Errores += 'No existe un ítem de entrada con el Id indicado. ';

    IF @IdTipoVisitante IS NULL OR NOT EXISTS (SELECT 1 FROM Administracion.TipoVisitante WHERE IdTipoVisitante = @IdTipoVisitante)
        SET @Errores += 'El tipo de visitante indicado no existe. ';

    IF @Cantidad IS NULL OR @Cantidad <= 0
        SET @Errores += 'La cantidad debe ser mayor a 0. ';

    IF @PrecioUnitario IS NULL OR @PrecioUnitario < 0
        SET @Errores += 'El precio unitario debe ser mayor o igual a 0. ';

    IF @Errores <> ''
    BEGIN
        RAISERROR(@Errores, 16, 1);
        RETURN;
    END

    UPDATE Facturacion.TicketItemEntrada
    SET IdTipoVisitante = @IdTipoVisitante,
        Cantidad = @Cantidad,
        FechaAcceso = @FechaAcceso,
        PrecioUnitario = @PrecioUnitario
    WHERE IdItemEntrada = @IdItemEntrada;
END
GO

-- ----------------------------------------------------------------------------
-- TicketItemEntrada_Eliminar
-- ----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE Facturacion.TicketItemEntrada_Eliminar
(
    @IdItemEntrada INT
)
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM Facturacion.TicketItemEntrada WHERE IdItemEntrada = @IdItemEntrada)
    BEGIN
        RAISERROR('No existe un ítem de entrada con el Id indicado.', 16, 1);
        RETURN;
    END

    DELETE FROM Facturacion.TicketItemEntrada
    WHERE IdItemEntrada = @IdItemEntrada;
END
GO

-- ----------------------------------------------------------------------------
-- TicketItemEntrada_Listar
-- ----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE Facturacion.TicketItemEntrada_Listar
(
    @IdItemEntrada INT = NULL,
    @IdTicketFactura INT = NULL,
    @IdTipoVisitante INT = NULL
)
AS
BEGIN
    SET NOCOUNT ON;

    -- Nota: Subtotal es un atributo derivado (no se persiste en la tabla,
    -- según definición del DER). Se calcula aquí como Cantidad * PrecioUnitario.
    SELECT ie.IdItemEntrada, ie.IdTicketFactura, ie.IdTipoVisitante,
           tv.Descripcion AS TipoVisitante, ie.Cantidad, ie.FechaAcceso,
           ie.PrecioUnitario, (ie.Cantidad * ie.PrecioUnitario) AS Subtotal
    FROM Facturacion.TicketItemEntrada ie
    INNER JOIN Administracion.TipoVisitante tv ON tv.IdTipoVisitante = ie.IdTipoVisitante
    WHERE (@IdItemEntrada IS NULL OR ie.IdItemEntrada = @IdItemEntrada)
      AND (@IdTicketFactura IS NULL OR ie.IdTicketFactura = @IdTicketFactura)
      AND (@IdTipoVisitante IS NULL OR ie.IdTipoVisitante = @IdTipoVisitante)
    ORDER BY ie.FechaAcceso DESC;
END
GO


-- ============================================================================
-- TABLA: Facturacion.PrecioEntrada
-- ============================================================================

-- ----------------------------------------------------------------------------
-- PrecioEntrada_Insertar
-- ----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE Facturacion.PrecioEntrada_Insertar
(
    @IdParque INT,
    @IdTipoVisitante INT,
    @Precio DECIMAL(10,2),
    @VigenteDesde DATE,
    @VigenteHasta DATE = NULL,
    @IdPrecio INT OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Errores VARCHAR(255) = '';

    IF @IdParque IS NULL OR NOT EXISTS (SELECT 1 FROM Administracion.Parque WHERE IdParque = @IdParque)
        SET @Errores += 'El parque indicado no existe. ';

    IF @IdTipoVisitante IS NULL OR NOT EXISTS (SELECT 1 FROM Administracion.TipoVisitante WHERE IdTipoVisitante = @IdTipoVisitante)
        SET @Errores += 'El tipo de visitante indicado no existe. ';

    IF @Precio IS NULL OR @Precio < 0
        SET @Errores += 'El precio debe ser mayor o igual a 0. ';

    IF @VigenteDesde IS NULL
        SET @Errores += 'La fecha de vigencia desde es obligatoria. ';

    IF @VigenteHasta IS NOT NULL AND @VigenteDesde IS NOT NULL AND @VigenteDesde > @VigenteHasta
        SET @Errores += 'La fecha de vigencia desde no puede ser posterior a la fecha de vigencia hasta. ';

    IF @Errores <> ''
    BEGIN
        RAISERROR(@Errores, 16, 1);
        RETURN;
    END

    INSERT INTO Facturacion.PrecioEntrada
        (IdParque, IdTipoVisitante, Precio, VigenteDesde, VigenteHasta)
    VALUES
        (@IdParque, @IdTipoVisitante, @Precio, @VigenteDesde, @VigenteHasta);

    SET @IdPrecio = SCOPE_IDENTITY();
END
GO

-- ----------------------------------------------------------------------------
-- PrecioEntrada_Actualizar
-- ----------------------------------------------------------------------------

CREATE OR ALTER PROCEDURE Facturacion.PrecioEntrada_Actualizar
(
    @IdPrecio INT,
    @Precio DECIMAL(10,2),
    @VigenteDesde DATE,
    @VigenteHasta DATE = NULL
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Errores VARCHAR(255) = '';

    IF NOT EXISTS (SELECT 1 FROM Facturacion.PrecioEntrada WHERE IdPrecio = @IdPrecio)
        SET @Errores += 'No existe un precio de entrada con el Id indicado. ';

    IF @Precio IS NULL OR @Precio < 0
        SET @Errores += 'El precio debe ser mayor o igual a 0. ';

    IF @VigenteHasta IS NOT NULL AND @VigenteDesde IS NOT NULL AND @VigenteDesde > @VigenteHasta
        SET @Errores += 'La fecha de vigencia desde no puede ser posterior a la fecha de vigencia hasta. ';

    IF @Errores <> ''
    BEGIN
        RAISERROR(@Errores, 16, 1);
        RETURN;
    END

    UPDATE Facturacion.PrecioEntrada
    SET Precio = @Precio,
        VigenteDesde = @VigenteDesde,
        VigenteHasta = @VigenteHasta
    WHERE IdPrecio = @IdPrecio;
END
GO

-- ----------------------------------------------------------------------------
-- PrecioEntrada_Eliminar
-- ----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE Facturacion.PrecioEntrada_Eliminar
(
    @IdPrecio INT
)
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM Facturacion.PrecioEntrada WHERE IdPrecio = @IdPrecio)
    BEGIN
        RAISERROR('No existe un precio de entrada con el Id indicado.', 16, 1);
        RETURN;
    END

    DELETE FROM Facturacion.PrecioEntrada
    WHERE IdPrecio = @IdPrecio;
END
GO

-- ----------------------------------------------------------------------------
-- PrecioEntrada_Listar
-- ----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE Facturacion.PrecioEntrada_Listar
(
    @IdPrecio INT = NULL,
    @IdParque INT = NULL,
    @IdTipoVisitante INT = NULL
)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT pe.IdPrecio, pe.IdParque, pq.Nombre AS NombreParque, pe.IdTipoVisitante,
           tv.Descripcion AS TipoVisitante, pe.Precio, pe.VigenteDesde, pe.VigenteHasta
    FROM Facturacion.PrecioEntrada pe
    INNER JOIN Administracion.Parque pq ON pq.IdParque = pe.IdParque
    INNER JOIN Administracion.TipoVisitante tv ON tv.IdTipoVisitante = pe.IdTipoVisitante
    WHERE (@IdPrecio IS NULL OR pe.IdPrecio = @IdPrecio)
      AND (@IdParque IS NULL OR pe.IdParque = @IdParque)
      AND (@IdTipoVisitante IS NULL OR pe.IdTipoVisitante = @IdTipoVisitante)
    ORDER BY pe.VigenteDesde DESC;
END
GO


-- ============================================================================
-- TABLA: Facturacion.PagoCanon
-- ============================================================================

-- ----------------------------------------------------------------------------
-- PagoCanon_Insertar
-- ----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE Facturacion.PagoCanon_Insertar
(
    @IdConcesion INT,
    @PeriodoMesPago TINYINT,
    @PeriodoAñoPago SMALLINT,
    @Monto DECIMAL(10,2),
    @FechaPago DATE,
    @Estado VARCHAR(25),
    @IdPago INT OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Errores VARCHAR(255) = '';

    IF @IdConcesion IS NULL OR NOT EXISTS (SELECT 1 FROM Administracion.Concesion WHERE IdConcesion = @IdConcesion)
        SET @Errores += 'La concesión indicada no existe. ';

    IF @PeriodoMesPago IS NULL OR @PeriodoMesPago < 1 OR @PeriodoMesPago > 12
        SET @Errores += 'El mes del período de pago debe estar entre 1 y 12. ';

    IF @PeriodoAñoPago IS NULL OR @PeriodoAñoPago <= 0
        SET @Errores += 'El año del período de pago debe ser mayor a 0. ';

    IF @Monto IS NULL OR @Monto < 0
        SET @Errores += 'El monto debe ser mayor o igual a 0. ';

    IF @FechaPago IS NULL
        SET @Errores += 'La fecha de pago es obligatoria. ';

    IF @Estado IS NULL OR LTRIM(RTRIM(@Estado)) = ''
        SET @Errores += 'El estado del pago es obligatorio. ';

    IF EXISTS (
        SELECT 1 FROM Facturacion.PagoCanon
        WHERE IdConcesion = @IdConcesion
          AND PeriodoMesPago = @PeriodoMesPago
          AND PeriodoAñoPago = @PeriodoAñoPago
    )
        SET @Errores += 'Ya existe un pago registrado para esa concesión en ese período. ';

    IF @Errores <> ''
    BEGIN
        RAISERROR(@Errores, 16, 1);
        RETURN;
    END

    INSERT INTO Facturacion.PagoCanon
        (IdConcesion, PeriodoMesPago, PeriodoAñoPago, Monto, FechaPago, Estado)
    VALUES
        (@IdConcesion, @PeriodoMesPago, @PeriodoAñoPago, @Monto, @FechaPago, @Estado);

    SET @IdPago = SCOPE_IDENTITY();
END
GO

-- ----------------------------------------------------------------------------
-- PagoCanon_Actualizar
-- ----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE Facturacion.PagoCanon_Actualizar
(
    @IdPago INT,
    @Monto DECIMAL(10,2),
    @FechaPago DATE,
    @Estado VARCHAR(25)
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Errores VARCHAR(255) = '';

    IF NOT EXISTS (SELECT 1 FROM Facturacion.PagoCanon WHERE IdPago = @IdPago)
        SET @Errores += 'No existe un pago de canon con el Id indicado. ';

    IF @Monto IS NULL OR @Monto < 0
        SET @Errores += 'El monto debe ser mayor o igual a 0. ';

    IF @Estado IS NULL OR LTRIM(RTRIM(@Estado)) = ''
        SET @Errores += 'El estado del pago es obligatorio. ';

    IF @Errores <> ''
    BEGIN
        RAISERROR(@Errores, 16, 1);
        RETURN;
    END

    UPDATE Facturacion.PagoCanon
    SET Monto = @Monto,
        FechaPago = @FechaPago,
        Estado = @Estado
    WHERE IdPago = @IdPago;
END
GO

-- ----------------------------------------------------------------------------
-- PagoCanon_Eliminar
-- ----------------------------------------------------------------------------

CREATE OR ALTER PROCEDURE Facturacion.PagoCanon_Eliminar
(
    @IdPago INT
)
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM Facturacion.PagoCanon WHERE IdPago = @IdPago)
    BEGIN
        RAISERROR('No existe un pago de canon con el Id indicado.', 16, 1);
        RETURN;
    END

    DELETE FROM Facturacion.PagoCanon
    WHERE IdPago = @IdPago;
END
GO

-- ----------------------------------------------------------------------------
-- PagoCanon_Listar
-- ----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE Facturacion.PagoCanon_Listar
(
    @IdPago INT = NULL,
    @IdConcesion INT = NULL,
    @Estado VARCHAR(25) = NULL
)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT pc.IdPago, pc.IdConcesion, ec.RazonSocial, pc.PeriodoMesPago, pc.PeriodoAñoPago,
           pc.Monto, pc.FechaPago, pc.Estado
    FROM Facturacion.PagoCanon pc
    INNER JOIN Administracion.Concesion co ON co.IdConcesion = pc.IdConcesion
    INNER JOIN Administracion.EmpresaConcesionaria ec ON ec.CUIT = co.IdEmpresaConcesionaria
    WHERE (@IdPago IS NULL OR pc.IdPago = @IdPago)
      AND (@IdConcesion IS NULL OR pc.IdConcesion = @IdConcesion)
      AND (@Estado IS NULL OR pc.Estado = @Estado)
    ORDER BY pc.PeriodoAñoPago DESC, pc.PeriodoMesPago DESC;
END
GO
