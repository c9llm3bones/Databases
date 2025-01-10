
USE master;
GO

IF DB_ID(N'FilmingDB') IS NOT NULL 
BEGIN
    ALTER DATABASE FilmingDB SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE FilmingDB;
END
GO

CREATE DATABASE FilmingDB;
GO

USE FilmingDB;
GO

-- Таблица Movie (IDENTITY KEY)
CREATE TABLE Movie (
    MovieID INT IDENTITY(1,1) PRIMARY KEY,  
    MovieName NVARCHAR(50) NOT NULL,        
    ReleaseDate SMALLDATETIME NOT NULL DEFAULT GETDATE(),     
    Genre NVARCHAR(50),
    RatingAge TINYINT CHECK (RatingAge BETWEEN 0 AND 18), 
    Duration INT CHECK (Duration > 0)
);
GO

INSERT INTO Movie (MovieName, Genre, RatingAge, Duration) OUTPUT INSERTED.MovieID VALUES
('Inception', 'Sci-Fi', 16, 148),
('Interstellar', 'Sci-Fi', 12, 169),
('Dune', 'Action', 16, 180);
GO

SELECT @@IDENTITY AS LastInsertedID;
GO

-- Таблица Studio (UID)
CREATE TABLE Studio (
    StudioID UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID() ,
    StudioName NVARCHAR(25) NOT NULL DEFAULT 'KS',
    Country CHAR(2) NOT NULL DEFAULT 'RS',
    NameOwner NVARCHAR(25) NOT NULL DEFAULT 'Kusturitsa',
    FoundationYear SMALLDATETIME CHECK (FoundationYear > 1800),
    Phone CHAR(13),
    URL NVARCHAR(2048)  
);
GO

INSERT INTO Studio (StudioName) VALUES
('Warner Bros.'),
('Paramount Pictures');
GO

SELECT * FROM Studio;
GO

-- Таблица Person (sequence)
CREATE SEQUENCE MySeq START WITH 1 INCREMENT BY 1;
GO

CREATE TABLE Person (
    PersonID INT PRIMARY KEY DEFAULT NEXT VALUE FOR MySeq,
    Name NVARCHAR(25) NOT NULL DEFAULT 'Jan',
    Surname NVARCHAR(25) NOT NULL DEFAULT 'CLOD',
    BirthDate SMALLDATETIME,
    Country CHAR(2),
    City NVARCHAR(25),
    BIO TEXT
);
GO

INSERT INTO Person (Name, Surname, BIO) 
VALUES ('Tom', 'Hardy', 'Really flexible, Actor'), 
       ('George', 'Miller', 'Really brilliant, Director');
GO

SELECT * FROM Person;
GO


DROP TABLE IF EXISTS Studio
GO

CREATE TABLE Studio (
    StudioID INT IDENTITY(1,1) PRIMARY KEY,
    StudioName NVARCHAR(25) NOT NULL DEFAULT 'KS',
    Country CHAR(2) NOT NULL DEFAULT 'RS',
    NameOwner NVARCHAR(25) NOT NULL DEFAULT 'Kusturitsa',
    FoundationYear SMALLDATETIME CHECK (FoundationYear > 1800),
    Phone CHAR(13),
    URL NVARCHAR(2048)  
);
GO

INSERT INTO Studio (StudioName) VALUES
('Warner Bros.'),
('Paramount Pictures');
GO

-- MovieStudio 
CREATE TABLE MovieStudio
(
    MovieID INT NOT NULL,
    StudioID INT NOT NULL,
    PRIMARY KEY (MovieID, StudioID),
    -- ограничение внешнего ключа на Movie
    CONSTRAINT FK_MovieStudio_Movie FOREIGN KEY (MovieID) REFERENCES Movie(MovieID)
    --ON DELETE NO ACTION,
    --ON DELETE SET NULL,
    --ON DELETE SET DEFAULT,
    ON DELETE CASCADE,

    -- ограничение внешнего ключа на Studio
    CONSTRAINT FK_MovieStudio_Studio FOREIGN KEY (StudioID) REFERENCES Studio(StudioID)
    --ON DELETE NO ACTION
    --ON DELETE SET NULL
    --ON DELETE SET DEFAULT
    ON DELETE CASCADE
);
GO


INSERT INTO MovieStudio (MovieID, StudioID) VALUES
(1, 1),  -- "Inception" "Warner Bros."
(2, 1),  -- "Interstellar" "Warner Bros."
(2, 2);  -- "Interstellar" "Paramount Pictures"
GO

SELECT SCOPE_IDENTITY() AS LastInsertedID;
GO

SELECT * FROM MovieStudio;
GO


DELETE FROM Studio WHERE StudioID = 1;
GO

SELECT * FROM Studio;
SELECT * FROM MovieStudio;
SELECT * FROM Movie;
GO
