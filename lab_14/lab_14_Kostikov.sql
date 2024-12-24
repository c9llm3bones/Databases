USE master;
GO

IF DB_ID('FilmingDB1') IS NOT NULL
DROP DATABASE FilmingDB1;
GO

IF DB_ID('FilmingDB2') IS NOT NULL
DROP DATABASE FilmingDB2;
GO

CREATE DATABASE FilmingDB1;
CREATE DATABASE FilmingDB2;
GO

USE FilmingDB1;
GO

DROP TABLE IF EXISTS MovieNameRelease;
GO

CREATE TABLE MovieNameRelease (
    MovieID INT IDENTITY(1, 1) PRIMARY KEY,  
    ReleaseDate SMALLDATETIME NOT NULL DEFAULT GETDATE(),   
    MovieName NVARCHAR(50) NOT NULL, 
    CONSTRAINT AK_Movie_MovieName_ReleaseDate UNIQUE (MovieName, ReleaseDate)    
);
GO

INSERT INTO MovieNameRelease (MovieID, MovieName, ReleaseDate)
VALUES
(3, 'Inception', '2010-07-16 00:00'),
(6, 'Interstellar', '2014-11-07 12:00');
GO

USE FilmingDB2;
GO

DROP TABLE IF EXISTS MovieDetails;
GO

CREATE TABLE MovieDetails
(
    MovieID INT PRIMARY KEY,   
    Genre NVARCHAR(50),
    RatingAge TINYINT CHECK (RatingAge BETWEEN 0 AND 18), 
    Duration INT CHECK (Duration > 0)
);
GO

USE master;
GO

DROP VIEW IF EXISTS vw_MovieFullDetails;
GO

CREATE VIEW vw_MovieFullDetails AS
SELECT 
    n.MovieID,
    n.MovieName,
    n.ReleaseDate,
    d.Genre,
    d.RatingAge,
    d.Duration
FROM FilmingDB1.dbo.MovieNameRelease n
JOIN FilmingDB2.dbo.MovieDetails d
ON n.MovieID = d.MovieID;
GO

CREATE OR ALTER TRIGGER trg_Insert_vw_MovieFullDetails
ON vw_MovieFullDetails
INSTEAD OF INSERT
AS
BEGIN
    IF EXISTS (SELECT 1 FROM inserted WHERE MovieID IS NOT NULL)
    BEGIN
        RAISERROR('Manual insertion of MovieID is not allowed !!!', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END;

    BEGIN TRY
        INSERT INTO FilmingDB1.dbo.MovieNameRelease (MovieName, ReleaseDate)
        SELECT 
            i.MovieName,
            i.ReleaseDate
        FROM inserted i;

        INSERT INTO FilmingDB2.dbo.MovieDetails (MovieID, Genre, RatingAge, Duration)
        SELECT 
            n.MovieID,
            i.Genre,
            i.RatingAge,
            i.Duration
        FROM inserted i
        JOIN FilmingDB1.dbo.MovieNameRelease n
        ON i.MovieName = n.MovieName AND i.ReleaseDate = n.ReleaseDate;
    END TRY
    BEGIN CATCH
        RAISERROR('Error occurred during insert: %s', 16, 1);
        ROLLBACK TRANSACTION;
    END CATCH;
END;
GO


INSERT INTO vw_MovieFullDetails (MovieID, MovieName, ReleaseDate, Genre, RatingAge, Duration)
VALUES
(1, 'Avatar', '2010-07-16 00:00', 'Sci-Fi', 13, 162), 
(2, 'Dune: Part Two', '2012-07-16 12:00', 'Sci-Fi', 16, 180);
GO

SELECT * FROM FilmingDB1.dbo.MovieNameRelease;
GO

SELECT * FROM FilmingDB2.dbo.MovieDetails;
GO

CREATE OR ALTER TRIGGER trg_Update_vw_MovieFullDetails
ON vw_MovieFullDetails
INSTEAD OF UPDATE
AS
BEGIN
    IF UPDATE(MovieID)
    BEGIN
        RAISERROR('Changing the MovieID is not allowed !!!', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END;

    BEGIN TRY
        UPDATE FilmingDB1.dbo.MovieNameRelease
        SET 
            MovieName = i.MovieName,
            ReleaseDate = i.ReleaseDate
        FROM FilmingDB1.dbo.MovieNameRelease n
        JOIN inserted i
        ON n.MovieID = i.MovieID;
        
        UPDATE FilmingDB2.dbo.MovieDetails
        SET 
            Genre = i.Genre,
            RatingAge = i.RatingAge,
            Duration = i.Duration
        FROM FilmingDB2.dbo.MovieDetails d
        JOIN inserted i
        ON d.MovieID = i.MovieID;
    END TRY
    BEGIN CATCH
        RAISERROR('Error occurred during update: %s', 16, 1);
        ROLLBACK TRANSACTION;
    END CATCH;
END;
GO


UPDATE vw_MovieFullDetails
SET 
    MovieID = 2,
    ReleaseDate = '2024-01-01'
WHERE MovieName = 'Inception' ;
GO

CREATE TRIGGER trg_Delete_vw_MovieFullDetails 
    ON vw_MovieFullDetails
    INSTEAD OF DELETE
AS
BEGIN
    DELETE FROM FilmingDB2.dbo.MovieDetails
    WHERE MovieID IN (SELECT MovieID FROM deleted);

    DELETE FROM FilmingDB1.dbo.MovieNameRelease
    WHERE MovieID IN (SELECT MovieID FROM deleted);
END;
GO

USE master;
GO

DROP DATABASE FilmingDB1;
GO

DROP DATABASE FilmingDB2;
GO
