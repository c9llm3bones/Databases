USE master;
GO

USE FilmingDB;
GO

DROP PROCEDURE IF EXISTS sp_GetMoviesCursor;
GO
-- 1 
CREATE PROCEDURE sp_GetMoviesCursor
AS
BEGIN
    DECLARE movieCursor CURSOR FOR
    SELECT MovieID, MovieName
    FROM Movie;

    OPEN movieCursor;
    RETURN;
END;
GO

DECLARE @movieCursor CURSOR;
EXEC sp_GetMoviesCursor;

GO
DECLARE @MovieID INT;
DECLARE @MovieName NVARCHAR(50);

FETCH NEXT FROM movieCursor INTO @MovieID, @MovieName;

WHILE @@FETCH_STATUS = 0
BEGIN
    PRINT CONCAT('Movie ID: ', @MovieID, ', Movie Name: ', @MovieName);
    FETCH NEXT FROM movieCursor INTO @MovieID, @MovieName;
END;

CLOSE movieCursor;
DEALLOCATE movieCursor;
GO



-- 2 
-- функция, формирующая столбец с длиной названия фильма
DROP FUNCTION IF EXISTS fn_MovieNameLength;
DROP PROCEDURE IF EXISTS sp_GetMoviesWithFunction;
GO

CREATE FUNCTION fn_MovieNameLength(@MovieName NVARCHAR(50))
RETURNS INT
AS
BEGIN
    RETURN LEN(@MovieName);
END;
GO

--  процедура с дополнительным столбцом
CREATE PROCEDURE sp_GetMoviesWithFunction
AS
BEGIN
    DECLARE movieCursor CURSOR FOR
    SELECT MovieID, 
           MovieName, 
           Genre, 
           ReleaseDate,
           dbo.fn_MovieNameLength(MovieName) AS NameLength
    FROM Movie;

    OPEN movieCursor;
    RETURN;
END;
GO

-- вызов процедуры
DECLARE @movieCursor CURSOR;
EXEC sp_GetMoviesWithFunction;

DECLARE @MovieID INT;
DECLARE @MovieName NVARCHAR(50);
DECLARE @Genre NVARCHAR(50);
DECLARE @ReleaseDate SMALLDATETIME;
DECLARE @NameLength INT;

FETCH NEXT FROM movieCursor INTO @MovieID, @MovieName, @Genre, @ReleaseDate, @NameLength;

WHILE @@FETCH_STATUS = 0
BEGIN
    PRINT CONCAT(@MovieID, @MovieName, @Genre, @ReleaseDate, @NameLength);
    FETCH NEXT FROM movieCursor INTO @MovieID, @MovieName, @Genre, @ReleaseDate, @NameLength;
END;

DEALLOCATE movieCursor;
GO


-- 3
-- Функция, проверяющая длину названия фильма
DROP FUNCTION IF EXISTS fn_IsMovieNameLong;

GO
CREATE FUNCTION fn_IsMovieNameLong(@NameLength INT)
RETURNS NVARCHAR(50)
AS
BEGIN
    DECLARE @Result NVARCHAR(50);

    IF @NameLength > 5
        SET @Result = 'Long movie name';
    ELSE
        SET @Result = 'Short movie name';

    RETURN @Result;
END;
GO

DROP PROCEDURE IF EXISTS sp_ProcessMoviesCursor;
GO

-- Хранимая процедура, прокручивающая курсор
CREATE PROCEDURE sp_ProcessMoviesCursor
AS
BEGIN
    DECLARE @MovieID INT;
    DECLARE @MovieName NVARCHAR(50);
    DECLARE @NameLength INT;

    DECLARE @movieCursor CURSOR
    exec sp_GetMoviesCursor;

    FETCH NEXT FROM movieCursor INTO @MovieID, @MovieName;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @NameLength = LEN(@MovieName);
        PRINT CONCAT('Movie: ', @MovieName, ' | Message: ', dbo.fn_IsMovieNameLong(@NameLength));

        FETCH NEXT FROM movieCursor INTO @MovieID, @MovieName;
    END;

    CLOSE movieCursor;
    DEALLOCATE movieCursor;
END;
GO

EXEC sp_ProcessMoviesCursor;
GO


--4
DROP FUNCTION IF EXISTS fn_GetMoviesWithLength;
DROP PROCEDURE IF EXISTS sp_GetMoviesWithTableFunction;
GO

CREATE FUNCTION fn_GetMoviesWithLength()
RETURNS TABLE
AS
RETURN
(
    SELECT MovieID,
           MovieName,
           Genre,
           ReleaseDate,
           dbo.fn_IsMovieNameLong(LEN(MovieName)) AS NameLength
    FROM Movie
);
GO


DROP FUNCTION IF EXISTS fn_GetMoviesWithLengthv2;
GO

-- В несокращенной форме 
CREATE FUNCTION fn_GetMoviesWithLengthv2()
RETURNS @Result TABLE (
    MovieID INT,
    MovieName NVARCHAR(50),
    Genre NVARCHAR(50),
    ReleaseDate SMALLDATETIME,
    NameLength NVARCHAR(50)
)
AS
BEGIN
    
    INSERT INTO @Result (MovieID, MovieName, Genre, ReleaseDate, NameLength)
    SELECT 
        MovieID,
        MovieName,
        Genre,
        ReleaseDate,
        dbo.fn_IsMovieNameLong(LEN(MovieName)) AS NameLength
    FROM Movie;

    RETURN;
END;
GO


-- хранимая процедура, использующая табличную функцию
CREATE PROCEDURE sp_GetMoviesWithTableFunction
AS
BEGIN
    DECLARE movieCursor CURSOR FOR
    SELECT * 
    FROM dbo.fn_GetMoviesWithLengthv2();

    OPEN movieCursor;
    RETURN;
END;
GO

DECLARE @movieCursor CURSOR;
EXEC sp_GetMoviesWithTableFunction;


DECLARE @MovieID INT;
DECLARE @MovieName NVARCHAR(50);
DECLARE @Genre NVARCHAR(50);
DECLARE @ReleaseDate SMALLDATETIME;
DECLARE @NameLength NVARCHAR(50);

FETCH NEXT FROM movieCursor INTO @MovieID, @MovieName, @Genre, @ReleaseDate, @NameLength;

WHILE @@FETCH_STATUS = 0
BEGIN
    PRINT CONCAT(@MovieID, @MovieName, @Genre, @ReleaseDate, @NameLength);
    FETCH NEXT FROM movieCursor INTO @MovieID, @MovieName, @Genre, @ReleaseDate, @NameLength;
END;

DEALLOCATE movieCursor;
GO