/*
	============================================================================
	File:		00 - preparation.sql

	Summary:	This script prepares the environment for the statistics topic
				
				THIS SCRIPT IS PART OF THE TRACK:
					"Workshop - Mastering SQL Server Statistics"

	Version:	1.00.000

	Date:		October 2025
	Revion:		October 2025

	SQL Server Version: >= 2016
	============================================================================
*/
SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

/* Create a table with ~6.500 rows in the demo database */
RAISERROR ('Creating table [dbo].[orders] in [demo_db]', 0, 1) WITH NOWAIT;

;WITH l
AS
(
	SELECT	MIN(o_orderdate)		AS	o_orderdate
	FROM		ERP_Demo.dbo.orders
)
SELECT	o.o_orderdate,
        o.o_orderkey,
        o.o_custkey,
        o.o_orderpriority,
        o.o_shippriority,
        o.o_clerk,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_comment,
        o.o_storekey
INTO		demo_db.dbo.orders
FROM		ERP_Demo.dbo.orders AS o
		INNER JOIN l
		ON (o.o_orderdate = l.o_orderdate)
GO

RAISERROR ('Creating table [dbo].[customers] in [demo_db]', 0, 1) WITH NOWAIT;
SELECT	c_custkey,
        c_mktsegment,
        c_nationkey,
        c_name,
        c_address,
        c_phone,
        c_acctbal,
        c_comment
INTO		demo_db.dbo.customers
FROM		ERP_Demo.dbo.customers;
GO

RAISERROR ('Creating table [dbo].[nations] in [demo_db]', 0, 1) WITH NOWAIT;
SELECT	*
INTO		demo_db.dbo.nations
FROM		ERP_Demo.dbo.nations;
GO

RAISERROR ('Creating PRIMARY KEY (clustered) on [dbo].[orders] in database [demo_db]', 0, 1) WITH NOWAIT;
ALTER TABLE demo_db.dbo.orders
ADD CONSTRAINT pk_orders
PRIMARY KEY CLUSTERED (o_orderkey);
GO

/*
	Creating an UDF for the analysis of the statistics
*/
USE demo_db;
GO

RAISERROR ('Creating function [dbo].[get_statistics_information] in [demo_db]', 0, 1) WITH NOWAIT;
GO

CREATE OR ALTER FUNCTION dbo.get_statistics_information
(
	@object_name NVARCHAR(128),
	@object_type NVARCHAR(5) = N'U'
)
RETURNS TABLE
AS
RETURN
(
	SELECT	s.stats_id,
		    s.name,
            sc.column_list,
            s.auto_created,
            s.user_created,
            s.no_recompute,
            s.auto_drop,
			s.has_persisted_sample,
			s.has_filter,
			s.filter_definition
    FROM		sys.stats AS s
            CROSS APPLY
            (
                SELECT  STRING_AGG(c.name, ',')    AS  column_list
                FROM    sys.stats_columns AS sc
                        INNER JOIN sys.columns AS c
                        ON
                        (
                            sc.object_id = c.object_id
                            AND sc.column_id  = c.column_id
                        )
                WHERE   s.object_id = sc.object_id
                        AND s.stats_id = sc.stats_id
            ) AS sc
    WHERE	s.object_id = OBJECT_ID(@object_name, @object_type)
);
GO

USE master;
GO