/*
	============================================================================
	File:		04 - update stats sampling rate.sql

	Summary:	This script demonstrates the sampling rate of automatic update
                of statistics

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
    This demo shows the sampling rates when it comes to automatic updates
    of statistics.

    For a better performance of the workload we create two indexes on the
    [dbo].[orders] table
    - o_orderkey
    - o_orderdate
*/
EXEC dbo.sp_create_indexes_orders @column_list = N'o_orderkey,o_orderdate';
GO

/* Now we switch to demo_db which holds the table we are inserting new rows */
USE demo_db;
GO

/* Let's create a table for the storage of the stats */
DROP TABLE IF EXISTS dbo.stats_performance_counters;
GO

CREATE TABLE dbo.stats_performance_counters
(
    id                              INT NOT NULL    IDENTITY (1, 1),
    partition_num_rows              INT NOT NULL,
    stats_num_of_rows               INT NOT NULL,
    stats_sample_rate_percent       INT NOT NULL,
    stats_modification_counter      INT NOT NULL,
    stats_required_rows_for_update  INT NOT NULL,

    CONSTRAINT pk_stats_performance_counters PRIMARY KEY CLUSTERED (id)
    WITH
    (
        DATA_COMPRESSION = PAGE
    )
);
GO

/*
    Let's remove all automatic statistics and make sure we have an index
    on [dbo].[orders] (o_orderdate) for the identification of the measures
    for WINDOWS ADMIN CENTER!
*/
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

SELECT	stats_id,
        name,
        column_list,
        auto_created,
        user_created,
        no_recompute,
        auto_drop,
        has_filter,
        filter_definition
FROM		dbo.get_statistics_information(N'dbo.orders', N'U')

UNION ALL

SELECT	stats_id,
        name,
        column_list,
        auto_created,
        user_created,
        no_recompute,
        auto_drop,
        has_filter,
        filter_definition
FROM		dbo.get_statistics_information(N'dbo.customers', N'U')
GO

/*
    Index on o_orderdate for the identification of the stats object
*/
IF NOT EXISTS (SELECT * FROM sys.indexes AS i WHERE i.object_id = OBJECT_ID(N'dbo.orders', N'U') AND i.name = N'nix_orders_o_orderdate')
    CREATE NONCLUSTERED INDEX nix_orders_o_orderdate
    ON dbo.orders (o_orderdate)
    WITH
    (
        DATA_COMPRESSION = PAGE,
        SORT_IN_TEMPDB = ON
    )
ELSE
    ALTER INDEX nix_orders_o_orderdate ON dbo.orders REBUILD
    WITH
    (
        DATA_COMPRESSION = PAGE,
        SORT_IN_TEMPDB = ON
    );
GO

/*
    The next step creates a wrapper stored procedure which should be run
    in SQLQueryStress.
*/
CREATE OR ALTER PROCEDURE dbo.insert_orders
    @start_date DATE = NULL,
    @end_date   DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @last_date_value                DATE = (SELECT DATEADD(DAY, 1, ISNULL(MAX(o_orderdate), '2009-12-31')) FROM dbo.orders);
    DECLARE @partition_num_of_rows          INT;
    DECLARE @stats_num_of_rows              INT;
    DECLARE @stats_modification_counter     INT;
    DECLARE @stats_sample_rate_percent      INT;
    DECLARE @stats_required_rows_for_update INT;

    /*
        If no value is given for the variable @start_date we look
        for the last inserted value in 
    */
    IF @start_date IS NULL OR @start_date < @last_date_value
        SET @start_date = @last_date_value;

    /*
        We check the @end_date, too. If it is NULL we take the last
        possible o_orderdate from ERP_Demo.dbo.orders
    */
    IF @end_date IS NULL
        SET @end_date = (SELECT MAX(o_orderdate) FROM ERP_Demo.dbo.orders);

    /*
        Now we loop through each day and insert new rows into the [dbo].[orders]
        After each loop we check the statistics information and run a simple SELECT
        against the [dbo].[orders]!
    */
    WHILE @start_date <= @end_date
    BEGIN
        /* Insert the rows of the given day into [dbo].[orders] */
        INSERT INTO dbo.orders WITH (TABLOCK)
        (o_orderdate, o_orderkey, o_custkey, o_orderpriority, o_shippriority, o_clerk, o_orderstatus, o_totalprice, o_comment, o_storekey)
        SELECT  o.o_orderdate,
                o.o_orderkey,
                o.o_custkey,
                o.o_orderpriority,
                o.o_shippriority,
                o.o_clerk,
                o.o_orderstatus,
                o.o_totalprice,
                o.o_comment,
                o.o_storekey
        FROM    ERP_Demo.dbo.orders AS o
        WHERE   o.o_orderdate = @start_date;

        /* Check the statistics information */
        SELECT	@partition_num_of_rows          = p.rows,
                @stats_num_of_rows              = ISNULL(sp.rows, p.rows),
                @stats_sample_rate_percent      = CAST (ISNULL(sp.rows_sampled * 100.0 / sp.rows, 0) AS INT),
                @stats_modification_counter     = ISNULL(sp.modification_counter, 0),
		        @stats_required_rows_for_update = CAST(SQRT(ISNULL(sp.rows, 0) * 1000) AS INT)
        FROM		sys.partitions AS p
		        INNER JOIN sys.indexes AS i
		        ON
		        (
			        p.object_id = i.object_id
			        AND p.index_id = i.index_id
		        )
		        INNER JOIN sys.stats AS s
		        ON
		        (
			        i.object_id = s.object_id
			        AND i.index_id = s.stats_id
		        )
		        OUTER APPLY sys.dm_db_stats_properties(s.object_id, s.stats_id) AS sp
        WHERE	p.object_id = OBJECT_ID(N'dbo.orders', N'U')
		        AND i.name = N'nix_orders_o_orderdate';

        INSERT INTO dbo.stats_performance_counters
        (
            partition_num_rows,
            stats_num_of_rows,
            stats_sample_rate_percent,
            stats_modification_counter,
            stats_required_rows_for_update
        )
        SELECT  @partition_num_of_rows,
                @stats_num_of_rows,
                @stats_sample_rate_percent,
                @stats_modification_counter,
                @stats_required_rows_for_update;

        DBCC SETINSTANCE('SQLServer:User Settable', 'Query', 'User counter 1', @partition_num_of_rows);
        DBCC SETINSTANCE('SQLServer:User Settable', 'Query', 'User counter 2', @stats_num_of_rows);
        DBCC SETINSTANCE('SQLServer:User Settable', 'Query', 'User counter 3', @stats_sample_rate_percent);
        DBCC SETINSTANCE('SQLServer:User Settable', 'Query', 'User counter 4', @stats_modification_counter);
        DBCC SETINSTANCE('SQLServer:User Settable', 'Query', 'User counter 5', @stats_required_rows_for_update);

        /*
            Run a query against the data by using the latest inserted date to - eventually - force
            an update on the stats object!
        */
        SELECT  @partition_num_of_rows = COUNT_BIG(*)
        FROM    dbo.orders
        WHERE   o_orderdate = @start_date
        OPTION  (RECOMPILE);

        SET @start_date = DATEADD(DAY, 1, @start_date);
    END

    SELECT  id,
            partition_num_rows,
            stats_num_of_rows,
            stats_sample_rate_percent,
            stats_modification_counter,
            stats_required_rows_for_update
    FROM    dbo.stats_performance_counters
    ORDER BY
            id;
END
GO

EXEC master..sp_reset_counters
    @clear_wait_stats = 0,
    @clear_user_counters = 1;
GO

TRUNCATE TABLE dbo.orders;
GO

UPDATE STATISTICS dbo.orders WITH FULLSCAN;
GO

EXEC dbo.insert_orders
    @start_date = NULL,
    @end_date = '2010-12-31';
GO
