IF OBJECT_ID('tempdb..#Environment') IS NOT NULL DROP TABLE #Environment
CREATE TABLE #Environment (ID int, Setting varchar(50), Result nvarchar(50))

IF EXISTS (SELECT * FROM sys.dm_os_performance_counters)
    BEGIN
	    INSERT INTO #Environment (ID, Setting, Result)
        SELECT TOP 1 1, 'Machine Name', COALESCE(CAST(SERVERPROPERTY('MachineName') AS NVARCHAR(50)), LEFT(OBJECT_NAME, (CHARINDEX(':', OBJECT_NAME) - 1)))
	    FROM sys.dm_os_performance_counters;
    END
    ELSE
    BEGIN
        INSERT INTO #Environment (ID, Setting, Result)
	    SELECT TOP 1 1, 'Machine Name', (CAST(SERVERPROPERTY('MachineName') AS NVARCHAR(50)))
    END

INSERT INTO #Environment (ID, Setting, Result)
SELECT 2, 'Instance Name', COALESCE(CAST(SERVERPROPERTY('InstanceName') AS NVARCHAR(50)),'Unnamed Instance')
UNION ALL
SELECT 3, 'Product Version', CAST(SERVERPROPERTY('ProductVersion') AS NVARCHAR(50))
UNION ALL 
SELECT 4, 'Product Level', CAST(SERVERPROPERTY('ProductLevel') AS NVARCHAR(50))
UNION ALL 
SELECT 5, 'Edition', CAST(SERVERPROPERTY('Edition') AS NVARCHAR(50))
UNION ALL
SELECT 6, 'IsClustered', CAST(SERVERPROPERTY('IsClustered') AS VARCHAR(100))
UNION ALL
SELECT 7, 'IsHadrEnabled', CAST(COALESCE(SERVERPROPERTY('IsHadrEnabled'),0) AS VARCHAR(100))
UNION ALL
SELECT 8, 'Last Server Start', CONVERT(NVARCHAR(50),create_date) FROM sys.databases WHERE database_id = 2
UNION ALL
SELECT 9, 'Days Uptime', CONVERT(NVARCHAR(50),CONVERT(DECIMAL(4,2),DATEDIFF(SS, create_date, GETDATE())/86400.0)) FROM sys.databases WHERE database_id = 2


DECLARE @sql NVARCHAR(MAX)

IF EXISTS (SELECT * FROM sys.all_objects o INNER JOIN sys.all_columns c ON o.object_id = c.object_id
			WHERE o.name = 'dm_os_sys_info' AND c.name = 'physical_memory_kb' )
BEGIN
    SET @sql = 
    N'INSERT INTO #Environment (ID, Setting, Result)  SELECT 10, ''CPU Count'', cpu_count FROM sys.dm_os_sys_info;
    INSERT INTO #Environment (ID, Setting, Result)  SELECT 11, ''Memory (GB)'', CAST(ROUND((physical_memory_kb / 1024.0 / 1024), 1) AS INT) FROM sys.dm_os_sys_info'
    EXEC (@sql)
END
ELSE
BEGIN
    SET @sql = 
    N'INSERT INTO #Environment (ID, Setting, Result)  SELECT 10, ''CPU Count'', cpu_count FROM sys.dm_os_sys_info;
    INSERT INTO #Environment (ID, Setting, Result)  SELECT 11, ''Memory (GB)'', CAST(ROUND((physical_memory_in_bytes/1024.0/1024.0/1024.0), 1) AS INT) FROM sys.dm_os_sys_info'
    EXEC (@sql)
END

SELECT Setting, Result FROM #Environment ORDER BY ID ASC
