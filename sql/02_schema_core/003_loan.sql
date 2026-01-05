/* =========================================================
   Script: 003_loan.sql
   Purpose: Create core.Loan (loan contract details)
   ========================================================= */

-- Ensure schema exists
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'core')
    EXEC('CREATE SCHEMA core');
GO

-- Drop if exists (safe re-run)
IF OBJECT_ID('core.Loan', 'U') IS NOT NULL
    DROP TABLE core.Loan;
GO

CREATE TABLE core.Loan
(
    LoanId INT IDENTITY(1,1) NOT NULL
        CONSTRAINT PK_core_Loan PRIMARY KEY CLUSTERED,

    LoanRef UNIQUEIDENTIFIER NOT NULL
        CONSTRAINT DF_core_Loan_LoanRef DEFAULT NEWID(),

    CustomerId INT NOT NULL,
    OriginatorId INT NOT NULL,
        -- Direct originator (agent/promoter/loan officer) responsible for the contract

    -- Contract dates
    OriginationDate DATE NOT NULL,
    FirstDueDate DATE NOT NULL,

    TermMonths INT NOT NULL
        CONSTRAINT CK_core_Loan_TermMonths_Positive
            CHECK (TermMonths > 0),

    MaturityDate DATE NOT NULL,
        -- Expected due date of the last installment

    -- Financial amounts
    PrincipalAmount DECIMAL(19,4) NOT NULL
        CONSTRAINT CK_core_Loan_PrincipalAmount_Positive
            CHECK (PrincipalAmount > 0),

    ProrataInterestAmount DECIMAL(19,4) NOT NULL
        CONSTRAINT DF_core_Loan_ProrataInterestAmount DEFAULT (0),
        CONSTRAINT CK_core_Loan_ProrataInterestAmount_Range
            CHECK (ProrataInterestAmount >= 0),

    FinancedAmount DECIMAL(19,4) NOT NULL,

    InstallmentAmount DECIMAL(19,4) NOT NULL
        CONSTRAINT CK_core_Loan_InstallmentAmount_Positive
            CHECK (InstallmentAmount > 0),

    -- Interest and penalties
    AnnualInterestRate DECIMAL(9,6) NOT NULL
        CONSTRAINT CK_core_Loan_AnnualInterestRate_Range
            CHECK (AnnualInterestRate >= 0),

    PenaltyRate DECIMAL(9,6) NOT NULL
        CONSTRAINT DF_core_Loan_PenaltyRate DEFAULT (0),
        CONSTRAINT CK_core_Loan_PenaltyRate_Range
            CHECK (PenaltyRate >= 0),

    LateInterestRateDaily DECIMAL(9,6) NOT NULL
        CONSTRAINT DF_core_Loan_LateInterestRateDaily DEFAULT (0),
        CONSTRAINT CK_core_Loan_LateInterestRateDaily_Range
            CHECK (LateInterestRateDaily >= 0),

    GraceDays INT NOT NULL
        CONSTRAINT DF_core_Loan_GraceDays DEFAULT (0),
        CONSTRAINT CK_core_Loan_GraceDays_Range
            CHECK (GraceDays >= 0),

    -- Currency and status
    CurrencyCode CHAR(3) NOT NULL
        CONSTRAINT DF_core_Loan_CurrencyCode DEFAULT ('GBP'),
        CONSTRAINT CK_core_Loan_CurrencyCode_Upper
            CHECK (CurrencyCode = UPPER(CurrencyCode)),
        CONSTRAINT CK_core_Loan_CurrencyCode_Len
            CHECK (LEN(CurrencyCode) = 3),

    Status VARCHAR(20) NOT NULL
        CONSTRAINT DF_core_Loan_Status DEFAULT ('ACTIVE'),
        CONSTRAINT CK_core_Loan_Status
            CHECK (Status IN ('ACTIVE','CLOSED','DEFAULTED','CANCELLED')),

    -- Audit fields
    CreatedAtUtc DATETIME2(0) NOT NULL
        CONSTRAINT DF_core_Loan_CreatedAtUtc DEFAULT SYSUTCDATETIME(),

    StatusChangedAtUtc DATETIME2(0) NOT NULL
        CONSTRAINT DF_core_Loan_StatusChangedAtUtc DEFAULT SYSUTCDATETIME(),

    -- Keys
    CONSTRAINT UQ_core_Loan_LoanRef UNIQUE (LoanRef),

    -- Foreign keys
    CONSTRAINT FK_core_Loan_Customer
        FOREIGN KEY (CustomerId)
        REFERENCES core.Customer (CustomerId),

    CONSTRAINT FK_core_Loan_Originator
        FOREIGN KEY (OriginatorId)
        REFERENCES core.Originator (OriginatorId),

    -- Cross-column invariants
    CONSTRAINT CK_core_Loan_FirstDueDate_Range
        CHECK (FirstDueDate >= OriginationDate),

    CONSTRAINT CK_core_Loan_MaturityDate_Range
        CHECK (MaturityDate >= FirstDueDate),

    CONSTRAINT CK_core_Loan_FinancedAmount_Range
        CHECK (FinancedAmount >= PrincipalAmount)
);
GO

-- Supporting indexes for joins / filters
CREATE INDEX IX_core_Loan_CustomerId
ON core.Loan (CustomerId);
GO

CREATE INDEX IX_core_Loan_OriginatorId
ON core.Loan (OriginatorId);
GO

