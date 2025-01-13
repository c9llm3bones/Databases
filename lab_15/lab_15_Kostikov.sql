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

USE FilmingDB1;
GO
DROP TABLE IF EXISTS Movie;
GO

CREATE TABLE Movie
(
    MovieID INT IDENTITY(1, 1) PRIMARY KEY,
    MovieName NVARCHAR(50) NOT NULL,
    ReleaseDate DATE NOT NULL,
    Genre NVARCHAR(50)
);
GO

INSERT INTO Movie (MovieName, ReleaseDate, Genre)
VALUES
('Inception', GETDATE(), 'Sci-Fi'),
('Interstellar', GETDATE(), 'Sci-Fi');

USE FilmingDB2;
GO

DROP TABLE IF EXISTS MovieFullDetails;
GO

CREATE TABLE MovieFullDetails
(
    MovieID INT PRIMARY KEY,
    Budget INT NOT NULL,
    BoxOffice INT NOT NULL
);
GO

USE FilmingDB2;
GO

DROP VIEW IF EXISTS vw_MovieDetails;
GO

USE FilmingDB1;
GO

DROP VIEW IF EXISTS vw_MovieDetails;
GO

CREATE VIEW vw_MovieDetails AS
SELECT 
    m.MovieID,
    m.MovieName,
    m.ReleaseDate,
    m.Genre,
    mfd.Budget,
    mfd.BoxOffice
FROM FilmingDB1.dbo.Movie AS m
JOIN FilmingDB2.dbo.MovieFullDetails AS mfd
    ON m.MovieID = mfd.MovieID;
GO

USE FilmingDB1;
GO

DROP TRIGGER IF EXISTS trg_MovieDelete;
GO

CREATE TRIGGER trg_MovieDelete
ON Movie
FOR DELETE
AS
BEGIN
    
    DELETE mfd
    FROM FilmingDB2.dbo.MovieFullDetails mfd
    JOIN deleted d
        ON mfd.MovieID = d.MovieID;

END;
GO

DROP TRIGGER IF EXISTS trg_MovieUpdate;
GO

CREATE TRIGGER trg_MovieUpdate
ON Movie
FOR UPDATE
AS
BEGIN
    UPDATE FilmingDB2.dbo.MovieFullDetails
    SET MovieID = i.MovieID
    FROM FilmingDB2.dbo.MovieFullDetails mfd
    JOIN inserted i
        ON mfd.MovieID = i.MovieID
    JOIN deleted d
        ON mfd.MovieID = d.MovieID;

END;
GO

select * from Movie
--update Movie set MovieID=MovieID+1
select * from Movie


USE FilmingDB2;
GO

DROP TRIGGER IF EXISTS trg_MovieFullDetailsInsert;
GO

CREATE TRIGGER trg_MovieFullDetailsInsert
ON MovieFullDetails
FOR INSERT, UPDATE
AS
BEGIN
    IF EXISTS
    (
        SELECT 1
        FROM inserted i
        JOIN FilmingDB1.dbo.Movie m
            ON i.MovieID = m.MovieID
        WHERE m.MovieID IS NULL
    )
    BEGIN
        RAISERROR(
            'ERROR1 - The specified MovieID does NOT exist in FilmingDB1.Movie.', 
            16, 
            1
        );
        ROLLBACK TRANSACTION;
    END;

END;
GO

DROP TRIGGER IF EXISTS trg_MovieFullDetailsUpdate;
GO

CREATE TRIGGER trg_MovieFullDetailsUpdate
ON MovieFullDetails
FOR UPDATE
AS
BEGIN
    IF EXISTS
    (
        SELECT 1
        FROM inserted i
        LEFT JOIN FilmingDB1.dbo.Movie m
            ON i.MovieID = m.MovieID
        WHERE m.MovieID IS NULL
    )
    BEGIN
        RAISERROR(
            'ERROR2 - The updated MovieID does NOT exist in FilmingDB1.Movie.', 
            16, 
            1
        );
        ROLLBACK TRANSACTION;
    END;

END;
GO

USE FilmingDB1;
GO
INSERT INTO Movie (MovieName, ReleaseDate, Genre)
VALUES ('Dune', '2024-10-01', 'Sci-Fi');


USE FilmingDB2;
GO
INSERT INTO MovieFullDetails (MovieID, Budget, BoxOffice)
VALUES (3, 165000000, 402000000);


select * from FilmingDB1.dbo.Movie
update FilmingDB2.dbo.MovieFullDetails set MovieID=7
where movieID=3
select * from Movie

UPDATE FilmingDB1.dbo.Movie
SET Genre = 'Drama'
WHERE MovieID = 1;

USE FilmingDB2;
GO
UPDATE MovieFullDetails
SET Budget = 180000000
WHERE MovieID = 1;


SELECT * FROM FilmingDB1.dbo.Movie
SELECT * FROM FilmingDB2.dbo.MovieFullDetails
SELECT * FROM FilmingDB1.dbo.vw_MovieDetails


USE master;
GO

DROP DATABASE FilmingDB1;
GO

DROP DATABASE FilmingDB2;
GO

