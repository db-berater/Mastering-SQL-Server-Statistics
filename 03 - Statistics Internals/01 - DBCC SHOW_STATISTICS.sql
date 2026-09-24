/*
	============================================================================
	File:		01 - DBCC SHOW_STATISTICS.sql

	Summary:		This script demonstrates the tool SHOW_STATISTICS to investigate
				the internals of a statistics object!

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

/*
	Let's create a demo table dbo.messages with two indexes
	- pk_messages			(primary key)
	- nix_messages_severity	(nonclustered index)
*/
DROP TABLE IF EXISTS dbo.messages;
GO

SELECT	message_id,
        language_id,
        severity,
        is_event_logged,
        [text]
INTO		dbo.messages
FROM		sys.messages;
GO

ALTER TABLE dbo.messages ADD CONSTRAINT pk_messages
PRIMARY KEY CLUSTERED
(
	message_id,
	language_id
)
WITH
(
	DATA_COMPRESSION = PAGE,
	SORT_IN_TEMPDB = ON
);
GO

CREATE NONCLUSTERED INDEX nix_messages_severity
ON dbo.messages (severity)
WITH
(
	DATA_COMPRESSION = PAGE,
	SORT_IN_TEMPDB = ON
);
GO

/*
	Let's look into the statistics information of the
	PRIMARY KEY first!
*/
DBCC SHOW_STATISTICS (N'dbo.messages', N'pk_messages');
GO

/*
	Demo for the HISTOGRAM!
*/
DBCC SHOW_STATISTICS (N'dbo.messages', N'pk_messages') WITH HISTOGRAM;
GO

SELECT	*
FROM		dbo.messages
WHERE	message_id = 21;
GO

SELECT	*
FROM		dbo.messages
WHERE	message_id = 21
		AND language_id = 1031;
GO

SELECT	*
FROM		dbo.messages
WHERE	language_id = 1031;
GO

/*
	Demo for the DENSITIY VECTOR!
*/
DBCC SHOW_STATISTICS (N'dbo.messages', N'pk_messages') WITH DENSITY_VECTOR;
GO
SELECT 'message_id'		AS	[columns],
		369204			AS	[rows],
		5.958765E-05		AS	[distribution key],
		CAST(5.958765E-05 AS NUMERIC(18, 10)) * 369204	AS [rows * distribution key]

UNION ALL

SELECT	'message_id, language_id'	AS [columns],
		369204						AS [rows],
		2.708530E-06					AS [distribution key],
		CAST(2.708530E-06 AS NUMERIC(18, 10)) * 369204	AS [rows * distribution key];
GO

DECLARE	@message_id	INT = 21;

SELECT	*
FROM		dbo.messages
WHERE	message_id = @message_id
ORDER BY
		text;
GO

DECLARE	@message_id	INT = 21;
DECLARE	@language_id INT = 1031;

SELECT	*
FROM		dbo.messages
WHERE	message_id = @message_id
		AND language_id = @language_id
ORDER BY
		text;
GO

/*
	It becomes tricky when the distribution of data is uneven!
*/
DBCC SHOW_STATISTICS (N'dbo.messages', N'nix_messages_severity');


/*
	BUT -	distribution can harm your system because of
			mismatch of estimates
*/
DBCC SHOW_STATISTICS (N'dbo.messages', N'nix_messages_severity');
GO

SELECT	*
FROM		dbo.messages
WHERE	severity = 12
ORDER BY
		text;
GO

SELECT	*
FROM		dbo.messages
WHERE	severity = 16
ORDER BY
		text;
GO

DECLARE	@severity	SMALLINT = 12;
SELECT	*
FROM		dbo.messages
WHERE	severity = @severity
ORDER BY
		text;
GO

DECLARE	@severity	SMALLINT = 16;
SELECT	*
FROM		dbo.messages
WHERE	severity = @severity
ORDER BY
		text;
GO

/*
	Clean the environment!
*/
DROP TABLE IF EXISTS dbo.messages;
GO
