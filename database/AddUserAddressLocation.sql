-- Migration: add map-pin columns to existing UserAddress table
USE RentAWeddingDress;
GO
IF COL_LENGTH('dbo.UserAddress', 'Latitude') IS NULL
    ALTER TABLE dbo.UserAddress ADD Latitude DECIMAL(9,6) NULL;
IF COL_LENGTH('dbo.UserAddress', 'Longitude') IS NULL
    ALTER TABLE dbo.UserAddress ADD Longitude DECIMAL(9,6) NULL;
GO
