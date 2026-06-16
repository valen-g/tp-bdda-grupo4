IF NOT EXISTS (SELECT 1 FROM sys.databases WHERE name = 'ParquesNacionalesDB')
BEGIN
    CREATE DATABASE ParquesNacionalesDB;
END

USE ParquesNacionalesDB;
SELECT * FROM sys.tables

--CREATE SCHEMA Facturacion;
--CREATE SCHEMA Administracion;


IF OBJECT_ID('Administracion.TipoParque', 'U') IS NULL
BEGIN 
    CREATE TABLE Administracion.TipoParque
    (
        IdTipoParque INT IDENTITY(1,1) PRIMARY KEY,
        Descripcion VARCHAR(100) NOT NULL UNIQUE,
    );
END


IF OBJECT_ID('Administracion.Parque', 'U') IS NULL
BEGIN
    CREATE TABLE Administracion.Parque
    (
        IdParque INT IDENTITY(1,1) PRIMARY KEY,
        Nombre VARCHAR(100) NOT NULL,
        Ubicacion VARCHAR(200) NOT NULL,
        Superficie DECIMAL(12,2) NOT NULL CHECK (Superficie > 0),
        Descripcion VARCHAR(100),
        IdTipoParque INT,
        EsActivo BIT NOT NULL DEFAULT 1,
        
        CONSTRAINT FK_Parque_TipoParque FOREIGN KEY (IdTipoParque) REFERENCES Administracion.TipoParque(IdTipoParque)
    );
END

IF OBJECT_ID('Administracion.AsignacionParque', 'U') IS NULL
BEGIN
    CREATE TABLE Administracion.AsignacionParque
    (
        IdAsignacion INT IDENTITY(1,1) PRIMARY KEY,
        IdParque INT,
        FechaIngreso DATE DEFAULT GETDATE(),
        FechaEgreso DATE,
        MotivoEgreso VARCHAR(100),

        CONSTRAINT FK_AsignacionParque_Parque FOREIGN KEY (IdParque) 
            REFERENCES Administracion.Parque(IdParque),
    );
END


IF OBJECT_ID('Administracion.Habilitacion', 'U') IS NULL
BEGIN
    CREATE TABLE Administracion.Habilitacion
    (
        IdHabilitacion INT IDENTITY(1,1) PRIMARY KEY,
        Descripcion VARCHAR(100) NOT NULL,
        FechaOtorgamiento DATE NOT NULL,
        FechaVencimiento DATE NOT NULL,
    );
END


IF OBJECT_ID('Administracion.Personal', 'U') IS NULL
BEGIN
    CREATE TABLE Administracion.Personal
    (
        Nombre VARCHAR(20) NOT NULL,
        Apellido VARCHAR(20) NOT NULL,
        DNI INT NOT NULL PRIMARY KEY,
        FechaNacimiento DATE,
        Email VARCHAR(50),
        Telefono BIGINT,
        TipoPersonal VARCHAR(20) NOT NULL,
        EsActivo BIT NOT NULL,
        IdHabilitacion INT,
        IdAsignacion INT,

        CONSTRAINT FK_Habilitacion_Personal FOREIGN KEY (IdHabilitacion) 
            REFERENCES Administracion.Habilitacion(IdHabilitacion),
        CONSTRAINT FK_AsignacionParque_Personal FOREIGN KEY (IdAsignacion) 
            REFERENCES Administracion.AsignacionParque(IdAsignacion)
    );
END


IF OBJECT_ID('Administracion.Actividad', 'U') IS NULL
BEGIN
    CREATE TABLE Administracion.Actividad
    (
        IdActividad INT IDENTITY(1,1) PRIMARY KEY,
        IdParque INT,
        Nombre VARCHAR(150) NOT NULL,
        Tipo VARCHAR(50) NOT NULL,
        Descripcion VARCHAR(100),
        Costo DECIMAL(10,2) CHECK(Costo>0) NOT NULL,
        DuracionMinutos INT CHECK (DuracionMinutos > 0) NOT NULL,
        CupoMaximo INT CHECK (CupoMaximo > 0) NOT NULL,
        EsActivo BIT NOT NULL DEFAULT 1,
        
        CONSTRAINT FK_Actividad_Parque FOREIGN KEY (IdParque) 
            REFERENCES Administracion.Parque(IdParque)
    );
END

IF OBJECT_ID('Administracion.ActividadGuia', 'U') IS NULL
BEGIN
    CREATE TABLE Administracion.ActividadGuia
    (
        DniPersonal INT,
        IdActividad INT,
        FechaDesde DATE NOT NULL,
        FechaHasta DATE,

        CONSTRAINT PK_ActividadGuia_Personal_Actividad PRIMARY KEY (DniPersonal,IdActividad),
        
        CONSTRAINT FK_ActividadGuia_Personal FOREIGN KEY (DniPersonal) REFERENCES Administracion.Personal(DNI),
        CONSTRAINT FK_ActividadGuia_Actividad FOREIGN KEY (IdActividad) REFERENCES Administracion.Actividad(IdActividad)
    );
END


IF OBJECT_ID('Facturacion.TicketFactura', 'U') IS NULL
BEGIN
    CREATE TABLE Facturacion.TicketFactura
    (
        IdTicketFactura INT IDENTITY(1,1) PRIMARY KEY,
        IdParque INT,
        NumeroFactura VARCHAR(20) NOT NULL,
        PuntoDeVenta VARCHAR(50) NOT NULL,
        FechaEmision DATE NOT NULL,
        FormaPago VARCHAR(20) NOT NULL,
        Moneda VARCHAR(3) NOT NULL DEFAULT 'ARS', --PREGUNTAR
        Total DECIMAL(10,2) NOT NULL CHECK (Total >= 0),
        
        CONSTRAINT FK_TicketFactura_Parque FOREIGN KEY (IdParque) 
            REFERENCES Administracion.Parque(IdParque),
        CONSTRAINT UQ_TicketFactura_Numero UNIQUE (PuntoDeVenta, NumeroFactura)
    );
END

ALTER TABLE Facturacion.TicketFactura DROP COLUMN Moneda



IF OBJECT_ID('Facturacion.TicketItemActividad', 'U') IS NULL
BEGIN
    CREATE TABLE Facturacion.TicketItemActividad
    (
        IdItemActividad INT IDENTITY(1,1) PRIMARY KEY,
        IdTicketFactura INT NOT NULL,
        IdActividad INT NOT NULL,
        Cantidad INT NOT NULL CHECK (Cantidad > 0),
        FechaActividad DATE NOT NULL,
        Precio DECIMAL(10,2) NOT NULL CHECK (Precio >= 0),
        Moneda VARCHAR(3) NOT NULL DEFAULT 'ARS',
        
        CONSTRAINT FK_TicketItemActividad_TicketFactura FOREIGN KEY (IdTicketFactura) 
            REFERENCES Facturacion.TicketFactura(IdTicketFactura) ON DELETE CASCADE,
        CONSTRAINT FK_TicketItemActividad_Actividad FOREIGN KEY (IdActividad) 
            REFERENCES Administracion.Actividad(IdActividad)
    );
END



IF OBJECT_ID('Facturacion.TicketItemEntrada', 'U') IS NULL
BEGIN
    CREATE TABLE Facturacion.TicketItemEntrada
    (
        IdItemEntrada INT IDENTITY(1,1) PRIMARY KEY,
        IdTicketFactura INT,
        Cantidad INT NOT NULL CHECK (Cantidad > 0),
        FechaAcceso DATE NOT NULL,
        PrecioUnitario DECIMAL(10,2) NOT NULL CHECK (PrecioUnitario >= 0),
        Moneda VARCHAR(3) NOT NULL DEFAULT 'ARS',


        CONSTRAINT FK_TicketItemEntrada_TicketFactura FOREIGN KEY (IdTicketFactura) 
            REFERENCES Facturacion.TicketFactura(IdTicketFactura) ON DELETE CASCADE,
    );
END


IF OBJECT_ID('Administracion.TipoVisitante', 'U') IS NULL
BEGIN
    CREATE TABLE Administracion.TipoVisitante
    (
        IdTipoVisitante INT IDENTITY(1,1) PRIMARY KEY,
        IdItemEntrada INT,
        Descripcion VARCHAR(100),
        EsActivo BIT NOT NULL,
        constraint FK_Ticket_Item_Entrada FOREIGN KEY (IdItemEntrada) REFERENCES Facturacion.TicketItemEntrada(IdItemEntrada)
    );
END


IF OBJECT_ID('Facturacion.PrecioEntrada', 'U') IS NULL
BEGIN
    CREATE TABLE Facturacion.PrecioEntrada
    (
        IdPrecio INT IDENTITY(1,1) PRIMARY KEY,
        IdParque INT,
        IdTipoVisitante INT,
        Precio DECIMAL(10,2) NOT NULL CHECK (Precio >= 0),
        VigenteDesde DATE NOT NULL,
        VigenteHasta DATE,
        Moneda VARCHAR(3) NOT NULL DEFAULT 'ARS', --PREGUNTAR
        
        CONSTRAINT FK_PrecioEntrada_Parque FOREIGN KEY (IdParque) 
            REFERENCES Administracion.Parque(IdParque),
        CONSTRAINT FK_PrecioEntrada_TipoVisitante FOREIGN KEY (IdTipoVisitante) 
            REFERENCES Administracion.TipoVisitante(IdTipoVisitante),
        CONSTRAINT CK_PrecioEntrada_Fechas CHECK (VigenteDesde <= VigenteHasta)
    );
END





IF OBJECT_ID('Administracion.EmpresaConcesionaria', 'U') IS NULL
BEGIN
    CREATE TABLE Administracion.EmpresaConcesionaria
    (
        CUIT INT PRIMARY KEY,
        RazonSocial VARCHAR(50) NOT NULL UNIQUE,
        Email VARCHAR(50),
        Telefono INT

    );
END


IF OBJECT_ID('Administracion.Concesion', 'U') IS NULL
BEGIN
    CREATE TABLE Administracion.Concesion
    (
        IdConcesion INT IDENTITY(1,1) PRIMARY KEY,
        IdEmpresaConcesionaria INT NOT NULL,
        IdParque INT NOT NULL,
        TipoDeActividad VARCHAR(30) NOT NULL,
        FechaInicio DATE NOT NULL,
        FechaFin DATE NOT NULL,
        Canon DECIMAL(10,2) NOT NULL CHECK (Canon >= 0),
        Moneda VARCHAR(3) NOT NULL DEFAULT 'ARS',
        Estado VARCHAR(20) NOT NULL,
        
        CONSTRAINT FK_Concesion_EmpresaConcesionaria FOREIGN KEY (IdEmpresaConcesionaria) 
            REFERENCES Administracion.EmpresaConcesionaria(CUIT),
        CONSTRAINT FK_Concesion_Parque FOREIGN KEY (IdParque) 
            REFERENCES Administracion.Parque(IdParque),
        CONSTRAINT CK_Concesion_Fechas CHECK (FechaInicio < FechaFin)
    );
END

IF OBJECT_ID('Facturacion.PagoCanon', 'U') IS NULL
BEGIN
    CREATE TABLE Facturacion.PagoCanon
    (
        IdPago INT IDENTITY(1,1) PRIMARY KEY,
        IdConcesion INT NOT NULL,
        PeriodoMesPago TINYINT NOT NULL CHECK (PeriodoMesPago >= 1 AND PeriodoMesPago <= 12),
        PeriodoAñoPago SMALLINT NOT NULL CHECK(PeriodoAñoPago>0),
        Monto DECIMAL(10,2) NOT NULL CHECK (Monto >= 0),
        Moneda VARCHAR(3) NOT NULL DEFAULT 'ARS',
        FechaPago DATE NOT NULL,
        Estado VARCHAR(25) NOT NULL,
        
        CONSTRAINT FK_PagoCanon_Concesion FOREIGN KEY (IdConcesion) 
            REFERENCES Administracion.Concesion(IdConcesion)
    );
END