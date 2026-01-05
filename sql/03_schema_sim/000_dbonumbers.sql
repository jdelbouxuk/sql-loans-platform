DROP TABLE IF EXISTS dbo.Numbers;
GO 
CREATE TABLE dbo.Numbers
(
    n INT NOT NULL
        CONSTRAINT PK_dbo_Numbers PRIMARY KEY
);
GO

INSERT dbo.Numbers (n)
SELECT TOP (1000000)
       ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) as n
FROM sys.all_objects a
CROSS JOIN sys.all_objects b;
GO