USE master;
GO

IF DB_ID('FilmingDB') IS NOT NULL
DROP DATABASE FilmingDB;
GO

CREATE DATABASE FilmingDB
GO

USE FilmingDB;
GO

DROP TABLE IF EXISTS Movie;
GO

CREATE TABLE Movie (
    MovieID INT IDENTITY(1,1) PRIMARY KEY,
    MovieName NVARCHAR(50) NOT NULL,
    ReleaseDate DATE NOT NULL,
    Genre NVARCHAR(50) NOT NULL,
    Budget DECIMAL(18, 2) CHECK (Budget > 0) NOT NULL
);
GO

INSERT INTO Movie (MovieName, ReleaseDate, Genre, Budget)
VALUES
('Inception', '2010-07-16', 'Sci-Fi', 160000000),
('Interstellar', '2014-11-07', 'Sci-Fi', 165000000),
('Dune', '2021-10-22', 'Sci-Fi', 165000000),
('Tenet', '2020-08-26', 'Sci-Fi', 200000000);
GO

SELECT * FROM Movie;
GO


USE FilmingDB;
GO

-- Различные уровни изоляции

-- 1) (READ UNCOMMITTED)
/*
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
BEGIN TRANSACTION;
    SELECT * FROM Movie;
    WAITFOR DELAY '00:00:15';
    SELECT * FROM Movie;
COMMIT TRANSACTION;
GO
*/

-- 2) Завершённое чтение (READ COMMITTED)
/*
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
BEGIN TRANSACTION;
    SELECT * FROM Movie;
    WAITFOR DELAY '00:00:15';
    SELECT * FROM Movie;
COMMIT TRANSACTION;
GO
*/

-- 3) Воспроизводимое чтение (REPEATABLE READ)

SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;
BEGIN TRANSACTION;
    SELECT * FROM Movie;
    WAITFOR DELAY '00:00:15';
    SELECT * FROM Movie;
COMMIT TRANSACTION;
GO


-- 4) Serializable
/*
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
BEGIN TRANSACTION;
    SELECT * FROM Movie;
    WAITFOR DELAY '00:00:15';
    SELECT * FROM Movie;
COMMIT TRANSACTION;
GO
*/


USE FilmingDB;
GO

-- Тестовые транзакции

-- 1) Обновление с блокировкой
/*
BEGIN TRANSACTION;
    UPDATE Movie SET Genre = 'Action' WHERE MovieName = 'Tenet';
    WAITFOR DELAY '00:00:15';
    ROLLBACK TRANSACTION;
GO
*/

-- 2) Обновление и чтение с блокировкой
/*
BEGIN TRANSACTION;
    UPDATE Movie SET Budget = Budget + 1000000 WHERE MovieName = 'Dune';
    SELECT * FROM Movie;
    COMMIT TRANSACTION;
GO
*/

-- 3) Обновление и вставка

BEGIN TRANSACTION;
    UPDATE Movie SET Budget = Budget * 1.1 WHERE MovieName = 'Inception';
    INSERT INTO Movie (MovieName, ReleaseDate, Genre, Budget)
    VALUES ('Avatar', '2009-12-18', 'Sci-Fi', 237000000);
    SELECT * FROM Movie;
    COMMIT TRANSACTION;
GO


-- 4) Вставка с проверкой
/*
BEGIN TRANSACTION;
    INSERT INTO Movie (MovieName, ReleaseDate, Genre, Budget)
    VALUES ('Blade Runner 2049', '2017-10-06', 'Sci-Fi', 150000000);
    SELECT * FROM Movie;
    COMMIT TRANSACTION;
GO
*/
