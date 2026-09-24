/*
	============================================================================
	File:		01 - filtered stats and variables.sql

	Summary:		This script demonstrates the negative impact of filtered indexes
				when you work with parameterized queries.

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

USE demo_db;
GO

DROP TABLE IF EXISTS dbo.customers;
DROP TABLE IF EXISTS dbo.orders;
DROP TABLE IF EXISTS dbo.nations;
GO

/*
	Let's create the demo tables first!
	- dbo.customers	(1.6 mio rows)
	- dbo.nations	(47 rows)
*/
SELECT	c_custkey,
        c_mktsegment,
        c_nationkey,
        c_name,
        c_address,
        c_phone,
        c_acctbal,
        c_comment
INTO		dbo.customers
FROM		ERP_Demo.dbo.customers;
GO

SELECT	n_nationkey,
        n_name,
        n_regionkey,
        n_comment
INTO		dbo.nations
FROM		ERP_Demo.dbo.nations;
GO

/*
	Let's create all necessary indexes and foreign key relations
*/
ALTER TABLE dbo.nations ADD CONSTRAINT pk_nations PRIMARY KEY CLUSTERED (n_nationkey);
ALTER TABLE dbo.customers ADD CONSTRAINT pk_customers PRIMARY KEY CLUSTERED (c_custkey);
CREATE NONCLUSTERED INDEX nix_customers_c_nationkey ON dbo.customers (c_nationkey);
ALTER TABLE dbo.customers ADD CONSTRAINT fk_nations_n_nationkey
FOREIGN KEY (c_nationkey) REFERENCES dbo.nations (n_nationkey);
GO

/*
	After the preparation is finished we can start with the demos
*/
SELECT	c.c_custkey,
		c.c_name,
		c.c_nationkey,
		n.n_name
FROM		dbo.customers AS c
		INNER JOIN dbo.nations AS n
		ON (c.c_nationkey = n.n_nationkey)
WHERE	n.n_nationkey = 44	/* Portugal */
ORDER BY
		c.c_name
OPTION	(QUERYTRACEON 9130, MAXDOP 1); /* make pushdown/residual predicates visible */
GO

/*
	The above way is not the typical way to examine data.
	Basically we know the country name but not it's primary key value!
*/
SELECT	c.c_custkey,
		c.c_name,
		c.c_nationkey,
		n.n_name
FROM		dbo.customers AS c
		INNER JOIN dbo.nations AS n
		ON (c.c_nationkey = n.n_nationkey)
WHERE	n.n_name = 'Portugal'
ORDER BY
		c.c_name
OPTION	(QUERYTRACEON 9130, MAXDOP 1);	 /* make pushdown/residual predicates visible */
GO

/*
	Analyse the problem!
	Q: What does SQL Server know about "Portugal"?
	Q: Can we elaborate the information from the statistics?
	Q: How does it impact the search in dbo.customers?
*/
SELECT	DISTINCT
		s.stats_id,
		s.name
FROM		sys.stats AS s
		CROSS APPLY sys.dm_db_stats_histogram
		(
			s.object_id,
			s.stats_id
		) AS h
WHERE	s.object_id = OBJECT_ID(N'dbo.nations');
GO

SELECT	h.step_number,
        h.range_high_key,
        h.range_rows,
        h.equal_rows,
        h.distinct_range_rows,
        h.average_range_rows
FROM		sys.stats AS s
		CROSS APPLY sys.dm_db_stats_histogram
		(
			s.object_id,
			2
		) AS h
WHERE	s.object_id = OBJECT_ID(N'dbo.nations');
GO

SELECT	c.c_custkey,
		c.c_name,
		c.c_nationkey,
		n.n_name
FROM		dbo.customers AS c
		INNER JOIN dbo.nations AS n
		ON (c.c_nationkey = n.n_nationkey)
WHERE	n.n_name = 'Portugal'
ORDER BY
		c.c_name
OPTION	(QUERYTRACEON 9130, MAXDOP 1);	 /* make pushdown/residual predicates visible */
GO

/*
	Analyse the estimates from dbo.customers: 32,815
*/
SELECT	s.name,
		h.step_number,
        h.range_high_key,
        h.range_rows,
        h.equal_rows,
        h.distinct_range_rows,
        h.average_range_rows
FROM		sys.stats AS s
		INNER JOIN sys.indexes AS i
		ON 
		(
			s.object_id = i.object_id
			AND s.stats_id = i.index_id
		)
		CROSS APPLY sys.dm_db_stats_histogram
		(
			i.object_id,
			i.index_id
		) AS h
WHERE	s.object_id = OBJECT_ID(N'dbo.customers')
		AND i.name = N'nix_customers_c_nationkey';
GO

/*
	We do not know the c_nationkey!!!
*/
DBCC SHOW_STATISTICS(N'dbo.customers', N'nix_customers_c_nationkey') WITH DENSITY_VECTOR;
GO

/* Distribution key: 0,02040816 */
SELECT	CAST(COUNT_BIG(*) * 0.02040816 AS BIGINT)	AS	avg_num_rows
FROM		dbo.customers;
GO

/* Do you remember this value? */
SELECT	c.c_custkey,
		c.c_name,
		c.c_nationkey,
		n.n_name
FROM		dbo.customers AS c
		INNER JOIN dbo.nations AS n
		ON (c.c_nationkey = n.n_nationkey)
WHERE	n.n_name = 'Portugal'
ORDER BY
		c.c_name
OPTION	(QUERYTRACEON 9130, MAXDOP 1);	 /* make pushdown/residual predicates visible */
GO

/*
	Q: How can we SQL Server let know the n_nationkey?
	A: Can an index help?
*/
CREATE UNIQUE NONCLUSTERED INDEX nix_nations_n_name
ON dbo.nations(n_name);
GO

SELECT	c.c_custkey,
		c.c_name,
		c.c_nationkey,
		n.n_name
FROM		dbo.customers AS c
		INNER JOIN dbo.nations AS n
		ON (c.c_nationkey = n.n_nationkey)
WHERE	n.n_name = 'Portugal'
ORDER BY
		c.c_name
OPTION	(QUERYTRACEON 9130, MAXDOP 1);	 /* make pushdown/residual predicates visible */
GO

/*
	Q: May a user defined FILTERED stats object help?
*/
CREATE STATISTICS nations_portugal ON dbo.nations (n_nationkey) WHERE n_name = 'PORTUGAL';
GO

SELECT	c.c_custkey,
		c.c_name,
		c.c_nationkey,
		n.n_name
FROM		dbo.customers AS c
		INNER JOIN dbo.nations AS n
		ON (c.c_nationkey = n.n_nationkey)
WHERE	n.n_name = 'Portugal'
ORDER BY
		c.c_name
OPTION	(QUERYTRACEON 9130, MAXDOP 1, RECOMPILE);	 /* make pushdown/residual predicates visible */
GO

/*
	Clean the environment!
*/
DROP TABLE IF EXISTS dbo.customers;
DROP TABLE IF EXISTS dbo.nations;
GO
