/*
	============================================================================
	File:		02 - auto created statistics objects.sql

	Summary:	This script demonstrates the situation(s) when new statistics
				objects will be created

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

/*
    If a column of a table does not have an index a statistics object
    will be created automatically if the option "AUTO_CREATE_STATISTICS" 
    is set to ON.
*/
SELECT  o_orderdate,
        o_orderkey,
        o_custkey,
        o_orderpriority,
        o_shippriority,
        o_clerk,
        o_orderstatus,
        o_totalprice,
        o_comment,
        o_storekey
FROM		dbo.orders
WHERE	o_custkey = 1302047;
GO

/*
    A new statistics object _WA_Sys_... has been created for the column
    [o_custkey]
*/
SELECT	stats_id,
        name,
        column_list,
        auto_created,
        user_created,
        no_recompute,
        auto_drop
FROM		dbo.get_statistics_information(N'dbo.orders', N'U');
GO

SELECT  o_orderdate,
        o_orderkey,
        o_custkey,
        o_orderpriority,
        o_shippriority,
        o_clerk,
        o_orderstatus,
        o_totalprice,
        o_comment,
        o_storekey
FROM		dbo.orders
WHERE	o_orderdate = '2013-01-01';
GO

/*
    A new statistics object _WA_Sys_... has been created for the column
    [o_orderdate]
*/
SELECT	stats_id,
        name,
        column_list,
        auto_created,
        user_created,
        no_recompute,
        auto_drop
FROM		dbo.get_statistics_information(N'dbo.orders', N'U');
GO

/*
    statistics will be created automatically when using DISTINCT
*/
SELECT	o_orderpriority
FROM		dbo.orders;
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

SELECT  DISTINCT
        o_orderpriority
FROM    dbo.orders;
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

/*
    statistics will NOT be created automatically when using ORDER BY!
*/
SELECT  o_orderdate,
        o_orderkey,
        o_custkey,
        o_orderpriority,
        o_shippriority,
        o_clerk,
        o_orderstatus,
        o_totalprice,
        o_comment,
        o_storekey
FROM    dbo.orders
ORDER BY
        o_clerk ASC;
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

/*
    Remove all auto created statistics from dbo.orders
*/
DECLARE @sql_cmd    NVARCHAR(256);

DECLARE c CURSOR LOCAL FORWARD_ONLY READ_ONLY
FOR
    SELECT  N'DROP STATISTICS [dbo].[orders].' + QUOTENAME(name) + N';'
    FROM    sys.stats AS s
    WHERE   s.object_id = OBJECT_ID(N'dbo.orders', N'U')
            AND s.auto_created = 1;

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

/*
    Be carful when using DISTINCT over all columns!
    SQL Server can create stats objects for each column
    which does not have a stats object.

	???
*/
SELECT  DISTINCT
        o_orderdate,
        o_orderkey,
        o_custkey,
        o_orderpriority,
        o_shippriority,
        o_clerk,
        o_orderstatus,
        o_totalprice,
        o_comment,
        o_storekey
FROM    dbo.orders;
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

/*
    Will create auto stats because there is NO unique
    index/constraint in the table
*/
SELECT  DISTINCT
        c_custkey,
        c_mktsegment,
        c_nationkey,
        c_name,
        c_address,
        c_phone,
        c_acctbal,
        c_comment
FROM    dbo.customers;
GO

SELECT	stats_id,
        name,
        column_list,
        auto_created,
        user_created,
        no_recompute,
        auto_drop
FROM		dbo.get_statistics_information(N'dbo.customers', N'U');
GO

ALTER TABLE dbo.customers
ADD CONSTRAINT pk_customers PRIMARY KEY CLUSTERED (c_custkey)
WITH
(
	DATA_COMPRESSION = PAGE,
	SORT_IN_TEMPDB = ON
);
GO

SELECT	stats_id,
        name,
        column_list,
        auto_created,
        user_created,
        no_recompute,
        auto_drop
FROM		dbo.get_statistics_information(N'dbo.customers', N'U');
GO


/*
    Remove all auto created statistics from dbo.orders
*/
DECLARE @sql_cmd    NVARCHAR(256);

DECLARE c CURSOR LOCAL FORWARD_ONLY READ_ONLY
FOR
    SELECT  N'DROP STATISTICS [dbo].[customers].' + QUOTENAME(name) + N';'
    FROM    sys.stats AS s
    WHERE   s.object_id = OBJECT_ID(N'dbo.customers', N'U')
            AND s.auto_created = 1;

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

ALTER TABLE dbo.customers DROP CONSTRAINT pk_customers;
GO

