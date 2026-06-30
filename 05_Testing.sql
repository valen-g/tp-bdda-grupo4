/*
================================================================================
    Objetivo: SCRIPT DE TESTING Y CARGA DE DATOS
    - 10 Parques (Manuales)
    - 20 Guardaparques
    - 20 Guías
    - 30 Actividades/Tours
    - 10 Concesiones
    - Historial de Ventas
    - Casos Obligatorios (Cupo completo, simultaneidad, concesión vencida, errores).
================================================================================
*/

USE ParquesNacionalesDB;
GO

SET NOCOUNT ON;
DELETE FROM Facturacion.TicketItemActividad;
DELETE FROM Facturacion.TicketItemEntrada;
DELETE FROM Facturacion.TicketFactura;
DELETE FROM Facturacion.PagoCanon;
DELETE FROM Administracion.Concesion;
DELETE FROM Administracion.EmpresaConcesionaria;
DELETE FROM Administracion.ActividadGuia;
DELETE FROM Administracion.Actividad;

-- ============================================================================
-- 1. PARQUES
-- ============================================================================
-- Resultado Esperado: Se insertan 10 parques nacionales correctamente. 

EXEC Administracion.Parque_Insertar 'Parque Nacional Esteros de Farrapos', 'Río Negro', 17496, 'Humedales protegidos', 1, 1;
EXEC Administracion.Parque_Insertar 'Parque Nacional Cabo Polonio', 'Rocha', 25820, 'Dunas y lobos marinos', 1, 1;
EXEC Administracion.Parque_Insertar 'Parque Nacional San Miguel', 'Rocha', 1540, 'Lagunas y monte nativo', 1, 1;
EXEC Administracion.Parque_Insertar 'Parque Nacional Valle del Lunarejo', 'Rivera', 29820, 'Quebradas y biodiversidad', 1, 1;
EXEC Administracion.Parque_Insertar 'Parque Nacional Estero de Pelotas', 'Rocha', 2200, 'Aves acuáticas', 1, 1;
EXEC Administracion.Parque_Insertar 'Parque Nacional Laguna de Rocha', 'Rocha', 7200, 'Laguna costera protegida', 1, 1;
EXEC Administracion.Parque_Insertar 'Parque Nacional Quebrada de los Cuervos', 'Treinta y Tres', 4413, 'Quebradas y senderos', 1, 1;
EXEC Administracion.Parque_Insertar 'Parque Nacional Montes del Queguay', 'Paysandú', 20000, 'Bosques ribereños', 1, 1;
EXEC Administracion.Parque_Insertar 'Parque Nacional Humedales del Santa Lucía', 'Canelones', 86500, 'Ecosistema de humedales', 1, 1;
EXEC Administracion.Parque_Insertar 'Parque Nacional Isla de Flores', 'Montevideo', 311, 'Fauna marina e historia', 1, 1;

-- ============================================================================
-- 2. PERSONAL: 20 GUARDAPARQUES Y 20 GUÍAS
-- ============================================================================
-- Resultado Esperado: Se insertan 20 Guardaparques y 20 Guías de manerca correcta.
DECLARE @i INT = 1;
DECLARE @IdHabilitacion INT;
DECLARE @IdAsignacion INT;
DECLARE @IdParqueLoop INT;
DECLARE @DNI INT;
DECLARE @Nombre VARCHAR(128);

WHILE @i <= 20
BEGIN
    SET @IdParqueLoop = ((@i - 1) % 10) + 1;

    SET @DNI = 10000000 + @i;
    SET @Nombre = 'Guardaparque Generico ' + CAST(@i AS VARCHAR);
    
    EXEC Administracion.Habilitacion_Insertar 'Guardaparque Nivel', '2025-01-01', '2028-01-01', @IdHabilitacion OUTPUT;
    EXEC Administracion.AsignacionParque_Insertar @IdParqueLoop, '2025-02-01', NULL, NULL, @IdAsignacion OUTPUT;
    EXEC Administracion.Personal_Insertar @Nombre, @DNI, '1990-01-01', 'gp@parques.gob.ar', 11111111, 'Guardaparques', 1, @IdHabilitacion, @IdAsignacion;

    SET @DNI = 20000000 + @i;
    SET @Nombre = 'Guia Generico ' + CAST(@i AS VARCHAR);
    
    EXEC Administracion.Habilitacion_Insertar 'Guia Turistico', '2025-01-01', '2028-01-01', @IdHabilitacion OUTPUT;
    EXEC Administracion.AsignacionParque_Insertar @IdParqueLoop, '2025-02-01', NULL, NULL, @IdAsignacion OUTPUT;
    EXEC Administracion.Personal_Insertar @Nombre, @DNI, '1992-01-01', 'guia@parques.gob.ar', 22222222, 'Guia', 1, @IdHabilitacion, @IdAsignacion;

    SET @i = @i + 1;
END
GO

-- ============================================================================
-- 3. ACTIVIDADES/TOURS (Mínimo 30)
-- ============================================================================
-- Resultado Esperado: Se generan 30 actividades correctamente.

DECLARE @j INT = 1;
DECLARE @IdActividadGen INT;
DECLARE @IdParqueLoop INT;
DECLARE @NombreAct VARCHAR(150);

WHILE @j <= 30
BEGIN
    SET @IdParqueLoop = ((@j - 1) % 10) + 1;
    SET @NombreAct = 'Actividad/Tour Genérico ' + CAST(@j AS VARCHAR);
    
    EXEC Administracion.Actividad_Insertar 
        @IdParque = @IdParqueLoop, 
        @Nombre = @NombreAct, 
        @Tipo = 'Tour Ecoturismo', 
        @Descripcion = 'Recorrido guiado estándar', 
        @Costo = 5000.00, 
        @DuracionMinutos = 120, 
        @CupoMaximo = 20, 
        @EsActivo = 1, 
        @IdActividad = @IdActividadGen OUTPUT;

    SET @j = @j + 1;
END
GO

-- ============================================================================
-- 4. CONCESIONES (Mínimo 10) Y CASO OBLIGATORIO: VIGENTE Y VENCIDA
-- ============================================================================
-- Resultado Esperado: Se insertan 10 empresas y 10 concesiones correctamente. 
DECLARE @IdConcesionGen INT;

-- Generación de 10 Empresas
EXEC Administracion.EmpresaConcesionaria_Insertar 30111111, 'Andes Outdoor S.A.', 'contacto@andes.com', 44441111;
EXEC Administracion.EmpresaConcesionaria_Insertar 30222222, 'Iguazu Falls Travels', 'info@iguazutravel.com', 44442222;
EXEC Administracion.EmpresaConcesionaria_Insertar 30333333, 'Patagonia Trekking SRL', 'ventas@patagonia.com', 44443333;
EXEC Administracion.EmpresaConcesionaria_Insertar 30444444, 'Servicios Lacustres', 'lacustres@sur.com', 44444444;
EXEC Administracion.EmpresaConcesionaria_Insertar 30555555, 'Aventura y Tradicion', 'info@aventura.com', 44445555;
EXEC Administracion.EmpresaConcesionaria_Insertar 30666666, 'Norte Extremo', 'norte@extremo.com', 44446666;
EXEC Administracion.EmpresaConcesionaria_Insertar 30777777, 'Cuyo Expediciones', 'cuyo@exp.com', 44447777;
EXEC Administracion.EmpresaConcesionaria_Insertar 30888888, 'Eco Resto Parques', 'resto@eco.com', 44448888;
EXEC Administracion.EmpresaConcesionaria_Insertar 30999999, 'Souvenirs Naturales', 'souvenir@nat.com', 44449999;
EXEC Administracion.EmpresaConcesionaria_Insertar 30101010, 'Empresa Quebrada SA', 'quebrada@sa.com', 44441010;

-- Asignación de las 10 Concesiones
EXEC Administracion.Concesion_Insertar 30111111, 1, 'Guiado', '2026-01-01', '2029-01-01', 150000, 'Vigente', @IdConcesionGen OUTPUT;
EXEC Administracion.Concesion_Insertar 30222222, 2, 'Gomón', '2026-02-15', '2031-02-15', 500000, 'Vigente', @IdConcesionGen OUTPUT;
EXEC Administracion.Concesion_Insertar 30333333, 3, 'Bicicletas', '2026-03-01', '2027-03-01', 80000, 'Vigente', @IdConcesionGen OUTPUT;
EXEC Administracion.Concesion_Insertar 30444444, 4, 'Catamarán', '2026-04-10', '2030-04-10', 650000, 'Vigente', @IdConcesionGen OUTPUT;
EXEC Administracion.Concesion_Insertar 30555555, 5, 'Kiosco', '2024-05-01', '2028-05-01', 120000, 'Vigente', @IdConcesionGen OUTPUT;
EXEC Administracion.Concesion_Insertar 30666666, 6, 'Camping', '2025-01-01', '2030-01-01', 200000, 'Vigente', @IdConcesionGen OUTPUT;
EXEC Administracion.Concesion_Insertar 30777777, 7, 'Restaurante', '2025-06-01', '2035-06-01', 800000, 'Vigente', @IdConcesionGen OUTPUT;
EXEC Administracion.Concesion_Insertar 30888888, 8, 'Tienda', '2026-01-01', '2028-01-01', 150000, 'Vigente', @IdConcesionGen OUTPUT;
EXEC Administracion.Concesion_Insertar 30999999, 9, 'Fotos', '2026-01-01', '2029-01-01', 50000, 'Vigente', @IdConcesionGen OUTPUT;

-- CONCESIÓN VENCIDA
EXEC Administracion.Concesion_Insertar 30101010, 10, 'Heladería', '2020-01-01', '2023-01-01', 90000, 'Vencida', @IdConcesionGen OUTPUT;
GO

-- ============================================================================
-- HISTORIAL DE VENTAS
-- ============================================================================

DECLARE @IdTicket INT;
DECLARE @IdItem INT;
DECLARE @IdActividadCupo INT;
DECLARE @IdActividadSim1 INT;
DECLARE @IdActividadSim2 INT;

-- CASO OBLIGATORIO: UN TOUR CON CUPO COMPLETO
EXEC Administracion.Actividad_Insertar 
    @IdParque = 1, @Nombre = 'Tour VIP Cataratas', @Tipo = 'Especial', 
    @Costo = 20000.00, @DuracionMinutos = 60, @CupoMaximo = 4, @EsActivo = 1, 
    @IdActividad = @IdActividadCupo OUTPUT;

EXEC Facturacion.TicketFactura_Insertar 1, '0001-00000999', 'Boletería VIP', '2026-06-01', 'Tarjeta', 80000.00, @IdTicket OUTPUT;
EXEC Facturacion.TicketItemActividad_Insertar @IdTicket, @IdActividadCupo, 4, '2026-06-15', 20000.00, @IdItem OUTPUT;


-- CASO OBLIGATORIO: UN PARQUE CON MÚLTIPLES ACTIVIDADES SIMULTÁNEAS 
EXEC Administracion.Actividad_Insertar 1, 'Paseo Inferior', 'Caminata', NULL, 3000, 120, 50, 1, @IdActividadSim1 OUTPUT;
EXEC Administracion.Actividad_Insertar 1, 'Paseo Superior', 'Caminata', NULL, 3500, 90, 50, 1, @IdActividadSim2 OUTPUT;

EXEC Facturacion.TicketFactura_Insertar 1, '0001-00001000', 'Boletería 1', '2026-06-01', 'Efectivo', 6500.00, @IdTicket OUTPUT;
EXEC Facturacion.TicketItemActividad_Insertar @IdTicket, @IdActividadSim1, 1, '2026-07-20', 3000.00, @IdItem OUTPUT;
EXEC Facturacion.TicketItemActividad_Insertar @IdTicket, @IdActividadSim2, 1, '2026-07-20', 3500.00, @IdItem OUTPUT;


-- GENERACIÓN DE HISTORIAL DE VENTAS DE ENTRADAS GENERALES
-- múltiples facturas con ítems de entrada variando tipos de visitantes y fechas.
DECLARE @k INT = 1;
WHILE @k <= 10
BEGIN
    DECLARE @NumeroFacturaActual VARCHAR(25) = '0001-0000200' + CAST(@k AS VARCHAR(2));
    EXEC Facturacion.TicketFactura_Insertar 
        @IdParque = 1, 
        @NumeroFactura = @NumeroFacturaActual, 
        @PuntoDeVenta = 'Boletería Web', 
        @FechaEmision = '2026-05-01', 
        @FormaPago = 'Mercado Pago', 
        @Total = 15000.00, 
        @IdTicketFactura = @IdTicket OUTPUT;

    EXEC Facturacion.TicketItemEntrada_Insertar @IdTicket, 1, 2, '2026-05-10', 7500.00, @IdItem OUTPUT;
    
    SET @k = @k + 1;
END
GO

DECLARE @IdPagoGen INT;

EXEC Facturacion.PagoCanon_Insertar 1, 1, 2026, 150000.00, '2026-01-10', 'Pagado', @IdPago = @IdPagoGen OUTPUT;
EXEC Facturacion.PagoCanon_Insertar 1, 2, 2026, 150000.00, '2026-02-09', 'Pagado', @IdPago = @IdPagoGen OUTPUT;
EXEC Facturacion.PagoCanon_Insertar 1, 3, 2026, 150000.00, '2026-03-11', 'Pagado', @IdPago = @IdPagoGen OUTPUT;


EXEC Facturacion.PagoCanon_Insertar 2, 2, 2026, 500000.00, '2026-02-20', 'Pagado', @IdPago = @IdPagoGen OUTPUT;
EXEC Facturacion.PagoCanon_Insertar 2, 3, 2026, 500000.00, '2026-03-15', 'Pagado', @IdPago = @IdPagoGen OUTPUT;


EXEC Facturacion.PagoCanon_Insertar 3, 3, 2026, 80000.00, '2026-03-05', 'Pagado', @IdPago = @IdPagoGen OUTPUT;
EXEC Facturacion.PagoCanon_Insertar 3, 4, 2026, 80000.00, '2026-04-05', 'Pagado', @IdPago = @IdPagoGen OUTPUT;
EXEC Facturacion.PagoCanon_Insertar 3, 5, 2026, 80000.00, '2026-05-15', 'Atrasado', @IdPago = @IdPagoGen OUTPUT; 

EXEC Facturacion.PagoCanon_Insertar 4, 4, 2026, 650000.00, '2026-04-12', 'Pagado', @IdPago = @IdPagoGen OUTPUT;

EXEC Facturacion.PagoCanon_Insertar 5, 4, 2026, 120000.00, '2026-04-10', 'Pagado', @IdPago = @IdPagoGen OUTPUT;
EXEC Facturacion.PagoCanon_Insertar 5, 5, 2026, 120000.00, '2026-05-10', 'Impago', @IdPago = @IdPagoGen OUTPUT; 

EXEC Facturacion.PagoCanon_Insertar 6, 1, 2026, 200000.00, '2026-01-05', 'Pagado', @IdPago = @IdPagoGen OUTPUT;
EXEC Facturacion.PagoCanon_Insertar 6, 2, 2026, 200000.00, '2026-02-05', 'Pagado', @IdPago = @IdPagoGen OUTPUT;


EXEC Facturacion.PagoCanon_Insertar 10, 11, 2022, 90000.00, '2022-11-15', 'Pagado', @IdPago = @IdPagoGen OUTPUT;
EXEC Facturacion.PagoCanon_Insertar 10, 12, 2022, 90000.00, '2022-12-15', 'Pagado', @IdPago = @IdPagoGen OUTPUT;

EXEC Facturacion.PagoCanon_Insertar 10, 1, 2023, 90000.00, '2023-01-10', 'Impago', @IdPago = @IdPagoGen OUTPUT; 
GO


-- Guía asignado a múltiples actividades actualmente
EXEC Administracion.ActividadGuia_Insertar 
    @DniPersonal = 20000001, @IdActividad = 1, @FechaDesde = '2025-03-01', @FechaHasta = NULL;
EXEC Administracion.ActividadGuia_Insertar 
    @DniPersonal = 20000001, @IdActividad = 2, @FechaDesde = '2025-03-01', @FechaHasta = NULL;

-- CASO 2: Múltiples guías para una misma actividad (Muchos a 1)
EXEC Administracion.ActividadGuia_Insertar 
    @DniPersonal = 20000002, @IdActividad = 3, @FechaDesde = '2025-04-01', @FechaHasta = NULL;
EXEC Administracion.ActividadGuia_Insertar 
    @DniPersonal = 20000003, @IdActividad = 3, @FechaDesde = '2025-04-15', @FechaHasta = NULL;
EXEC Administracion.ActividadGuia_Insertar 
    @DniPersonal = 20000004, @IdActividad = 3, @FechaDesde = '2025-05-01', @FechaHasta = NULL;

-- CASO 3: Historial / Asignaciones pasadas (Trazabilidad)
EXEC Administracion.ActividadGuia_Insertar 
    @DniPersonal = 20000005, @IdActividad = 4, @FechaDesde = '2024-01-01', @FechaHasta = '2024-12-31';
EXEC Administracion.ActividadGuia_Insertar 
    @DniPersonal = 20000006, @IdActividad = 5, @FechaDesde = '2024-06-01', @FechaHasta = '2025-01-01';

-- ============================================================================
-- CASO 4: Reasignación temporal del mismo guía
-- ============================================================================
-- El guía 20000007 dio la Actividad 6 hasta fin de año, y al día siguiente empezó con la Actividad 7
EXEC Administracion.ActividadGuia_Insertar 
    @DniPersonal = 20000007, @IdActividad = 6, @FechaDesde = '2024-01-01', @FechaHasta = '2024-12-31';
EXEC Administracion.ActividadGuia_Insertar 
    @DniPersonal = 20000007, @IdActividad = 7, @FechaDesde = '2025-01-01', @FechaHasta = NULL;

-- ============================================================================
-- CASO 5: Asignaciones estándar para cumplir volumen
-- ============================================================================
EXEC Administracion.ActividadGuia_Insertar @DniPersonal = 20000008, @IdActividad = 8, @FechaDesde = '2025-02-01', @FechaHasta = NULL;
EXEC Administracion.ActividadGuia_Insertar @DniPersonal = 20000009, @IdActividad = 9, @FechaDesde = '2025-02-01', @FechaHasta = NULL;
EXEC Administracion.ActividadGuia_Insertar @DniPersonal = 20000010, @IdActividad = 10, @FechaDesde = '2025-02-01', @FechaHasta = NULL;
EXEC Administracion.ActividadGuia_Insertar @DniPersonal = 20000011, @IdActividad = 11, @FechaDesde = '2025-02-01', @FechaHasta = NULL;
EXEC Administracion.ActividadGuia_Insertar @DniPersonal = 20000012, @IdActividad = 12, @FechaDesde = '2025-02-01', @FechaHasta = NULL;
GO

-- ============================================================================
-- IMPORTACIÓN CON ERRORES PARCIALES
-- ============================================================================
/*
    Al ejecutar el SP de importación (ej: ImportarArchivoTarifaCSV) provisto con un 
    archivo CSV que contenga líneas corruptas (por ejemplo, una letra 'A' en la 
    columna de Precio), el uso de TRY_CAST convertirá ese error en NULL, y la 
    validación de lógica de negocio o constraints de la tabla ignorará ese registro 
    (o la consulta descartará nulos), permitiendo que el resto del bloque (BULK INSERT 
    y el Cursor) finalice con éxito e importe el resto de los registros correctos.
*/

/*
================================================================================
    SCRIPT DE TESTING NEGATIVO (VALIDACIONES DE NEGOCIO)
    Objetivo: Demostrar que los SPs rechazan datos inválidos y cumplen con 
    el requisito de mostrar un único mensaje con todos los errores acumulados.
================================================================================
*/

PRINT '--- PRUEBA 1: Insertar un parque con múltiples errores ---';
-- Errores forzados: Nombre vacío, Ubicación vacía, Superficie negativa.
-- Resultado esperado: Un solo RAISERROR indicando los tres problemas.
EXEC Administracion.Parque_Insertar 
    @Nombre = '', 
    @Ubicacion = '   ', 
    @Superficie = -500, 
    @Descripcion = 'Parque Inválido', 
    @IdTipoParque = 1;
GO

PRINT '--- PRUEBA 2: Insertar una actividad con valores ilógicos ---';
-- Errores forzados: Costo negativo, Duración en 0, Cupo negativo.
-- Resultado esperado: RAISERROR acumulando las tres reglas de negocio rotas.
DECLARE @FalloIdActividad INT;
EXEC Administracion.Actividad_Insertar 
    @IdParque = 1, 
    @Nombre = 'Tour de prueba', 
    @Tipo = 'Caminata', 
    @Costo = -1500, 
    @DuracionMinutos = 0, 
    @CupoMaximo = -5, 
    @IdActividad = @FalloIdActividad OUTPUT;
GO

PRINT '--- PRUEBA 3: Insertar una concesión con fechas invertidas y canon inválido ---';
-- Errores forzados: Fecha de inicio es posterior a la fecha de fin, y canon negativo.
DECLARE @FalloIdConcesion INT;
EXEC Administracion.Concesion_Insertar 
    @IdEmpresaConcesionaria = 30111111, 
    @IdParque = 1, 
    @TipoDeActividad = 'Venta de comida', 
    @FechaInicio = '2026-12-01', 
    @FechaFin = '2025-01-01', -- FECHA INVERTIDA
    @Canon = -10000,          -- CANON NEGATIVO
    @Estado = 'Vigente', 
    @IdConcesion = @FalloIdConcesion OUTPUT;
GO

PRINT '--- PRUEBA 4: Venta de Entradas con cantidad y precios inválidos ---';
-- Errores forzados: Intentar vender 0 entradas y a un precio negativo.
DECLARE @FalloIdItemEntrada INT;
EXEC Facturacion.TicketItemEntrada_Insertar 
    @IdTicketFactura = 1, 
    @IdTipoVisitante = 1, 
    @Cantidad = 0, 
    @FechaAcceso = '2026-06-01', 
    @PrecioUnitario = -500, 
    @IdItemEntrada = @FalloIdItemEntrada OUTPUT;
GO

PRINT '--- PRUEBA 5: Intentar eliminar un Tipo de Parque que está en uso ---';
-- Error forzado: Violación de integridad referencial gestionada por lógica.
-- Resultado esperado: El SP valida si existen parques asociados antes de hacer el DELETE.
-- (Asumiendo que el IdTipoParque 1 se usó en el script de carga masiva).
EXEC Administracion.TipoParque_Eliminar @IdTipoParque = 1;
GO

PRINT '--- PRUEBA 6: Duplicidad de Empresa Concesionaria ---';
-- Error forzado: Insertar un CUIT o Razón Social que ya existe.
-- Resultado esperado: El SP frena la inserción indicando que ya existe.
EXEC Administracion.EmpresaConcesionaria_Insertar 
    @CUIT = 30111111, -- Este CUIT ya lo insertamos en el script anterior
    @RazonSocial = 'Otra Empresa Falsa';
GO
