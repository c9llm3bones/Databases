USE master;
GO

IF DB_ID(N'FilmingDB') IS NOT NULL
    DROP DATABASE FilmingDB;
GO

CREATE DATABASE FilmingDB
/* 

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
*/
GO

USE FilmingDB;
GO

DROP TABLE IF EXISTS Studio;
DROP TABLE IF EXISTS Movie;
DROP TABLE IF EXISTS MovieStudio;
DROP TABLE IF EXISTS Person;
DROP TABLE IF EXISTS Participation;
GO


CREATE TABLE Studio
(
    StudioID        INT IDENTITY(1,1) PRIMARY KEY NOT NULL,
    StudioName      NVARCHAR(25) NOT NULL DEFAULT 'KS',
    Country         CHAR(2) NOT NULL DEFAULT 'RS',
    NameOwner       NVARCHAR(25) NOT NULL DEFAULT 'Kusturitsa',
    FoundationYear  SMALLDATETIME CHECK (FoundationYear > '1900-01-01') NOT NULL,
    Phone           CHAR(13),
    CONSTRAINT AK_Studio_Name_Country_Owner UNIQUE (StudioName, Country, NameOwner)
);
GO


ALTER TABLE Studio
ADD URL NVARCHAR(2048) NULL;
GO

INSERT INTO dbo.Studio (StudioName, FoundationYear)
VALUES ('Warner Bros.', '1990-01-01'); 

GO

INSERT INTO Studio (StudioName, FoundationYear)
VALUES ('Paramount Pictures', '1999-12-31');
GO

UPDATE Studio
SET URL = 'www.unknownStudio.com'
WHERE URL IS NULL;
GO

ALTER TABLE Studio
ALTER COLUMN URL NVARCHAR(100) NOT NULL;
GO

ALTER TABLE Studio
ADD CONSTRAINT DF_Studio_URL
DEFAULT ('www.unknownStudio.com') FOR URL;
GO

CREATE TABLE Movie
(
    MovieID         INT IDENTITY(1,1) PRIMARY KEY NOT NULL,
    MovieName       NVARCHAR(50) NOT NULL,
    ReleaseDate     SMALLDATETIME NOT NULL DEFAULT GETDATE(),
    Genre           NVARCHAR(50),
    RatingAge       TINYINT CHECK (RatingAge BETWEEN 0 AND 21) DEFAULT 18,
    Duration        INT CHECK (Duration > 0),
    CONSTRAINT AK_Movie_MovieName_ReleaseDate UNIQUE (MovieName, ReleaseDate)
);
GO

CREATE NONCLUSTERED INDEX idx_Movie_MovieName
    ON Movie (MovieName ASC);
GO


CREATE OR ALTER TRIGGER trg_InsteadOfInsert_Movie
ON Movie
INSTEAD OF INSERT
AS
BEGIN
    IF EXISTS (SELECT 1 FROM Movie WHERE MovieName IN (SELECT MovieName FROM inserted) 
               AND ReleaseDate IN (SELECT ReleaseDate FROM inserted))
    BEGIN
        RAISERROR('Фильм с таким названием и датой выпуска уже существует.', 16, 1);
    END
    ELSE
    BEGIN
        INSERT INTO Movie (MovieName, ReleaseDate, Genre, RatingAge, Duration)
        SELECT MovieName, ReleaseDate, Genre, RatingAge, Duration
        FROM inserted;
    END
END;
GO


INSERT INTO Movie (MovieName, Genre, RatingAge, Duration)
VALUES
('Inception', 'Sci-Fi', 16, 148),
('Interstellar', 'Sci-Fi', 12, 169),
('Dune', 'Action', 18, 180), 
('Gunfight', 'Western', 21, 200);
GO

INSERT INTO Movie (MovieName, Genre, RatingAge, Duration)
VALUES
('Interstellar', 'Sci-Fi', 12, 169)
GO


CREATE TABLE Person
(
    PersonID    INT IDENTITY(1,1) PRIMARY KEY NOT NULL,
    Name      NVARCHAR(25) NOT NULL DEFAULT 'Jan',
    Surname     NVARCHAR(25) NOT NULL DEFAULT 'CLOD',
    BirthDate   SMALLDATETIME,
    Country     CHAR(2),
    City        NVARCHAR(25),
    BIO         TEXT,
    CONSTRAINT AK_Person_Name_Surname_BirthDate UNIQUE (Name, Surname, BirthDate)
);
GO

CREATE TABLE MovieStudio
(
    MovieID  INT NOT NULL,
    StudioID INT NOT NULL,
    CONSTRAINT PK_MovieStudio PRIMARY KEY (MovieID, StudioID),

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

CREATE OR ALTER VIEW vw_MovieDetails
AS
SELECT 
    m.MovieID,
    m.MovieName,
    m.Genre,
    m.RatingAge,
    m.Duration,
    s.StudioName,
    s.URL
FROM Movie m

JOIN MovieStudio ms ON m.MovieID = ms.MovieID
JOIN Studio s ON ms.StudioID = s.StudioID;
GO

SELECT * FROM vw_MovieDetails;
GO

CREATE TABLE Participation
(
    MovieID       INT NOT NULL,
    PersonID      INT NOT NULL,
    PersonTypeID  INT NOT NULL,
    BeginDate     SMALLDATETIME NULL,
    EndDate       SMALLDATETIME NULL,
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

INSERT INTO Person (Name, Surname, BirthDate, Country, City, BIO)
VALUES
('Leonardo', 'DiCaprio', '1974-11-11', 'US', 'Los Angeles', 'Famous actor'),
('Christopher', 'Nolan', '1970-07-30', 'GB', 'London', 'Director'),
('Zendaya', 'Coleman', '1996-09-01', 'US', 'Oakland', 'Actress'),
('Aleksandr', 'Nevskiy', '1984-09-01', 'RU', 'Moscow', 'GOD');

INSERT INTO MovieStudio (MovieID, StudioID)
VALUES
(1, 1), 
(2, 1), 
(3, 2); 

INSERT INTO Participation (MovieID, PersonID, PersonTypeID, BeginDate, EndDate)
VALUES
(1, 1, 1, '2009-01-01', '2010-12-31'), 
(1, 2, 2, '2009-01-01', '2010-12-31'), 
(2, 2, 2, '2012-01-01', '2014-12-31'), 
(3, 3, 1, '2019-01-01', '2021-12-31'),
(4, 4, 1, '2022-01-01', '2023-12-31'),
(4, 4, 2, '2022-01-01', '2023-12-31'); 


SELECT * FROM vw_MovieDetails WHERE RatingAge = 18;
GO

DROP FUNCTION IF EXISTS fn_GetAverageRatingAge;
GO

CREATE FUNCTION fn_GetAverageRatingAge()
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
GO

CREATE OR ALTER PROCEDURE GetAdultMovies
AS
BEGIN
    SELECT 
        MovieID, 
        MovieName, 
        ReleaseDate, 
        Genre, 
        RatingAge, 
        Duration
    FROM Movie
    WHERE RatingAge >= 18;
END;
GO

EXEC GetAdultMovies;
GO

SELECT DISTINCT Genre
FROM Movie
WHERE Genre IS NOT NULL
ORDER BY Genre DESC;

SELECT 
    p.PersonID,
    p.PersonTypeID,
    per.Name + N' ' + per.Surname AS [Полное имя],
    m.MovieName,
    p.BeginDate,
    p.EndDate
FROM Participation p
    INNER JOIN Person per ON p.PersonID = per.PersonID
    INNER JOIN Movie m ON p.MovieID = m.MovieID
ORDER BY per.Surname, per.Name;

SELECT 
    m.MovieID,
    m.MovieName,
    p.PersonID,
    per.Name AS Имя,
    per.Surname AS Фамилия
FROM Movie m
    JOIN Participation p ON m.MovieID = p.MovieID
    JOIN Person per ON p.PersonID = per.PersonID
ORDER BY m.MovieName;
GO

CREATE OR ALTER PROCEDURE GetMoviesByGenreAndRating
    @Genre NVARCHAR(50),
    @MinRating TINYINT,
    @MaxRating TINYINT
AS
BEGIN

    SELECT 
        MovieID, 
        MovieName, 
        Genre, 
        RatingAge, 
        Duration
    FROM Movie
    WHERE Genre = @Genre AND RatingAge BETWEEN @MinRating AND @MaxRating;
END;
GO

EXEC GetMoviesByGenreAndRating 
    @Genre = 'Sci-Fi', 
    @MinRating = 12, 
    @MaxRating = 18;

SELECT MovieName, YEAR(ReleaseDate) AS ReleaseYear
FROM Movie
WHERE RatingAge BETWEEN 0 AND 12
UNION ALL

SELECT MovieName, YEAR(ReleaseDate) AS ReleaseYear
FROM Movie
WHERE RatingAge > 12;
GO

SELECT * FROM Movie WHERE MovieID BETWEEN 0 AND 2
UNION 
SELECT * FROM Movie WHERE MovieID in (4, 1)
ORDER BY MovieID ASC;
GO

SELECT * FROM Movie WHERE MovieID BETWEEN 0 AND 2
UNION ALL
SELECT * FROM Movie WHERE MovieID in (4, 1)
ORDER BY MovieID ASC;
GO

SELECT MovieName
FROM Movie
WHERE RatingAge <= 12

EXCEPT
SELECT MovieName
FROM Movie
WHERE Genre = 'Sci-fi';
GO

SELECT 
    m.MovieName AS [Фильм],
    s.StudioName AS [Студия]
FROM Movie m
FULL OUTER JOIN MovieStudio ms ON m.MovieID = ms.MovieID
FULL OUTER JOIN Studio s ON ms.StudioID = s.StudioID
ORDER BY [Фильм], [Студия];
GO

INSERT INTO Movie (MovieName, Genre, RatingAge, Duration)
VALUES
('Frank', 'Drama', 16, 148);

SELECT * FROM Movie;
GO

SELECT * FROM Studio;
GO

SELECT * FROM MovieStudio;
GO

SELECT * FROM Movie as m
JOIN MovieStudio as ms ON m.MovieID=ms.MovieID;

SELECT * FROM Movie as m
LEFT OUTER JOIN MovieStudio as ms ON m.MovieID=ms.MovieID;

SELECT * FROM Movie as m
RIGHT JOIN MovieStudio as ms ON m.MovieID=ms.MovieID;

SELECT * FROM Movie as m
FULL OUTER JOIN MovieStudio as ms ON m.MovieID=ms.MovieID;

SELECT genre, COUNT(*) as c FROM Movie GROUP BY genre;

SELECT Genre, AVG(RatingAge) as avg_rate FROM Movie GROUP BY Genre HAVING AVG(RatingAge) > 16;
GO
--SELECT genre, COUNT(*) as c FROM Movie GROUP BY genre HAVING ;
/*ALTER DATABASE FilmingDB SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
GO
DROP DATABASE FilmingDB;
GO*/

SELECT * FROM Person WHERE Surname LIKE '%iy';
GO

SELECT * FROM Person WHERE Surname in ('Nevskiy', 'not Nevskiy');
GO

SELECT Genre, MAX(Duration) AS max_dur FROM Movie WHERE Genre = 'Sci-Fi' GROUP BY Genre;
GO
SELECT Genre, MIN(Duration) AS min_dur FROM Movie WHERE Genre = 'Action' GROUP BY Genre;
GO


SELECT * FROM Movie WHERE MovieID BETWEEN 0 AND 2
Intersect 
SELECT * FROM Movie WHERE MovieID in (4, 1)
ORDER BY MovieID ASC;
GO

SELECT Genre, SUM(Duration) as s_dur FROM Movie GROUP BY Genre;
GO