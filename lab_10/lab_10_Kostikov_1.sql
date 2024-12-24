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