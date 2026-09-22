/*
	============================================================================
	File:		03 - index created statistics objects.sql

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

/* what statistics do we have in an initial table? */
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
WHERE	s.object_id = OBJECT_ID(N'dbo.customers', N'U');
GO

/*
    If there is an existing auto created statistics object in the 
    database it will NOT be deleted if you create an index afterwards!
*/
BEGIN
    ALTER TABLE dbo.customers ADD CONSTRAINT pk_customers
    PRIMARY KEY CLUSTERED (c_custkey);

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
    WHERE	s.object_id = OBJECT_ID(N'dbo.customers', N'U');
END
GO

/*
    After the implementation of an index the statistics have
    a sample rate of 100%
*/
SELECT  s.name,
        p.object_id,
        p.stats_id,
        p.last_updated,
        p.rows,
        p.rows_sampled,
        p.rows_sampled * 100 / p.rows   AS  sample_rate,
        p.steps,
        p.unfiltered_rows,
        p.modification_counter,
        p.persisted_sample_percent
FROM    sys.stats AS s
        CROSS APPLY sys.dm_db_stats_properties(s.object_id, s.stats_id) AS p
WHERE   s.object_id = OBJECT_ID(N'dbo.customers', N'U');
GO

/* We create an index on c_nationkey on dbo.customers */
BEGIN
    CREATE NONCLUSTERED INDEX nix_customers_c_nationkey
    ON dbo.customers (c_nationkey);

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
    WHERE	s.object_id = OBJECT_ID(N'dbo.customers', N'U');
END
GO

/*
    Let's remove all auto stats objects from the table
*/
BEGIN
    DECLARE @sql_cmd NVARCHAR(MAX);

    DECLARE c CURSOR LOCAL READ_ONLY FORWARD_ONLY
    FOR
        SELECT  N'DROP STATISTICS dbo.' + QUOTENAME(t.name) + N'.' + QUOTENAME(s.name)
        FROM    sys.tables AS t
                INNER JOIN sys.stats AS s
                ON (t.object_id = s.object_id)
        WHERE	(
                    s.object_id = OBJECT_ID(N'dbo.orders', N'U')
                    OR s.object_id = OBJECT_ID(N'dbo.customers', N'U')
                )
                AND s.auto_created = 1;

    OPEN c;
    FETCH NEXT FROM c INTO @sql_cmd;
    WHILE @@FETCH_STATUS <> -1
    BEGIN
        EXEC sp_executesql @sql_cmd;
        FETCH NEXT FROM c INTO @sql_cmd;
    END

    CLOSE c;
    DEALLOCATE c;

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
    WHERE	(
                s.object_id = OBJECT_ID(N'dbo.orders', N'U')
                OR s.object_id = OBJECT_ID(N'dbo.customers', N'U')
            );
END
GO