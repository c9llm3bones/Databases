USE master;
GO

IF DB_ID('FilmingDB1') IS NOT NULL
DROP DATABASE FilmingDB1;
GO

IF DB_ID('FilmingDB2') IS NOT NULL
DROP DATABASE FilmingDB2;
GO

CREATE DATABASE FilmingDB1
GO 

CREATE DATABASE FilmingDB2
GO


DROP TRIGGER IF EXISTS InsertStudio;
GO

USE FilmingDB1;
GO

DROP TABLE IF EXISTS Movie;
GO

CREATE TABLE Movie
(
    MovieID INT PRIMARY KEY CHECK (MovieID <= 10),
    MovieName NVARCHAR(50) NOT NULL,
    ReleaseDate DATE NOT NULL,
    Genre NVARCHAR(50)
);
GO

INSERT INTO Movie (MovieID, MovieName, ReleaseDate, Genre)
VALUES
(1, 'Inception', GETDATE(), 'Sci-Fi'),
(2, 'Interstellar', GETDATE(), 'Sci-Fi');

USE FilmingDB2;
GO

DROP TABLE IF EXISTS Movie;
GO

CREATE TABLE Movie
(
    MovieID INT PRIMARY KEY CHECK (MovieID > 10),
    MovieName NVARCHAR(50) NOT NULL,
    ReleaseDate DATE NOT NULL,
    Genre NVARCHAR(50)
);
GO

USE FilmingDB1;
GO

CREATE VIEW vw_MovieFullDetails
AS
SELECT 
    MovieID,
    MovieName,
    ReleaseDate,
    Genre
FROM FilmingDB1.dbo.Movie
UNION ALL
SELECT 
    MovieID,
    MovieName,
    ReleaseDate,
    Genre
FROM FilmingDB2.dbo.Movie;
GO

CREATE TRIGGER trg_Insert_vw_MovieFullDetails
ON vw_MovieFullDetails
INSTEAD OF INSERT
AS
BEGIN
    BEGIN TRY
        INSERT INTO FilmingDB1.dbo.Movie (MovieID, MovieName, ReleaseDate, Genre)
        SELECT 
            i.MovieID,
            i.MovieName,
            i.ReleaseDate,
            i.Genre
        FROM inserted i
        WHERE i.MovieID <= 10;

        INSERT INTO FilmingDB2.dbo.Movie (MovieID, MovieName, ReleaseDate, Genre)
        SELECT 
            i.MovieID,
            i.MovieName,
            i.ReleaseDate,
            i.Genre
        FROM inserted i
        WHERE i.MovieID > 10;
    END TRY
    BEGIN CATCH
        RAISERROR('Error occurred during insert: %s', 16, 1);
        ROLLBACK TRANSACTION;
    END CATCH;
END;
GO


CREATE TRIGGER trg_Update_vw_MovieFullDetails
ON vw_MovieFullDetails
INSTEAD OF UPDATE
AS
BEGIN
    BEGIN TRY
        UPDATE FilmingDB1.dbo.Movie
        SET 
            MovieName = i.MovieName,
            ReleaseDate = i.ReleaseDate,
            Genre = i.Genre
        FROM FilmingDB1.dbo.Movie m
        JOIN inserted i ON m.MovieID = i.MovieID;

        UPDATE FilmingDB2.dbo.Movie
        SET 
            MovieName = i.MovieName,
            ReleaseDate = i.ReleaseDate,
            Genre = i.Genre
        FROM FilmingDB2.dbo.Movie m
        JOIN inserted i ON m.MovieID = i.MovieID;
    END TRY
    BEGIN CATCH
        RAISERROR('Error occurred during update: %s', 16, 1);
        ROLLBACK TRANSACTION;
    END CATCH;
END;
GO

CREATE TRIGGER trg_Delete_vw_MovieFullDetails
ON vw_MovieFullDetails
INSTEAD OF DELETE
AS
BEGIN
    BEGIN TRY
        DELETE FROM FilmingDB1.dbo.Movie
        WHERE MovieID IN (SELECT MovieID FROM deleted);

        DELETE FROM FilmingDB2.dbo.Movie
        WHERE MovieID IN (SELECT MovieID FROM deleted);
    END TRY
    BEGIN CATCH
        RAISERROR('Error occurred during delete: %s', 16, 1);
        ROLLBACK TRANSACTION;
    END CATCH;
END;
GO
