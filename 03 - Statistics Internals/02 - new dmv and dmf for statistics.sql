/*
	============================================================================
	File:		02 - DBCC SHOW_STATISTICS.sql

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
SELECT	s.*
FROM		sys.stats AS s
WHERE	object_id = OBJECT_ID(N'dbo.messages', N'U')
GO

/*
	For the histogram you have your own function
*/
SELECT	h.*
FROM		sys.stats AS s
		CROSS APPLY sys.dm_db_stats_histogram
		(
			s.object_id,
			s.stats_id
		) AS h
WHERE	s.object_id = OBJECT_ID(N'dbo.messages', N'U')
		AND s.stats_id = 1;
GO

SELECT	h.*
FROM		sys.stats AS s
		CROSS APPLY sys.dm_db_stats_histogram
		(
			s.object_id,
			s.stats_id
		) AS h
WHERE	s.object_id = OBJECT_ID(N'dbo.messages', N'U')
		AND s.stats_id = 2;
GO

/*
	Same with the properties of a stats object!
*/
SELECT	sp.*,
		s.has_persisted_sample
FROM		sys.stats AS s
		CROSS APPLY sys.dm_db_stats_properties
		(
			s.object_id,
			s.stats_id
		) AS sp
WHERE	s.object_id = OBJECT_ID(N'dbo.messages', N'U')
		AND s.stats_id = 1;
GO

SELECT	sp.*,
		s.has_persisted_sample
FROM		sys.stats AS s
		CROSS APPLY sys.dm_db_stats_properties_internal
		(
			s.object_id,
			s.stats_id
		) AS sp
WHERE	s.object_id = OBJECT_ID(N'dbo.messages', N'U')
		AND s.stats_id = 1;
GO

/*
	Clean the environment!
*/
DROP TABLE IF EXISTS dbo.messages;
GO
