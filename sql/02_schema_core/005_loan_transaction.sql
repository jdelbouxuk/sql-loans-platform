/* =========================================================
   Script: 005_loan_transaction.sql
   Purpose: Create core.LoanTransaction (financial ledger for loans)
   Notes:
     - Amount is SIGNED: positive = payment/charge, negative = reversal
     - Ledger entries are immutable: do not update/delete; post reversals instead
   ========================================================= */

-- Ensure schema exists
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'core')
    EXEC('CREATE SCHEMA core');
GO

-- Drop if exists (safe re-run)
IF OBJECT_ID('core.LoanTransaction', 'U') IS NOT NULL
    DROP TABLE core.LoanTransaction;
GO

CREATE TABLE core.LoanTransaction
(
    LoanTransactionId INT IDENTITY(1,1) NOT NULL
        CONSTRAINT PK_core_LoanTransaction PRIMARY KEY CLUSTERED,

    LoanTransactionRef UNIQUEIDENTIFIER NOT NULL
        CONSTRAINT DF_core_LoanTransaction_LoanTransactionRef DEFAULT NEWID(),

    LoanId INT NOT NULL,

    TransactionAtUtc DATETIME2(0) NOT NULL,
        -- Business event timestamp (when the event is effective)

    TransactionType VARCHAR(30) NOT NULL,
        -- Ledger event type (see CHECK constraint)

    Amount DECIMAL(19,4) NOT NULL,
        -- SIGNED amount: +payment/charge, -reversal

    CurrencyCode CHAR(3) NOT NULL
        CONSTRAINT DF_core_LoanTransaction_CurrencyCode DEFAULT ('GBP'),
        CONSTRAINT CK_core_LoanTransaction_CurrencyCode_Upper CHECK (CurrencyCode = UPPER(CurrencyCode)),
        CONSTRAINT CK_core_LoanTransaction_CurrencyCode_Len   CHECK (LEN(CurrencyCode) = 3),

    ReversesLoanTransactionId INT NULL,
        -- Points to the original transaction being reversed

    Narrative NVARCHAR(250) NULL,
        -- Optional free-text description (bank ref, notes, etc.)

    CreatedAtUtc DATETIME2(0) NOT NULL
        CONSTRAINT DF_core_LoanTransaction_CreatedAtUtc DEFAULT SYSUTCDATETIME(),

    -- Uniques
    CONSTRAINT UQ_core_LoanTransaction_LoanTransactionRef UNIQUE (LoanTransactionRef),

    -- FK
    CONSTRAINT FK_core_LoanTransaction_Loan
        FOREIGN KEY (LoanId)
        REFERENCES core.Loan (LoanId),

    CONSTRAINT FK_core_LoanTransaction_ReversesLoanTransaction
        FOREIGN KEY (ReversesLoanTransactionId)
        REFERENCES core.LoanTransaction (LoanTransactionId),

    -- Checks
    CONSTRAINT CK_core_LoanTransaction_Type
        CHECK (TransactionType IN
        (
            'DISBURSEMENT',
            'PAYMENT',
            'PAYMENT_REVERSAL',
            'PENALTY_CHARGE',
            'PENALTY_REVERSAL',
            'LATE_INTEREST_ACCRUAL',
            'LATE_INTEREST_REVERSAL'
        )),

    CONSTRAINT CK_core_LoanTransaction_Amount_NonZero
        CHECK (Amount <> 0),

    -- Reversal invariants
    CONSTRAINT CK_core_LoanTransaction_Reversal_Reference
        CHECK
        (
            (TransactionType LIKE '%_REVERSAL' AND ReversesLoanTransactionId IS NOT NULL)
            OR
            (TransactionType NOT LIKE '%_REVERSAL' AND ReversesLoanTransactionId IS NULL)
        ),

    -- Sign rules
    CONSTRAINT CK_core_LoanTransaction_Amount_Sign_ByType
        CHECK
        (
            (TransactionType IN ('DISBURSEMENT','PAYMENT','PENALTY_CHARGE','LATE_INTEREST_ACCRUAL') AND Amount > 0)
            OR
            (TransactionType IN ('PAYMENT_REVERSAL','PENALTY_REVERSAL','LATE_INTEREST_REVERSAL') AND Amount < 0)
        )
);
GO

-- Useful indexes for "as-of" and loan history queries
CREATE INDEX IX_core_LoanTransaction_LoanId_TransactionAtUtc
ON core.LoanTransaction (LoanId, TransactionAtUtc);
GO

CREATE INDEX IX_core_LoanTransaction_ReversesLoanTransactionId
ON core.LoanTransaction (ReversesLoanTransactionId)
WHERE ReversesLoanTransactionId IS NOT NULL;
GO

