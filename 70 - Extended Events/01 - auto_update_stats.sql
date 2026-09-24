USE master;
GO

IF EXISTS (SELECT * FROM sys.dm_xe_sessions WHERE name = N'monitor_auto_update_stats')
BEGIN
	RAISERROR (N'Dropping XEvent-Session: [monitor_auto_update_stats]', 0, 1) WITH NOWAIT;
	DROP EVENT SESSION [monitor_auto_update_stats] ON SERVER;
END
GO

CREATE EVENT SESSION [monitor_auto_update_stats] ON SERVER 
ADD EVENT sqlserver.auto_stats
(
    WHERE	sqlserver.database_name = N'demo_db'
			OR sqlserver.database_name = N'ERP_Demo'
)
ADD TARGET package0.ring_buffer
GO

RAISERROR (N'Starting XEvent-Session: [monitor_auto_update_stats]', 0, 1) WITH NOWAIT;
ALTER EVENT SESSION [monitor_auto_update_stats] ON SERVER STATE = START;
GO
