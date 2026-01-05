/* =========================================================
   Script: 002_generatedcustomer.sql
   Purpose: Map customers generated in a specific SimRun
   Notes:
     - One row per generated customer per SimRun
     - Customers are not shared across SimRuns (UNIQUE CustomerId)
   ========================================================= */

-- Ensure schema exists
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'sim')
    EXEC('CREATE SCHEMA sim');
GO

-- Drop if exists (safe re-run)
DROP TABLE IF EXISTS sim.GeneratedCustomer;
GO

CREATE TABLE sim.GeneratedCustomer
(
    SimRunId           INT NOT NULL,
    CustomerNaturalKey INT NOT NULL,   -- 1..N inside the run (stable within this run)
    CustomerId         INT NOT NULL,  
    CreatedAtUtc       DATETIME2(0) NOT NULL
        CONSTRAINT DF_sim_GeneratedCustomer_CreatedAtUtc DEFAULT SYSUTCDATETIME(),

    CONSTRAINT PK_sim_GeneratedCustomer
        PRIMARY KEY CLUSTERED (SimRunId, CustomerNaturalKey),

    -- Prevent a customer from being linked to multiple SimRuns (simplifies reruns)
    CONSTRAINT UQ_sim_GeneratedCustomer_CustomerId
        UNIQUE (CustomerId),

    CONSTRAINT FK_sim_GeneratedCustomer_SimRun
        FOREIGN KEY (SimRunId)
        REFERENCES sim.SimRun (SimRunId),

);
GO

-- Helpful for joins when issuing loans for a given SimRun
CREATE INDEX IX_sim_GeneratedCustomer_SimRunId
ON sim.GeneratedCustomer (SimRunId)
INCLUDE (CustomerId);
GO
