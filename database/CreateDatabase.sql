-- =============================================
-- RENT A WEDDING DRESS - Complete Database Script
-- Matches EF Database-First model (singular table names)
-- Run this in SQL Server Management Studio
-- =============================================

-- 1. CREATE DATABASE
IF DB_ID('RentAWeddingDress') IS NOT NULL
BEGIN
    ALTER DATABASE RentAWeddingDress SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE RentAWeddingDress;
END
GO
CREATE DATABASE RentAWeddingDress;
GO
USE RentAWeddingDress;
GO

-- 2. CREATE TABLES

-- Users (+ credit balance for penalty)
CREATE TABLE Users (
    U_id INT PRIMARY KEY IDENTITY(1,1),
    Name NVARCHAR(200) NOT NULL,
    Contact NVARCHAR(100) NOT NULL UNIQUE,
    Password NVARCHAR(510) NOT NULL,
    CreditBalance DECIMAL(10,2) NULL DEFAULT 0
);
GO

-- User Addresses (+ map pin from Google Maps)
CREATE TABLE UserAddress (
    UA_id INT PRIMARY KEY IDENTITY(1,1),
    U_id INT NOT NULL FOREIGN KEY REFERENCES Users(U_id),
    Address NVARCHAR(MAX) NOT NULL,
    Latitude DECIMAL(9,6) NULL,
    Longitude DECIMAL(9,6) NULL
);
GO

-- Dress Categories
CREATE TABLE DressCategory (
    Category_id INT PRIMARY KEY IDENTITY(1,1),
    Cname NVARCHAR(100) NOT NULL UNIQUE
);
GO

-- Sub Categories
CREATE TABLE SubCategory (
    SubCategory_id INT PRIMARY KEY IDENTITY(1,1),
    Category_id INT NOT NULL FOREIGN KEY REFERENCES DressCategory(Category_id),
    SCname NVARCHAR(100) NOT NULL
);
GO

-- Sizes
CREATE TABLE Sizes (
    Size_id INT PRIMARY KEY IDENTITY(1,1),
    SizeName NVARCHAR(20) NOT NULL UNIQUE
);
GO

-- Dresses (+ age/condition + shop location)
CREATE TABLE Dress (
    D_id INT PRIMARY KEY IDENTITY(1,1),
    U_id INT NOT NULL FOREIGN KEY REFERENCES Users(U_id),
    Category_id INT NOT NULL FOREIGN KEY REFERENCES DressCategory(Category_id),
    SubCategory_id INT NOT NULL FOREIGN KEY REFERENCES SubCategory(SubCategory_id),
    Condition INT NULL DEFAULT 5,
    Dtitle NVARCHAR(300) NOT NULL,
    Description NVARCHAR(MAX),
    Gender NVARCHAR(20) NOT NULL,
    RentPrice DECIMAL(18,2) NOT NULL,
    AgeYears INT NULL DEFAULT 0,
    AgeMonths INT NULL DEFAULT 0,
    AgeDays INT NULL DEFAULT 0,
    Latitude DECIMAL(9,6) NULL,
    Longitude DECIMAL(9,6) NULL
);
GO

-- Dress Images (multiple images per dress)
CREATE TABLE DressImages (
    DI_id INT PRIMARY KEY IDENTITY(1,1),
    D_id INT NOT NULL FOREIGN KEY REFERENCES Dress(D_id) ON DELETE CASCADE,
    ImgPath NVARCHAR(MAX) NOT NULL
);
GO

-- Dress Occasions (multiple occasions per dress)
CREATE TABLE DressOccasion (
    Occasion_id INT PRIMARY KEY IDENTITY(1,1),
    D_id INT NOT NULL FOREIGN KEY REFERENCES Dress(D_id) ON DELETE CASCADE,
    Occasion NVARCHAR(100) NOT NULL
);
GO

-- Dress Sizes junction (+ stock for multi-copy)
CREATE TABLE DressSizes (
    DS_id INT PRIMARY KEY IDENTITY(1,1),
    D_id INT NOT NULL FOREIGN KEY REFERENCES Dress(D_id) ON DELETE CASCADE,
    Size_id INT NOT NULL FOREIGN KEY REFERENCES Sizes(Size_id),
    Stock INT NULL DEFAULT 1
);
GO

-- Booking Requests (+ cancellation / penalty fields)
CREATE TABLE BookingRequest (
    BR_id INT PRIMARY KEY IDENTITY(1,1),
    U_id INT NOT NULL FOREIGN KEY REFERENCES Users(U_id),
    UserAddressID INT NOT NULL FOREIGN KEY REFERENCES UserAddress(UA_id),
    StartingDate DATETIME NOT NULL,
    ReturnDate DATETIME NOT NULL,
    NoOfDays INT NOT NULL,
    Status INT NULL DEFAULT 0,  -- 0=Pending 1=Accepted 2=Cancelled 3=Rejected 4=Picked 5=PickupConfirmed 6=ReturnRequested 7=Completed
    CancelledDate DATETIME NULL,
    PenaltyAmount DECIMAL(10,2) NULL DEFAULT 0
);
GO

-- Booking Details (+ multi-size quantity)
-- One BookingRequest can have MANY BookingDetails (2M + 1S + 4XL = 3 rows)
CREATE TABLE BookingDetail (
    BD_id INT PRIMARY KEY IDENTITY(1,1),
    BR_id INT NOT NULL FOREIGN KEY REFERENCES BookingRequest(BR_id) ON DELETE CASCADE,
    D_id INT NOT NULL FOREIGN KEY REFERENCES Dress(D_id),
    TotalPrice DECIMAL(18,2) NOT NULL,
    Feedback NVARCHAR(MAX),
    Rating INT NULL,
    Quantity INT NULL DEFAULT 1,
    Size_id INT NULL  -- no FK (legacy rows may be NULL)
);
GO

-- 3. SEED DATA

-- Categories
INSERT INTO DressCategory (Cname) VALUES ('Bridal'), ('Groom'), ('Formal'), ('Casual');
GO

-- SubCategories
INSERT INTO SubCategory (Category_id, SCname) VALUES
(1, 'Nikah Dress'), (1, 'Walima Dress'), (1, 'Mehndi Dress'),
(2, 'Sherwani'), (2, 'Suit'), (2, 'Kurta'),
(3, 'Evening Gown'), (3, 'Cocktail Dress'), (3, 'Maxi'),
(4, 'Summer Dress'), (4, 'Winter Collection'), (4, 'Party Wear');
GO

-- Sizes
INSERT INTO Sizes (SizeName) VALUES ('XS'), ('S'), ('M'), ('L'), ('XL'), ('XXL');
GO

-- Sample User (password: 123)
INSERT INTO Users (Name, Contact, Password, CreditBalance) VALUES ('Admin', '03001234567', '123', 0);
GO

-- Sample Address
INSERT INTO UserAddress (U_id, Address) VALUES (1, 'Lahore, Pakistan');
GO

-- Sample Dress
INSERT INTO Dress (U_id, Category_id, SubCategory_id, Condition, Dtitle, Description, Gender, RentPrice, AgeYears, AgeMonths, AgeDays, Latitude, Longitude)
VALUES (1, 1, 1, 9, 'Beautiful Red Bridal', 'Premium quality bridal dress for nikah ceremony', 'Female', 5000, 0, 6, 0, 31.5204, 74.3587);
GO

-- Sample Dress Image
INSERT INTO DressImages (D_id, ImgPath) VALUES (1, 'Content/images/sample.jpg');
GO

-- Sample Occasions
INSERT INTO DressOccasion (D_id, Occasion) VALUES (1, 'Wedding'), (1, 'Nikkah');
GO

-- Sample Dress Sizes (M and L, stock 3 each)
INSERT INTO DressSizes (D_id, Size_id, Stock) VALUES (1, 3, 3), (1, 4, 3);
GO

-- Sample Booking (for My Rentals demo)
INSERT INTO BookingRequest (U_id, UserAddressID, StartingDate, ReturnDate, NoOfDays, Status, CancelledDate, PenaltyAmount)
VALUES (1, 1, DATEADD(DAY, 7, GETDATE()), DATEADD(DAY, 9, GETDATE()), 3, 0, NULL, 0);
GO

INSERT INTO BookingDetail (BR_id, D_id, TotalPrice, Feedback, Rating, Quantity, Size_id)
VALUES (1, 1, 15000, NULL, NULL, 1, 3);
GO

PRINT 'Database created successfully!';
GO
