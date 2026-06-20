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

# Objetivo:
Crear la base de datos ParquesNacionalesDB y los esquemas
utilizados para organizar los objetos del sistema
(Administracion y Facturacion).
Valida la existencia de los objetos antes de crearlos.
*/

-- ============================================================================
-- 1. CREACIÓN DE LA BASE DE DATOS
-- ============================================================================
IF NOT EXISTS (SELECT 1 FROM sys.databases WHERE name = 'ParquesNacionalesDB')
BEGIN
    CREATE DATABASE ParquesNacionalesDB;
END
GO

USE ParquesNacionalesDB;
GO

-- ============================================================================
-- 2. CREACIÓN DE ESQUEMAS
-- ============================================================================


IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'Administracion')
BEGIN
    EXEC('CREATE SCHEMA Administracion');
END
GO


IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'Facturacion')
BEGIN
    EXEC('CREATE SCHEMA Facturacion');
END
GO
