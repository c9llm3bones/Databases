IF DB_ID(N'Lab5') IS NOT NULL
    DROP DATABASE Lab5BD;
GO

SELECT name, database_id, create_date
FROM sys.databases;
GO

SELECT * 
FROM sys.filegroups 

USE master;
GO


ALTER DATABASE FilmingDB2 SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
GO
DROP DATABASE FilmingDB2;
GO