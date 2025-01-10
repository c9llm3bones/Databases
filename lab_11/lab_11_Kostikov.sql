USE master;

GO
IF DB_ID(N'FilmingDB') IS NOT NULL
    DROP DATABASE FilmingDB;
GO

    CREATE DATABASE FilmingDB
    ON PRIMARY
    (
        NAME = Filming_PrimaryData,
    FILENAME = '/home/kostya/5_sem/BD/lab_11/FilmingDB.mdf', 
        SIZE = 10MB,
        MAXSIZE = 100MB,
        FILEGROWTH = 5MB
    )
    LOG ON
    (
        NAME = Filming_Log,
    FILENAME = '/home/kostya/5_sem/BD/lab_11/Filming_log.ldf', 
        SIZE = 5MB,
        MAXSIZE = 50MB,
        FILEGROWTH = 5MB
    );
GO

CREATE TABLE Studio (
    StudioID INT IDENTITY(1,1) PRIMARY KEY,
    StudioName NVARCHAR(25) NOT NULL DEFAULT 'KS',
    Country CHAR(2) NOT NULL DEFAULT 'RS',
    NameOwner NVARCHAR(25) NOT NULL DEFAULT 'Kusturitsa',
    FoundationYear SMALLDATETIME CHECK (FoundationYear > 1800),
    Phone CHAR(13), 
    CONSTRAINT PK_Studio PRIMARY KEY (StudioID)
);
GO

ALTER TABLE Studio
ADD URL NVARCHAR(2048) NULL;
GO

INSERT INTO Studio (StudioName) VALUES
('Warner Bros.'),

UPDATE dbo.Studio
SET URL = 'www.unknownStudio.com'
WHERE URL IS NULL;
GO

ALTER TABLE dbo.Studio
ALTER COLUMN URL NVARCHAR(100) NOT NULL;
GO

ALTER TABLE dbo.Studio
ADD CONSTRAINT DF_Studio_URL
DEFAULT ('www.unknownStudio.com') FOR URL;
GO

INSERT INTO Studio (StudioName) VALUES
('Paramount Pictures');
GO

CREATE TABLE Movie (
    MovieID INT IDENTITY(1,1) PRIMARY KEY,  
    MovieName NVARCHAR(50) NOT NULL,        
    ReleaseDate SMALLDATETIME NOT NULL DEFAULT GETDATE(),     
    Genre NVARCHAR(50),
    RatingAge TINYINT CHECK (RatingAge BETWEEN 0 AND 21) DEFAULT 18, 
    Duration INT CHECK (Duration > 0),
    CONSTRAINT PK_Movie PRIMARY KEY (MovieID)
);
GO

CREATE NONCLUSTERED INDEX idx_Movie_MovieName
    ON Movie (MovieName ASC);
GO

INSERT INTO Movie (MovieName, Genre, RatingAge, Duration) VALUES
('Inception', 'Sci-Fi', 16, 148),
('Interstellar', 'Sci-Fi', 12, 169),
('Dune', 'Action', 16, 180);
GO

CREATE TABLE Person (
    PersonID INT IDENTITY(1, 1) PRIMARY KEY,
    Name NVARCHAR(25) NOT NULL DEFAULT 'Jan',
    Surname NVARCHAR(25) NOT NULL DEFAULT 'CLOD',
    BirthDate SMALLDATETIME,
    Country CHAR(2),
    City NVARCHAR(25),
    BIO TEXT
);
GO

CREATE TABLE MovieStudio
(
    MovieID  INT NOT NULL,
    StudioID INT NOT NULL,
    CONSTRAINT PK_MovieStudio 
        PRIMARY KEY (MovieID, StudioID),

    CONSTRAINT FK_MovieStudio_Movie
        FOREIGN KEY (MovieID) 
        REFERENCES Movie (MovieID)
        ON DELETE CASCADE,

    CONSTRAINT FK_MovieStudio_Studio
        FOREIGN KEY (StudioID) 
        REFERENCES Studio (StudioID)
        ON DELETE CASCADE
);
GO

CREATE TABLE Person (
    PersonID INT IDENTITY(1, 1) PRIMARY KEY,
    Name NVARCHAR(25) NOT NULL DEFAULT 'Jan',
    Surname NVARCHAR(25) NOT NULL DEFAULT 'CLOD',
    BirthDate SMALLDATETIME,
    Country CHAR(2),
    City NVARCHAR(25),
    BIO TEXT,
    CONSTRAINT PK_Person PRIMARY KEY (PersonID)
);
GO

CREATE TABLE Participation
(
    MovieID       INT     NOT NULL,
    PersonID      INT     NOT NULL,
    PersonTypeID  INT     NOT NULL,
    BeginDate     SMALLDATETIME   NULL,
    EndDate       SMALLDATETIME   NULL,
    CONSTRAINT PK_Participation
        PRIMARY KEY (MovieID, PersonID, PersonTypeID),

    CONSTRAINT FK_Participation_Movie
        FOREIGN KEY (MovieID) 
        REFERENCES Movie (MovieID),

    CONSTRAINT FK_Participation_Person
        FOREIGN KEY (PersonID) 
        REFERENCES Person (PersonID)
);
GO

CREATE OR ALTER FUNCTION dbo.fn_GetAverageRatingAge()
RETURNS INT
AS
BEGIN
    DECLARE @result INT;

    SELECT @result = AVG(RatingAge)
    FROM Movie
    WHERE RatingAge IS NOT NULL;

    RETURN @result;
END;
GO

SELECT dbo.fn_GetAverageRatingAge() AS AvgRatingAge;

CREATE OR ALTER PROCEDURE dbo.GetAdultMovies
AS
BEGIN

    SELECT MovieID, MovieName, ReleaseDate, Genre, RatingAge, Duration
    FROM dbo.Movie
    WHERE RatingAge = 18;
END;
GO

EXEC dbo.GetAdultMovies;

SELECT DISTINCT Genre
FROM dbo.Movie
WHERE Genre IS NOT NULL
ORDER BY Genre;

SELECT 
    p.PersonID,
    per.[Name] + N' ' + per.Surname AS [Полное имя],
    m.MovieName,
    p.PersonTypeID,
    p.BeginDate,
    p.EndDate
FROM dbo.Participation p
    INNER JOIN dbo.Person per ON p.PersonID = per.PersonID
    INNER JOIN dbo.Movie m ON p.MovieID = m.MovieID
ORDER BY per.Surname, per.[Name];

SELECT 
    m.MovieID,
    m.MovieName,
    p.PersonID,
    per.[Name] AS [Имя],
    per.Surname AS [Фамилия]
FROM dbo.Movie m
    LEFT JOIN dbo.Participation p ON m.MovieID = p.MovieID
    LEFT JOIN dbo.Person per ON p.PersonID = per.PersonID
ORDER BY m.MovieName;

SELECT 
    m.MovieID,
    m.MovieName,
    p.PersonID,
    per.[Name] AS [Имя],
    per.Surname AS [Фамилия]
FROM dbo.Movie m
    LEFT JOIN dbo.Participation p ON m.MovieID = p.MovieID
    LEFT JOIN dbo.Person per ON p.PersonID = per.PersonID
ORDER BY m.MovieName;

