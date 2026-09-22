/*
	============================================================================
	File:		01 - Update Statistics and Trivial Plans.sql

	Summary:	This script demonstrates the AUTO_UPDATE_STATS behavior if the
				query is compiled as a Trivial Plan.

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

/* Let's first remove all statistics from the table [dbo].[customers] */
EXEC dbo.sp_drop_indexes
	@table_name = N'ALL',
    @check_only = 0;
GO

EXEC dbo.sp_drop_statistics
	@table_name = N'ALL',
    @check_only = 0;
GO

/*
	Now we create on every column in dbo.customers an auto created 
	statistics object!
*/
BEGIN
    SELECT	DISTINCT
		    c_custkey,
            c_mktsegment,
            c_nationkey,
            c_name,
            c_address,
            c_phone,
            c_acctbal,
            c_comment
    FROM	dbo.customers;

    UPDATE STATISTICS dbo.customers WITH FULLSCAN;

    SELECT	object_id,
            stats_id,
            stats_name,
            auto_created,
            has_filter,
            no_recompute,
            stats_columns,
            stats_rows,
            stats_sampled_rows,
            sample_quote
    FROM	dbo.get_statistics_columns_info(N'dbo.customers', N'U');
END
GO

/*
    Now we execute the same query with different parameter values to 
    check the underlying execution plans
*/
DBCC FREEPROCCACHE;
GO

SELECT  c_custkey,
        c_mktsegment,
        c_nationkey,
        c_name,
        c_address,
        c_phone,
        c_acctbal,
        c_comment
FROM    dbo.customers
WHERE   c_nationkey = 0
ORDER BY
        c_custkey;
GO
 
SELECT  c_custkey,
        c_mktsegment,
        c_nationkey,
        c_name,
        c_address,
        c_phone,
        c_acctbal,
        c_comment
FROM    dbo.customers
WHERE   c_nationkey = 1
ORDER BY
        c_custkey;
 
/* Get an inside into the cached plans! */
SELECT  CP.usecounts,
        CP.cacheobjtype,
        CP.objtype,
        CP.size_in_bytes,
        ST.[text],
        QP.query_plan
FROM    sys.dm_exec_cached_plans AS CP
        OUTER APPLY sys.dm_exec_sql_text (CP.plan_handle) AS ST
        OUTER APPLY sys.dm_exec_query_plan (CP.plan_handle) AS QP
WHERE   ST.[text] NOT LIKE '%dm_exec_cached_plans%'
        AND ST.[text] LIKE '%customers%'
ORDER BY
        CP.usecounts ASC;
GO