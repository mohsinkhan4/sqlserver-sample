/*==============================================================*/
/* CREATING DATABASE                                            */
/*==============================================================*/
--DROP DATABASE IF EXISTS [Digitas_RemoteSQL_Practical_Test]  
--GO 
--CREATE DATABASE [Digitas_RemoteSQL_Practical_Test]
--GO
USE Digitas_RemoteSQL_Practical_Test
GO

/*==============================================================*/
/* TASK 0. DROPPING PRE-CREATED TABLES                          */
/*==============================================================*/

DROP TABLE IF EXISTS OrderItem 
DROP TABLE IF EXISTS "Order" 
DROP TABLE IF EXISTS Product 
DROP TABLE IF EXISTS CustomerCard 
DROP TABLE IF EXISTS Customer 
DROP TABLE IF EXISTS IsDiscontinued 
DROP TABLE IF EXISTS Package
DROP TABLE IF EXISTS SupplierProductCost
DROP TABLE IF EXISTS Supplier
DROP TABLE IF EXISTS City
DROP TABLE IF EXISTS Country

/*==============================================================*/
/* TASK 1. CREATING AND LOADING TABLES FROM CSVs                */
/*==============================================================*/

/*==============================================================*/
/* Table: Customer                                              */
/*==============================================================*/
CREATE TABLE Customer 
(
   Id                   int                  not null,
   FirstName            nvarchar(40)         not null,
   LastName             nvarchar(40)         not null,
   City                 nvarchar(40)         null,
   Country              nvarchar(40)         null,
   Phone                nvarchar(20)         null   
)
GO

BULK INSERT Customer
FROM 'D:\RemoteSQLPracticalTest\Data\Customer.CSV'
WITH 
(
-- FORMAT = 'CSV',
FIRSTROW = 2,
FIELDTERMINATOR = ';',
ROWTERMINATOR='\n'
)
GO


/*==============================================================*/
/* Table: CustomerCard                                              */
/*==============================================================*/
CREATE TABLE CustomerCard 
(
   CustomerId           int                  not null,
   CardNo				bigint				 not null   
)
GO

BULK INSERT CustomerCard
FROM 'D:\RemoteSQLPracticalTest\Data\CustomerCard.CSV'
WITH 
(
-- FORMAT = 'CSV',
FIRSTROW = 2,
FIELDTERMINATOR = ';', 
ROWTERMINATOR='\n'
)
GO


/*==============================================================*/
/* Table: "Order"                                               */
/*==============================================================*/
CREATE TABLE "Order" 
(
   Id                   int                  not null,
   OrderDate            datetime             not null default getdate(),
   OrderNumber          nvarchar(10)         null,
   CardNo           	bigint               not null,
   TotalAmount          decimal(12,2)        null default 0
)
GO

BULK INSERT "Order"
FROM 'D:\RemoteSQLPracticalTest\Data\Order.CSV'
WITH 
(
-- FORMAT = 'CSV',
FIRSTROW = 2,
FIELDTERMINATOR = ';', 
ROWTERMINATOR='\n'
)
GO


/*==============================================================*/
/* Table: OrderItem                                             */
/*==============================================================*/
CREATE TABLE OrderItem 
(
   Id                   int                  not null,
   OrderId              int                  not null,
   ProductId            int                  not null,
   UnitPrice            decimal(12,2)        not null default 0,
   Quantity             int                  not null default 1
)
GO

BULK INSERT OrderItem
FROM 'D:\RemoteSQLPracticalTest\Data\OrderItem.CSV'
WITH 
(
-- FORMAT = 'CSV',
FIRSTROW = 2,
FIELDTERMINATOR = ';',
ROWTERMINATOR='\n' 
)
GO


/*==============================================================*/
/* Table: Product                                               */
/*==============================================================*/
CREATE TABLE Product 
(
   Id                   int                  not null,
   ProductName          nvarchar(50)         not null,
   SupplierId           int                  not null,
   UnitPrice            decimal(12,2)        null default 0,
   [Package]            nvarchar(30)         null,
   --- Uploading True/False as bit is giving error
   --- Threfore upload the CSV using nvarchar and then Alter Table back to bit  
   IsDiscontinued		nvarchar(10)	     not null --default 0,
   	
)
GO

BULK INSERT Product
FROM 'D:\RemoteSQLPracticalTest\Data\Product.CSV'
WITH 
(
-- FORMAT = 'CSV',
FIRSTROW = 2,
FIELDTERMINATOR = ';', 
ROWTERMINATOR='\n',
CODEPAGE = '1252'
)
GO
--- Altering the Data Type of IsDiscontinued Coloum to bit from nvarchar
ALTER TABLE Product
ALTER COLUMN IsDiscontinued bit not null 
GO


/*==============================================================*/
/* TASK 2. NORMALISING SCHEMA					                */
/*==============================================================*/


/*==============================================================*/
/* Creating Country	Table					                        */
/*==============================================================*/
--- Creating Temporary Table with Distinct Country Names 
DROP TABLE IF EXISTS Temp_Country
GO
SELECT DISTINCT
Country AS "CountryName" 
INTO Temp_Country
FROM Customer	
GO

--- Assigning Ids to Country Names
GO
SELECT 
ROW_NUMBER() Over (Order By CountryName) AS Id,
CountryName  
INTO Country
FROM Temp_Country
GO

--- Dropping Temp Table
DROP TABLE Temp_Country
GO

--- Assigning Primary Key Constrainst to Country Ids 
ALTER TABLE Country
ALTER COLUMN Id int not null
GO

ALTER TABLE Country
ADD PRIMARY KEY (Id)
GO 

/*==============================================================*/
/* Creating City Table					                        */
/*==============================================================*/

--- Creating Temporary Table with Distinct City Names with Respective Countries
DROP TABLE IF EXISTS Temp_City
GO
SELECT DISTINCT City,Country
INTO Temp_City
FROM
Customer
ORDER By City	

--- Assigning Ids to City Names and Country_Ids from Country Table 
SELECT 
ROW_NUMBER() Over (Order By City) AS Id,
City, 
c.Id AS Country_Id 
INTO City
FROM Temp_City tc
INNER JOIN Country c
ON c.CountryName=tc.Country

--- Dropping Temp Table
DROP TABLE Temp_City
GO

--- Assigning Primary Key Contraint to City Ids  
ALTER TABLE City
ALTER COLUMN Id int not null
GO
ALTER TABLE City
ADD PRIMARY KEY (Id)
GO 

--- Assigning Foreign Key Contraint to Country_Id  
ALTER TABLE City
ADD FOREIGN KEY (Country_Id) REFERENCES Country(Id)
GO


/*==============================================================*/
/* Modifying Customer Table				                        */
/*==============================================================*/

--- Dropping City Names and Country and Assigning City_Id as Foreign Key  
DROP TABLE IF EXISTS Temp_Customer
GO 
SELECT
cust.Id, cust.FirstName, cust.LastName, cust.Phone, 
c.Id AS City_Id
INTO Temp_Customer
FROM Customer cust
INNER JOIN City c
ON c.City=cust.City
GO

DROP TABLE Customer

SELECT * INTO Customer FROM Temp_Customer
DROP TABLE Temp_Customer

--- Assigning Primary Key Contraint to Ids  
ALTER TABLE Customer
ALTER COLUMN Id int not null
GO

ALTER TABLE Customer
ADD PRIMARY KEY (Id)
GO 

--- Assigning Foreign Key Contraint to City_Id  
ALTER TABLE Customer
ADD FOREIGN KEY (City_Id) REFERENCES City(Id)
GO


/*==============================================================*/
/* Assigning Keys and elationships to CustomerCard Table	    */
/*==============================================================*/

--- Assigning Primary Key Contraint to CardNo   
ALTER TABLE CustomerCard
ALTER COLUMN CardNo bigint not null
GO

ALTER TABLE CustomerCard
ADD PRIMARY KEY (CardNo)
GO 

--- Assigning Foreign Key Contraint to Customer_Id  
ALTER TABLE CustomerCard
ADD FOREIGN KEY (CustomerId) REFERENCES Customer(Id)
GO

/*==============================================================*/
/* Assigning Keys and elationships to Orders Table	            */
/*==============================================================*/

--- Assigning Primary Key Contraint to Id   
ALTER TABLE "Order"
ALTER COLUMN Id int not null
GO

ALTER TABLE "Order"
ADD PRIMARY KEY (Id)
GO 

--- Assigning Foreign Key Contraint to CardNo  
ALTER TABLE "Order"
ADD FOREIGN KEY (CardNo) REFERENCES CustomerCard(CardNo)
GO


/*==============================================================*/
/* Assigning Keys and elationships to OrderItem Table	        */
/*==============================================================*/

--- Deleting Transactions in OrderItems Not There in Orders Table
DROP TABLE IF EXISTS Temp_OrderItem
GO
SELECT * INTO Temp_OrderItem
FROM OrderItem
WHERE OrderId IN
(SELECT id from "Order")
GO

DROP TABLE OrderItem
GO

SELECT * INTO OrderItem
FROM Temp_OrderItem
GO

DROP TABLE Temp_OrderItem
GO

--- Assigning Primary Key Contraint to Id   
ALTER TABLE OrderItem
ALTER COLUMN Id int not null
GO

ALTER TABLE OrderItem
ADD PRIMARY KEY (Id)
GO 

--- Assigning Foreign Key Contraint to Order Table  
ALTER TABLE OrderItem
ADD FOREIGN KEY (OrderId) REFERENCES "Order"(Id)
GO

--- NOTE WE STILL HAVE TO ASSIGN FOREIGN KEY PRODUCT ID WITH PRODUCT TABLE

/*==============================================================*/
/* Table: Supplier						                        */
/*==============================================================*/

--- Creating Temporary Table with Distinct Supplier_Id
GO
SELECT DISTINCT SupplierId AS Id
INTO Supplier
FROM
Product
ORDER By SupplierId	
GO

--- Assigning Primary Key Contraint to Supplier Ids  
ALTER TABLE Supplier
ALTER COLUMN Id int not null

ALTER TABLE Supplier
ADD PRIMARY KEY (Id)
GO 

/*==============================================================*/
/* Table: SupplierProductCost			                        */
/*==============================================================*/
DROP TABLE IF EXISTS Temp_SupplierProductCost
GO
SELECT 
SupplierId, id AS "ProductId", UnitPrice as "CostPrice"
INTO Temp_SupplierProductCost
FROM Product
ORDER BY SupplierId
GO
--- Assigning Ids to Records 
GO
SELECT 
ROW_NUMBER() Over (Order By SupplierId) AS Id,
* INTO SupplierProductCost
FROM Temp_SupplierProductCost
ORDER BY SupplierId
GO

--- Drop Temp Table
DROP TABLE Temp_SupplierProductCost

--- Assigning Primary Key Contraint to Record Ids  
ALTER TABLE SupplierProductCost
ALTER COLUMN Id int not null
GO
ALTER TABLE SupplierProductCost
ADD PRIMARY KEY (Id)
GO 

--- Assigning Foreign Key Contraint to SupplierId 
ALTER TABLE SupplierProductCost
ADD FOREIGN KEY (SupplierId) REFERENCES Supplier(Id)
GO

/*==============================================================*/
/* Table: Package						                        */
/*==============================================================*/
--- Creating Temporary Table with Distinct Package Names
DROP TABLE IF EXISTS Temp_Package
GO 
SELECT DISTINCT Package
INTO Temp_Package
FROM
Product
ORDER By Package	
GO

--- Assigning Ids to Package Types 
GO 
SELECT 
ROW_NUMBER() Over (Order By Package) AS Id,
Package 
INTO Package
FROM 
Temp_Package
ORDER BY Package
GO 

--- Dropping Temp Table
DROP TABLE Temp_Package

--- Assigning Primary Key Contraint to Package Ids  
ALTER TABLE Package
ALTER COLUMN Id int not null
Go

ALTER TABLE Package
ADD PRIMARY KEY (Id)
GO 


/*==============================================================*/
/* Table: IsDiscontinued						                        */
/*==============================================================*/
--- Creating Temporary Table with Distinct Values
DROP TABLE IF EXISTS Temp_IsDiscontinued
GO 
SELECT DISTINCT IsDiscontinued
INTO Temp_IsDiscontinued
FROM
Product
ORDER By IsDiscontinued	
GO

--- Assigning Ids to Values 
GO 
SELECT 
ROW_NUMBER() Over (Order By IsDiscontinued) AS Id,
IsDiscontinued
INTO IsDiscontinued
FROM 
Temp_IsDiscontinued
ORDER BY IsDiscontinued
GO 

--- Dropping Temp Table
DROP TABLE Temp_IsDiscontinued

--- Assigning Primary Key Contraint to Ids  
ALTER TABLE IsDiscontinued
ALTER COLUMN Id int not null
Go

ALTER TABLE IsDiscontinued
ADD PRIMARY KEY (Id)
GO 


/*==============================================================*/
/* Table: Product						                        */
/*==============================================================*/
--- Creating Temp Table from Product with Modified Fields
DROP TABLE IF EXISTS TEMP_Product 
GO
SELECT
DISTINCT prod.id AS Id, prod.ProductName, 
supprocost.Id AS SupplierCostId,
pack.id AS PackageId, isdis.id AS IsDiscontinuedId
INTO TEMP_Product
FROM 
Product prod
LEFT JOIN SupplierProductCost supprocost
ON supprocost.ProductId = prod.Id
LEFT JOIN Package pack
ON pack.Package = prod.Package
LEFT JOIN 
IsDiscontinued isdis
ON isdis.IsDiscontinued = prod.IsDiscontinued
GO

--- Dropping Original Product Table
DROP TABLE Product
GO
--- Assigning Values from Temp Product Table to New Product Table
SELECT *
INTO Product
FROM TEMP_Product
GO

---Assigning Primary Key Constraint to ProductId
ALTER TABLE Product
ALTER COLUMN Id int not null
GO
ALTER TABLE Product
ADD PRIMARY KEY (Id)
GO

--- Dropping Temp Table
DROP TABLE TEMP_Product


--------------- ASSIGNING FOREIGN KEY Constraint

--- Assigning Foreign Key in OrderItem to Product Table
ALTER TABLE OrderItem
ADD FOREIGN KEY (ProductId) REFERENCES Product(Id)
GO

--- Assigning Foreign Key In Product Table To SupplierProductCost
ALTER TABLE Product
ADD FOREIGN KEY (SupplierCostId) REFERENCES SupplierProductCost(Id)
GO

--- Assigning Foreign Key In Product Table To IsDiscontinued

ALTER TABLE Product
ADD FOREIGN KEY (IsDiscontinuedId) REFERENCES IsDiscontinued(Id)
GO

--- Assigning Foreign Key In Product Table To Package 
ALTER TABLE Product
ADD FOREIGN KEY (PackageId) REFERENCES Package(Id)
GO


/*==============================================================*/
/* TASK 3. SELECT           					                */
/*==============================================================*/

/*==============================================================*/
/* TASK 3.1 Total sales for 2013 for each Country               */
/*==============================================================*/

SELECT
Country.CountryName, SUM("Order".TotalAmount) AS TotalSales
FROM
"Order", CustomerCard, Customer, City, Country
WHERE
"Order".CardNo = CustomerCard.CardNo
AND CustomerCard.CustomerId = Customer.Id
AND Customer.City_Id = City.Id
AND City.Country_Id = Country.Id
AND YEAR("Order".OrderDate) = 2013
GROUP BY Country.CountryName
GO

-- Verify per Country
SELECT
*
FROM
"Order", CustomerCard, Customer, City, Country
WHERE
"Order".CardNo = CustomerCard.CardNo
AND CustomerCard.CustomerId = Customer.Id
AND Customer.City_Id = City.Id
AND City.Country_Id = Country.Id
AND YEAR("Order".OrderDate) = 2013
AND Country.CountryName = 'Argentina'
GO

-- Verify per Card
SELECT
*
FROM
"Order"
WHERE
"Order".CardNo = 2067471061
ORDER BY "Order".CardNo
GO

/*=========================================================================*/
/* TASK 3.2 The single top selling product for each supplier for each year */
/*=========================================================================*/

--- Top Selling Product by Sales Amount
SELECT
Id AS SupplierId, OrderYear, ProductName AS TopSellingProduct, ProductSalesAmount
FROM
(
	SELECT 
	-- Assigning Rank of Product Sales Amount by SupplierId and then by Year of Order
	ROW_NUMBER() OVER (
		PARTITION BY Supplier.id, YEAR("Order".OrderDate) 
		ORDER BY SUM(OrderItem.UnitPrice * OrderItem.Quantity) DESC
	) AS RankNo,
	Supplier.Id,
	YEAR("Order".OrderDate) AS OrderYear,
	OrderItem.ProductId AS ProductId,
	Product.ProductName, 
	SUM(OrderItem.UnitPrice * OrderItem.Quantity) AS ProductSalesAmount

	FROM
	OrderItem
	INNER JOIN
	"Order" ON "Order".Id = OrderItem.OrderId
	INNER JOIN
	Product ON Product.Id = OrderItem.ProductId
	INNER JOIN 
	SupplierProductCost ON SupplierProductCost.ProductId = Product.Id
	INNER JOIN
	Supplier ON Supplier.Id = SupplierProductCost.SupplierId

	GROUP BY 
	Supplier.Id,
	YEAR("Order".OrderDate), 
	OrderItem.ProductId,
	Product.ProductName
) AS YearProductSales 
WHERE
RankNo = 1
GO

--- Top Selling Product by Sales Quantity
SELECT
Id AS SupplierId, OrderYear, ProductName AS TopSellingProduct, ProductQuantity
FROM
(
	SELECT 
		-- Assigning Rank of Product Sales Amount by SupplierId and then by Year of Order
		ROW_NUMBER() OVER (
			PARTITION BY Supplier.id, YEAR("Order".OrderDate) 
			ORDER BY SUM(OrderItem.Quantity) DESC
		) AS RankNo,
		Supplier.Id,
		YEAR("Order".OrderDate) AS OrderYear,
		OrderItem.ProductId AS ProductId,
		Product.ProductName, 
		SUM(OrderItem.Quantity) as ProductQuantity

	FROM OrderItem
	INNER JOIN
		"Order" ON "Order".Id = OrderItem.OrderId
	INNER JOIN
		Product ON Product.Id = OrderItem.ProductId
	INNER JOIN 
		SupplierProductCost ON SupplierProductCost.ProductId = Product.Id
	INNER JOIN
		Supplier ON Supplier.Id = SupplierProductCost.SupplierId

	GROUP BY 
		Supplier.Id,
		YEAR("Order".OrderDate), 
		OrderItem.ProductId,
		Product.ProductName
) AS YearProductSales 
WHERE
RankNo = 1
GO

-- Verify per Product per Supplier
SELECT
*,
SUM(OrderItem.UnitPrice * OrderItem.Quantity) OVER (PARTITION BY YEAR("Order".OrderDate)) AS ProductSalesAmount
FROM
"Order", OrderItem, Product, SupplierProductCost, Supplier
WHERE
"Order".Id = OrderItem.OrderId
AND Product.Id = OrderItem.ProductId
AND SupplierProductCost.Id = Product.SupplierCostId
AND Supplier.Id = SupplierProductCost.SupplierId
AND SupplierId = 18
AND Product.ProductName = 'Côte de Blaye'

/*=======================================================================================*/
/* TASK 3.3 Create a table with columns for CustomerId and Average Weekly Spend Quartile */
/*=======================================================================================*/

SELECT Customer.Id AS CustomerId
	,OrderWithYearWeek.OrderDateYearWeek
	,CONVERT(FLOAT, AVG(OrderWithYearWeek.TotalAmount), 1) AS AvgSalesAmountForWeek
	,NTILE(4) OVER(PARTITION BY
		Customer.Id
		ORDER BY AVG(OrderWithYearWeek.TotalAmount) ASC
	) AS Quartile
FROM 
(
	SELECT *
		,DATEPART(YEAR, "Order".OrderDate) * 100 + DATEPART(WEEK, "Order".OrderDate) AS OrderDateYearWeek
	FROM "Order"
) AS OrderWithYearWeek
INNER JOIN CustomerCard
	ON OrderWithYearWeek.CardNo = CustomerCard.CardNo
INNER JOIN Customer
    ON CustomerCard.CustomerId = Customer.Id
GROUP BY
	Customer.Id,
	OrderWithYearWeek.OrderDateYearWeek
ORDER BY
	Customer.Id
GO

