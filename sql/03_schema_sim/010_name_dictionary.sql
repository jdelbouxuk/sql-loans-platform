/* =========================================================
   Script: 010_name_dictionary.sql
   Purpose: Name dictionary (FIRST/LAST) with weights
   ========================================================= */

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'sim')
    EXEC('CREATE SCHEMA sim');
GO

DROP TABLE IF EXISTS sim.NameDictionary;
GO

CREATE TABLE sim.NameDictionary
(
    NameId      INT IDENTITY(1,1) NOT NULL
        CONSTRAINT PK_sim_NameDictionary PRIMARY KEY,

    NameType    CHAR(5) NOT NULL
        CONSTRAINT CK_sim_NameDictionary_NameType CHECK (NameType IN ('FIRST','LAST')),

    NameValue   NVARCHAR(100) NOT NULL,

    Weight      INT NOT NULL
        CONSTRAINT CK_sim_NameDictionary_Weight CHECK (Weight BETWEEN 1 AND 100),

    CultureTag  NVARCHAR(30) NULL,  -- optional (e.g. 'UK', 'SouthAsian', 'African', 'EastAsian', 'EU', etc.)

    CONSTRAINT UQ_sim_NameDictionary UNIQUE (NameType, NameValue)
);
GO

CREATE INDEX IX_sim_NameDictionary_Type
ON sim.NameDictionary (NameType) INCLUDE (Weight, CultureTag);
GO

/* Filling up FIRST names */
INSERT INTO sim.NameDictionary (NameType, NameValue, Weight, CultureTag) VALUES
-- UK very common
('FIRST', N'Oliver', 28, N'UK'), ('FIRST', N'George', 26, N'UK'), ('FIRST', N'Harry', 24, N'UK'),
('FIRST', N'Jack', 24, N'UK'),   ('FIRST', N'Noah', 22, N'UK'),   ('FIRST', N'Leo', 22, N'UK'),
('FIRST', N'Arthur', 20, N'UK'), ('FIRST', N'Muhammad', 20, N'UK'),
('FIRST', N'Charlie', 18, N'UK'),('FIRST', N'Oscar', 18, N'UK'),
('FIRST', N'Henry', 18, N'UK'),  ('FIRST', N'Alfie', 16, N'UK'),
('FIRST', N'James', 16, N'UK'),  ('FIRST', N'William', 16, N'UK'),
('FIRST', N'Thomas', 14, N'UK'), ('FIRST', N'Jacob', 14, N'UK'),
('FIRST', N'Freddie', 12, N'UK'),('FIRST', N'Theodore', 10, N'UK'),

('FIRST', N'Amelia', 28, N'UK'), ('FIRST', N'Olivia', 26, N'UK'), ('FIRST', N'Isla', 22, N'UK'),
('FIRST', N'Ava', 22, N'UK'),    ('FIRST', N'Emily', 20, N'UK'),  ('FIRST', N'Sophia', 18, N'UK'),
('FIRST', N'Grace', 18, N'UK'),  ('FIRST', N'Lily', 18, N'UK'),
('FIRST', N'Freya', 16, N'UK'),  ('FIRST', N'Jessica', 14, N'UK'),
('FIRST', N'Ella', 14, N'UK'),   ('FIRST', N'Mia', 14, N'UK'),
('FIRST', N'Poppy', 10, N'UK'),  ('FIRST', N'Ivy', 10, N'UK'),

-- South Asian (very common in UK as well)
('FIRST', N'Aisha', 10, N'SouthAsian'), ('FIRST', N'Fatima', 10, N'SouthAsian'),
('FIRST', N'Sara', 10, N'SouthAsian'),  ('FIRST', N'Zara', 10, N'SouthAsian'),
('FIRST', N'Ahmed', 10, N'SouthAsian'), ('FIRST', N'Ali', 10, N'SouthAsian'),
('FIRST', N'Omar', 8, N'SouthAsian'),   ('FIRST', N'Yusuf', 8, N'SouthAsian'),
('FIRST', N'Ibrahim', 6, N'SouthAsian'),('FIRST', N'Hassan', 6, N'SouthAsian'),
('FIRST', N'Imran', 6, N'SouthAsian'),  ('FIRST', N'Bilal', 5, N'SouthAsian'),
('FIRST', N'Riya', 6, N'SouthAsian'),   ('FIRST', N'Anaya', 6, N'SouthAsian'),
('FIRST', N'Priya', 6, N'SouthAsian'),  ('FIRST', N'Neha', 5, N'SouthAsian'),
('FIRST', N'Arjun', 6, N'SouthAsian'),  ('FIRST', N'Rahul', 6, N'SouthAsian'),
('FIRST', N'Karan', 5, N'SouthAsian'),  ('FIRST', N'Sanjay', 4, N'SouthAsian'),

-- African / Afro-Caribbean
('FIRST', N'David', 12, N'African'), ('FIRST', N'Daniel', 12, N'African'),
('FIRST', N'Samuel', 10, N'African'),('FIRST', N'Joshua', 10, N'African'),
('FIRST', N'Hope', 6, N'African'),   ('FIRST', N'Blessing', 5, N'African'),
('FIRST', N'Chinedu', 4, N'African'),('FIRST', N'Chioma', 4, N'African'),
('FIRST', N'Kofi', 4, N'African'),   ('FIRST', N'Ama', 4, N'African'),
('FIRST', N'Yaa', 3, N'African'),    ('FIRST', N'Kwame', 3, N'African'),

-- East Asian
('FIRST', N'Wei', 4, N'EastAsian'),  ('FIRST', N'Ming', 4, N'EastAsian'),
('FIRST', N'Jin', 3, N'EastAsian'),  ('FIRST', N'Li', 3, N'EastAsian'),
('FIRST', N'Yuki', 3, N'EastAsian'), ('FIRST', N'Hana', 3, N'EastAsian'),

-- EU / Other
('FIRST', N'Luca', 5, N'EU'), ('FIRST', N'Matteo', 4, N'EU'),
('FIRST', N'Sofia', 6, N'EU'),('FIRST', N'Ana', 6, N'EU'),
('FIRST', N'Maria', 6, N'EU'),('FIRST', N'Elena', 4, N'EU'),
('FIRST', N'Lucas', 6, N'EU'),('FIRST', N'Gabriel', 6, N'EU'),
('FIRST', N'Jean', 3, N'EU'), ('FIRST', N'Andre', 3, N'EU');
GO


/* Filling up LAST names */
INSERT INTO sim.NameDictionary (NameType, NameValue, Weight, CultureTag) VALUES
-- UK very common
('LAST', N'Smith', 30, N'UK'), ('LAST', N'Jones', 24, N'UK'), ('LAST', N'Taylor', 20, N'UK'),
('LAST', N'Brown', 20, N'UK'), ('LAST', N'Williams', 18, N'UK'), ('LAST', N'Wilson', 16, N'UK'),
('LAST', N'Johnson', 16, N'UK'), ('LAST', N'Davies', 14, N'UK'), ('LAST', N'Robinson', 12, N'UK'),
('LAST', N'Wright', 12, N'UK'), ('LAST', N'Thompson', 10, N'UK'), ('LAST', N'Walker', 10, N'UK'),
('LAST', N'White', 10, N'UK'), ('LAST', N'Hughes', 9, N'UK'), ('LAST', N'Edwards', 9, N'UK'),
('LAST', N'Green', 9, N'UK'), ('LAST', N'Hall', 9, N'UK'), ('LAST', N'Lewis', 9, N'UK'),
('LAST', N'Clarke', 8, N'UK'), ('LAST', N'King', 8, N'UK'), ('LAST', N'Moore', 8, N'UK'),
('LAST', N'Lee', 8, N'UK'), ('LAST', N'Baker', 7, N'UK'), ('LAST', N'Ward', 7, N'UK'),

-- South Asian common
('LAST', N'Patel', 14, N'SouthAsian'), ('LAST', N'Singh', 14, N'SouthAsian'),
('LAST', N'Khan', 14, N'SouthAsian'),  ('LAST', N'Begum', 8, N'SouthAsian'),
('LAST', N'Ahmed', 8, N'SouthAsian'),  ('LAST', N'Ali', 8, N'SouthAsian'),
('LAST', N'Hussain', 7, N'SouthAsian'),('LAST', N'Chowdhury', 6, N'SouthAsian'),
('LAST', N'Rahman', 6, N'SouthAsian'), ('LAST', N'Sharma', 6, N'SouthAsian'),
('LAST', N'Gupta', 5, N'SouthAsian'),  ('LAST', N'Kaur', 5, N'SouthAsian'),

-- African / Afro-Caribbean
('LAST', N'Okafor', 5, N'African'), ('LAST', N'Adeyemi', 5, N'African'),
('LAST', N'Boateng', 4, N'African'), ('LAST', N'Mensah', 4, N'African'),
('LAST', N'Obi', 3, N'African'), ('LAST', N'Addo', 3, N'African'),

-- East Asian
('LAST', N'Chen', 5, N'EastAsian'), ('LAST', N'Wang', 5, N'EastAsian'),
('LAST', N'Zhang', 4, N'EastAsian'),('LAST', N'Li', 4, N'EastAsian'),
('LAST', N'Ng', 3, N'EastAsian'), ('LAST', N'Kim', 3, N'EastAsian'),

-- EU / Other
('LAST', N'Garcia', 5, N'EU'), ('LAST', N'Rodriguez', 4, N'EU'),
('LAST', N'Martinez', 4, N'EU'), ('LAST', N'Lopez', 4, N'EU'),
('LAST', N'Rossi', 4, N'EU'), ('LAST', N'Ferrari', 3, N'EU'),
('LAST', N'Dupont', 3, N'EU'), ('LAST', N'Martin', 5, N'EU'),
('LAST', N'Novak', 3, N'EU'), ('LAST', N'Kowalski', 3, N'EU');
GO
