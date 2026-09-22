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

USE ERP_Demo;
GO

/*
	Let's create a database first for the storage of data

	Note:	Procedures / Functions are elements of the framework of
			the demo database ERP_Demo.
*/
RAISERROR ('Creating database [demo_db]', 0, 1) WITH NOWAIT;

EXEC dbo.sp_create_demo_db
	@num_of_files = 1,
    @initial_size_MB = 1024,
    @use_filegroups = 0;
GO

/* Create a table with ~6.500 rows in the demo database */
RAISERROR ('Creating table [dbo].[orders] in [demo_db]', 0, 1) WITH NOWAIT;

;WITH l
AS
(
	SELECT	MIN(o_orderdate)	AS	o_orderdate
	FROM	ERP_Demo.dbo.orders
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
INTO	demo_db.dbo.orders
FROM	ERP_Demo.dbo.orders AS o
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
INTO	demo_db.dbo.customers
FROM	ERP_Demo.dbo.customers;
GO

RAISERROR ('Creating PRIMARY KEY (clustered) on [dbo].[orders] in database [demo_db]', 0, 1) WITH NOWAIT;

ALTER TABLE demo_db.dbo.orders
ADD CONSTRAINT pk_orders
PRIMARY KEY CLUSTERED (o_orderkey);
GO