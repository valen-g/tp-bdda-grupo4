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
    Script          : 05_Seguridad.sql
    Objetivo        : Implementar las medidas de seguridad de la Entrega 8:
                       1) Cifrado de Email/Telefono de Administracion.Personal.
                       2) Roles de seguridad con permisos granulares.
                       3) Logins y usuarios de ejemplo para cada rol.
                       Requiere haber ejecutado previamente 01, 02, 03 y 04.
================================================================================
*/

USE ParquesNacionalesDB;
GO


-- ============================================================================
-- BLOQUE 1: CIFRADO DE DATOS SENSIBLES (Email y Telefono de Personal)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1.1) Alta de columnas cifradas en Administracion.Personal
-- ----------------------------------------------------------------------------
IF NOT EXISTS (
    SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID('Administracion.Personal') AND name = 'EmailCifrado'
)
BEGIN
    ALTER TABLE Administracion.Personal ADD EmailCifrado VARBINARY(256) NULL;
END
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID('Administracion.Personal') AND name = 'TelefonoCifrado'
)
BEGIN
    ALTER TABLE Administracion.Personal ADD TelefonoCifrado VARBINARY(256) NULL;
END
GO

-- ----------------------------------------------------------------------------
-- 1.2) Migración de los datos existentes a las columnas cifradas
-- ----------------------------------------------------------------------------
IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Administracion.Personal') AND name = 'Email')
BEGIN
    DECLARE @FraseClaveMigracion NVARCHAR(128) = 'ParquesNacionales#ClaveCifrado2026';

    UPDATE Administracion.Personal
    SET EmailCifrado = CASE WHEN Email IS NULL THEN NULL
                            ELSE EncryptByPassPhrase(@FraseClaveMigracion, Email, 1, CONVERT(VARBINARY, DNI)) END,
        TelefonoCifrado = CASE WHEN Telefono IS NULL THEN NULL
                               ELSE EncryptByPassPhrase(@FraseClaveMigracion, CONVERT(VARCHAR(20), Telefono), 1, CONVERT(VARBINARY, DNI)) END
    WHERE EmailCifrado IS NULL
      AND (Email IS NOT NULL OR Telefono IS NOT NULL);
END
GO

-- ----------------------------------------------------------------------------
-- 1.3) Eliminación de las columnas en texto plano
-- ----------------------------------------------------------------------------
IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Administracion.Personal') AND name = 'Email')
BEGIN
    ALTER TABLE Administracion.Personal DROP COLUMN Email;
END
GO

IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Administracion.Personal') AND name = 'Telefono')
BEGIN
    ALTER TABLE Administracion.Personal DROP COLUMN Telefono;
END
GO

-- ----------------------------------------------------------------------------
-- 1.4) Redefinición de Administracion.Personal_Insertar
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
    DECLARE @FraseClave NVARCHAR(128) = 'ParquesNacionales#ClaveCifrado2026';

    IF @DNI IS NULL
        SET @Errores += 'El DNI es obligatorio. ';
    ELSE IF EXISTS (SELECT 1 FROM Administracion.Personal WHERE DNI = @DNI)
        SET @Errores += 'Ya existe una persona registrada con ese DNI. ';

    IF @NombreApellido IS NULL OR TRIM(@NombreApellido) = ''
        SET @Errores += 'El nombre y apellido son obligatorios. ';

    IF @TipoPersonal IS NULL OR TRIM(@TipoPersonal) = ''
        SET @Errores += 'El tipo de personal es obligatorio. ';

    IF @IdHabilitacion IS NOT NULL
       AND NOT EXISTS (SELECT 1 FROM Administracion.Habilitacion WHERE IdHabilitacion = @IdHabilitacion)
        SET @Errores += 'La habilitación indicada no existe. ';

    IF @IdAsignacion IS NOT NULL
       AND NOT EXISTS (SELECT 1 FROM Administracion.AsignacionParque WHERE IdAsignacion = @IdAsignacion)
        SET @Errores += 'La asignación indicada no existe. ';

    IF @Errores <> ''
    BEGIN
        RAISERROR(@Errores, 16, 1);
        RETURN;
    END

    INSERT INTO Administracion.Personal
    (
        NombreApellido, DNI, FechaNacimiento, EmailCifrado, TelefonoCifrado,
        TipoPersonal, EsActivo, IdHabilitacion, IdAsignacion
    )
    VALUES
    (
        @NombreApellido,
        @DNI,
        @FechaNacimiento,
        CASE WHEN @Email IS NULL THEN NULL ELSE EncryptByPassPhrase(@FraseClave, @Email, 1, CONVERT(VARBINARY, @DNI)) END,
        CASE WHEN @Telefono IS NULL THEN NULL ELSE EncryptByPassPhrase(@FraseClave, CONVERT(VARCHAR(20), @Telefono), 1, CONVERT(VARBINARY, @DNI)) END,
        @TipoPersonal,
        @EsActivo,
        @IdHabilitacion,
        @IdAsignacion
    );
END
GO

-- ----------------------------------------------------------------------------
-- 1.5) Redefinición de Administracion.Personal_Actualizar
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
    DECLARE @FraseClave NVARCHAR(128) = 'ParquesNacionales#ClaveCifrado2026';

    IF NOT EXISTS (SELECT 1 FROM Administracion.Personal WHERE DNI = @DNI)
        SET @Errores += 'No existe personal registrado con ese DNI. ';

    IF @NombreApellido IS NULL OR TRIM(@NombreApellido) = ''
        SET @Errores += 'El nombre y apellido son obligatorios. ';

    IF @TipoPersonal IS NULL OR TRIM(@TipoPersonal) = ''
        SET @Errores += 'El tipo de personal es obligatorio. ';

    IF @IdHabilitacion IS NOT NULL
       AND NOT EXISTS (SELECT 1 FROM Administracion.Habilitacion WHERE IdHabilitacion = @IdHabilitacion)
        SET @Errores += 'La habilitación indicada no existe. ';

    IF @IdAsignacion IS NOT NULL
       AND NOT EXISTS (SELECT 1 FROM Administracion.AsignacionParque WHERE IdAsignacion = @IdAsignacion)
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
        EmailCifrado = CASE WHEN @Email IS NULL THEN NULL ELSE EncryptByPassPhrase(@FraseClave, @Email, 1, CONVERT(VARBINARY, @DNI)) END,
        TelefonoCifrado = CASE WHEN @Telefono IS NULL THEN NULL ELSE EncryptByPassPhrase(@FraseClave, CONVERT(VARCHAR(20), @Telefono), 1, CONVERT(VARBINARY, @DNI)) END,
        TipoPersonal = @TipoPersonal,
        EsActivo = @EsActivo,
        IdHabilitacion = @IdHabilitacion,
        IdAsignacion = @IdAsignacion
    WHERE DNI = @DNI;
END
GO

-- ----------------------------------------------------------------------------
-- 1.6) Redefinición de Administracion.Personal_Listar
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

    SELECT pe.DNI, pe.NombreApellido, pe.FechaNacimiento,
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

-- ----------------------------------------------------------------------------
-- 1.7) Personal_ListarSeguro: único procedimiento que devuelve el
--      contacto descifrado. Reservado al rol Administrador.
-- ----------------------------------------------------------------------------
IF OBJECT_ID('Administracion.Personal_ListarSeguro', 'P') IS NOT NULL
    DROP PROCEDURE Administracion.Personal_ListarSeguro;
GO
CREATE PROCEDURE Administracion.Personal_ListarSeguro
(
    @DNI INT = NULL
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @FraseClave NVARCHAR(128) = 'ParquesNacionales#ClaveCifrado2026';

    SELECT
        DNI,
        NombreApellido,
        FechaNacimiento,
        CONVERT(VARCHAR(50), DecryptByPassPhrase(@FraseClave, EmailCifrado, 1, CONVERT(VARBINARY, DNI))) AS EmailDescifrado,
        CONVERT(VARCHAR(20), DecryptByPassPhrase(@FraseClave, TelefonoCifrado, 1, CONVERT(VARBINARY, DNI))) AS TelefonoDescifrado,
        TipoPersonal,
        EsActivo
    FROM Administracion.Personal
    WHERE (@DNI IS NULL OR DNI = @DNI)
    ORDER BY NombreApellido;
END
GO


-- ============================================================================
-- BLOQUE 2: LOGINS DE EJEMPLO
-- ============================================================================
-- Usuario          | Login            | Contraseña      | Rol asignado
-- -----------------|------------------|-----------------|------------------
-- Administrador    | LoginAdmin       | Admin#2026      | rolAdministrador
-- Importador       | LoginImportador  | Import#2026     | rolImportador
-- Consulta         | LoginConsulta    | Consulta#2026   | rolConsulta
-- ============================================================================

USE master;
GO

IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'LoginAdmin')
BEGIN
    CREATE LOGIN LoginAdmin WITH PASSWORD = 'Admin#2026', CHECK_POLICY = ON;
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'LoginImportador')
BEGIN
    CREATE LOGIN LoginImportador WITH PASSWORD = 'Import#2026', CHECK_POLICY = ON;
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'LoginConsulta')
BEGIN
    CREATE LOGIN LoginConsulta WITH PASSWORD = 'Consulta#2026', CHECK_POLICY = ON;
END
GO

USE ParquesNacionalesDB;
GO

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'LoginAdmin')
BEGIN
    CREATE USER LoginAdmin FOR LOGIN LoginAdmin WITH DEFAULT_SCHEMA = Administracion;
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'LoginImportador')
BEGIN
    CREATE USER LoginImportador FOR LOGIN LoginImportador WITH DEFAULT_SCHEMA = Administracion;
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'LoginConsulta')
BEGIN
    CREATE USER LoginConsulta FOR LOGIN LoginConsulta WITH DEFAULT_SCHEMA = Administracion;
END
GO


-- ============================================================================
-- BLOQUE 3: ROLES DE SEGURIDAD Y PERMISOS GRANULARES (POLP)
-- ============================================================================
-- Ver documento "Entrega8_RolesYPermisos.docx" para el cuadro completo de
-- permisos por rol.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 3.1) Creación de los roles
-- ----------------------------------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'rolAdministrador' AND type = 'R')
BEGIN
    CREATE ROLE rolAdministrador AUTHORIZATION dbo;
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'rolImportador' AND type = 'R')
BEGIN
    CREATE ROLE rolImportador AUTHORIZATION dbo;
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'rolConsulta' AND type = 'R')
BEGIN
    CREATE ROLE rolConsulta AUTHORIZATION dbo;
END
GO

-- ----------------------------------------------------------------------------
-- 3.2) Permisos del rol Administrador
-- ----------------------------------------------------------------------------
GRANT CONTROL ON SCHEMA::Administracion TO rolAdministrador;
GRANT CONTROL ON SCHEMA::Facturacion TO rolAdministrador;
GO

-- ----------------------------------------------------------------------------
-- 3.3) Permisos del rol Importador
-- ----------------------------------------------------------------------------
GRANT EXECUTE ON OBJECT::Administracion.ImportarArchivoParqueCSV TO rolImportador;
GRANT EXECUTE ON OBJECT::Administracion.CargarTiposVisitante TO rolImportador;
GRANT EXECUTE ON OBJECT::Administracion.ImportarArchivoTarifaCSV TO rolImportador;
GRANT EXECUTE ON OBJECT::Administracion.ImportarArchivoPersonal TO rolImportador;

GRANT EXECUTE ON OBJECT::Administracion.TipoParque_Insertar TO rolImportador;
GRANT EXECUTE ON OBJECT::Administracion.TipoParque_Actualizar TO rolImportador;
GRANT EXECUTE ON OBJECT::Administracion.Parque_Insertar TO rolImportador;
GRANT EXECUTE ON OBJECT::Administracion.Parque_Actualizar TO rolImportador;
GRANT EXECUTE ON OBJECT::Administracion.TipoVisitante_Insertar TO rolImportador;
GRANT EXECUTE ON OBJECT::Facturacion.PrecioEntrada_Insertar TO rolImportador;
GRANT EXECUTE ON OBJECT::Administracion.Personal_Insertar TO rolImportador;
GRANT EXECUTE ON OBJECT::Administracion.Personal_Actualizar TO rolImportador;
GRANT EXECUTE ON OBJECT::Administracion.Habilitacion_Insertar TO rolImportador;
GRANT EXECUTE ON OBJECT::Administracion.Habilitacion_Actualizar TO rolImportador;
GRANT EXECUTE ON OBJECT::Administracion.AsignacionParque_Insertar TO rolImportador;
GRANT EXECUTE ON OBJECT::Administracion.AsignacionParque_Actualizar TO rolImportador;
GO

-- ----------------------------------------------------------------------------
-- 3.4) Permisos del rol Consulta
-- ----------------------------------------------------------------------------
GRANT EXECUTE ON OBJECT::Administracion.TipoParque_Listar TO rolConsulta;
GRANT EXECUTE ON OBJECT::Administracion.Parque_Listar TO rolConsulta;
GRANT EXECUTE ON OBJECT::Administracion.AsignacionParque_Listar TO rolConsulta;
GRANT EXECUTE ON OBJECT::Administracion.Habilitacion_Listar TO rolConsulta;
GRANT EXECUTE ON OBJECT::Administracion.Personal_Listar TO rolConsulta;
GRANT EXECUTE ON OBJECT::Administracion.Actividad_Listar TO rolConsulta;
GRANT EXECUTE ON OBJECT::Administracion.ActividadGuia_Listar TO rolConsulta;
GRANT EXECUTE ON OBJECT::Administracion.TipoVisitante_Listar TO rolConsulta;
GRANT EXECUTE ON OBJECT::Administracion.EmpresaConcesionaria_Listar TO rolConsulta;
GRANT EXECUTE ON OBJECT::Administracion.Concesion_Listar TO rolConsulta;
GRANT EXECUTE ON OBJECT::Facturacion.TicketFactura_Listar TO rolConsulta;
GRANT EXECUTE ON OBJECT::Facturacion.TicketItemActividad_Listar TO rolConsulta;
GRANT EXECUTE ON OBJECT::Facturacion.TicketItemEntrada_Listar TO rolConsulta;
GRANT EXECUTE ON OBJECT::Facturacion.PrecioEntrada_Listar TO rolConsulta;
GRANT EXECUTE ON OBJECT::Facturacion.PagoCanon_Listar TO rolConsulta;

-- Reportes de la Entrega 7
GRANT EXECUTE ON OBJECT::Facturacion.ReporteVisitasPorSemanaXML TO rolConsulta;
GRANT EXECUTE ON OBJECT::Facturacion.ReporteVisitasPorMesXML TO rolConsulta;
GRANT EXECUTE ON OBJECT::Facturacion.ReporteVisitasPorAnioXML TO rolConsulta;
GRANT EXECUTE ON OBJECT::Facturacion.ReporteIngresosTotalesXML TO rolConsulta;
GRANT EXECUTE ON OBJECT::Facturacion.ReporteDeudoresConcesionesXML TO rolConsulta;
GRANT EXECUTE ON OBJECT::Facturacion.MatrizVisitasPivotXML TO rolConsulta;
GRANT EXECUTE ON OBJECT::Administracion.ParquesYConcesionesAnidadasXML TO rolConsulta;

-- Reporte de clima
GRANT EXECUTE ON OBJECT::Administracion.MostrarTemperaturaParque TO rolConsulta;
GO

-- ----------------------------------------------------------------------------
-- 3.5) Restricción explícita sobre Personal_ListarSeguro
-- ----------------------------------------------------------------------------
DENY EXECUTE ON OBJECT::Administracion.Personal_ListarSeguro TO rolImportador, rolConsulta;
GRANT EXECUTE ON OBJECT::Administracion.Personal_ListarSeguro TO rolAdministrador;
GO

-- ----------------------------------------------------------------------------
-- 3.6) Asignación de usuarios a roles
-- ----------------------------------------------------------------------------
ALTER ROLE rolAdministrador ADD MEMBER LoginAdmin;
GO
ALTER ROLE rolImportador ADD MEMBER LoginImportador;
GO
ALTER ROLE rolConsulta ADD MEMBER LoginConsulta;
GO
