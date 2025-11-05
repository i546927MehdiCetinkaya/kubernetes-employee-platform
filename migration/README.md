# Database Migration Documentation

## Overview
This directory contains the database schema and seed data for the Employee Lifecycle Automation system. The migration approach uses **mock data** to demonstrate the HR database structure for Case Study 3.

## Migration Strategy: Replatform Approach

### From SQL Server to Cloud SQL PostgreSQL

**Decision Rationale:**
- **Cost Efficiency**: Eliminate SQL Server licensing costs (~€1,000-2,000/year per core)
- **GCP Native Integration**: Seamless integration with GCP services (IAM, Cloud Monitoring, VPC)
- **Modern Features**: Advanced PostgreSQL features (JSONB, full-text search, extensions)
- **Managed Service**: Automatic backups, HA, patching, and scaling handled by Google

### Mock Data Approach (Case Study Implementation)

For this case study, we use **mock data** rather than migrating from a real SQL Server database because:

1. **Learning Focus**: Demonstrates database design and GCP integration principles
2. **No Source System**: Student project doesn't have an existing SQL Server database
3. **GDPR Compliance**: Mock data allows demonstration of privacy requirements without real PII
4. **Reproducibility**: Anyone can deploy and test the system with consistent data

### Production Migration Approach (Real-World Scenario)

If this were a real production migration, the approach would be:

#### Phase 1: Assessment & Planning (1-2 weeks)
- Inventory SQL Server databases and dependencies
- Analyze schema compatibility (T-SQL → PostgreSQL)
- Identify incompatible features (stored procedures, triggers, T-SQL specific syntax)
- Size database and estimate migration time
- Plan downtime window or zero-downtime strategy

#### Phase 2: Schema Conversion (2-3 weeks)
- Use **Google Database Migration Service (DMS)** or **pgloader**
- Convert SQL Server schema to PostgreSQL:
  - Data types: `DATETIME` → `TIMESTAMP`, `NVARCHAR` → `VARCHAR`, `BIT` → `BOOLEAN`
  - Identity columns: `IDENTITY(1,1)` → `SERIAL` or `GENERATED ALWAYS AS IDENTITY`
  - Constraints: Convert CHECK constraints, foreign keys, unique constraints
- Convert stored procedures: T-SQL → PL/pgSQL
- Convert triggers and functions
- Test schema in staging environment

#### Phase 3: Data Migration (1 week)
```bash
# Option 1: Google Database Migration Service
# - Continuous replication from SQL Server to Cloud SQL
# - Minimal downtime
# - Automated cutover

# Option 2: Offline migration with pgloader
pgloader mssql://user:pass@sqlserver-host/hrdb \
         postgresql://user:pass@cloud-sql-ip/hr_database

# Option 3: Custom ETL pipeline
# - Export SQL Server data to CSV/JSON
# - Transform and validate
# - Import to Cloud SQL PostgreSQL
```

#### Phase 4: Validation & Testing (1-2 weeks)
- Data integrity checks (row counts, checksums)
- Application compatibility testing
- Performance testing and optimization
- User acceptance testing (UAT)

#### Phase 5: Cutover & Go-Live (1 day)
1. Enable read-only mode on SQL Server
2. Final incremental sync
3. Run validation queries
4. Update application connection strings
5. Cutover DNS/load balancer
6. Monitor application and database

#### Phase 6: Post-Migration (Ongoing)
- Monitor performance and optimize queries
- Decommission SQL Server after validation period
- Update documentation and runbooks
- Train team on PostgreSQL-specific features

### Schema Mapping: SQL Server → PostgreSQL

| SQL Server Type | PostgreSQL Type | Notes |
|-----------------|-----------------|-------|
| `INT IDENTITY(1,1)` | `SERIAL` or `GENERATED ALWAYS AS IDENTITY` | Auto-incrementing primary key |
| `NVARCHAR(n)` | `VARCHAR(n)` | Unicode strings |
| `NVARCHAR(MAX)` | `TEXT` | Unlimited length strings |
| `DATETIME` | `TIMESTAMP` | Date and time |
| `BIT` | `BOOLEAN` | True/false values |
| `MONEY` | `DECIMAL(19,4)` | Currency values |
| `UNIQUEIDENTIFIER` | `UUID` | Globally unique identifiers |
| `VARBINARY(MAX)` | `BYTEA` | Binary data |
| `XML` | `XML` or `JSONB` | Structured data |

## Mock Data Structure

### Files
```
migration/mock_data/
├── hr_schema.sql           # PostgreSQL CREATE TABLE statements
├── seed_data.sql          # INSERT statements with 50+ employees
└── validation_queries.sql # Data integrity checks
```

### Database Schema
- **departments**: 4 departments (Engineering, HR, Finance, IT)
- **employees**: 53 employees (50 active, 3 terminated/inactive)
- **access_logs**: 20 audit trail entries
- **employee_history**: Change tracking for GDPR compliance
- **leave_requests**: Employee time-off requests
- **equipment**: IT equipment assignments

### GDPR Compliance Features
1. **Encrypted SSN Field**: Uses base64 encoding for mock data (use AES encryption in production)
2. **Audit Logs**: Comprehensive access logging in `access_logs` table
3. **Change Tracking**: Employee changes logged in `employee_history` table
4. **Right to be Forgotten**: Soft delete via status field + deletion triggers (to be implemented)
5. **Data Minimization**: Only essential fields are stored

## Deployment Instructions

### Step 1: Deploy Infrastructure
```bash
cd terraform
terraform init
terraform plan
terraform apply
```

### Step 2: Get Cloud SQL Connection Info
```bash
terraform output cloudsql_instance_connection_name
terraform output -raw database_admin_password
```

### Step 3: Connect to Cloud SQL via Cloud SQL Proxy
```bash
# Install Cloud SQL Proxy
curl -o cloud-sql-proxy https://storage.googleapis.com/cloud-sql-connectors/cloud-sql-proxy/v2.8.0/cloud-sql-proxy.linux.amd64
chmod +x cloud-sql-proxy

# Start proxy
./cloud-sql-proxy <PROJECT>:<REGION>:<INSTANCE> --port 5432

# In another terminal, connect with psql
export PGPASSWORD=$(terraform output -raw database_admin_password)
psql -h 127.0.0.1 -U postgres -d hr_database
```

### Step 4: Initialize Database Schema
```bash
# Run schema creation
psql -h 127.0.0.1 -U postgres -d hr_database -f migration/mock_data/hr_schema.sql

# Verify schema
psql -h 127.0.0.1 -U postgres -d hr_database -c "\dt"
```

### Step 5: Load Seed Data
```bash
# Insert mock employee data
psql -h 127.0.0.1 -U postgres -d hr_database -f migration/mock_data/seed_data.sql
```

### Step 6: Validate Data
```bash
# Run validation queries
psql -h 127.0.0.1 -U postgres -d hr_database -f migration/mock_data/validation_queries.sql
```

## Security Considerations

### Production Best Practices
1. **No Hardcoded Passwords**: Use Secret Manager to store database credentials
2. **Least Privilege**: Grant only required permissions to application service accounts
3. **Encrypted Connections**: Enforce SSL/TLS for all database connections
4. **Network Isolation**: Use private IP only, no public internet access
5. **Audit Logging**: Enable Cloud Audit Logs for database access monitoring
6. **Backup & Recovery**: Automated backups with 7-day retention + PITR
7. **Encryption at Rest**: Enabled by default on Cloud SQL (GDPR requirement)

### IAM Service Accounts
- `cloud-sql-admin@`: For database migrations and admin tasks
- `gke-workload@`: For application access from Kubernetes (Phase 3)
- `github-actions@`: For Terraform deployment (infrastructure only)

## Cost Considerations

| Component | Configuration | Monthly Cost (EUR) |
|-----------|--------------|-------------------|
| Cloud SQL | db-f1-micro, HA, 20GB SSD | €25-30 |
| Storage | Database backups (7-day retention) | €2-3 |
| Network | VPC peering, private IP | €0 |
| **Total** | | **€27-33** |

## Troubleshooting

### Connection Issues
```bash
# Test Cloud SQL Proxy connection
./cloud-sql-proxy <CONNECTION_NAME> --port 5432

# Verify private IP connectivity from GKE
gcloud compute ssh <GKE_NODE> --zone <ZONE>
nc -zv <CLOUD_SQL_PRIVATE_IP> 5432
```

### Schema Issues
```sql
-- Check table structure
\d+ employees

-- Verify constraints
SELECT conname, contype FROM pg_constraint WHERE conrelid = 'employees'::regclass;

-- Check indexes
\di
```

### Permission Issues
```sql
-- Grant permissions to app user
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO hr_app_user;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO hr_app_user;
```

## Next Steps

After database migration:
1. Deploy application backend (Phase 2)
2. Set up GKE Autopilot cluster (Phase 3)
3. Configure CI/CD pipeline for application deployment
4. Implement automated testing and monitoring
5. Set up alerting for database issues

## References
- [Google Database Migration Service](https://cloud.google.com/database-migration/docs)
- [Cloud SQL PostgreSQL Documentation](https://cloud.google.com/sql/docs/postgres)
- [pgloader Documentation](https://pgloader.readthedocs.io/)
- [PostgreSQL Migration Best Practices](https://www.postgresql.org/docs/current/migration.html)
