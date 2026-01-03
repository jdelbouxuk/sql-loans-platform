/* =========================================================
   Script: 006_payment_allocation.sql
   Purpose: Create core.PaymentAllocation
   Notes:
     - Links a loan transaction (payment/reversal) to installments and components
     - Amount is SIGNED to match the ledger transaction direction
   ========================================================= */

-- Ensure schema exists
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'core')
    EXEC('CREATE SCHEMA core');
GO

-- Drop if exists (safe re-run)
IF OBJECT_ID('core.PaymentAllocation', 'U') IS NOT NULL
    DROP TABLE core.PaymentAllocation;
GO

CREATE TABLE core.PaymentAllocation
(
    PaymentAllocationId INT IDENTITY(1,1) NOT NULL
        CONSTRAINT PK_core_PaymentAllocation PRIMARY KEY CLUSTERED,

    LoanTransactionId INT NOT NULL,
    InstallmentId INT NOT NULL,

    ComponentType VARCHAR(20) NOT NULL,
        -- PRINCIPAL / INTEREST / PENALTY

    Amount DECIMAL(19,4) NOT NULL,
        -- SIGNED allocation amount (negative for reversal allocations)

    CreatedAtUtc DATETIME2(0) NOT NULL
        CONSTRAINT DF_core_PaymentAllocation_CreatedAtUtc DEFAULT SYSUTCDATETIME(),

    -- FKs
    CONSTRAINT FK_core_PaymentAllocation_LoanTransaction
        FOREIGN KEY (LoanTransactionId)
        REFERENCES core.LoanTransaction (LoanTransactionId),

    CONSTRAINT FK_core_PaymentAllocation_Installment
        FOREIGN KEY (InstallmentId)
        REFERENCES core.Installment (InstallmentId),

    -- Checks
    CONSTRAINT CK_core_PaymentAllocation_ComponentType
        CHECK (ComponentType IN ('PRINCIPAL','INTEREST','PENALTY')),

    CONSTRAINT CK_core_PaymentAllocation_Amount_NonZero
        CHECK (Amount <> 0),

    -- Prevent duplicate component allocation lines per installment per transaction
    CONSTRAINT UQ_core_PaymentAllocation_Txn_Inst_Component
        UNIQUE (LoanTransactionId, InstallmentId, ComponentType)
);
GO

-- Useful indexes for joins and installment rollups
CREATE INDEX IX_core_PaymentAllocation_LoanTransactionId
ON core.PaymentAllocation (LoanTransactionId);
GO

CREATE INDEX IX_core_PaymentAllocation_InstallmentId
ON core.PaymentAllocation (InstallmentId);
GO

