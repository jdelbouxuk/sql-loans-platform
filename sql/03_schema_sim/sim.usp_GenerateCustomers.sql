/* =========================================================
   Proc: sim.usp_GenerateCustomers
   Purpose:
     - Generate N customers for a given SimRun (seeded, deterministic)
     - Insert into core.Customer
     - Insert mapping into sim.GeneratedCustomer (SimRunId + NaturalKey -> CustomerId)
   Key concepts:
     - Reproducible data via Seed (same seed => same dataset)
     - Business-time correctness via AsOfDate (DOB validation uses AsOfDate)
     - Set-based generation (no cursor/while)
   ========================================================= */

CREATE OR ALTER PROCEDURE sim.usp_GenerateCustomers
(
    @SimRunId INT,
    @CustomerCount INT
)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        /* ---------------------------
           1) Validate inputs
           --------------------------- */
        IF @SimRunId IS NULL OR @SimRunId <= 0
            THROW 50001, '@SimRunId is required and must be > 0.', 1;

        IF @CustomerCount IS NULL OR @CustomerCount <= 0
            THROW 50002, '@CustomerCount must be > 0.', 1;

        -- Load SimRun context (Seed + AsOfDate)
        DECLARE @Seed INT, @AsOfDate DATE;
        SELECT
            @Seed = r.Seed,
            @AsOfDate = r.AsOfDate
        FROM sim.SimRun r
        WHERE r.SimRunId = @SimRunId;

        IF @Seed IS NULL OR @AsOfDate IS NULL
            THROW 50003, 'SimRun not found or missing Seed/AsOfDate.', 1;

        -- Idempotency guard: prevent generating customers twice for the same SimRun
        IF EXISTS (SELECT 1 FROM sim.GeneratedCustomer WHERE SimRunId = @SimRunId)
            THROW 50004, 'Customers already generated for this SimRunId (mapping exists).', 1;
        
        -- Deterministic generation using Seed + NaturalKey (reproducible dataset)
        DROP TABLE IF EXISTS #GenCustomers;
        CREATE TABLE #GenCustomers
        (
            CustomerNaturalKey INT NOT NULL PRIMARY KEY,
            HashValueFirst     BIGINT NOT NULL,
            HashValueLast      BIGINT NOT NULL,
            FullName           NVARCHAR(200) NULL,
            Email              NVARCHAR(320) NULL,
            CountryCode        CHAR(2) NULL,
            DateOfBirth        DATE NULL
        );

        INSERT #GenCustomers(CustomerNaturalKey, HashValueFirst, HashValueLast)
        SELECT TOP (@CustomerCount)
               n AS CustomerNaturalKey,
               ABS(CONVERT(BIGINT, CAST(SUBSTRING(HASHBYTES('SHA2_256', CONCAT(@Seed, ':F:', n)), 1, 4) AS INT))) AS HashValueFirst,
               ABS(CONVERT(BIGINT, CAST(SUBSTRING(HASHBYTES('SHA2_256', CONCAT(@Seed, ':L:', n)), 1, 4) AS INT))) AS HashValueLast
        FROM dbo.Numbers
        ORDER BY n;
        
        IF @@ROWCOUNT <> @CustomerCount 
            THROW 50005, 'dbo.Numbers does not contain enough rows for @CustomerCount.', 1;

        DECLARE @FirstNameCount INT, @FirstTotalWeight INT;
        DECLARE @LastNameCount INT, @LastTotalWeight  INT;

        DROP TABLE IF EXISTS #FirstNames;

        ;WITH x AS
        (
            SELECT
                rn = ROW_NUMBER() OVER (ORDER BY NameId),
                NameValue,
                Weight,
                RunningSum = SUM(Weight) OVER (ORDER BY NameId)
            FROM sim.NameDictionary
            WHERE NameType = 'FIRST'
        )
        SELECT
            rn,
            NameValue,
            CumStart = RunningSum - Weight,
            CumEnd   = RunningSum - 1,
            Weight
        INTO #FirstNames
        FROM x;

        SELECT @FirstTotalWeight = SUM(Weight) FROM #FirstNames;

        DROP TABLE IF EXISTS #LastNames;
        ;WITH x AS
        (
            SELECT
                rn = ROW_NUMBER() OVER (ORDER BY NameId),
                NameValue,
                Weight,
                RunningSum = SUM(Weight) OVER (ORDER BY NameId)
            FROM sim.NameDictionary
            WHERE NameType = 'LAST'
        )
        SELECT
            rn,
            NameValue,
            CumStart = RunningSum - Weight,
            CumEnd   = RunningSum - 1,
            Weight
        INTO #LastNames
        FROM x;
    
        SELECT @LastTotalWeight = SUM(Weight) FROM #LastNames;

        IF @FirstTotalWeight IS NULL OR @FirstTotalWeight <= 0
            THROW 50006, 'NameDictionary has no active FIRST names or invalid weights.', 1;

        IF @LastTotalWeight IS NULL OR @LastTotalWeight <= 0
            THROW 50007, 'NameDictionary has no active LAST names or invalid weights.', 1;

        DECLARE @DobMin DATE = DATEADD(YEAR, -75, @AsOfDate);
        DECLARE @DobMax DATE = DATEADD(YEAR, -18, @AsOfDate);
        DECLARE @DobSpanDays INT = DATEDIFF(DAY, @DobMin, @DobMax) + 1;
   
        UPDATE G 
            SET 
                G.FullName = CONCAT(fn.NameValue, ' ', ln.NameValue),
                G.DateOfBirth = DATEADD(DAY, r.rDOB, @DobMin),
                G.Email = LOWER(CONCAT(fn.NameValue, '.', ln.NameValue, '+', CAST(@Seed AS varchar (20)), '_', CAST(G.CustomerNaturalKey AS varchar(20)),  '@example.com')),
                G.CountryCode = CAST(CASE WHEN r.rCountry < 95 then 'GB' ELSE 'IE' END AS CHAR(2))
        FROM #GenCustomers G
            CROSS APPLY(
                SELECT 
                    rFirst = G.HashValueFirst % @FirstTotalWeight,
                    rLast = G.HashValueLast % @LastTotalWeight,
                    rDOB = G.HashValueFirst % @DobSpanDays,
                    rCountry = G.HashValueLast % 100
            ) r
            JOIN #FirstNames fn
                ON fn.CumStart <= r.rFirst and r.rFirst <= fn.CumEnd
            JOIN #LastNames ln
                ON ln.CumStart <= r.rLast and r.rLast <= ln.CumEnd;

        DROP TABLE IF EXISTS #Map;
        CREATE TABLE #Map
        (
            CustomerNaturalKey INT NOT NULL PRIMARY KEY,
            CustomerId         INT NOT NULL UNIQUE
        );

        BEGIN TRAN;
            -- Insert into core and capture generated CustomerId for mapping
            INSERT INTO core.Customer
            (
                CustomerRef,
                FullName,
                Email,
                CountryCode,
                DateOfBirth,
                SourceTypeId,
                SourceBatchId,
                SourceEntityKey
            )
            OUTPUT
                inserted.SourceEntityKey,
                inserted.CustomerId
            INTO #Map (CustomerNaturalKey, CustomerId)
            SELECT
                NEWID() AS CustomerRef,
                src.FullName,
                src.Email,
                src.CountryCode,
                src.DateOfBirth,
                1, -- Simulator
                @SimRunId,
                src.CustomerNaturalKey
            FROM #GenCustomers AS src;
            
            -- Persist mapping (SimRunId + NaturalKey -> core.CustomerId)
            INSERT 
                sim.GeneratedCustomer(SimRunId, CustomerNaturalKey, CustomerId)
            SELECT 
                @SimRunId, m.CustomerNaturalKey, m.CustomerId
            FROM #Map m;
         
         COMMIT TRAN;
 
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
            ROLLBACK TRAN;        
        
        THROW;
    END CATCH

END;
GO




