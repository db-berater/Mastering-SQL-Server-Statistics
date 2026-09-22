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

/*
    Check the statistics of the dbo.orders table before we start
*/
SELECT	s.stats_id,
		s.name,
        sc.column_list,
        s.auto_created,
        s.user_created,
        s.no_recompute,
        s.auto_drop
FROM	sys.stats AS s
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
WHERE	s.object_id = OBJECT_ID(N'dbo.orders', N'U');
GO

/* create customer stats object with defaults */
BEGIN
    DROP STATISTICS dbo.orders.stats_orders_o_orderpriority;

    CREATE STATISTICS stats_orders_o_orderpriority
    ON dbo.orders (o_orderpriority);

    SELECT	s.stats_id,
		    s.name,
            sc.column_list,
            s.user_created,
            s.no_recompute,
            s.has_filter,
            s.filter_definition,
            s.has_persisted_sample,
            s.auto_drop
    FROM	sys.stats AS s
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
    WHERE	s.object_id = OBJECT_ID(N'dbo.orders', N'U');
END
GO

/* create customer stats which will NOT automatically updated */
BEGIN
    CREATE STATISTICS stats_orders_o_orderpriority_no_recompute
    ON dbo.orders (o_orderpriority)
    WITH
        NORECOMPUTE;

    SELECT	s.stats_id,
		    s.name,
            sc.column_list,
            s.user_created,
            s.no_recompute,
            s.has_filter,
            s.filter_definition,
            s.has_persisted_sample,
            s.auto_drop
    FROM	sys.stats AS s
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
    WHERE	s.object_id = OBJECT_ID(N'dbo.orders', N'U');
END
GO

/* create customer stats for a dedicated (filtered) value */
BEGIN
    CREATE STATISTICS stats_orders_o_orderpriority_filter
    ON dbo.orders (o_orderpriority)
    WHERE   o_orderpriority = '2-HIGH';

    SELECT	s.stats_id,
		    s.name,
            sc.column_list,
            s.user_created,
            s.no_recompute,
            s.has_filter,
            s.filter_definition,
            s.has_persisted_sample,
            s.auto_drop
    FROM	sys.stats AS s
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
    WHERE	s.object_id = OBJECT_ID(N'dbo.orders', N'U');
END
GO

/* create customer stats for a dedicated (filtered) value */
BEGIN
    CREATE STATISTICS stats_orders_o_orderpriority_sample_30
    ON dbo.orders (o_orderpriority)
    WITH
        SAMPLE 30 PERCENT,
        PERSIST_SAMPLE_PERCENT = ON;

    SELECT	s.stats_id,
		    s.name,
            sc.column_list,
            s.user_created,
            s.no_recompute,
            s.has_filter,
            s.filter_definition,
            s.has_persisted_sample,
            s.auto_drop
    FROM	sys.stats AS s
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
    WHERE	s.object_id = OBJECT_ID(N'dbo.orders', N'U');
END
GO