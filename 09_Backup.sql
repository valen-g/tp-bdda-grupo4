/*

# Universidad: Universidad Nacional de La Matanza
# Materia: 3641 - Bases de Datos Aplicada
# Grupo: Grupo 4
# Integrantes:
- Belloni, Nicolas
- Bernardo, Ivan
- Gonzalez, Agustin
- Gallo, Valentina

# Fecha: 27/06/2026

# Objetivo:
Crear SPs para realizar el backup y el restore de la base de datos.

*/

/**
    REQUISITO:
    La carpeta C:\Backups debe existir y el servicio de SQL Server
    debe tener permisos de escritura sobre ella.
**/


USE ParquesNacionalesDB;
GO

CREATE OR ALTER PROCEDURE Administracion.RealizarBackup
AS
BEGIN

    BACKUP DATABASE ParquesNacionalesDB
    TO DISK = 'C:\Backups\ParquesNacionalesDB.bak'
    WITH
        INIT,
        NAME = 'Backup Completo ParquesNacionalesDB',
        DESCRIPTION = 'Respaldo generado mediante Stored Procedure',
        STATS = 10;

END
GO

--Para restaurar la bdd

USE master;
GO

ALTER DATABASE ParquesNacionalesDB
SET SINGLE_USER
WITH ROLLBACK IMMEDIATE;
GO

RESTORE DATABASE ParquesNacionalesDB
FROM DISK = 'C:\Backups\ParquesNacionalesDB.bak'
WITH REPLACE, STATS = 10;
GO

ALTER DATABASE ParquesNacionalesDB
SET MULTI_USER;
GO

