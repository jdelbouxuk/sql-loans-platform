/* =========================================================
   Script: 002_originator.sql
   Purpose: Create core.Originator (loan sales / origination hierarchy)
   ========================================================= */

-- Ensure schema exists
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'core')
    EXEC('CREATE SCHEMA core');
GO

-- Drop if exists (safe re-run)
IF OBJECT_ID('core.Originator', 'U') IS NOT NULL
    DROP TABLE core.Originator;
GO

CREATE TABLE core.Originator
(
    OriginatorId INT IDENTITY(1,1) NOT NULL
        CONSTRAINT PK_core_Originator PRIMARY KEY CLUSTERED,

    OriginatorRef UNIQUEIDENTIFIER NOT NULL
        CONSTRAINT DF_core_Originator_OriginatorRef DEFAULT NEWID(),

    OriginatorCode VARCHAR(30) NOT NULL,
        -- Business identifier (e.g. employee code / agent code)

    FullName NVARCHAR(200) NOT NULL,
        -- Display name

    RoleType VARCHAR(20) NOT NULL,
        -- AGENT / SUPERVISOR / MANAGER / PROMOTER (adjust as needed)

    ParentOriginatorId INT NULL,
        -- Self-reference to represent the hierarchy (e.g. AGENT -> SUPERVISOR -> MANAGER)

    RegionCode VARCHAR(20) NULL,
        -- Optional: commercial region identifier (kept simple for now)

    IsActive BIT NOT NULL
        CONSTRAINT DF_core_Originator_IsActive DEFAULT (1),

    CreatedAtUtc DATETIME2(0) NOT NULL
        CONSTRAINT DF_core_Originator_CreatedAtUtc DEFAULT SYSUTCDATETIME(),

    -- Uniques
    CONSTRAINT UQ_core_Originator_OriginatorRef UNIQUE (OriginatorRef),
    CONSTRAINT UQ_core_Originator_OriginatorCode UNIQUE (OriginatorCode),

    -- FK (hierarchy)
    CONSTRAINT FK_core_Originator_ParentOriginator
        FOREIGN KEY (ParentOriginatorId)
        REFERENCES core.Originator (OriginatorId),

    -- Checks
    CONSTRAINT CK_core_Originator_FullName_NotBlank
        CHECK (LEN(LTRIM(RTRIM(FullName))) > 0),

    CONSTRAINT CK_core_Originator_RoleType
        CHECK (RoleType IN ('AGENT','SUPERVISOR','MANAGER','PROMOTER')),

    CONSTRAINT CK_core_Originator_RegionCode_NotBlank
        CHECK (RegionCode IS NULL OR LEN(LTRIM(RTRIM(RegionCode))) > 0)
);
GO
