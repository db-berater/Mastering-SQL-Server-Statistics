/*
	============================================================================
	File:		06 - sp_read_xevent_auto_stats.sql

	Summary:	This script creates a stored procedure in master to read the data
				from extended event "monitor_auto_stats" from the ring buffer.

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

USE master;
GO

CREATE OR ALTER PROCEDURE dbo.sp_read_xevent_auto_stats
	@xevent_name		NVARCHAR(128)
AS
BEGIN
	SET NOCOUNT ON;
	SET XACT_ABORT ON;

	DROP TABLE IF EXISTS #event_data;

	RAISERROR ('Catching the data from the ring_buffer for extended event [%s]', 0, 1, @xevent_name) WITH NOWAIT;

	SELECT	CAST(target_data AS XML) AS target_data
	INTO	#event_data
	FROM	sys.dm_xe_session_targets AS t
			INNER JOIN sys.dm_xe_sessions AS s
			ON (t.event_session_address = s.address)
	WHERE	s.name = @xevent_name
			AND t.target_name = N'ring_buffer';

	RAISERROR ('Analyzing the data from the ring buffer', 0, 1) WITH NOWAIT;

	WITH xe
	AS
	(
		SELECT	x.event_data.value('(@timestamp)[1]','datetime')								AS	[time],
				x.event_data.value('(@name)[1]', 'VARCHAR(128)')								AS	[Event_name],
				x.event_data.value('(data[@name="status"]/value)[1]','VARCHAR(128)')			AS	[status],
				x.event_data.value('(data[@name="statistics_list"]/value)[1]','VARCHAR(256)')	AS	[statistics_list],
				x.event_data.value('(data[@name="duration"]/value)[1]','BIGINT')				AS	[duration],
				x.event_data.value('(data[@name="sample_percentage"]/value)[1]','SMALLINT')		AS	[sample_rate],
				x.event_data.value('(data[@name="max_dop"]/value)[1]','SMALLINT')				AS	[max_dop]
		FROM	#event_data AS ed
				CROSS APPLY ed.target_data.nodes('//RingBufferTarget/event') AS x (event_data)
	)
	SELECT	DISTINCT
			xe.Event_name,
			xe.time,
			xe.statistics_list,
			CAST(xe.duration / 1000.0 AS NUMERIC(10, 2))	AS	duration,
			xe.sample_rate,
			xe.max_dop
	FROM	xe LEFT JOIN
			(
				SELECT	map_key,
						map_value
				FROM	sys.dm_xe_map_values
				WHERE	name = N'statistics_update_status'
			) AS kv
			ON (xe.status = kv.map_key)
	WHERE	xe.status = 1
	ORDER BY
			xe.time DESC;
END
GO

EXEC master..sp_ms_marksystemobject N'dbo.sp_read_xevent_auto_stats';
GO