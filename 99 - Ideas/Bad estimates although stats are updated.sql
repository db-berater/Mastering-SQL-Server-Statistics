USE ERP_Demo;
GO

EXEC dbo.sp_create_demo_schema;
GO

DROP TABLE IF EXISTS demo.orders;
GO

CREATE TABLE demo.orders
(
	o_orderkey		BIGINT		NOT NULL,
	o_orderpriority	CHAR(15)		NOT NULL,
	o_orderdate		DATE			NOT NULL,

	CONSTRAINT pk_demo_orders PRIMARY KEY CLUSTERED
	(o_orderkey)
);
GO

CREATE NONCLUSTERED INDEX nix_demo_orders_o_orderpriority_o_orderdate
ON demo.orders (o_orderpriority, o_orderdate);
GO

/*
	Insert data from 2024 into the table and update stats
*/
INSERT INTO demo.orders WITH (TABLOCK)
(o_orderkey, o_orderpriority, o_orderdate)
SELECT	o_orderkey,
		o_orderpriority,
		o_orderdate
FROM		dbo.orders
WHERE	o_orderdate >= '2024-01-01'
		AND o_orderdate <= '2024-12-31';
GO

/*
	Update statistics to have fresh new data
*/
UPDATE STATISTICS demo.orders WITH FULLSCAN;
GO

DBCC SHOW_STATISTICS(N'demo.orders', N'nix_demo_orders_o_orderpriority_o_orderdate');
DBCC SHOW_STATISTICS(N'demo.orders', N'_WA_Sys_00000003_23E931E9');
GO

/*
	Check the execution plan of the query with updated stats!
*/
ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;
GO

SELECT	*
FROM		demo.orders AS o
WHERE	o.o_orderpriority = '1-URGENT'
		AND o_orderdate >= '2024-01-01'
ORDER BY
		o_orderdate
OPTION	(RECOMPILE);
GO

/*
	See the actual stats of all indexes
*/
SELECT	statistics_name,
        stats_id,
        last_updated,
        rows,
        rows_sampled,
        sample_percentage,
        steps,
        modification_counter,
        required_update_rows
FROM		dbo.get_statistics_threshold_info
(
	OBJECT_ID(N'demo.orders',N'U'),
	NULL,
	1
);
GO

/*
	We insert 40.000 new rows to prevent automatic stats updates
*/

/*
	Now we insert another 40,000 rows to prevent and automatic update of stats!
*/
INSERT INTO demo.orders WITH (TABLOCK)
(o_orderkey, o_orderpriority, o_orderdate)
SELECT	TOP (40000)
		o_orderkey,
		o_orderpriority,
		o_orderdate
FROM		dbo.orders
WHERE	o_orderdate >= '2025-01-01'
		AND o_orderdate <= '2025-12-31'
		AND o_orderpriority = '1-URGENT';
GO

SELECT	statistics_name,
        stats_id,
        last_updated,
        rows,
        rows_sampled,
        sample_percentage,
        steps,
        modification_counter,
        required_update_rows
FROM		dbo.get_statistics_threshold_info
(
	OBJECT_ID(N'demo.orders',N'U'),
	NULL,
	1
);
GO

SELECT	*
FROM		demo.orders AS o
WHERE	o.o_orderpriority = '1-URGENT'
		AND o_orderdate >= '2025-01-01'
OPTION	(RECOMPILE);
GO