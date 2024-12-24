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

DROP VIEW IF EXISTS vw_Movies;
GO

CREATE VIEW vw_Movies AS
SELECT * FROM FilmingDB1.dbo.Movie
UNION ALL
SELECT * FROM FilmingDB2.dbo.Movie;
GO

INSERT INTO vw_Movies (MovieID, MovieName, ReleaseDate, Genre)
VALUES
(3, 'Avatar', '2009-12-18', 'Sci-Fi'),
(11, 'Dune: Part Two', '2023-11-03', 'Sci-Fi');
GO

SELECT * FROM vw_Movies;
GO

SELECT * FROM FilmingDB1.dbo.Movie;
SELECT * FROM FilmingDB2.dbo.Movie;
GO

UPDATE vw_Movies
SET MovieID = 5
WHERE MovieID = 11;
GO

SELECT * FROM FilmingDB1.dbo.Movie;
SELECT * FROM FilmingDB2.dbo.Movie;
GO

DELETE FROM vw_Movies
WHERE MovieID = 2;
GO

SELECT * FROM FilmingDB1.dbo.Movie;
SELECT * FROM FilmingDB2.dbo.Movie;
GO

