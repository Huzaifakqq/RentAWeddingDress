-- =============================================
-- DEMO SEED DATA - Run AFTER CreateDatabase.sql
-- Adds multiple users, dresses, bookings for demo
-- =============================================
USE RentAWeddingDress;
GO

-- ========== DEMO USERS ==========
-- Owner (already exists): Admin / 03001234567 / 123
-- Add more users for customer + owner demo
INSERT INTO Users (Name, Contact, Password, CreditBalance) VALUES
('Ali Khan',    '03001111111', '123', 0),
('Sara Ahmed',  '03002222222', '123', 0),
('Usman Raza',  '03003333333', '123', 0),
('Fatima Noor', '03004444444', '123', 0);
GO

-- Addresses for each user
INSERT INTO UserAddress (U_id, Address, Latitude, Longitude) VALUES
(1, 'Lahore, Pakistan',           31.5204, 74.3587),
(2, 'Karachi, Pakistan',          24.8607, 67.0011),
(3, 'Islamabad, Pakistan',        33.6844, 73.0479),
(4, 'Rawalpindi, Pakistan',       33.5651, 73.0169),
(5, 'Lahore, Gulberg, Pakistan',  31.5163, 74.3455);
GO

-- ========== DEMO DRESSES ==========
-- Dress 1: Beautiful Red Bridal (already in CreateDatabase.sql, owner=Admin)

-- Dress 2: Gold Walima Gown (owner=Admin)
INSERT INTO Dress (U_id, Category_id, SubCategory_id, Condition, Dtitle, Description, Gender, RentPrice, AgeYears, AgeMonths, AgeDays, Latitude, Longitude)
VALUES (1, 1, 2, 8, 'Gold Walima Gown', 'Elegant gold embroidered walima dress with full sleeves', 'Female', 8000, 1, 0, 0, 31.5204, 74.3587);
GO
INSERT INTO DressImages (D_id, ImgPath) VALUES (2, 'Content/images/sample.jpg');
GO
INSERT INTO DressOccasion (D_id, Occasion) VALUES (2, 'Walima'), (2, 'Wedding');
GO
INSERT INTO DressSizes (D_id, Size_id, Stock) VALUES (2, 3, 2), (2, 4, 2), (2, 5, 1);
GO

-- Dress 3: Green Mehndi Lehenga (owner=Admin)
INSERT INTO Dress (U_id, Category_id, SubCategory_id, Condition, Dtitle, Description, Gender, RentPrice, AgeYears, AgeMonths, AgeDays, Latitude, Longitude)
VALUES (1, 1, 3, 7, 'Green Mehndi Lehenga', 'Bright green mehndi outfit with mirror work', 'Female', 4500, 0, 8, 0, 31.5204, 74.3587);
GO
INSERT INTO DressImages (D_id, ImgPath) VALUES (3, 'Content/images/sample.jpg');
GO
INSERT INTO DressOccasion (D_id, Occasion) VALUES (3, 'Mehndi'), (3, 'Wedding');
GO
INSERT INTO DressSizes (D_id, Size_id, Stock) VALUES (3, 2, 3), (3, 3, 3);
GO

-- Dress 4: Black Sherwani (owner=Admin)
INSERT INTO Dress (U_id, Category_id, SubCategory_id, Condition, Dtitle, Description, Gender, RentPrice, AgeYears, AgeMonths, AgeDays, Latitude, Longitude)
VALUES (1, 2, 4, 9, 'Classic Black Sherwani', 'Formal black sherwani for groom, includes turban', 'Male', 6000, 0, 4, 0, 31.5204, 74.3587);
GO
INSERT INTO DressImages (D_id, ImgPath) VALUES (4, 'Content/images/sample.jpg');
GO
INSERT INTO DressOccasion (D_id, Occasion) VALUES (4, 'Nikkah'), (4, 'Wedding');
GO
INSERT INTO DressSizes (D_id, Size_id, Stock) VALUES (4, 3, 2), (4, 4, 2), (4, 5, 2);
GO

-- Dress 5: White Maxi (owner=Ali Khan, id=2)
INSERT INTO Dress (U_id, Category_id, SubCategory_id, Condition, Dtitle, Description, Gender, RentPrice, AgeYears, AgeMonths, AgeDays, Latitude, Longitude)
VALUES (2, 3, 8, 6, 'White Evening Maxi', 'Flowing white maxi dress for formal events', 'Female', 3500, 2, 0, 0, 24.8607, 67.0011);
GO
INSERT INTO DressImages (D_id, ImgPath) VALUES (5, 'Content/images/sample.jpg');
GO
INSERT INTO DressOccasion (D_id, Occasion) VALUES (5, 'Party'), (5, 'Formal');
GO
INSERT INTO DressSizes (D_id, Size_id, Stock) VALUES (5, 2, 1), (5, 3, 2), (5, 4, 1);
GO

-- Dress 6: Blue Cocktail Dress (owner=Sara Ahmed, id=3)
INSERT INTO Dress (U_id, Category_id, SubCategory_id, Condition, Dtitle, Description, Gender, RentPrice, AgeYears, AgeMonths, AgeDays, Latitude, Longitude)
VALUES (3, 3, 7, 8, 'Blue Cocktail Dress', 'Stylish blue cocktail dress with sequins', 'Female', 2800, 1, 2, 0, 33.6844, 73.0479);
GO
INSERT INTO DressImages (D_id, ImgPath) VALUES (6, 'Content/images/sample.jpg');
GO
INSERT INTO DressOccasion (D_id, Occasion) VALUES (6, 'Party'), (6, 'Cocktail');
GO
INSERT INTO DressSizes (D_id, Size_id, Stock) VALUES (6, 1, 2), (6, 2, 2), (6, 3, 1);
GO

-- ========== DEMO BOOKINGS ==========
-- Booking 1: Already in CreateDatabase.sql (Admin books Dress 1, Pending)

-- Booking 2: Ali Khan (user 2) books Dress 2, Accepted (status=1)
INSERT INTO BookingRequest (U_id, UserAddressID, StartingDate, ReturnDate, NoOfDays, Status, CancelledDate, PenaltyAmount)
VALUES (2, 2, DATEADD(DAY, 5, GETDATE()), DATEADD(DAY, 7, GETDATE()), 3, 1, NULL, 0);
GO
INSERT INTO BookingDetail (BR_id, D_id, TotalPrice, Feedback, Rating, Quantity, Size_id)
VALUES (2, 2, 16000, NULL, NULL, 2, 3);
GO

-- Booking 3: Sara Ahmed (user 3) books Dress 3, Completed (status=7) — for review demo
INSERT INTO BookingRequest (U_id, UserAddressID, StartingDate, ReturnDate, NoOfDays, Status, CancelledDate, PenaltyAmount)
VALUES (3, 3, DATEADD(DAY, -10, GETDATE()), DATEADD(DAY, -8, GETDATE()), 3, 7, NULL, 0);
GO
INSERT INTO BookingDetail (BR_id, D_id, TotalPrice, Feedback, Rating, Quantity, Size_id)
VALUES (3, 3, 9000, NULL, NULL, 2, 3);
GO

-- Booking 4: Usman Raza (user 4) books Dress 4, Picked (status=4)
INSERT INTO BookingRequest (U_id, UserAddressID, StartingDate, ReturnDate, NoOfDays, Status, CancelledDate, PenaltyAmount)
VALUES (4, 4, DATEADD(DAY, 2, GETDATE()), DATEADD(DAY, 4, GETDATE()), 3, 4, NULL, 0);
GO
INSERT INTO BookingDetail (BR_id, D_id, TotalPrice, Feedback, Rating, Quantity, Size_id)
VALUES (4, 4, 12000, NULL, NULL, 2, 4);
GO

-- Booking 5: Fatima Noor (user 5) books Dress 5, Pending (status=0)
INSERT INTO BookingRequest (U_id, UserAddressID, StartingDate, ReturnDate, NoOfDays, Status, CancelledDate, PenaltyAmount)
VALUES (5, 5, DATEADD(DAY, 10, GETDATE()), DATEADD(DAY, 12, GETDATE()), 3, 0, NULL, 0);
GO
INSERT INTO BookingDetail (BR_id, D_id, TotalPrice, Feedback, Rating, Quantity, Size_id)
VALUES (5, 5, 7000, NULL, NULL, 2, 3);
GO

-- ========== DEMO REVIEW ==========
-- Review for Dress 3 (from completed Booking 3 by Sara)
INSERT INTO BookingDetail (BR_id, D_id, TotalPrice, Feedback, Rating, Quantity, Size_id)
VALUES (3, 3, 0, 'Amazing dress! Perfect for mehndi. Highly recommend!', 5, 0, NULL);
GO

PRINT 'Demo seed data inserted successfully!';
PRINT '';
PRINT '=== DEMO ACCOUNTS ===';
PRINT 'Owner:    03001234567 / 123 (Admin - has 4 dresses)';
PRINT 'Customer: 03001111111 / 123 (Ali Khan)';
PRINT 'Customer: 03002222222 / 123 (Sara Ahmed)';
PRINT 'Customer: 03003333333 / 123 (Usman Raza)';
PRINT 'Customer: 03004444444 / 123 (Fatima Noor)';
GO
