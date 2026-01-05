/* =========================================================
   Script: 001_customer.sql
   Purpose: Create core.Customer (borrower master data)
   Notes:
     - CustomerId: internal surrogate PK (performance + FKs)
     - CustomerRef: stable external reference (integrations)
   ========================================================= */

-- Ensure schema exists
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'core')
    EXEC('CREATE SCHEMA core');
GO

-- Drop if exists (safe re-run)
IF OBJECT_ID('core.Customer', 'U') IS NOT NULL
    DROP TABLE core.Customer;
GO


CREATE TABLE core.Customer
(
    CustomerId      INT IDENTITY(1,1) NOT NULL
        CONSTRAINT PK_core_Customer PRIMARY KEY CLUSTERED,
    CustomerRef     UNIQUEIDENTIFIER NOT NULL
        CONSTRAINT DF_core_Customer_CustomerRef DEFAULT NEWID(),
    FullName        NVARCHAR(200) NOT NULL,
    DateOfBirth     DATETIME2(0) NOT NULL,
    Email           NVARCHAR(320) NULL,
    CountryCode     CHAR(2) NOT NULL,
    SourceTypeId    TINYINT NOT NULL
        CONSTRAINT DF_core_Customer_SourceTypeId DEFAULT 0,
    SourceBatchId   INT NULL, 
    SourceEntityKey INT NULL, 
    CreatedAtUtc    DATETIME2(0) NOT NULL
        CONSTRAINT DF_core_Customer_CreatedAtUtc DEFAULT SYSUTCDATETIME(),
        
    -- Constraints
    CONSTRAINT UQ_core_Customer_CustomerRef UNIQUE (CustomerRef),
    CONSTRAINT CK_core_Customer_CountryCode_Upper
        CHECK (CountryCode = UPPER(CountryCode)),
    CONSTRAINT CK_core_Customer_CountryCode_Len
        CHECK (LEN(CountryCode) = 2),
    CONSTRAINT CK_core_Customer_DateOfBirth
        CHECK (LEN(CountryCode) = 2),

    CONSTRAINT CK_core_Customer_FullName_NotBlank
        CHECK (LEN(LTRIM(RTRIM(FullName))) > 0),

    CONSTRAINT CK_core_Customer_Email_NotBlank
        CHECK (Email IS NULL OR LEN(LTRIM(RTRIM(Email))) > 0)

);
GO

-- Optional index if you expect lookups by Email
-- (unique index is NOT recommended unless you can guarantee uniqueness)
CREATE INDEX IX_core_Customer_Email
ON core.Customer (Email)
WHERE Email IS NOT NULL;
GO
