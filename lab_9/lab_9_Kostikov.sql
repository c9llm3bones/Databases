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
    Duration INT CHECK (Duration > 0),
    CONSTRAINT AK_Movie_MovieName_ReleaseDate UNIQUE (MovieName, ReleaseDate)
);
GO

INSERT INTO Movie (MovieName, Genre, RatingAge, Duration) VALUES
('Inception', 'Sci-Fi', 16, 148),
('Interstellar', 'Sci-Fi', 12, 169);
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

DROP TABLE IF EXISTS TriggerJournal;
GO

CREATE TABLE TriggerJournal(
    id INT IDENTITY(1, 1) PRIMARY KEY,
    StudioID INT NOT NULL,
    Operation NVARCHAR(200) NOT NULL,
    CreatedAt DATETIME NOT NULL DEFAULT GETDATE(),
);
GO
-- 1
DROP TRIGGER IF EXISTS InsertStudio;
GO

CREATE TRIGGER InsertStudio 
    ON Studio
    AFTER INSERT
AS
    INSERT INTO TriggerJournal (StudioID, Operation)
    SELECT StudioID, StudioName + ' Was inserted into table Studio'
    FROM inserted
GO

INSERT INTO Studio (StudioName) VALUES
('A24'),
('Riga Film Studio');
GO

SELECT * FROM Studio;
SELECT * FROM TriggerJournal;
GO

DROP TRIGGER IF EXISTS UpdateStudio;
GO

CREATE TRIGGER UpdateStudio
    ON Studio
    AFTER UPDATE
AS
    INSERT INTO TriggerJournal (StudioID, Operation)
    SELECT StudioID, StudioName + ' Was updated'
    FROM inserted
GO

--UPDATE Studio SET Phone = '880035504' WHERE StudioName = 'A24'
GO

SELECT * FROM Studio
SELECT * FROM TriggerJournal
GO

DROP TRIGGER IF EXISTS DeleteStudio;
GO

CREATE TRIGGER DeleteStudio
    ON Studio
    AFTER DELETE
AS
BEGIN
    DECLARE @CountStudios INT;
    SELECT @CountStudios = COUNT(*) FROM Studio;

    IF @CountStudios < 1
    BEGIN
        RAISERROR ('No more studio deletions !!!', 16, 1);
        ROLLBACK TRANSACTION
        RETURN;
    END;

    INSERT INTO TriggerJournal (StudioID, Operation)
    SELECT StudioID, 'Studio ' + StudioName + ' Was deleted'
    FROM deleted;
    
END;
GO

DELETE FROM Studio WHERE Phone IS NULL;
GO

SELECT * FROM Studio
SELECT * FROM TriggerJournal
GO


--- новая таблица для связи 1-1

CREATE TABLE MovieDetails (
    MovieID INT PRIMARY KEY, -- Связь с Movie через первичный ключ
    Budget INT NOT NULL, -- Бюджет фильма
    BoxOffice INT NOT NULL, -- Кассовые сборы
    FOREIGN KEY (MovieID) REFERENCES Movie(MovieID) ON DELETE CASCADE
);
GO


INSERT INTO MovieDetails (MovieID, Budget, BoxOffice)
VALUES
    (1, 160000000, 829895144), -- Данные для Inception
    (2, 165000000, 677471339); -- Данные для Interstellar
GO

CREATE VIEW vw_MovieFullDetails
AS
SELECT 
    m.MovieID,
    m.MovieName,
    m.ReleaseDate,
    m.Genre,
    m.RatingAge,
    m.Duration,
    md.Budget,
    md.BoxOffice
FROM Movie m
LEFT JOIN MovieDetails md ON m.MovieID = md.MovieID;
GO

DROP TRIGGER IF EXISTS trg_Insert_vw_MovieFullDetails;
GO

CREATE TRIGGER trg_Insert_vw_MovieFullDetails
ON vw_MovieFullDetails
INSTEAD OF INSERT
AS
BEGIN
    -- ввод MovieID
    IF EXISTS (SELECT 1 FROM inserted WHERE MovieID IS NOT NULL)
    BEGIN
        RAISERROR('Manual insertion of MovieID is not allowed !!!', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END;

    BEGIN TRY
        -- Вставка данных 
        INSERT INTO Movie (MovieName, ReleaseDate, Genre, RatingAge, Duration)
        SELECT 
            i.MovieName,
            i.ReleaseDate,
            i.Genre,
            i.RatingAge,
            i.Duration
        FROM inserted i;

        INSERT INTO MovieDetails (MovieID, Budget, BoxOffice)
        SELECT 
            m.MovieID,
            i.Budget,
            i.BoxOffice
        FROM inserted i
        JOIN Movie m 
        ON i.MovieName = m.MovieName AND i.ReleaseDate = m.ReleaseDate;
    END TRY
    BEGIN CATCH
        RAISERROR('Error occurred during insert: %s', 16, 1);
        ROLLBACK TRANSACTION;
    END CATCH;
END;
GO


/*
INSERT INTO vw_MovieFullDetails (MovieID, MovieName, Genre, ReleaseDate, Country)
VALUES 
    (1, 'Shrek', 'Warner Bros.', GETDATE(), 'US'), 
    (2, 'Pinokkio', 'Paramount Pictures', GETDATE(), 'US');
GO

INSERT INTO vw_MovieFullDetails (MovieName, StudioName, ReleaseDate, Country)
VALUES 
    ('Shrek', 'Warner Bros.', GETDATE(), 'US');
GO

INSERT INTO vw_MovieFullDetails (MovieName, StudioName, ReleaseDate, Country)
VALUES 
    ('Shrek1', 'Bethesda', GETDATE(), 'US');
GO
*/

INSERT INTO vw_MovieFullDetails (MovieID, MovieName, ReleaseDate, Genre, RatingAge, Duration, Budget, BoxOffice)
VALUES
    (1, 'Dune', GETDATE(), 'Sci-Fi', 13, 155, 165000000, 402000000);
GO

INSERT INTO vw_MovieFullDetails (MovieName, ReleaseDate, Genre, RatingAge, Duration, Budget, BoxOffice)
VALUES
    ('Dune', GETDATE(), 'Sci-Fi', 13, 155, 165000000, 402000000),
    ('Dune', GETDATE(), 'Sci-Fi', 13, 155, 165000000, 402000000);
GO

SELECT * FROM Movie;
SELECT * FROM MovieDetails;
SELECT * FROM vw_MovieFullDetails;
GO


DROP TRIGGER IF EXISTS trg_Delete_vw_MovieFullDetails;
GO

CREATE TRIGGER trg_Delete_vw_MovieFullDetails
ON vw_MovieFullDetails
INSTEAD OF DELETE
AS
BEGIN
    DELETE FROM MovieDetails
    WHERE MovieID IN (SELECT MovieID FROM deleted);

    DELETE FROM Movie
    WHERE MovieID IN (SELECT MovieID FROM deleted);
END;
GO

--DELETE FROM vw_MovieFullDetails WHERE MovieID = 1;
GO

SELECT * FROM Movie
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
        UPDATE Movie
        SET 
            MovieName = i.MovieName,
            ReleaseDate = i.ReleaseDate,
            Genre = i.Genre,
            RatingAge = i.RatingAge,
            Duration = i.Duration
        FROM Movie m
        JOIN inserted i ON m.MovieID = i.MovieID;

        UPDATE MovieDetails
        SET 
            Budget = i.Budget,
            BoxOffice = i.BoxOffice
        FROM MovieDetails md
        JOIN inserted i ON md.MovieID = i.MovieID;
    END TRY
    BEGIN CATCH
        RAISERROR('Error occurred during update: %s', 16, 1);
        ROLLBACK TRANSACTION;
    END CATCH;
END;
GO



UPDATE vw_MovieFullDetails
SET 
    MovieName = 'Dune',
    ReleaseDate = '2024-01-01'
WHERE MovieID = 1;

UPDATE vw_MovieFullDetails
SET 
    MovieName = 'Dune',
    ReleaseDate = '2024-01-01'
WHERE MovieID = 2;

SELECT * FROM Movie
GO