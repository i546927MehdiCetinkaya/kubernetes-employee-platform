# Schema Analysis: SQL Server to PostgreSQL Migration

## Executive Summary
This document analyzes the schema conversion requirements for migrating an HR database from Microsoft SQL Server to Cloud SQL PostgreSQL. The analysis covers data type mappings, feature compatibility, and migration strategies.

## Source Database: SQL Server HR System
**Assumed Architecture:**
- **Database**: HR Management System (HRMS)
- **Version**: SQL Server 2019 or later
- **Size**: ~5GB data, 100-500 active users
- **Tables**: 15-20 core tables (employees, departments, payroll, benefits)
- **Features**: Stored procedures, triggers, views, indexes, constraints

## Target Database: Cloud SQL PostgreSQL
**Target Configuration:**
- **Database**: hr_database
- **Version**: PostgreSQL 15
- **Instance**: db-f1-micro (HA, REGIONAL)
- **Region**: europe-west4 (Netherlands)
- **Networking**: Private IP only, VPC peering

## Data Type Mapping

### Numeric Types
| SQL Server | PostgreSQL | Migration Notes |
|------------|------------|-----------------|
| `TINYINT` | `SMALLINT` | Range: 0-255 → -32768 to 32767 |
| `SMALLINT` | `SMALLINT` | Direct mapping |
| `INT` | `INTEGER` | Direct mapping |
| `BIGINT` | `BIGINT` | Direct mapping |
| `DECIMAL(p,s)` | `DECIMAL(p,s)` | Direct mapping |
| `NUMERIC(p,s)` | `NUMERIC(p,s)` | Direct mapping |
| `MONEY` | `DECIMAL(19,4)` | PostgreSQL doesn't have MONEY type |
| `SMALLMONEY` | `DECIMAL(10,4)` | Convert to DECIMAL |
| `FLOAT` | `DOUBLE PRECISION` | 64-bit floating point |
| `REAL` | `REAL` | 32-bit floating point |

### String Types
| SQL Server | PostgreSQL | Migration Notes |
|------------|------------|-----------------|
| `CHAR(n)` | `CHAR(n)` | Fixed-length string |
| `VARCHAR(n)` | `VARCHAR(n)` | Variable-length string |
| `NCHAR(n)` | `CHAR(n)` | UTF-8 by default in PostgreSQL |
| `NVARCHAR(n)` | `VARCHAR(n)` | UTF-8 by default in PostgreSQL |
| `VARCHAR(MAX)` | `TEXT` | Unlimited length |
| `NVARCHAR(MAX)` | `TEXT` | Unlimited length |
| `TEXT` | `TEXT` | Direct mapping |

### Date/Time Types
| SQL Server | PostgreSQL | Migration Notes |
|------------|------------|-----------------|
| `DATE` | `DATE` | Direct mapping |
| `TIME` | `TIME` | Direct mapping |
| `DATETIME` | `TIMESTAMP` | Precision differences (ms vs μs) |
| `DATETIME2` | `TIMESTAMP` | Higher precision support |
| `SMALLDATETIME` | `TIMESTAMP` | Direct mapping |
| `DATETIMEOFFSET` | `TIMESTAMP WITH TIME ZONE` | Timezone aware |

### Binary Types
| SQL Server | PostgreSQL | Migration Notes |
|------------|------------|-----------------|
| `BINARY(n)` | `BYTEA` | Fixed-length binary |
| `VARBINARY(n)` | `BYTEA` | Variable-length binary |
| `VARBINARY(MAX)` | `BYTEA` | Unlimited binary data |

### Other Types
| SQL Server | PostgreSQL | Migration Notes |
|------------|------------|-----------------|
| `BIT` | `BOOLEAN` | True/False values |
| `UNIQUEIDENTIFIER` | `UUID` | Requires uuid-ossp extension |
| `XML` | `XML` or `JSONB` | Consider JSONB for flexibility |
| `GEOGRAPHY` | `GEOGRAPHY` | Requires PostGIS extension |
| `GEOMETRY` | `GEOMETRY` | Requires PostGIS extension |
| `HIERARCHYID` | `LTREE` | Requires ltree extension |

## Identity Columns

### SQL Server
```sql
CREATE TABLE employees (
    id INT IDENTITY(1,1) PRIMARY KEY,
    name NVARCHAR(100) NOT NULL
);
```

### PostgreSQL Option 1: SERIAL
```sql
CREATE TABLE employees (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL
);
```

### PostgreSQL Option 2: GENERATED ALWAYS AS IDENTITY (SQL Standard)
```sql
CREATE TABLE employees (
    id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR(100) NOT NULL
);
```

**Recommendation**: Use `GENERATED ALWAYS AS IDENTITY` for new tables (SQL standard, better semantics).

## Constraints & Indexes

### Primary Keys
```sql
-- SQL Server
ALTER TABLE employees ADD CONSTRAINT PK_employees PRIMARY KEY (id);

-- PostgreSQL (identical)
ALTER TABLE employees ADD CONSTRAINT PK_employees PRIMARY KEY (id);
```

### Foreign Keys
```sql
-- SQL Server
ALTER TABLE employees ADD CONSTRAINT FK_employees_departments 
    FOREIGN KEY (department_id) REFERENCES departments(id);

-- PostgreSQL (identical)
ALTER TABLE employees ADD CONSTRAINT FK_employees_departments 
    FOREIGN KEY (department_id) REFERENCES departments(id);
```

### Check Constraints
```sql
-- SQL Server
ALTER TABLE employees ADD CONSTRAINT CHK_status 
    CHECK (status IN ('active', 'inactive', 'terminated'));

-- PostgreSQL (identical)
ALTER TABLE employees ADD CONSTRAINT CHK_status 
    CHECK (status IN ('active', 'inactive', 'terminated'));
```

### Indexes
```sql
-- SQL Server
CREATE NONCLUSTERED INDEX IX_employees_email ON employees(email);
CREATE UNIQUE NONCLUSTERED INDEX UX_employees_email ON employees(email);

-- PostgreSQL (clustered/nonclustered distinction doesn't exist)
CREATE INDEX IX_employees_email ON employees(email);
CREATE UNIQUE INDEX UX_employees_email ON employees(email);
```

## Stored Procedures & Functions

### SQL Server T-SQL
```sql
CREATE PROCEDURE usp_GetEmployeesByDepartment
    @DepartmentId INT
AS
BEGIN
    SELECT * FROM employees WHERE department_id = @DepartmentId;
END;
```

### PostgreSQL PL/pgSQL
```sql
CREATE OR REPLACE FUNCTION get_employees_by_department(dept_id INTEGER)
RETURNS TABLE (
    id INTEGER,
    first_name VARCHAR,
    last_name VARCHAR,
    email VARCHAR
) AS $$
BEGIN
    RETURN QUERY
    SELECT e.id, e.first_name, e.last_name, e.email
    FROM employees e
    WHERE e.department_id = dept_id;
END;
$$ LANGUAGE plpgsql;
```

**Key Differences:**
- PostgreSQL uses functions instead of procedures (until PG 11+)
- Parameter syntax: `@param` (T-SQL) → `param_name TYPE` (PL/pgSQL)
- Variable declaration: `DECLARE @var TYPE` (T-SQL) → `DECLARE var TYPE` (PL/pgSQL)
- Return syntax: `SELECT` (T-SQL) → `RETURN QUERY SELECT` (PL/pgSQL)

## Triggers

### SQL Server
```sql
CREATE TRIGGER trg_employees_audit
ON employees
AFTER UPDATE
AS
BEGIN
    INSERT INTO employee_history (employee_id, field_name, old_value, new_value)
    SELECT i.id, 'status', d.status, i.status
    FROM inserted i
    INNER JOIN deleted d ON i.id = d.id
    WHERE i.status <> d.status;
END;
```

### PostgreSQL
```sql
CREATE OR REPLACE FUNCTION log_employee_changes()
RETURNS TRIGGER AS $$
BEGIN
    IF (TG_OP = 'UPDATE' AND OLD.status IS DISTINCT FROM NEW.status) THEN
        INSERT INTO employee_history (employee_id, field_name, old_value, new_value)
        VALUES (NEW.id, 'status', OLD.status, NEW.status);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER log_employee_changes_trigger
AFTER UPDATE ON employees
FOR EACH ROW
EXECUTE FUNCTION log_employee_changes();
```

**Key Differences:**
- PostgreSQL uses trigger functions (two-step process)
- `inserted`/`deleted` tables → `NEW`/`OLD` records
- `TG_OP` variable indicates operation type

## Views

### SQL Server
```sql
CREATE VIEW v_active_employees AS
SELECT id, first_name, last_name, email, department_id
FROM employees
WHERE status = 'active';
```

### PostgreSQL (Identical)
```sql
CREATE VIEW v_active_employees AS
SELECT id, first_name, last_name, email, department_id
FROM employees
WHERE status = 'active';
```

## T-SQL to PL/pgSQL Function Conversion

### Common T-SQL Functions
| T-SQL | PostgreSQL | Notes |
|-------|-----------|--------|
| `GETDATE()` | `CURRENT_TIMESTAMP` or `NOW()` | Current date/time |
| `DATEADD()` | `+ INTERVAL` | Date arithmetic |
| `DATEDIFF()` | `AGE()` or `-` operator | Date difference |
| `LEN()` | `LENGTH()` or `CHAR_LENGTH()` | String length |
| `SUBSTRING()` | `SUBSTRING()` | Direct mapping |
| `ISNULL()` | `COALESCE()` | Null handling |
| `NEWID()` | `gen_random_uuid()` | UUID generation |
| `CONCAT()` | `CONCAT()` or `||` | String concatenation |
| `TOP n` | `LIMIT n` | Result limiting |

### String Functions
```sql
-- T-SQL
SELECT UPPER(first_name), LOWER(last_name), LEN(email)
FROM employees;

-- PostgreSQL (mostly identical)
SELECT UPPER(first_name), LOWER(last_name), LENGTH(email)
FROM employees;
```

### Date Functions
```sql
-- T-SQL
SELECT GETDATE(), DATEADD(day, 7, hire_date), DATEDIFF(day, hire_date, GETDATE())
FROM employees;

-- PostgreSQL
SELECT CURRENT_TIMESTAMP, hire_date + INTERVAL '7 days', CURRENT_DATE - hire_date
FROM employees;
```

## Migration Challenges

### 1. Collation Differences
- **SQL Server**: Windows collation (e.g., `SQL_Latin1_General_CP1_CI_AS`)
- **PostgreSQL**: ICU or libc collation (e.g., `en_US.UTF-8`)
- **Solution**: Use UTF-8 encoding, test case-sensitive queries

### 2. Transaction Isolation
- **SQL Server**: Default is `READ COMMITTED` with row versioning
- **PostgreSQL**: Default is `READ COMMITTED` with MVCC
- **Solution**: Review application transaction logic, adjust isolation levels if needed

### 3. Locking Behavior
- **SQL Server**: Page-level and row-level locking
- **PostgreSQL**: MVCC (Multi-Version Concurrency Control)
- **Solution**: PostgreSQL generally has better concurrency, but review lock hints in queries

### 4. Query Optimizer
- **SQL Server**: Cost-based optimizer with query hints
- **PostgreSQL**: Cost-based optimizer with different statistics
- **Solution**: Re-analyze query plans, update statistics, consider new indexes

### 5. Full-Text Search
- **SQL Server**: Built-in full-text search
- **PostgreSQL**: `tsvector`, `tsquery`, and full-text indexes
- **Solution**: Rewrite full-text queries using PostgreSQL syntax

## Performance Considerations

### Indexes
```sql
-- Create indexes for foreign keys (not automatic in PostgreSQL)
CREATE INDEX idx_employees_department_id ON employees(department_id);
CREATE INDEX idx_employees_manager_id ON employees(manager_id);

-- Partial indexes (PostgreSQL feature)
CREATE INDEX idx_active_employees ON employees(email) WHERE status = 'active';

-- Covering indexes
CREATE INDEX idx_employees_email_name ON employees(email, first_name, last_name);
```

### Statistics
```sql
-- Update table statistics after migration
ANALYZE employees;
ANALYZE departments;
ANALYZE access_logs;

-- Auto-vacuum configuration (already enabled in Cloud SQL)
-- No manual configuration needed for Cloud SQL
```

### Connection Pooling
- Use **PgBouncer** or **Cloud SQL connection pooling**
- Recommended pool size: 10-20 connections per application instance

## Testing & Validation

### Data Integrity Checks
```sql
-- Row count validation
SELECT 'employees' AS table_name, COUNT(*) AS row_count FROM employees
UNION ALL
SELECT 'departments', COUNT(*) FROM departments;

-- Checksum validation (if available)
SELECT md5(string_agg(email::text, '' ORDER BY id)) AS checksum
FROM employees;

-- Foreign key validation
SELECT COUNT(*) FROM employees e
LEFT JOIN departments d ON e.department_id = d.id
WHERE e.department_id IS NOT NULL AND d.id IS NULL;
```

### Performance Testing
1. **Query Performance**: Compare execution plans and timings
2. **Load Testing**: Simulate concurrent users (100-500 connections)
3. **Backup/Restore**: Test backup and point-in-time recovery
4. **Failover**: Test HA failover (REGIONAL instance)

## Rollback Plan

### Option 1: Blue-Green Deployment
1. Keep SQL Server running (read-only mode)
2. Deploy PostgreSQL and migrate data
3. Run both systems in parallel for validation period
4. Switch traffic to PostgreSQL
5. Keep SQL Server for 30-day rollback window

### Option 2: Backup-Based Rollback
1. Full SQL Server backup before migration
2. Document all schema changes
3. Keep migration scripts for rollback
4. Test rollback procedure in staging

## Estimated Migration Timeline

| Phase | Duration | Tasks |
|-------|----------|-------|
| Assessment | 1 week | Schema analysis, dependency mapping |
| Schema Conversion | 2 weeks | Convert DDL, stored procedures, triggers |
| Data Migration | 3-5 days | Export, transform, load data |
| Testing | 1-2 weeks | Functional, performance, UAT |
| Cutover | 1 day | Final sync, DNS cutover, monitoring |
| Validation | 1 week | Post-migration monitoring, rollback window |
| **Total** | **4-6 weeks** | End-to-end migration |

## Conclusion

PostgreSQL is a robust replacement for SQL Server with:
- ✅ Feature parity for most use cases
- ✅ Better cost efficiency (no licensing)
- ✅ Superior concurrency (MVCC)
- ✅ Cloud-native integration (GCP)
- ⚠️ Requires stored procedure rewrites
- ⚠️ Different performance characteristics
- ⚠️ Learning curve for T-SQL developers

**Recommendation**: Proceed with migration using Google Database Migration Service for minimal downtime and continuous replication.
