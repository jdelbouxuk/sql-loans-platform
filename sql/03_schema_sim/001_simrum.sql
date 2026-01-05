/* =========================================================
   Script: 001_simrun.sql
   Purpose: Create sim.SimRun (simulator run tracker)
   Notes:
     - Re-runnable
     - Stores seed + config snapshot (optional) for reproducibility
   ========================================================= */

-- Ensure schema exists
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'sim')
    EXEC('CREATE SCHEMA sim');
GO

-- Drop if exists (safe re-run)
DROP TABLE IF EXISTS sim.SimRun;
GO

CREATE TABLE sim.SimRun
(
    SimRunId        INT IDENTITY(1,1) NOT NULL
        CONSTRAINT PK_sim_SimRun PRIMARY KEY CLUSTERED,

    RunName         NVARCHAR(100) NULL, -- e.g. 'SIM_M1_BASELINE_20260104'
    
    Seed            INT NOT NULL,

    AsOfDate        DATE NOT NULL
        CONSTRAINT DF_sim_SimRun_AsOfDate DEFAULT (CONVERT(date, SYSUTCDATETIME())),

    ConfigCode      NVARCHAR(30) NOT NULL
        CONSTRAINT DF_sim_SimRun_ConfigCode DEFAULT (N'BASELINE'),

    ParamsJson      NVARCHAR(MAX) NULL, -- snapshot/config of run (optional)

    StartedAtUtc    DATETIME2(0) NOT NULL
        CONSTRAINT DF_sim_SimRun_StartedAtUtc DEFAULT SYSUTCDATETIME(),

    EndedAtUtc      DATETIME2(0) NULL,

    Status          NVARCHAR(30) NOT NULL
        CONSTRAINT DF_sim_SimRun_Status DEFAULT (N'RUNNING'),

    CONSTRAINT CK_sim_SimRun_Status
        CHECK (Status IN (N'RUNNING', N'SUCCESS', N'FAILED'))
);
GO

-- helps quickly find latest running/failed/success runs
CREATE INDEX IX_sim_SimRun_Status_StartedAtUtc
ON sim.SimRun (Status, StartedAtUtc DESC);
GO
