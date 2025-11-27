--*************************************************************************--
-- Title: Assignment07
-- Author: ABigley
-- Desc: This file demonstrates how to use Functions
-- Change Log: When,Who,What
-- 2025-11-19,ABigley,Created File
--**************************************************************************--
Begin Try
	Use Master;
	If Exists(Select Name From SysDatabases Where Name = 'Assignment07DB_ABigley')
	 Begin 
	  Alter Database [Assignment07DB_ABigley] set Single_user With Rollback Immediate;
	  Drop Database Assignment07DB_ABigley;
	 End
	Create Database Assignment07DB_ABigley;
End Try
Begin Catch
	Print Error_Number();
End Catch
go
Use Assignment07DB_ABigley;

-- Create Tables (Module 01)-- 
Create Table Categories
([CategoryID] [int] IDENTITY(1,1) NOT NULL 
,[CategoryName] [nvarchar](100) NOT NULL
);
go

Create Table Products
([ProductID] [int] IDENTITY(1,1) NOT NULL 
,[ProductName] [nvarchar](100) NOT NULL 
,[CategoryID] [int] NULL  
,[UnitPrice] [money] NOT NULL
);
go

Create Table Employees -- New Table
([EmployeeID] [int] IDENTITY(1,1) NOT NULL 
,[EmployeeFirstName] [nvarchar](100) NOT NULL
,[EmployeeLastName] [nvarchar](100) NOT NULL 
,[ManagerID] [int] NULL  
);
go

Create Table Inventories
([InventoryID] [int] IDENTITY(1,1) NOT NULL
,[InventoryDate] [Date] NOT NULL
,[EmployeeID] [int] NOT NULL
,[ProductID] [int] NOT NULL
,[ReorderLevel] int NOT NULL -- New Column 
,[Count] [int] NOT NULL
);
go

-- Add Constraints (Module 02) -- 
Begin  -- Categories
	Alter Table Categories 
	 Add Constraint pkCategories 
	  Primary Key (CategoryId);

	Alter Table Categories 
	 Add Constraint ukCategories 
	  Unique (CategoryName);
End
go 

Begin -- Products
	Alter Table Products 
	 Add Constraint pkProducts 
	  Primary Key (ProductId);

	Alter Table Products 
	 Add Constraint ukProducts 
	  Unique (ProductName);

	Alter Table Products 
	 Add Constraint fkProductsToCategories 
	  Foreign Key (CategoryId) References Categories(CategoryId);

	Alter Table Products 
	 Add Constraint ckProductUnitPriceZeroOrHigher 
	  Check (UnitPrice >= 0);
End
go

Begin -- Employees
	Alter Table Employees
	 Add Constraint pkEmployees 
	  Primary Key (EmployeeId);

	Alter Table Employees 
	 Add Constraint fkEmployeesToEmployeesManager 
	  Foreign Key (ManagerId) References Employees(EmployeeId);
End
go

Begin -- Inventories
	Alter Table Inventories 
	 Add Constraint pkInventories 
	  Primary Key (InventoryId);

	Alter Table Inventories
	 Add Constraint dfInventoryDate
	  Default GetDate() For InventoryDate;

	Alter Table Inventories
	 Add Constraint fkInventoriesToProducts
	  Foreign Key (ProductId) References Products(ProductId);

	Alter Table Inventories 
	 Add Constraint ckInventoryCountZeroOrHigher 
	  Check ([Count] >= 0);

	Alter Table Inventories
	 Add Constraint fkInventoriesToEmployees
	  Foreign Key (EmployeeId) References Employees(EmployeeId);
End 
go

-- Adding Data (Module 04) -- 
Insert Into Categories 
(CategoryName)
Select CategoryName 
 From Northwind.dbo.Categories
 Order By CategoryID;
go

Insert Into Products
(ProductName, CategoryID, UnitPrice)
Select ProductName,CategoryID, UnitPrice 
 From Northwind.dbo.Products
  Order By ProductID;
go

Insert Into Employees
(EmployeeFirstName, EmployeeLastName, ManagerID)
Select E.FirstName, E.LastName, IsNull(E.ReportsTo, E.EmployeeID) 
 From Northwind.dbo.Employees as E
  Order By E.EmployeeID;
go

Insert Into Inventories
(InventoryDate, EmployeeID, ProductID, [Count], [ReorderLevel]) -- New column added this week
Select '20170101' as InventoryDate, 5 as EmployeeID, ProductID, UnitsInStock, ReorderLevel
From Northwind.dbo.Products
UNIOn
Select '20170201' as InventoryDate, 7 as EmployeeID, ProductID, UnitsInStock + 10, ReorderLevel -- Using this is to create a made up value
From Northwind.dbo.Products
UNIOn
Select '20170301' as InventoryDate, 9 as EmployeeID, ProductID, abs(UnitsInStock - 10), ReorderLevel -- Using this is to create a made up value
From Northwind.dbo.Products
Order By 1, 2
go


-- Adding Views (Module 06) -- 
Create View vCategories With SchemaBinding
 AS
  Select CategoryID, CategoryName From dbo.Categories;
go
Create View vProducts With SchemaBinding
 AS
  Select ProductID, ProductName, CategoryID, UnitPrice From dbo.Products;
go
Create View vEmployees With SchemaBinding
 AS
  Select EmployeeID, EmployeeFirstName, EmployeeLastName, ManagerID From dbo.Employees;
go
Create View vInventories With SchemaBinding 
 AS
  Select InventoryID, InventoryDate, EmployeeID, ProductID, ReorderLevel, [Count] From dbo.Inventories;
go

-- Show the Current data in the Categories, Products, and Inventories Tables
Select * From vCategories;
go
Select * From vProducts;
go
Select * From vEmployees;
go
Select * From vInventories;
go

/********************************* Questions and Answers *********************************/
Print
'NOTES------------------------------------------------------------------------------------ 
 1) You must use the BASIC views for each table.
 2) To make sure the Dates are sorted correctly, you can use Functions in the Order By clause!
------------------------------------------------------------------------------------------'
GO	-- Needed so the CREATE FUNCTION executes as the only statement in the batch.
-- Question 1 (5% of pts):
-- Show a list of Product names and the price of each product.
-- Use a function to format the price as US dollars.
-- Order the result by the product name.
/*Andy's note: Create the function first to format prices in USD*/
CREATE FUNCTION dbo.fnFormatPriceUSD
(
    @UnitPrice MONEY
)
RETURNS NVARCHAR(50)
AS
BEGIN
    RETURN (N'$' + FORMAT(@UnitPrice, 'N2'));
END;
GO
/*Create the query using the function*/
SELECT TOP 100000
       P.ProductName,
       dbo.fnFormatPriceUSD(P.UnitPrice) AS UnitPrice
FROM dbo.vProducts AS P
ORDER BY P.ProductName;
GO

-- Question 2 (10% of pts): 
-- Show a list of Category and Product names, and the price of each product.
-- Use a function to format the price as US dollars.
-- Order the result by the Category and Product.
/*Andy's note: I will reuse the USD formatting function from Question 1.*/
SELECT TOP 100000
       C.CategoryName,
       P.ProductName,
       dbo.fnFormatPriceUSD(P.UnitPrice) AS UnitPrice
FROM dbo.vCategories AS C
     INNER JOIN dbo.vProducts AS P
        ON C.CategoryID = P.CategoryID
ORDER BY 
       C.CategoryName,
       P.ProductName;
GO

-- Question 3 (10% of pts): 
-- Use functions to show a list of Product names, each Inventory Date, and the Inventory Count.
-- Format the date like 'January, 2017'.
-- Order the results by the Product and Date.
/*Andy's note: Create the date formatting function first.*/
CREATE FUNCTION dbo.fnFormatMonthYear
(
    @InputDate DATE
)
RETURNS NVARCHAR(30)
AS
BEGIN
    RETURN FORMAT(@InputDate, 'MMMM, yyyy');
END;
GO
/*Call the function in the view query*/
SELECT TOP 100000
       P.ProductName,
       dbo.fnFormatMonthYear(I.InventoryDate) AS InventoryDate,
       I.[Count] AS InventoryCount
FROM dbo.vProducts AS P
     INNER JOIN dbo.vInventories AS I
        ON P.ProductID = I.ProductID
ORDER BY 
       P.ProductName,
       I.InventoryDate;
GO

-- Question 4 (10% of pts): 
-- CREATE A VIEW called vProductInventories. 
-- Shows a list of Product names, each Inventory Date, and the Inventory Count. 
-- Format the date like 'January, 2017'.
-- Order the results by the Product and Date.
CREATE VIEW dbo.vProductInventories
AS
    SELECT TOP 100000
           P.ProductName,
           dbo.fnFormatMonthYear(I.InventoryDate) AS InventoryDate,   -- formatted
           I.[Count] AS InventoryCount
    FROM dbo.vProducts     AS P
    INNER JOIN dbo.vInventories AS I
        ON P.ProductID = I.ProductID
    ORDER BY
           P.ProductName,
           I.InventoryDate;    -- DATE sort ensures Jan → Feb → Mar
GO

Select * From vProductInventories;
GO

-- Question 5 (10% of pts): 
-- CREATE A VIEW called vCategoryInventories. 
-- Shows a list of Category names, Inventory Dates, and a TOTAL Inventory Count BY CATEGORY
-- Format the date like 'January, 2017'.
-- Order the results by the Product and Date.
CREATE VIEW dbo.vCategoryInventories
AS
    SELECT TOP 100000
           C.CategoryName,
           dbo.fnFormatMonthYear(I.InventoryDate) AS InventoryDate,
           SUM(I.[Count]) AS InventoryCountByCategory
    FROM dbo.vCategories   AS C
         INNER JOIN dbo.vProducts    AS P
             ON C.CategoryID = P.CategoryID
         INNER JOIN dbo.vInventories AS I
             ON P.ProductID = I.ProductID
    GROUP BY
           C.CategoryName,
           I.InventoryDate
    ORDER BY
           C.CategoryName,
           I.InventoryDate;
GO

Select * From vCategoryInventories;
GO

-- Question 6 (10% of pts): 
-- CREATE ANOTHER VIEW called vProductInventoriesWithPreviouMonthCounts. 
-- Show a list of Product names, Inventory Dates, Inventory Count, AND the Previous Month Count.
-- Use functions to set any January NULL counts to zero. 
-- Order the results by the Product and Date. 
-- This new view must use your vProductInventories view.
/*Create a 'helper' function for sorting on date, rather than string.
    Without this function, February (starts with 'F') comes before January (starts with 'J').
*/
CREATE OR ALTER FUNCTION dbo.fnMonthYearToDate
(
    @MonthYear NVARCHAR(30)
)
RETURNS DATE
AS
BEGIN
    -- Assumes English month names like 'January, 2017'
    RETURN CAST('1 ' + @MonthYear AS DATE);
END;
GO
/*Create the logic function for January NULLs*/
CREATE OR ALTER FUNCTION dbo.fnPreviousMonthCountOrZeroForJanuary
(
    @PreviousMonthCount INT,
    @InventoryDate      DATE
)
RETURNS INT
AS
BEGIN
    -- If this row is in January and there is no previous-month count, return 0
    IF @PreviousMonthCount IS NULL
       AND MONTH(@InventoryDate) = 1
    BEGIN
        RETURN 0;
    END;

    -- Otherwise, return the previous month’s count (may be NULL)
    RETURN @PreviousMonthCount;
END;
GO
/*Create the new view.*/
IF OBJECT_ID('dbo.vProductInventoriesWithPreviousMonthCounts', 'V') IS NOT NULL
    DROP VIEW dbo.vProductInventoriesWithPreviousMonthCounts;
GO

CREATE VIEW dbo.vProductInventoriesWithPreviousMonthCounts
AS
    SELECT TOP 100000
           cur.ProductName,
           cur.InventoryDate,                      -- 'January, 2017'
           cur.InventoryCount,
           dbo.fnPreviousMonthCountOrZeroForJanuary(
               prev.InventoryCount,
               curDate.InventoryDateKey            -- real DATE for month logic
           ) AS PreviousMonthCount
    FROM dbo.vProductInventories AS cur
    CROSS APPLY (
        SELECT dbo.fnMonthYearToDate(cur.InventoryDate) AS InventoryDateKey
    ) AS curDate
    LEFT JOIN dbo.vProductInventories AS prev
        CROSS APPLY (
            SELECT dbo.fnMonthYearToDate(prev.InventoryDate) AS InventoryDateKey
        ) AS prevDate
        ON prev.ProductName       = cur.ProductName
       AND prevDate.InventoryDateKey = DATEADD(MONTH, -1, curDate.InventoryDateKey)
    ORDER BY
           cur.ProductName,
           curDate.InventoryDateKey;               -- true chronological order
GO

-- Check that it works: Select * From vProductInventoriesWithPreviousMonthCounts;
Select * From vProductInventoriesWithPreviousMonthCounts;
go

-- Question 7 (15% of pts): 
-- CREATE a VIEW called vProductInventoriesWithPreviousMonthCountsWithKPIs.
-- Show columns for the Product names, Inventory Dates, Inventory Count, Previous Month Count. 
-- The Previous Month Count is a KPI. The result can show only KPIs with a value of either 1, 0, or -1. 
-- Display months with increased counts as 1, same counts as 0, and decreased counts as -1. 
-- Varify that the results are ordered by the Product and Date.
-- Important: This new view must use your vProductInventoriesWithPreviousMonthCounts view!
IF OBJECT_ID('dbo.vProductInventoriesWithPreviousMonthCountsWithKPIs', 'V') IS NOT NULL
    DROP VIEW dbo.vProductInventoriesWithPreviousMonthCountsWithKPIs;
GO

CREATE VIEW dbo.vProductInventoriesWithPreviousMonthCountsWithKPIs
AS
    SELECT TOP 100000
           v.ProductName,
           v.InventoryDate,          -- formatted: 'January, 2017'
           v.InventoryCount,
           v.PreviousMonthCount,
           CASE
               WHEN v.InventoryCount > v.PreviousMonthCount THEN  1
               WHEN v.InventoryCount = v.PreviousMonthCount THEN  0
               WHEN v.InventoryCount < v.PreviousMonthCount THEN -1
           END AS CountVsPreviousCountKPI
    FROM dbo.vProductInventoriesWithPreviousMonthCounts AS v
    CROSS APPLY (
        SELECT dbo.fnMonthYearToDate(v.InventoryDate) AS InventoryDateKey
    ) AS d
    WHERE v.PreviousMonthCount IS NOT NULL      -- ensures KPI is always -1, 0, or 1
    ORDER BY
           v.ProductName,
           d.InventoryDateKey;                  -- true chronological order
GO

-- Select * From vProductInventoriesWithPreviousMonthCountsWithKPIs;
-- go

-- Question 8 (25% of pts): 
-- CREATE a User Defined Function (UDF) called fProductInventoriesWithPreviousMonthCountsWithKPIs.
-- Show columns for the Product names, Inventory Dates, Inventory Count, the Previous Month Count. 
-- The Previous Month Count is a KPI. The result can show only KPIs with a value of either 1, 0, or -1. 
-- Display months with increased counts as 1, same counts as 0, and decreased counts as -1. 
-- The function must use the ProductInventoriesWithPreviousMonthCountsWithKPIs view.
-- Varify that the results are ordered by the Product and Date.
CREATE OR ALTER FUNCTION dbo.fProductInventoriesWithPreviousMonthCountsWithKPIs
(
    @KPI INT   -- must be -1, 0, or 1
)
RETURNS TABLE
AS
RETURN
(
    SELECT TOP 100000
           v.ProductName,
           v.InventoryDate,          -- formatted 'January, 2017'
           v.InventoryCount,
           v.PreviousMonthCount,
           v.CountVsPreviousCountKPI
    FROM dbo.vProductInventoriesWithPreviousMonthCountsWithKPIs AS v
    CROSS APPLY (
        SELECT dbo.fnMonthYearToDate(v.InventoryDate) AS InventoryDateKey
    ) AS d
    WHERE v.CountVsPreviousCountKPI = @KPI                 -- use parameter here
    ORDER BY
           v.ProductName,
           d.InventoryDateKey                        -- true chronological order
);
GO




Select * From fProductInventoriesWithPreviousMonthCountsWithKPIs(1);
Select * From fProductInventoriesWithPreviousMonthCountsWithKPIs(0);
Select * From fProductInventoriesWithPreviousMonthCountsWithKPIs(-1);

go

/***************************************************************************************/