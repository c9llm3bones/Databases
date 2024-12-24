USE master;

GO
IF DB_ID(N'FilmingDB') IS NOT NULL
    DROP DATABASE FilmingDB;
GO

CREATE DATABASE FilmingDB
ON PRIMARY
(
    NAME = Filming_PrimaryData,
    FILENAME = '/home/kostya/5_sem/BD/lab_5/FilmingDB.mdf', 
    SIZE = 10MB,
    MAXSIZE = 100MB,
    FILEGROWTH = 5MB
),
FILEGROUP LargeFileGroup
(
    NAME = Filming_LargeData,
    FILENAME = '/home/kostya/5_sem/BD/lab_5/Filming_large.ndf', 
    SIZE = 20MB,
    MAXSIZE = 200MB,
    FILEGROWTH = 10MB
)
LOG ON
(
    NAME = Filming_Log,
    FILENAME = '/home/kostya/5_sem/BD/lab_5/Filming_log.ldf', 
    SIZE = 5MB,
    MAXSIZE = 50MB,
    FILEGROWTH = 5MB
);
GO

SELECT name, database_id, create_date
FROM sys.databases;
GO

USE FilmingDB;
GO
--  Movie
CREATE TABLE Movie (
    MovieID INT PRIMARY KEY,
    MovieName NVARCHAR(50) NOT NULL,
    ReleaseDate SMALLDATETIME NOT NULL,
    Genre Nvarchar(100),
    RatingAge TINYINT,
    Duration INT
);

--  Person
CREATE TABLE Person (
    PersonID INT PRIMARY KEY,
    Name NVARCHAR(25) NOT NULL,
    Surname NVARCHAR(25) NOT NULL,
    BirthDate SMALLDATETIME NOT NULL,
    Country CHAR(2),
    City NVARCHAR(25),
    Bio TEXT
);

--  Studio
CREATE TABLE Studio (
    StudioID INT PRIMARY KEY,
    StudioName NVARCHAR(25) NOT NULL,
    Country CHAR(2) NOT NULL,
    NameOwner NVARCHAR(25),
    FoundationYear SMALLDATETIME,
    Phone CHAR(13),
    URL NVARCHAR(2048)
);

--  Participation
CREATE TABLE Participation (
    MovieID INT NOT NULL,
    PersonID INT NOT NULL,
    PersonTypeID TINYINT NOT NULL,
    BeginDate SMALLDATETIME,
    EndDate SMALLDATETIME
);

GO
/*
USE FilmingDB;
GO

SELECT * FROM Studio;
GO

SELECT * FROM Movie;
GO

SELECT * FROM Person;
GO

SELECT * FROM Participation;
GO

SELECT name AS TableName
FROM sys.tables;
GO
*/

ALTER DATABASE FilmingDB
ADD FILEGROUP AdditionalFileGroup;
GO

ALTER DATABASE FilmingDB
ADD FILE 
(
    NAME = FilmingDB_AdditionalData,
    FILENAME = '/home/kostya/5_sem/BD/lab_5/Filming_additional.ndf',
    SIZE = 10MB,
    MAXSIZE = 100MB,
    FILEGROWTH = 5MB
) 
TO FILEGROUP AdditionalFileGroup;
GO


ALTER DATABASE FilmingDB 
MODIFY FILEGROUP AdditionalFileGroup DEFAULT;
GO

CREATE TABLE MovieStudio (
    MovieID INT NOT NULL,
    StudioID INT NOT NULL
) ON AdditionalFileGroup;
GO

INSERT INTO MovieStudio (MovieID, StudioID) VALUES (3, 4);
GO

ALTER DATABASE FilmingDB 
MODIFY FILEGROUP [PRIMARY] DEFAULT;
GO

CREATE TABLE MovieStudioTemp (
    MovieID INT NOT NULL,
    StudioID INT NOT NULL
);

INSERT INTO MovieStudioTemp (MovieID, StudioID)
SELECT MovieID, StudioID FROM MovieStudio;

DROP TABLE MovieStudio;

EXEC sp_rename 'MovieStudioTemp', 'MovieStudio';
GO

ALTER DATABASE FilmingDB
REMOVE FILE FilmingDB_AdditionalData;
GO

ALTER DATABASE FilmingDB
REMOVE FILEGROUP AdditionalFileGroup;
GO

CREATE SCHEMA newSchema;
GO

ALTER SCHEMA newSchema TRANSFER dbo.MovieStudio;
GO

ALTER SCHEMA dbo TRANSFER newSchema.MovieStudio;
GO

DROP SCHEMA newSchema;
GO