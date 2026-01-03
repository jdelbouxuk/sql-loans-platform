/* =========================================================
   Script: 004_installment.sql
   Purpose: Create core.Installment (loan repayment schedule and payment tracking)
   ========================================================= */

-- Ensure schema exists
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'core')
    EXEC('CREATE SCHEMA core');
GO

-- Drop if exists (safe re-run)
IF OBJECT_ID('core.Installment', 'U') IS NOT NULL
    DROP TABLE core.Installment;
GO

CREATE TABLE core.Installment
(
    InstallmentId INT IDENTITY(1,1) NOT NULL
        CONSTRAINT PK_core_Installment PRIMARY KEY CLUSTERED,

    InstallmentRef UNIQUEIDENTIFIER NOT NULL
        CONSTRAINT DF_core_Installment_InstallmentRef DEFAULT NEWID(),

    LoanId INT NOT NULL,

    InstallmentNumber INT NOT NULL
        CONSTRAINT CK_core_Installment_InstallmentNumber_Range
            CHECK (InstallmentNumber >= 1),

    DueDate DATE NOT NULL,

    -- Contracted (scheduled) amounts - set at origination time
    ScheduledAmount DECIMAL(19,4) NOT NULL
        CONSTRAINT CK_core_Installment_ScheduledAmount_Positive
            CHECK (ScheduledAmount > 0),

    DuePrincipal DECIMAL(19,4) NOT NULL
        CONSTRAINT CK_core_Installment_DuePrincipal_Range
            CHECK (DuePrincipal >= 0),

    DueInterest DECIMAL(19,4) NOT NULL
        CONSTRAINT CK_core_Installment_DueInterest_Range
            CHECK (DueInterest >= 0),

    -- Payment tracking (accumulated)
    PaidPrincipal DECIMAL(19,4) NOT NULL
        CONSTRAINT DF_core_Installment_PaidPrincipal DEFAULT (0),
        CONSTRAINT CK_core_Installment_PaidPrincipal_Range
            CHECK (PaidPrincipal >= 0),

    PaidInterest DECIMAL(19,4) NOT NULL
        CONSTRAINT DF_core_Installment_PaidInterest DEFAULT (0),
        CONSTRAINT CK_core_Installment_PaidInterest_Range
            CHECK (PaidInterest >= 0),

    PaidPenalty DECIMAL(19,4) NOT NULL
        CONSTRAINT DF_core_Installment_PaidPenalty DEFAULT (0),
        CONSTRAINT CK_core_Installment_PaidPenalty_Range
            CHECK (PaidPenalty >= 0),

    Status VARCHAR(20) NOT NULL
        CONSTRAINT DF_core_Installment_Status DEFAULT ('SCHEDULED'),
        CONSTRAINT CK_core_Installment_Status
            CHECK (Status IN ('SCHEDULED','PARTIAL','PAID','LATE')),

    CreatedAtUtc DATETIME2(0) NOT NULL
        CONSTRAINT DF_core_Installment_CreatedAtUtc DEFAULT SYSUTCDATETIME(),

    StatusChangedAtUtc DATETIME2(0) NOT NULL
        CONSTRAINT DF_core_Installment_StatusChangedAtUtc DEFAULT SYSUTCDATETIME(),

    -- Uniques
    CONSTRAINT UQ_core_Installment_InstallmentRef UNIQUE (InstallmentRef),

    CONSTRAINT UQ_core_Installment_Loan_InstallmentNumber
        UNIQUE (LoanId, InstallmentNumber),

    -- FK
    CONSTRAINT FK_core_Installment_Loan
        FOREIGN KEY (LoanId)
        REFERENCES core.Loan (LoanId),

    -- Cross-column invariants
    CONSTRAINT CK_core_Installment_DueBreakdown
        CHECK (DuePrincipal + DueInterest = ScheduledAmount)
);
GO

-- Supporting indexes (common access paths)
CREATE INDEX IX_core_Installment_LoanId_DueDate
ON core.Installment (LoanId, DueDate);
GO

CREATE INDEX IX_core_Installment_DueDate_Status
ON core.Installment (DueDate, Status);
GO
