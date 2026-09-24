/*
	============================================================================
	File:		01 - statistics and parameterized queries.sql

	Summary:		This script demonstrates the problem with parameterized queries
				and statistics

				THIS SCRIPT IS PART OF THE TRACK:
					"Workshop - Mastering SQL Server Statistics"

	Version:	1.00.000

	Date:		October 2025
	Revion:		October 2025

	SQL Server Version: >= 2016
	============================================================================
*/
USE demo_db;
GO

/*
	Let's start with a fresh new table dbo.messages
*/
DROP TABLE IF EXISTS dbo.messages;
GO

SELECT	*
INTO		dbo.messages
FROM		sys.messages;
GO

/*
	and create an index on severity for the demos!
*/
CREATE NONCLUSTERED INDEX nix_messages_severity ON dbo.messages (severity);
GO

/*
	Let's analyze how SQL Server will use the histogram for a query
*/
SELECT	*
FROM		dbo.messages
WHERE	severity = 12
ORDER BY
		language_id,
		message_id;
GO

/*
	Why does Microsoft SQL Server know the exact number of rows?
*/
DBCC SHOW_STATISTICS(N'dbo.messages', N'nix_messages_severity') WITH HISTOGRAM;
GO

SELECT	*
FROM		dbo.messages
WHERE	severity = 16
ORDER BY
		language_id,
		message_id;
GO

DBCC SHOW_STATISTICS(N'dbo.messages', N'nix_messages_severity') WITH HISTOGRAM;
GO

/*
	If the value is not know SQL Server must use the densitiy vector
	of the stats object
*/
DECLARE	@severity SMALLINT = 12;

SELECT	*
FROM		dbo.messages
WHERE	severity = @severity
ORDER BY
		language_id,
		message_id;
GO

/*
	Why is SQL Server "thinking" that only 23.075 rows are coming back?
*/
DBCC SHOW_STATISTICS(N'dbo.messages', N'nix_messages_severity') WITH DENSITY_VECTOR;
GO

/*
	The densitiy vector is a calculation of the distribution key for each value
	We have 16 unique values in the index!
	1/16 = 0.0625
*/
SELECT	1.0/16	AS	[density_vector];
GO

/*
	The estimates is a multiplication of the distribution key with the total
	number of rows (when no new rows have been added!)
*/
SELECT	CAST(COUNT_BIG(*) * (1.0 / 16) AS BIGINT)	AS	avg_number_of_rows
FROM		dbo.messages;
GO

DECLARE	@severity SMALLINT = 12;

SELECT	*
FROM		dbo.messages
WHERE	severity = @severity
ORDER BY
		language_id,
		message_id;
GO

/*
	To prevent the UNKNOWN value for the variable you MUST recompile the query
*/
DECLARE	@severity SMALLINT = 12;

SELECT	*
FROM		dbo.messages
WHERE	severity = @severity
ORDER BY
		language_id,
		message_id
OPTION	(RECOMPILE);
GO



/*
	Let's clean the environment!
*/
DROP TABLE IF EXISTS dbo.messages;
GO
