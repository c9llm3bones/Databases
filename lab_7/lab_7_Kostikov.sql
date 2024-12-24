USE master;
GO

USE FilmingDB;
GO

DROP VIEW IF EXISTS vw_MovieDetails;
DROP VIEW IF EXISTS vw_MovieStudioDetails;
DROP INDEX IF EXISTS idx_Movie_MovieName ON Movie;
DROP INDEX IF EXISTS idx_vw_GenreMovieCount ON vw_GenreMovieCount;
DROP VIEW IF EXISTS vw_GenreMovieCount;
GO

-- 1. Создать представление на основе одной из таблиц (Movie)
CREATE VIEW vw_MovieDetails
AS
SELECT
    MovieID,
    MovieName,
    ReleaseDate,
    Genre,
    RatingAge,
    Duration
FROM Movie
WHERE Genre = 'Sci-Fi'
WITH CHECK OPTION;
GO

SELECT * FROM vw_MovieDetails;
GO

-- 2. Создать представление на основе полей обеих связанных таблиц (Movie и Studio)
CREATE VIEW vw_MovieStudioDetails
AS
SELECT
    m.MovieID,
    m.MovieName,
    s.StudioID,
    s.StudioName,
    s.Country,
    s.FoundationYear
FROM Movie m
JOIN MovieStudio ms ON m.MovieID = ms.MovieID
JOIN Studio s ON s.StudioID = ms.StudioID;
GO

SELECT * FROM vw_MovieStudioDetails;
GO

-- 3. Создать индекс для одной из таблиц (Movie), включив дополнительные неключевые поля
CREATE NONCLUSTERED INDEX idx_Movie_MovieName
ON Movie (MovieName, Genre)
INCLUDE (ReleaseDate);
GO

-- индекс в запросе
SELECT
    MovieID,
    MovieName,
    Genre,
    ReleaseDate
FROM Movie
WHERE MovieName = 'Inception' AND Genre = 'Sci-Fi';
GO

-- 4. Создать индексированное представление
CREATE VIEW vw_GenreMovieCount
WITH SCHEMABINDING
AS
SELECT
    Genre,
    COUNT_BIG(*) AS MovieCount
FROM dbo.Movie
GROUP BY Genre;
GO

ALTER TABLE Movie ALTER COLUMN MovieName INT;
GO

ALTER TABLE Movie ALTER COLUMN Genre INT;
GO

ALTER TABLE Movie ADD ReleaseYear INT;
GO

SELECT * FROM Movie;
GO


-- уникальный кластеризованный индекс 
CREATE UNIQUE CLUSTERED INDEX idx_vw_GenreMovieCount
ON vw_GenreMovieCount (Genre);
GO

-- некластеризованный индекс
CREATE NONCLUSTERED INDEX idx_vw_GenreMovieCount_MovieCount
ON vw_GenreMovieCount (MovieCount);
GO

SELECT * FROM vw_GenreMovieCount;
GO

SELECT Genre, MovieCount
FROM vw_GenreMovieCount
WHERE MovieCount > 1;
GO
