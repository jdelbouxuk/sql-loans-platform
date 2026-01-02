# SQL Loans Platform (T-SQL)

A **SQL Server–based portfolio project** that simulates a loans/credit data platform using **pure T-SQL**.  
The project demonstrates professional-level skills in **database design, ETL logging, data quality, analytics (DW)** and **performance tuning**, aligned with real-world financial systems.

> **Target role:** SQL / Database Developer (mid-level strong)  
> **Focus:** logic, data integrity, auditability, and performance — not BI tools or frameworks.

---

## 🎯 Project Goals

- Demonstrate strong **T-SQL and relational modelling** skills
- Simulate a **realistic loans/credit domain** (origination, installments, payments)
- Implement **enterprise-style data layers**
- Show **ETL auditability and data quality controls**
- Provide **measurable performance tuning examples**
- Be easy to explain and run locally or in Azure SQL

---

## 🧱 Architecture Overview

The project is organised in clear data layers, similar to production financial systems:

```
[ SIMULATOR ]
     ↓
[ CORE (3NF) ]
     ↓
[ STAGING ]
     ↓
[ DATA WAREHOUSE ]
```

### Layers explained

- **sim**  
  Minimal operational simulator (T-SQL procedures) to generate realistic loan data  
  (issue loans, generate installments, post payments).

- **core**  
  Clean, relational 3NF model containing the system-of-record entities  
  (Customer, Loan, Installment, Transaction).

- **stg**  
  Raw staging tables simulating system exports or snapshots.

- **dw**  
  Star schema designed for analytics (facts and dimensions).

- **etl**  
  Batch control, step logging and error handling.

- **dq**  
  Data quality rules and detected issues per batch.

---

## 🗂️ Repository Structure

```
sql-loans-platform/
│
├── sql/
│   ├── 00_setup/        # Schemas and initial setup
│   ├── 01_schema_etl/   # ETL logging & audit tables/procedures
│   ├── 02_schema_core/  # Core 3NF data model
│   ├── 03_schema_sim/   # Data simulator (loan issuing, payments)
│   ├── 04_schema_stg/   # Raw staging tables
│   ├── 05_schema_dq/    # Data quality rules & issues
│   ├── 06_schema_dw/    # Star schema (facts & dimensions)
│   ├── 07_etl_jobs/     # End-to-end batch execution scripts
│   └── 08_perf/         # Performance tests and tuning
│
├── docs/
│   ├── architecture.md
│   ├── data_dictionary.md
│   └── performance.md
│
├── sql-loans-platform-gitDoc.md
└── README.md
```

---

## 🏦 Domain Model (Loans / Credit)

The domain is inspired by real loan systems rather than trading platforms.

### Core concepts

- **Customer** – loan borrower  
- **Loan** – credit contract (principal, rate, term)  
- **Installment** – fixed-price schedule (Price amortisation)  
- **Transaction** – financial events (disbursement, payment)

### Transaction philosophy

- Disbursement → positive amount  
- Payment → negative amount  
- Ledger-style accumulation (balances derived from transactions)

This mirrors how production financial systems are commonly designed.

---

## 🔄 ETL & Data Quality

### ETL Logging
Every execution runs inside a **Batch**, capturing:
- start/end time
- step-level row counts
- errors with context

### Data Quality
Rules are executed per batch, for example:
- future-dated transactions
- zero or invalid amounts
- missing loan references
- duplicate transaction identifiers

All issues are logged and traceable.

---

## ⚡ Performance Tuning

The project includes:
- baseline queries
- optimised versions
- before/after measurements using `STATISTICS IO/TIME`
- documented indexing and query rewrite decisions

Results are stored in `docs/performance.md`.

---

## ▶️ How to Run (Local)

**Requirements**
- SQL Server (Developer Edition)
- SSMS or Azure Data Studio

**High-level steps**
1. Run scripts in `sql/00_setup`
2. Create ETL and core schemas
3. Generate sample data using simulator procedures
4. Execute ETL jobs in `sql/07_etl_jobs`
5. Review analytics and performance results

Detailed steps are documented in the `/docs` folder.

---

## ☁️ Azure SQL

The project can also be deployed to **Azure SQL Database** (basic tier):
- Same scripts
- No code changes
- Demonstrates cloud readiness without overengineering

---

## 📌 Why This Project

This repository is intentionally:
- **SQL-first**
- **Framework-light**
- **Logic-heavy**
- **Business-realistic**

It is designed to be:
- easy to reason about in interviews
- easy to extend
- easy to validate technically

---

## 👤 Author

Built as a professional portfolio project focused on **SQL / Database Developer roles**  
with experience in **financial and credit systems**.

---

## 📄 License

This project is for educational and portfolio purposes.
