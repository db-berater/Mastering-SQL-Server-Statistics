/*
	============================================================================
	File:		04 - manual created statistics.sql

	Summary:	This script demonstrates the creation of manual statistics

				THIS SCRIPT IS PART OF THE TRACK:
					"Workshop - Improve your DBA Skills"

	Version:	1.00.000

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

/* what statistics do we have in the table [dbo].[orders]? */
SELECT	stats_id,
        name,
        column_list,
        auto_created,
        user_created,
        no_recompute,
        auto_drop
FROM		dbo.get_statistics_information(N'dbo.orders', N'U');
GO

/* create orders stats object on o_orderpriority */
CREATE STATISTICS stats_orders_o_orderpriority
ON dbo.orders (o_orderpriority);
GO

SELECT	stats_id,
        name,
        column_list,
        auto_created,
        user_created,
        no_recompute,
        auto_drop
FROM		dbo.get_statistics_information(N'dbo.orders', N'U');
GO


/* create custom stats which will NOT automatically updated */
CREATE STATISTICS stats_orders_o_orderpriority_no_recompute
ON dbo.orders (o_orderpriority)
WITH
    NORECOMPUTE;
GO

SELECT	stats_id,
        name,
        column_list,
        auto_created,
        user_created,
        no_recompute,
        auto_drop
FROM		dbo.get_statistics_information(N'dbo.orders', N'U');
GO

/* create custom stats for a dedicated (filtered) value */
CREATE STATISTICS stats_orders_o_orderpriority_filter
ON dbo.orders (o_orderpriority)
WHERE   o_orderpriority = '2-HIGH';
GO

SELECT	stats_id,
        name,
        column_list,
        auto_created,
        user_created,
        no_recompute,
        auto_drop,
		has_filter,
		filter_definition
FROM		dbo.get_statistics_information(N'dbo.orders', N'U');
GO

/* create customer stats for a specific sample rate */
CREATE STATISTICS stats_orders_o_orderpriority_sample_30
ON dbo.orders (o_orderpriority)
WITH
    SAMPLE 30 PERCENT,
    PERSIST_SAMPLE_PERCENT = ON;
GO

SELECT	stats_id,
		name,
        column_list,
        user_created,
        no_recompute,
        has_filter,
		has_persisted_sample,
        auto_drop
FROM		dbo.get_statistics_information(N'dbo.orders', N'U');
GO

/*
    Remove all user created statistics from dbo.orders
*/
DECLARE @sql_cmd    NVARCHAR(256);

DECLARE c CURSOR LOCAL FORWARD_ONLY READ_ONLY
FOR
    SELECT  N'DROP STATISTICS [dbo].[orders].' + QUOTENAME(name) + N';'
    FROM    sys.stats AS s
    WHERE   s.object_id = OBJECT_ID(N'dbo.orders', N'U')
            AND s.user_created = 1;

OPEN c;

FETCH NEXT FROM c INTO @sql_cmd
WHILE @@FETCH_STATUS <> -1
BEGIN
    PRINT @sql_cmd;
    EXEC sp_executesql @sql_cmd;

    FETCH NEXT FROM c INTO @sql_cmd;
END

CLOSE c;
DEALLOCATE c;
GO
