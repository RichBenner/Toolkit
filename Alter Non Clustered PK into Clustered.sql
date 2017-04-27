IF OBJECT_ID('tempdb..#FKAgainstTableList') IS NOT NULL DROP TABLE #FKAgainstTableList

DECLARE @PKTableName VARCHAR(100), 
        @PKName varchar(100),
		@ClusteredIndexName varchar(100),
        @FKName varchar(100),
        @sql varchar(max),
        @PKcolumnName varchar(30),
        @table VARCHAR(100),
        @FKColumnName VARCHAR(100), 
        @parentColumnNumber int

SET @PKTableName = 'RichPKTest_Main'
SET @PKName = (SELECT name FROM sys.indexes WHERE OBJECT_NAME(object_id) = @PKTableName AND is_primary_key = 1)
SET @PKcolumnName = (SELECT column_name FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE WHERE OBJECTPROPERTY(OBJECT_ID(constraint_name), 'IsPrimaryKey') = 1 AND table_name = @PKTableName)
PRINT @PKcolumnName

/* Let's grab the foreign keys and put them into a temp table */
SELECT 
	OBJECT_NAME(sys.foreign_key_columns.parent_object_id) [Table]
	,sys.columns.name [FKColumnName]
	,sys.foreign_keys.name [FKName] 
INTO #FKAgainstTableList
FROM sys.foreign_keys 
INNER JOIN sys.foreign_key_columns ON sys.foreign_keys.object_id = sys.foreign_key_columns.constraint_object_id
INNER JOIN sys.columns ON sys.columns.object_id = sys.foreign_keys.parent_object_id 
	AND sys.columns.column_id = sys.foreign_key_columns.parent_column_id
WHERE OBJECT_NAME(sys.foreign_keys.referenced_object_id) = @PKTableName


DECLARE cursor1 CURSOR  FOR
    SELECT * FROM #FKAgainstTableList

    PRINT @sql

/* Disable constraint on FK Tables */
OPEN cursor1
FETCH NEXT FROM cursor1 INTO @table,@FKColumnName,@FKName
WHILE   @@FETCH_STATUS = 0
    BEGIN
        SET @sql ='ALTER TABLE '+@table+' DROP CONSTRAINT '+ @FKName
        PRINT @sql
		EXEC(@sql)
        FETCH NEXT FROM cursor1 INTO @table,@FKColumnName,@FKName
    END
CLOSE cursor1
DEALLOCATE cursor1
/* Let's drop that PK */
IF  EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(@PKTableName) AND name = @PKName)
BEGIN
    SET @sql = 'ALTER TABLE '+@PKTableName+' DROP CONSTRAINT '+ @PKName
    PRINT @sql
	EXEC(@sql)

END

/* But what if the clustered index is not the same as the PK? Let's drop that too */
IF  EXISTS (SELECT 1 FROM sys.objects o JOIN sys.indexes i ON o.object_id = i.object_id WHERE o.name = @PKTableName and i.type = 1)
BEGIN
	SET @ClusteredIndexName = (SELECT i.name FROM sys.objects o JOIN sys.indexes i ON o.object_id = i.object_id WHERE o.name = @PKTableName and i.type = 1)
    SET @sql = 'DROP INDEX ' + @ClusteredIndexName + ' ON ' +@PKTableName
    PRINT @sql
	EXEC(@sql)

END

/* OK, let's apply that PK but cluster it this time */
SET @sql = 'ALTER TABLE '+@PKTableName +' ADD  CONSTRAINT '+@PKName+' PRIMARY KEY CLUSTERED ('+@PKcolumnName+' ASC)
WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 100) ON [PRIMARY]'
PRINT(@sql)
EXEC(@sql)

/* Put the FK's back on */
DECLARE cursor2 CURSOR  FOR
    SELECT  * FROM #FKAgainstTableList
OPEN cursor2
FETCH NEXT FROM cursor2 INTO @table,@FKColumnName,@FKName
WHILE   @@FETCH_STATUS = 0
    BEGIN
        SET @sql = 'ALTER TABLE '+@table+' WITH NOCHECK ADD  CONSTRAINT  '+ @FKName+' FOREIGN KEY(['+@FKColumnName+'])
        REFERENCES ['+@PKTableName+'] (['+@PKcolumnName+'])'
        PRINT(@sql)
		EXEC(@sql)
        SET @sql = 'ALTER TABLE '+@table+' CHECK CONSTRAINT  '+@FKName
        PRINT(@sql)
		EXEC(@sql)

        FETCH NEXT FROM cursor2 INTO @table,@FKColumnName,@FKName
	END
CLOSE cursor2
DEALLOCATE cursor2
DROP TABLE #FKAgainstTableList