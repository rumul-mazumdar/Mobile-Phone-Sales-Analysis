create database Mobile_Phones;

use Mobile_Phones;

select * from [dbo].[top 120 best-selling mobile phones];



--1. Complex Queries:

--○ Write a query to list the top 5 models with the highest units sold in
--each year.

WITH RankedModels AS
(
    SELECT
        Year,
        Manufacturer,
        Model,
        Units_Sold_million,

        ROW_NUMBER() OVER
        (
            PARTITION BY Year
            ORDER BY Units_Sold_million DESC
        ) AS rank_in_year

    FROM [dbo].[top 120 best-selling mobile phones]
)

SELECT
    Year,
    Manufacturer,
    Model,
    Units_Sold_million,
    rank_in_year
FROM RankedModels
WHERE rank_in_year <= 5
ORDER BY Year, rank_in_year;

--○ Use a CTE to rank manufacturers based on their total units sold and
--display the top 3.

WITH ManufacturerSales AS
(
    SELECT
        Manufacturer,
        SUM(Units_Sold_million) AS Total_Units_Sold
    FROM [dbo].[top 120 best-selling mobile phones]
    GROUP BY Manufacturer
),
RankedManufacturers AS
(
    SELECT
        Manufacturer,
        Total_Units_Sold,
        ROW_NUMBER() OVER
        (
            ORDER BY Total_Units_Sold DESC
        ) AS manufacturer_rank
    FROM ManufacturerSales
)

SELECT
    Manufacturer,
    Total_Units_Sold,
    manufacturer_rank
FROM RankedManufacturers
WHERE manufacturer_rank <= 3
ORDER BY manufacturer_rank;


--○ Develop a stored function to calculate the average units sold for a
--given manufacturer.

CREATE FUNCTION dbo.GetAverageUnitsSold
(
    @Manufacturer VARCHAR(100)
)
RETURNS DECIMAL(10,2)
AS
BEGIN

    DECLARE @AverageUnits DECIMAL(10,2);

    SELECT @AverageUnits =
        AVG(Units_Sold_million)
    FROM [dbo].[top 120 best-selling mobile phones]
    WHERE Manufacturer = @Manufacturer;

    RETURN @AverageUnits;

END;


SELECT dbo.GetAverageUnitsSold('Apple') AS Average_Units_Sold;


--2. Advanced SQL Functions:
--○ Use window functions to calculate the moving average of units sold
--per manufacturer.

SELECT
    Manufacturer,
    Year,
    Units_Sold_million,

    AVG(Units_Sold_million) OVER
    (
        PARTITION BY Manufacturer
        ORDER BY Year
        ROWS BETWEEN 3 PRECEDING AND CURRENT ROW
    ) AS Moving_Average

FROM [dbo].[top 120 best-selling mobile phones]

ORDER BY Manufacturer, Year;

--○ Create a trigger to log changes in units sold when a model's details
--are updated.

CREATE TABLE UnitsSold_Log
(
    LogID INT IDENTITY(1,1) PRIMARY KEY,
    Model VARCHAR(200),
    Old_Units_Sold DECIMAL(18,2),
    New_Units_Sold DECIMAL(18,2),
    Changed_Date DATETIME DEFAULT GETDATE()
);


CREATE TRIGGER trg_LogUnitsSoldChange
ON [dbo].[top 120 best-selling mobile phones]
AFTER UPDATE
AS
BEGIN

    INSERT INTO UnitsSold_Log
    (
        Model,
        Old_Units_Sold,
        New_Units_Sold
    )
    SELECT
        i.Model,
        d.Units_Sold_million,
        i.Units_Sold_million
    FROM inserted AS i
    INNER JOIN deleted AS d
        ON i.Rank = d.Rank
    WHERE i.Units_Sold_million <> d.Units_Sold_million;

END;

SELECT *
FROM [dbo].[top 120 best-selling mobile phones]
WHERE Rank = 4;

UPDATE [dbo].[top 120 best-selling mobile phones]
SET Units_Sold_million = 500
WHERE Rank = 4;

SELECT *
FROM UnitsSold_Log;