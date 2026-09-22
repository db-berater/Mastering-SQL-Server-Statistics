/*
	============================================================================
	File:		01 - filtered stats and variables.sql

	Summary:		This script demonstrates the negative impact of filtered indexes
				when you work with parameterized queries.

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
