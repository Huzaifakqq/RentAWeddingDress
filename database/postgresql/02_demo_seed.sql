-- =============================================================
-- DEMO SEED DATA (PostgreSQL) - Run AFTER 01_create.sql
-- Translation of DemoSeed.sql (SQL Server → PostgreSQL)
-- Adds multiple users, dresses, bookings for demo
-- =============================================================

-- ========== DEMO USERS ==========
-- Owner (already exists): Admin / 03001234567 / 123
INSERT INTO "Users" ("Name", "Contact", "Password", "CreditBalance", "Role") VALUES
('Ali Khan',    '03001111111', '123', 0, 'customer'),
('Sara Ahmed',  '03002222222', '123', 0, 'customer'),
('Usman Raza',  '03003333333', '123', 0, 'customer'),
('Fatima Noor', '03004444444', '123', 0, 'customer');

-- Rider LAST → Bilal gets U_id 6, matching the live DB (login mode: Rider)
INSERT INTO "Users" ("Name", "Contact", "Password", "CreditBalance", "Role") VALUES ('Bilal Rider', '03005555555', '123', 0, 'rider');

-- Addresses for each user
INSERT INTO "UserAddress" ("U_id", "Address", "Latitude", "Longitude") VALUES
(1, 'Lahore, Pakistan',           31.5204, 74.3587),
(2, 'Karachi, Pakistan',          24.8607, 67.0011),
(3, 'Islamabad, Pakistan',        33.6844, 73.0479),
(4, 'Rawalpindi, Pakistan',       33.5651, 73.0169),
(5, 'Lahore, Gulberg, Pakistan',  31.5163, 74.3455),
(6, 'Lahore, Johar Town, Pakistan', 31.5925, 74.3144);

-- ========== DEMO DRESSES ==========
-- Dress 1: Beautiful Red Bridal (already in 01_create.sql, owner=Admin)

-- Dress 2: Gold Walima Gown (owner=Admin)
INSERT INTO "Dress" ("U_id", "Category_id", "SubCategory_id", "Condition", "Dtitle", "Description", "Gender", "RentPrice", "AgeYears", "AgeMonths", "AgeDays", "Latitude", "Longitude")
VALUES (1, 1, 2, 8, 'Gold Walima Gown', 'Elegant gold embroidered walima dress with full sleeves', 'Female', 8000, 1, 0, 0, 31.5204, 74.3587);
INSERT INTO "DressImages" ("D_id", "ImgPath") VALUES (2, 'Content/images/sample.jpg');
INSERT INTO "DressOccasion" ("D_id", "Occasion") VALUES (2, 'Walima'), (2, 'Wedding');
INSERT INTO "DressSizes" ("D_id", "Size_id", "Stock") VALUES (2, 3, 2), (2, 4, 2), (2, 5, 1);

-- Dress 3: Green Mehndi Lehenga (owner=Admin)
INSERT INTO "Dress" ("U_id", "Category_id", "SubCategory_id", "Condition", "Dtitle", "Description", "Gender", "RentPrice", "AgeYears", "AgeMonths", "AgeDays", "Latitude", "Longitude")
VALUES (1, 1, 3, 7, 'Green Mehndi Lehenga', 'Bright green mehndi outfit with mirror work', 'Female', 4500, 0, 8, 0, 31.5204, 74.3587);
INSERT INTO "DressImages" ("D_id", "ImgPath") VALUES (3, 'Content/images/sample.jpg');
INSERT INTO "DressOccasion" ("D_id", "Occasion") VALUES (3, 'Mehndi'), (3, 'Wedding');
INSERT INTO "DressSizes" ("D_id", "Size_id", "Stock") VALUES (3, 2, 3), (3, 3, 3);

-- Dress 4: Black Sherwani (owner=Admin)
INSERT INTO "Dress" ("U_id", "Category_id", "SubCategory_id", "Condition", "Dtitle", "Description", "Gender", "RentPrice", "AgeYears", "AgeMonths", "AgeDays", "Latitude", "Longitude")
VALUES (1, 2, 4, 9, 'Classic Black Sherwani', 'Formal black sherwani for groom, includes turban', 'Male', 6000, 0, 4, 0, 31.5204, 74.3587);
INSERT INTO "DressImages" ("D_id", "ImgPath") VALUES (4, 'Content/images/sample.jpg');
INSERT INTO "DressOccasion" ("D_id", "Occasion") VALUES (4, 'Nikkah'), (4, 'Wedding');
INSERT INTO "DressSizes" ("D_id", "Size_id", "Stock") VALUES (4, 3, 2), (4, 4, 2), (4, 5, 2);

-- Dress 5: White Maxi (owner=Ali Khan, id=2)
INSERT INTO "Dress" ("U_id", "Category_id", "SubCategory_id", "Condition", "Dtitle", "Description", "Gender", "RentPrice", "AgeYears", "AgeMonths", "AgeDays", "Latitude", "Longitude")
VALUES (2, 3, 8, 6, 'White Evening Maxi', 'Flowing white maxi dress for formal events', 'Female', 3500, 2, 0, 0, 24.8607, 67.0011);
INSERT INTO "DressImages" ("D_id", "ImgPath") VALUES (5, 'Content/images/sample.jpg');
INSERT INTO "DressOccasion" ("D_id", "Occasion") VALUES (5, 'Party'), (5, 'Formal');
INSERT INTO "DressSizes" ("D_id", "Size_id", "Stock") VALUES (5, 2, 1), (5, 3, 2), (5, 4, 1);

-- Dress 6: Blue Cocktail Dress (owner=Sara Ahmed, id=3)
INSERT INTO "Dress" ("U_id", "Category_id", "SubCategory_id", "Condition", "Dtitle", "Description", "Gender", "RentPrice", "AgeYears", "AgeMonths", "AgeDays", "Latitude", "Longitude")
VALUES (3, 3, 7, 8, 'Blue Cocktail Dress', 'Stylish blue cocktail dress with sequins', 'Female', 2800, 1, 2, 0, 33.6844, 73.0479);
INSERT INTO "DressImages" ("D_id", "ImgPath") VALUES (6, 'Content/images/sample.jpg');
INSERT INTO "DressOccasion" ("D_id", "Occasion") VALUES (6, 'Party'), (6, 'Cocktail');
INSERT INTO "DressSizes" ("D_id", "Size_id", "Stock") VALUES (6, 1, 2), (6, 2, 2), (6, 3, 1);

-- ========== DEMO BOOKINGS ==========
-- Booking 1: Already in 01_create.sql (Admin books Dress 1, Pending)

-- Booking 2: Ali Khan (user 2) books Dress 2, Accepted (status=1)
INSERT INTO "BookingRequest" ("U_id", "UserAddressID", "StartingDate", "ReturnDate", "NoOfDays", "Status", "CancelledDate", "PenaltyAmount")
VALUES (2, 2, LOCALTIMESTAMP + INTERVAL '5 days', LOCALTIMESTAMP + INTERVAL '7 days', 3, 1, NULL, 0);
INSERT INTO "BookingDetail" ("BR_id", "D_id", "TotalPrice", "Feedback", "Rating", "Quantity", "Size_id")
VALUES (2, 2, 16000, NULL, NULL, 2, 3);

-- Booking 3: Sara Ahmed (user 3) books Dress 3, Completed (status=7) — for review demo
INSERT INTO "BookingRequest" ("U_id", "UserAddressID", "StartingDate", "ReturnDate", "NoOfDays", "Status", "CancelledDate", "PenaltyAmount")
VALUES (3, 3, LOCALTIMESTAMP - INTERVAL '10 days', LOCALTIMESTAMP - INTERVAL '8 days', 3, 7, NULL, 0);
INSERT INTO "BookingDetail" ("BR_id", "D_id", "TotalPrice", "Feedback", "Rating", "Quantity", "Size_id")
VALUES (3, 3, 9000, NULL, NULL, 2, 3);

-- Booking 4: Usman Raza (user 4) books Dress 4, Picked (status=4)
INSERT INTO "BookingRequest" ("U_id", "UserAddressID", "StartingDate", "ReturnDate", "NoOfDays", "Status", "CancelledDate", "PenaltyAmount")
VALUES (4, 4, LOCALTIMESTAMP + INTERVAL '2 days', LOCALTIMESTAMP + INTERVAL '4 days', 3, 4, NULL, 0);
INSERT INTO "BookingDetail" ("BR_id", "D_id", "TotalPrice", "Feedback", "Rating", "Quantity", "Size_id")
VALUES (4, 4, 12000, NULL, NULL, 2, 4);

-- Booking 5: Fatima Noor (user 5) books Dress 5, Pending (status=0)
INSERT INTO "BookingRequest" ("U_id", "UserAddressID", "StartingDate", "ReturnDate", "NoOfDays", "Status", "CancelledDate", "PenaltyAmount")
VALUES (5, 5, LOCALTIMESTAMP + INTERVAL '10 days', LOCALTIMESTAMP + INTERVAL '12 days', 3, 0, NULL, 0);
INSERT INTO "BookingDetail" ("BR_id", "D_id", "TotalPrice", "Feedback", "Rating", "Quantity", "Size_id")
VALUES (5, 5, 7000, NULL, NULL, 2, 3);

-- ========== DEMO REVIEW ==========
-- Review for Dress 3 (from completed Booking 3 by Sara)
INSERT INTO "BookingDetail" ("BR_id", "D_id", "TotalPrice", "Feedback", "Rating", "Quantity", "Size_id")
VALUES (3, 3, 0, 'Amazing dress! Perfect for mehndi. Highly recommend!', 5, 0, NULL);

SELECT 'Demo seed data inserted successfully!' AS result;
