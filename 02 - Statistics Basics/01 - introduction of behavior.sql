/*
	============================================================================
	File:		00 - introduction of behavior.sql

	Summary:	This script demonstrates the general compilation and optimization
                of a query based on statistics!
				
				THIS SCRIPT IS PART OF THE TRACK:
					"Workshop - Mastering SQL Server Statistics"

	Version:	1.00.000

	Date:		October 2025
	Revion:		October 2025

	SQL Server Version: >= 2016
	============================================================================
*/
SET NOCOUNT ON;
SET XACT_ABORT;
GO

USE demo_db;
GO

DROP TABLE IF EXISTS dbo.messages;
GO

SELECT * INTO dbo.messages FROM sys.messages;
GO

CREATE NONCLUSTERED INDEX nix_messages_severity
ON dbo.messages (severity);
GO

/*
    Search for all messages of severity = 12
    Check the execution plan after running the query!
*/
SELECT	message_id,
        language_id,
        severity,
        is_event_logged,
        text
FROM	dbo.messages
WHERE	severity = 12
ORDER BY
        language_id,
        message_id;
GO

/*
    Let's search for all messages of severity = 10
    Check the execution plan after running the query
*/
SELECT	message_id,
        language_id,
        severity,
        is_event_logged,
        text
FROM	dbo.messages
WHERE	severity = 10
ORDER BY
        language_id,
        message_id;
GO

/*
    Last demo will show what happens if the estimated costs
    are way out of scope!
*/
DECLARE @severity TINYINT = 12;
SELECT	message_id,
        language_id,
        severity,
        is_event_logged,
        text
FROM	dbo.messages
WHERE	severity = @severity
ORDER BY
        language_id,
        message_id;
GO

DECLARE @severity TINYINT = 16;
SELECT	message_id,
        language_id,
        severity,
        is_event_logged,
        text
FROM	dbo.messages
WHERE	severity = @severity
ORDER BY
        language_id,
        message_id;
GO

/*
    Clean the environment after the demo!
*/
DROP TABLE IF EXISTS dbo.messages;
GO