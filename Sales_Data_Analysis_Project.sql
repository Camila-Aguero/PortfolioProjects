Query 1: Montly Sales Analysis

-- This query extracts and manipulates sales data to focus on monthly sales.
-- It converts the OrderDateKey to a character type for month and year extraction and filters the data
-- to include sales for all countries during the year 2012.

SELECT
    FORMAT(CONVERT(DATETIME, SUBSTRING(CAST([OrderDateKey] AS CHAR), 1, 4) + '-' + SUBSTRING(CAST([OrderDateKey] AS CHAR), 5, 2) + '-01'), 'yyyy/MM') AS MonthYear, -- Formats YYYYMM as YYYY/MM
    [SalesOrderNumber] AS OrderNumber, -- Unique identifier of the sales order
    CAST([OrderDate] AS DATE) AS OrderDate -- Date of the sales order with time removed
FROM
    [AdventureWorksDW2019].[dbo].[FactInternetSales] SalesData
WHERE
    SUBSTRING(CAST([OrderDateKey] AS CHAR), 1, 4) = '2012'; -- Filters data for the year 2013

Query 2: Product Sales By Sub-Categories Analysis

-- This query examines product sales categorized by subcategories.
-- It provides insights into how different product subcategories perform in terms of sales.
-- Valuable information for optimizing product strategies.

WITH CTE_ProductSales AS (
    -- Common Table Expression to join and analyze sales data
    SELECT
        P.EnglishProductName AS ProductName,
        PS.EnglishProductSubcategoryName AS ProductSubcategory,
        S.SalesOrderNumber
    FROM
        [AdventureWorksDW2019].[dbo].[FactInternetSales] S
    JOIN
        AdventureWorksDW2019.DBO.DimCustomer C ON S.CustomerKey = C.CustomerKey
    JOIN
        AdventureWorksDW2019.DBO.DimProduct P ON S.ProductKey = P.ProductKey
    JOIN
        [AdventureWorksDW2019].[DBO].[DimProductSubcategory] PS ON P.ProductSubcategoryKey = PS.ProductSubcategoryKey
)
SELECT
    ProductSubcategory AS ProductType,
    COUNT(SalesOrderNumber) AS TotalSales -- Counting the number of sales for each product subcategory

Query 3: Sales by Customers with Children and No Children

-- Common Table Expression (CTE) to retrieve sales data for bike-related products
WITH bike_sales AS
(
    -- Retrieves relevant columns for bike sales, joining necessary tables and applying filters
    SELECT
        orderdatekey,
        OrderDate,
        CustomerKey,
        BirthDate,
        YearlyIncome,
        TotalChildren,
        CommuteDistance,
        englishcountryregionname AS Country,
        SalesAmount,
        SalesOrderNumber
    FROM [AdventureWorksDW2019].[dbo].[FactInternetSales] T1
    JOIN [AdventureWorksDW2019].[dbo].[DimCustomer] T2 ON T1.CustomerKey = T2.CustomerKey
    JOIN [AdventureWorksDW2019].[dbo].[DimGeography] T3 ON T2.Geographykey = T3.Geographykey
    JOIN [AdventureWorksDW2019].[dbo].[DimProduct] T4 ON T1.ProductKey = T4.ProductKey
    JOIN [AdventureWorksDW2019].[dbo].[DimProductSubcategory] T5 ON T4.ProductSubcategoryKey = T5.ProductSubcategoryKey
    WHERE EnglishProductSubcategoryName IN ('Mountain Bikes', 'Touring Bikes', 'Road Bikes')
)

-- Building upon the "bike_sales" CTE to further analyze sales data
SELECT
    SUBSTRING(CAST(Orderdatekey AS char), 1, 6) AS month_key,
    CASE
        WHEN TotalChildren = 0 THEN 'No Children'
        ELSE 'Has Children'
    END AS 'Has Children',
    COUNT(salesordernumber) AS sales
-- Filtering the data to include only sales orders from the year 2012 based on the substring of the Orderdatekey column
FROM bike_sales
WHERE SUBSTRING(CAST(Orderdatekey AS char), 1, 4) = '2012'
-- Grouping the results by the month_key and TotalChildren
GROUP BY
    SUBSTRING(CAST(Orderdatekey AS char), 1, 6),
    TotalChildren;

Query 4: Sales By Country Analysis

-- Common Table Expression (CTE) to join and analyze sales data
WITH CTE_Sales AS (
    SELECT
        -- Selecting relevant columns from the data
        G.EnglishCountryRegionName AS RegionName,
        S.SalesOrderNumber AS OrderNumber,
        CAST(S.OrderDate AS DATE) AS OrderDate
    FROM
        [AdventureWorksDW2019].[dbo].[FactInternetSales] AS S
    JOIN
        AdventureWorksDW2019.DBO.DimCustomer AS C ON S.CustomerKey = C.CustomerKey
    JOIN
        AdventureWorksDW2019.DBO.DimGeography AS G ON C.GeographyKey = G.GeographyKey
    WHERE
        SUBSTRING(CAST(S.OrderDateKey AS CHAR), 1, 4) = '2013' -- Filters data for the year 2013
)
-- Analyzing sales data for countries
SELECT
    RegionName AS Country,
    COUNT(OrderNumber) AS TotalSales -- Counting the number of sales for each country
FROM
    CTE_Sales
GROUP BY
    RegionName
ORDER BY
    RegionName; -- Controlling the order of the rows

Query 5: Sales by Commute Distance Analysis

-- Common Table Expression (CTE) to retrieve sales data for commute distance
WITH CommuteSales AS
(
    -- Retrieves relevant columns for sales by commute distance, joining necessary tables and applying filters
    SELECT
        CommuteDistance,
        SalesOrderNumber
    FROM [AdventureWorksDW2019].[dbo].[FactInternetSales] T1
    JOIN [AdventureWorksDW2019].[dbo].[DimCustomer] T2 ON T1.CustomerKey = T2.CustomerKey
    JOIN [AdventureWorksDW2019].[dbo].[DimGeography] T3 ON T2.Geographykey = T3.Geographykey
    JOIN [AdventureWorksDW2019].[dbo].[DimProduct] T4 ON T1.ProductKey = T4.ProductKey
    JOIN [AdventureWorksDW2019].[dbo].[DimProductSubcategory] T5 ON T4.ProductSubcategoryKey = T5.ProductSubcategoryKey
    WHERE EnglishProductSubcategoryName IN ('Mountain Bikes', 'Touring Bikes', 'Road Bikes')
)

-- Analyzing sales data by commute distance
SELECT
    CommuteDistance,
    COUNT(DISTINCT SalesOrderNumber) AS Sales
FROM CommuteSales
GROUP BY CommuteDistance
ORDER BY CommuteDistance;

Query 6: Sales BY Age Groups

-- Analyzing Sales by Customer Age Groups

-- This query examines sales data categorized by customer age groups.
-- It calculates customer ages based on birthdates and order dates, and then analyzes sales data.
-- Understanding how different age groups engage with products can help optimize marketing strategies.

WITH CTE_SalesAge AS (
    -- Common Table Expression to join and analyze sales data
    SELECT
        G.EnglishCountryRegionName,
        DATEDIFF(YEAR, C.BirthDate, S.ORDERDATE) AS CustomerAge, -- Calculate customer ages when they placed orders
        S.SalesOrderNumber
    FROM
        [AdventureWorksDW2019].[dbo].[FactInternetSales] AS S
    JOIN
        AdventureWorksDW2019.DBO.DimCustomer AS C ON S.CustomerKey = C.CustomerKey
    JOIN
        AdventureWorksDW2019.DBO.DimGeography AS G ON C.GeographyKey = G.GeographyKey
)
-- Creating age groups using CASE WHEN statements to analyze sales by age groups
SELECT
    EnglishCountryRegionName,
    CASE
        WHEN CustomerAge < 30 THEN 'a: Under 30'
        WHEN CustomerAge BETWEEN 30 AND 40 THEN 'b: 30 - 40'
        WHEN CustomerAge BETWEEN 40 AND 50 THEN 'c: 40 - 50'
        WHEN CustomerAge BETWEEN 50 AND 60 THEN 'd: 50 - 60'
        WHEN CustomerAge > 60 THEN 'e: Over 60'
        ELSE 'Other'
    END AS AgeGroup,
    COUNT(SalesOrderNumber) AS TotalSales -- Counting the number of sales in each age group
FROM
    CTE_SalesAge
GROUP BY
    EnglishCountryRegionName,
    CASE
        WHEN CustomerAge < 30 THEN 'a: Under 30'
        WHEN CustomerAge BETWEEN 30 AND 40 THEN 'b: 30 - 40'
        WHEN CustomerAge BETWEEN 40 AND 50 THEN 'c: 40 - 50'
        WHEN CustomerAge BETWEEN 50 AND 60 THEN 'd: 50 - 60'
        WHEN CustomerAge > 60 THEN 'e: Over 60'
        ELSE 'Other'
    END
ORDER BY
    EnglishCountryRegionName,
    AgeGroup; -- Controlling the order of the rows


