/*
	============================================================================
	File:		07 - clean the environment.sql

	Summary:		This script removes all indexes and stats on the demo objects
				- dbo.customers
				- dbo.orders
				- dbo.nations

				THIS SCRIPT IS PART OF THE TRACK:
					"Workshop - Mastering SQL Server Statistics"

	Version:		1.00.000

	Date:		October 2025
	Revion:		October 2025

	SQL Server Version: >= 2016
	============================================================================
*/
SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

USE demo_db;
GO

/*
	1. Remove all indexes from the tables
*/
DECLARE	@exec_stmt	NVARCHAR(MAX);

DECLARE	c CURSOR LOCAL FORWARD_ONLY READ_ONLY
FOR
	SELECT	CASE WHEN i.is_primary_key = 1
				 THEN N'ALTER TABLE [dbo].' + QUOTENAME(OBJECT_NAME(i.object_id)) + N'
	DROP CONSTRAINT ' + QUOTENAME(i.name) + N';'
				 ELSE N'DROP INDEX ' + QUOTENAME(i.name) + N' ON [dbo].' + QUOTENAME(OBJECT_NAME(i.object_id))
			END
	FROM		sys.indexes AS i
	WHERE	i.index_id > 0
			AND i.object_id IN
			(
				OBJECT_ID(N'dbo.customers', N'U'),
				OBJECT_ID(N'dbo.orders', N'U'),
				OBJECT_ID(N'dbo.nations', N'U')
			);

OPEN c;

FETCH NEXT FROM c INTO @exec_stmt;
WHILE @@FETCH_STATUS <> -1
BEGIN
    PRINT @exec_stmt;
	EXEC sp_executesql @exec_stmt;
	FETCH NEXT FROM c INTO @exec_stmt;
END

CLOSE c;
DEALLOCATE c;
GO

/*
	2. Remove all statistics from the tables
*/
DECLARE @exec_stmt    NVARCHAR(MAX);

DECLARE c CURSOR LOCAL FORWARD_ONLY READ_ONLY
FOR
    SELECT  N'DROP STATISTICS [dbo].' + QUOTENAME(OBJECT_NAME(s.object_id)) + '.' + QUOTENAME(name) + N';'
    FROM    sys.stats AS s
    WHERE   s.object_id IN
			(
				OBJECT_ID(N'dbo.orders', N'U'),
				OBJECT_ID(N'dbo.customers', N'U'),
				OBJECT_ID(N'dbo.nations', N'U')
			);

OPEN c;

FETCH NEXT FROM c INTO @exec_stmt
WHILE @@FETCH_STATUS <> -1
BEGIN
    PRINT @exec_stmt;
    EXEC sp_executesql @exec_stmt;

    FETCH NEXT FROM c INTO @exec_stmt;
END

CLOSE c;
DEALLOCATE c;
GO