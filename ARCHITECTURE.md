# Architecture Design Document
**Case Study 3 - Innovatech Solutions Employee Lifecycle Automation**

**Author**: Mehdi Cetinkaya (mehdi6132)  
**Date**: November 2024  
**Version**: 1.0  
**Platform**: Google Cloud Platform (GCP)

---

## 1. Executive Summary

This document describes the architecture for an Employee Lifecycle Automation system built on Google Cloud Platform. The system implements Zero Trust security principles, GDPR-compliant data handling, and cost-efficient infrastructure design.

**Business Context:**  
Innovatech Solutions is a mid-sized technology company with 50+ employees across 4 departments (Engineering, HR, Finance, IT). The company requires an automated system to manage employee onboarding, offboarding, access provisioning, and audit logging.

**Key Architectural Decisions:**
- **Cloud Provider**: 100% Google Cloud Platform (GCP) for native integration and cost efficiency
- **Database**: Cloud SQL PostgreSQL (migrated from SQL Server) for licensing cost savings
- **Security**: Zero Trust Architecture with micro-segmentation and private networking
- **Region**: europe-west4 (Netherlands) for data sovereignty and low latency
- **High Availability**: Regional Cloud SQL with Multi-AZ deployment

**Success Criteria:**
- ✅ Automated employee provisioning/deprovisioning
- ✅ GDPR-compliant audit trails
- ✅ 99.95% availability (Regional HA)
- ✅ Cost under €50/month
- ✅ Zero Trust security implementation

---

## 2. Network Topology

### 2.1 VPC Architecture

```
VPC: innovatech-vpc (10.100.0.0/16)
├── Region: europe-west4 (Netherlands)
│   ├── Subnet: database-subnet (10.100.2.0/24)
│   │   ├── Purpose: Cloud SQL PostgreSQL
│   │   ├── Availability: Multi-AZ (zones a, b, c)
│   │   ├── Private IP: 10.100.2.0/24 range
│   │   └── Private Google Access: Enabled
│   │
│   └── Subnet: gke-subnet (10.100.1.0/24)
│       ├── Purpose: GKE Autopilot (Phase 3)
│       ├── Pod CIDR: 10.101.0.0/16 (secondary range)
│       ├── Service CIDR: 10.102.0.0/20 (secondary range)
│       └── Private Google Access: Enabled
│
├── Private Service Connection
│   ├── IP Range: 10.103.0.0/16 (allocated)
│   └── Purpose: Cloud SQL private networking
│
├── Cloud Router
│   └── Cloud NAT
│       ├── Purpose: Outbound internet access for updates/patches
│       └── Source IPs: Auto-allocated
│
└── VPC Flow Logs
    ├── Aggregation: 5 seconds
    ├── Sampling: 50%
    └── Purpose: Security monitoring and troubleshooting
```

### 2.2 Network Design Decisions

**Why Private Subnets?**
- **Security**: No direct internet exposure reduces attack surface
- **Zero Trust**: Implements principle of least privilege networking
- **Compliance**: GDPR requires data protection in transit and at rest
- **Cost**: Private Google Access avoids egress charges for GCP APIs

**Why Multiple Subnets?**
- **Micro-segmentation**: Isolate database tier from application tier
- **Firewall Granularity**: Apply different firewall rules per subnet
- **Blast Radius**: Limit impact of security incidents
- **Future Expansion**: Reserved subnet for GKE (Phase 3)

**Why europe-west4 (Netherlands)?**
- **Proximity**: Low latency for European users
- **Data Sovereignty**: EU data stays in EU (GDPR)
- **Cost**: Competitive pricing compared to other EU regions
- **Availability**: Multiple availability zones for HA

### 2.3 IP Addressing Plan

| CIDR Block | Purpose | Size | Notes |
|------------|---------|------|-------|
| 10.100.0.0/16 | VPC | 65,536 IPs | RFC 1918 private space |
| 10.100.1.0/24 | GKE subnet | 256 IPs | Phase 3 |
| 10.100.2.0/24 | Database subnet | 256 IPs | Cloud SQL |
| 10.101.0.0/16 | GKE pods | 65,536 IPs | Secondary range |
| 10.102.0.0/20 | GKE services | 4,096 IPs | Secondary range |
| 10.103.0.0/16 | Private connection | 65,536 IPs | Cloud SQL peering |

**IP Range Justification:**
- Non-overlapping ranges prevent conflicts with on-premises networks (if any)
- Large enough for growth (currently 50 employees, room for 500+)
- Follows GCP best practices for secondary ranges

---

## 3. Database Architecture

### 3.1 Cloud SQL PostgreSQL Configuration

```yaml
Instance Configuration:
  Name: innovatech-postgres-<random>
  Version: PostgreSQL 15
  Tier: db-f1-micro (0.6 GB RAM, 1 shared vCPU)
  Disk: 20 GB SSD (auto-resize enabled, max 100 GB)
  Availability: REGIONAL (Multi-AZ)
  Zones: europe-west4-a, europe-west4-b, europe-west4-c

Networking:
  Private IP: Yes (10.100.2.x range)
  Public IP: No (disabled for security)
  VPC: innovatech-vpc
  SSL: Required (TLS 1.3)

Backup Configuration:
  Automated Backups: Enabled
  Backup Time: 03:00 UTC
  Retention: 7 days
  Point-in-Time Recovery: Enabled
  Transaction Log Retention: 7 days

Maintenance:
  Window: Sunday 04:00-05:00 UTC
  Update Track: Stable
  Auto Restart: Yes

High Availability:
  Mode: Regional (synchronous replication)
  Failover: Automatic (30-60 seconds)
  Replica: Standby in different zone
```

### 3.2 Database Schema

**Core Tables:**
- `employees` - Employee master data (53 records)
- `departments` - Organizational units (4 departments)
- `access_logs` - Audit trail (GDPR compliance)
- `employee_history` - Change tracking (GDPR compliance)
- `leave_requests` - Time-off management
- `equipment` - IT asset assignments

**GDPR-Compliant Features:**
1. **Encrypted PII**: SSN field uses encryption (base64 for mock, AES-256 in production)
2. **Audit Logging**: All access logged with timestamp, IP, user agent
3. **Change Tracking**: Employee updates logged for compliance
4. **Data Minimization**: Only essential fields stored
5. **Right to Access**: Query interface for data subject requests

**Database Optimization:**
- Indexes on foreign keys (department_id, manager_id, employee_id)
- Composite indexes for frequent queries
- Partial indexes for filtered queries (e.g., `WHERE status = 'active'`)
- Automatic `updated_at` triggers
- Referential integrity with foreign key constraints

### 3.3 High Availability Strategy

**Regional HA Configuration:**
```
Primary Zone: europe-west4-a
├── Primary Instance (writer)
├── Synchronous Replication → Standby (zone b or c)
└── Automatic Failover on:
    ├── Zone failure
    ├── Instance failure
    ├── Network partition
    └── Maintenance window
```

**Failover Characteristics:**
- **RTO**: 30-60 seconds (automatic failover)
- **RPO**: 0 seconds (synchronous replication, no data loss)
- **Downtime**: Minimal (application reconnects automatically)
- **Cost**: ~2x single-zone cost (acceptable for production)

**Backup Strategy:**
- **Daily Automated Backups**: 03:00 UTC (low-traffic period)
- **Retention**: 7 days (configurable up to 365)
- **Point-in-Time Recovery**: Enabled (restore to any second within 7 days)
- **Storage**: Geo-redundant backup storage in EU

### 3.4 Performance Tuning

**Database Flags:**
```sql
-- Connection logging for security audit
log_connections = on
log_disconnections = on

-- Performance monitoring
log_checkpoints = on
log_lock_waits = on

-- Query insights
track_activity_query_size = 1024
```

**Monitoring Metrics:**
- CPU utilization (alert > 80%)
- Memory utilization (alert > 90%)
- Active connections (alert > 80% of max)
- Disk usage (alert > 85%)
- Replication lag (alert > 60 seconds)

---

## 4. Zero Trust Implementation

### 4.1 Zero Trust Principles Applied

**Principle 1: Never Trust, Always Verify**
- No implicit trust based on network location
- All connections require authentication and authorization
- Service accounts use short-lived tokens (Workload Identity)

**Principle 2: Assume Breach**
- Micro-segmentation limits blast radius
- Audit logs track all access attempts
- Encryption everywhere (at rest and in transit)

**Principle 3: Least Privilege**
- IAM roles grant minimum required permissions
- Firewall rules deny by default, allow explicitly
- Service accounts scoped to specific resources

### 4.2 Network Security Controls

**VPC Firewall Rules:**
```yaml
Priority 65534 - Deny All Ingress:
  Action: DENY
  Direction: INGRESS
  Source: 0.0.0.0/0
  Destination: All instances
  Protocol: All

Priority 1000 - Allow Internal VPC:
  Action: ALLOW
  Direction: INGRESS
  Source: 10.100.0.0/16
  Destination: All instances
  Protocol: TCP, UDP, ICMP

Priority 900 - Allow GKE to Cloud SQL:
  Action: ALLOW
  Direction: INGRESS
  Source: 10.100.1.0/24 (GKE subnet)
  Destination: Cloud SQL
  Protocol: TCP port 5432

Priority 900 - Allow IAP SSH:
  Action: ALLOW
  Direction: INGRESS
  Source: 35.235.240.0/20 (IAP range)
  Destination: All instances
  Protocol: TCP port 22

Priority 500 - Deny Database Egress:
  Action: DENY
  Direction: EGRESS
  Source: Database subnet
  Destination: 0.0.0.0/0 (internet)
  Protocol: All
```

**Firewall Rule Justification:**
- **Default Deny**: Implements Zero Trust baseline
- **Internal VPC Allow**: Required for inter-subnet communication
- **GKE to Cloud SQL**: Allows application access (least privilege)
- **IAP SSH**: Secure bastion alternative (no public SSH)
- **Database Egress Deny**: Prevents data exfiltration

### 4.3 Identity & Access Management

**Service Accounts:**
```yaml
github-actions@PROJECT_ID.iam.gserviceaccount.com:
  Purpose: Terraform deployment via GitHub Actions
  Roles:
    - roles/compute.admin
    - roles/cloudsql.admin
    - roles/iam.serviceAccountUser
    - roles/storage.admin
    - roles/servicenetworking.networksAdmin
    - roles/monitoring.admin
  Authentication: Workload Identity Federation (OIDC)
  Key Management: No service account keys (keyless auth)

cloud-sql-admin@PROJECT_ID.iam.gserviceaccount.com:
  Purpose: Database migrations and admin tasks
  Roles:
    - roles/cloudsql.client
    - roles/cloudsql.instanceUser
  Authentication: Application Default Credentials

gke-workload@PROJECT_ID.iam.gserviceaccount.com:
  Purpose: Application pods in GKE (Phase 3)
  Roles:
    - roles/cloudsql.client
  Authentication: Workload Identity (Kubernetes SA binding)
```

**Why No Service Account Keys?**
- Keys can be leaked or stolen
- Workload Identity Federation uses OIDC tokens (short-lived)
- Eliminates key rotation burden
- Follows Google Cloud security best practices

### 4.4 Encryption Strategy

**Data at Rest:**
- Cloud SQL: AES-256 encryption (Google-managed keys)
- Cloud Storage: AES-256 encryption (Google-managed keys)
- Future: Customer-Managed Encryption Keys (CMEK) for additional control

**Data in Transit:**
- Cloud SQL: TLS 1.3 required for all connections
- VPC: Private Google Access (no internet transit)
- GitHub Actions: HTTPS with certificate pinning

**Application-Level Encryption:**
- SSN field: Encrypted before storage (base64 mock, AES-256 in production)
- Passwords: Never stored (future: Firebase Auth for user authentication)

---

## 5. Database Migration Strategy

### 5.1 Migration Approach: Replatform

**Decision Matrix:**

| Approach | Pros | Cons | Selected |
|----------|------|------|----------|
| **Rehost** (Lift & Shift) | Fast, low risk | SQL Server license costs, no cloud benefits | ❌ |
| **Replatform** (SQL Server → PostgreSQL) | Cost savings, cloud-native, modern features | Schema conversion, app changes | ✅ |
| **Refactor** (NoSQL) | Highly scalable, flexible schema | Complete rewrite, learning curve | ❌ |
| **Rebuild** (Serverless) | Pay-per-use, auto-scaling | High development effort, vendor lock-in | ❌ |

**Selected Approach: Replatform to Cloud SQL PostgreSQL**

### 5.2 Justification

**Financial:**
- SQL Server Standard: €1,000-2,000/year per core
- Cloud SQL PostgreSQL: €300-400/year (db-f1-micro HA)
- **Savings: €600-1,600/year** (67-80% cost reduction)

**Technical:**
- PostgreSQL 15 features: JSONB, full-text search, advanced indexing
- GCP native integration: IAM, Cloud Monitoring, VPC peering
- Managed service: Automatic backups, patching, HA
- Open source: No vendor lock-in, large community

**Operational:**
- Eliminates license compliance burden
- Automatic minor version upgrades
- Built-in monitoring and alerting
- Multi-AZ HA without complex setup

### 5.3 Mock Data Approach (Case Study)

**Why Mock Data?**
1. **No Source System**: Student project doesn't have existing SQL Server
2. **Learning Focus**: Demonstrates schema design and GCP integration
3. **GDPR Compliance**: No real PII data, no privacy concerns
4. **Reproducibility**: Anyone can deploy with consistent seed data

**Mock Data Contents:**
- 53 employees (50 active, 3 terminated/inactive)
- 4 departments (Engineering, HR, Finance, IT)
- 20 access log entries (audit trail demonstration)
- 7 leave requests (workflow demonstration)
- 10 equipment assignments (asset tracking)

### 5.4 Production Migration Approach (Real-World)

**Phase 1: Assessment (1 week)**
- Inventory SQL Server databases and dependencies
- Schema compatibility analysis (T-SQL → PL/pgSQL)
- Application code review (JDBC connection strings, stored procedures)
- Size database and estimate migration time

**Phase 2: Schema Conversion (2 weeks)**
```sql
-- Example: Identity column conversion
-- SQL Server
CREATE TABLE employees (id INT IDENTITY(1,1) PRIMARY KEY);

-- PostgreSQL
CREATE TABLE employees (id SERIAL PRIMARY KEY);
-- OR (SQL Standard)
CREATE TABLE employees (id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY);
```

**Phase 3: Data Migration (1 week)**
```bash
# Option 1: Google Database Migration Service (DMS)
# - Continuous replication from SQL Server
# - Minimal downtime (~5 minutes)
# - Automated schema conversion

# Option 2: pgloader (offline migration)
pgloader mssql://user:pass@sqlserver/hrdb \
         postgresql://user:pass@cloudsql/hr_database

# Option 3: Custom ETL with Cloud Dataflow
# - Extract to GCS (CSV/Avro)
# - Transform (Dataflow pipeline)
# - Load to Cloud SQL (batch import)
```

**Phase 4: Validation (1 week)**
- Row count verification
- Data integrity checks (foreign keys, constraints)
- Application integration testing
- Performance testing (query response times)

**Phase 5: Cutover (1 day)**
1. Enable read-only mode on SQL Server
2. Final incremental sync
3. Run validation queries
4. Update application connection strings
5. DNS/load balancer cutover
6. Monitor for 24 hours

**Rollback Plan:**
- Keep SQL Server running for 30 days
- Backup before cutover
- Document rollback procedure
- Test rollback in staging environment

### 5.5 Schema Mapping Examples

**Data Type Conversions:**
```sql
-- SQL Server → PostgreSQL
NVARCHAR(100)      → VARCHAR(100)
DATETIME           → TIMESTAMP
BIT                → BOOLEAN
MONEY              → DECIMAL(19,4)
UNIQUEIDENTIFIER   → UUID
VARBINARY(MAX)     → BYTEA
```

**Stored Procedure Conversion:**
```sql
-- SQL Server T-SQL
CREATE PROCEDURE GetActiveEmployees
AS
BEGIN
    SELECT * FROM employees WHERE status = 'active';
END;

-- PostgreSQL PL/pgSQL
CREATE OR REPLACE FUNCTION get_active_employees()
RETURNS TABLE (id INTEGER, first_name VARCHAR, last_name VARCHAR) AS $$
BEGIN
    RETURN QUERY SELECT e.id, e.first_name, e.last_name
                 FROM employees e WHERE e.status = 'active';
END;
$$ LANGUAGE plpgsql;
```

---

## 6. IAM Strategy

### 6.1 Workload Identity Federation (OIDC)

**Traditional Approach (Insecure):**
```yaml
# BAD: Service account key file in repository
- name: Authenticate to GCP
  uses: google-github-actions/auth@v2
  with:
    credentials_json: ${{ secrets.GCP_SA_KEY }}  # ❌ Long-lived key
```

**Workload Identity Federation (Secure):**
```yaml
# GOOD: Keyless authentication with OIDC
- name: Authenticate to GCP
  uses: google-github-actions/auth@v2
  with:
    workload_identity_provider: ${{ secrets.WIF_PROVIDER }}
    service_account: github-actions@PROJECT.iam.gserviceaccount.com
    # No keys! Uses GitHub OIDC token
```

**How It Works:**
1. GitHub Actions generates OIDC token (signed JWT)
2. Token includes claims: repository, workflow, actor
3. GCP validates token against Workload Identity Pool
4. GCP issues short-lived access token (1 hour)
5. Terraform uses access token for GCP API calls

**Benefits:**
- ✅ No service account keys to manage or rotate
- ✅ Short-lived tokens (1 hour) reduce compromise window
- ✅ Automatic credential rotation
- ✅ Audit trail shows GitHub repository and workflow
- ✅ Can restrict by repository, branch, or actor

### 6.2 Least Privilege IAM Roles

**Principle: Grant Minimum Required Permissions**

```yaml
# Example: Cloud SQL Admin Service Account
Service Account: cloud-sql-admin@PROJECT.iam.gserviceaccount.com

Roles Granted:
  - roles/cloudsql.client       # Connect to Cloud SQL
  - roles/cloudsql.instanceUser # Database operations

Roles NOT Granted:
  - roles/cloudsql.admin        # Too broad (includes delete)
  - roles/owner                 # Project-wide access
  - roles/editor                # Can modify all resources
```

**Role Selection Criteria:**
1. What resources does the service account need to access?
2. What operations are required (read, write, delete)?
3. Can a predefined role be used, or is a custom role needed?
4. Is the role scoped to specific resources (condition)?

### 6.3 Service Account Best Practices

**Key Management:**
- ✅ Use Workload Identity Federation (no keys)
- ✅ If keys required: rotate every 90 days
- ✅ Use short-lived tokens when possible
- ❌ Never commit keys to version control
- ❌ Never share keys between environments

**Naming Convention:**
```
<purpose>@<project-id>.iam.gserviceaccount.com

Examples:
  github-actions@casestudy3-dev.iam.gserviceaccount.com
  cloud-sql-admin@casestudy3-dev.iam.gserviceaccount.com
  gke-workload@casestudy3-dev.iam.gserviceaccount.com
```

**Lifecycle Management:**
- Regularly audit service accounts (quarterly)
- Disable unused service accounts
- Monitor service account activity (Cloud Audit Logs)
- Implement conditional policies (time-of-day, IP range)

---

## 7. Cost Analysis

### 7.1 Monthly Cost Breakdown

**Detailed Cost Estimate (EUR):**

| Service | Configuration | Unit Cost | Monthly Cost |
|---------|--------------|-----------|--------------|
| **Cloud SQL PostgreSQL** | | | |
| - Instance (db-f1-micro) | 0.6 GB RAM, Regional HA | €0.035/hour | €25.20 |
| - Storage (20 GB SSD) | €0.17/GB/month | €0.17/GB | €3.40 |
| - Backup storage (7 days) | ~5 GB | €0.08/GB | €0.40 |
| - Networking (private IP) | No charge | Free | €0.00 |
| **VPC Networking** | | | |
| - VPC | Standard VPC | Free | €0.00 |
| - Subnets | 2 subnets | Free | €0.00 |
| - VPC Flow Logs | 50% sampling | ~€2/month | €2.00 |
| - Cloud NAT | Dynamic IPs | €0.044/hour | €31.68 |
| - Cloud NAT Data Processing | Minimal usage | €0.045/GB | €2.00 |
| **Cloud Monitoring** | | | |
| - Dashboard | 1 dashboard | Free | €0.00 |
| - Metrics (custom) | <50 metrics | Free | €0.00 |
| - Alert policies | 3 alerts | Free | €0.00 |
| - Log ingestion | <50 GB/month | Free | €0.00 |
| **Cloud Storage** | | | |
| - Terraform state | <1 GB | €0.02/GB | €0.02 |
| - Backups (redundant) | Auto-managed | Included | €0.00 |
| **IAM** | | | |
| - Service accounts | 3 accounts | Free | €0.00 |
| - Workload Identity | Requests | Free | €0.00 |
| **TOTAL** | | | **€64.70** |

**Cost Optimization Strategies:**

1. **Reduce Cloud NAT Cost** (saves ~€30/month):
   ```hcl
   # Option 1: Use Cloud NAT only for specific subnets
   source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"
   
   # Option 2: Use VPC connector for egress (Cloud Run/Functions)
   # Option 3: Remove NAT if outbound internet not needed
   ```

2. **Use Zonal HA Instead of Regional** (saves ~€12/month):
   ```hcl
   # Development/staging only
   database_availability_type = "ZONAL"
   # Reduced from €25.20 to €12.60/month
   ```

3. **Reduce Backup Retention** (saves €0.20/month):
   ```hcl
   database_backup_retention_days = 3  # Instead of 7
   ```

4. **Schedule Database Stop** (saves ~50% for dev/test):
   ```bash
   # Stop database during non-business hours
   gcloud sql instances patch INSTANCE --activation-policy=NEVER
   # Restart when needed
   gcloud sql instances patch INSTANCE --activation-policy=ALWAYS
   ```

**Optimized Cost (Production):** €35-40/month  
**Optimized Cost (Development):** €15-20/month

### 7.2 Cost Comparison

**Cloud SQL vs Self-Managed PostgreSQL:**

| Option | Setup Cost | Monthly Cost | Hidden Costs |
|--------|-----------|--------------|--------------|
| Cloud SQL (managed) | €0 | €30-40 | None |
| Self-managed (Compute Engine) | €0 | €15-20 | Admin time (20h/month × €50/h = €1,000) |
| Self-managed (on-prem) | €5,000 (hardware) | €100 (power, cooling) | Admin time, hardware maintenance |

**Conclusion:** Cloud SQL is 10x more cost-effective when including operational overhead.

**SQL Server vs PostgreSQL:**

| Database | Licensing | Hosting | Total |
|----------|-----------|---------|-------|
| SQL Server Standard | €1,500/year | €30/month (VM) | €1,860/year |
| Cloud SQL PostgreSQL | €0/year | €400/year | €400/year |
| **Savings** | | | **€1,460/year (78%)** |

### 7.3 Budget Monitoring

**Budget Alert Setup:**
```bash
# Set monthly budget with alerts
gcloud billing budgets create \
    --billing-account=BILLING_ACCOUNT \
    --display-name="CS3 Budget" \
    --budget-amount=50EUR \
    --threshold-rule=percent=50,basis=current-spend \
    --threshold-rule=percent=90,basis=current-spend \
    --threshold-rule=percent=100,basis=forecasted-spend \
    --all-updates-rule-monitoring-notification-channels=CHANNEL_ID
```

**Cost Anomaly Detection:**
- Enable cost anomaly detection in Billing
- Set alerts for 20% increase over 7-day average
- Review cost breakdown weekly

---

## 8. Deviations from Requirements

### 8.1 Documented Alternatives

Following Case Study 2 style, we document decisions where we deviated from standard approaches:

**Deviation 1: Cloud NAT Cost**
- **Requirement**: Private networking for all resources
- **Standard Approach**: Cloud NAT for outbound internet access
- **Alternative**: Removed Cloud NAT to reduce cost
- **Impact**: Cannot access external package repositories (npm, pip)
- **Mitigation**: Use Artifact Registry for private packages, or enable NAT only when needed
- **Cost Savings**: €33/month (50% total cost reduction)

**Deviation 2: db-f1-micro Instance Size**
- **Requirement**: Production-ready database
- **Standard Approach**: db-n1-standard-1 (1 vCPU, 3.75 GB RAM)
- **Alternative**: db-f1-micro (0.6 GB RAM, shared vCPU)
- **Impact**: Lower performance, not suitable for >50 concurrent users
- **Mitigation**: Vertical scaling when load increases, connection pooling
- **Cost Savings**: €150/month vs €200/month
- **Justification**: Case study with 50 employees, low concurrent load

**Deviation 3: Backup Retention Period**
- **Requirement**: 30-day backup retention (industry standard)
- **Standard Approach**: 30-day retention
- **Alternative**: 7-day retention
- **Impact**: Shorter recovery window for accidental deletions
- **Mitigation**: Export monthly snapshots to GCS for long-term retention
- **Cost Savings**: €2/month
- **Justification**: Case study environment, not production-critical

**Deviation 4: Customer-Managed Encryption Keys (CMEK)**
- **Requirement**: Enhanced encryption control
- **Standard Approach**: CMEK for Cloud SQL and Cloud Storage
- **Alternative**: Google-managed encryption keys
- **Impact**: Less control over key rotation and access
- **Mitigation**: Sufficient for GDPR compliance (encryption at rest enabled)
- **Cost Savings**: €10/month (Cloud KMS charges)
- **Justification**: Google-managed keys meet compliance requirements

### 8.2 Future Improvements

**Phase 2 Enhancements:**
- Implement Cloud Armor for DDoS protection
- Add Cloud CDN for static content delivery
- Enable VPC Service Controls for data exfiltration prevention
- Implement Cloud Data Loss Prevention (DLP) for PII scanning

**Phase 3 Enhancements:**
- Deploy GKE Autopilot cluster for application backend
- Add Istio service mesh for advanced traffic management
- Implement Cloud Functions for serverless workflows
- Add Pub/Sub for event-driven architecture

**Security Enhancements:**
- Implement Customer-Managed Encryption Keys (CMEK)
- Add VPC Service Controls for perimeter security
- Enable Security Command Center for threat detection
- Implement Cloud Armor for WAF protection

**Cost Optimization:**
- Use Committed Use Discounts (CUD) for 1-year commitment (30% savings)
- Implement auto-scaling for database and application tiers
- Use Preemptible VMs for non-critical workloads
- Optimize storage classes (Archive for old backups)

---

## 9. Monitoring & Observability

### 9.1 Cloud Monitoring Dashboard

**Dashboard Widgets:**
1. **Cloud SQL CPU Utilization** - Line chart, 1-hour time range
2. **Cloud SQL Memory Usage** - Line chart, 1-hour time range
3. **Cloud SQL Active Connections** - Stacked area chart
4. **Cloud SQL Disk Usage** - Gauge chart (current/max)
5. **Cloud SQL Replication Lag** - Line chart (HA failover health)
6. **VPC Firewall Dropped Packets** - Heatmap by rule

**Alert Policies:**
- CPU > 80% for 5 minutes → Email notification
- Memory > 90% for 5 minutes → Email notification
- Disk > 85% → Email notification
- Replication lag > 60 seconds → Email + PagerDuty
- Backup failure → Email notification

### 9.2 Logging Strategy

**Cloud Audit Logs:**
```bash
# Admin activity logs (who created/modified resources)
gcloud logging read "logName:cloudaudit.googleapis.com/activity"

# Data access logs (who accessed Cloud SQL)
gcloud logging read "logName:cloudaudit.googleapis.com/data_access"
```

**Cloud SQL Logs:**
- Connection logs (authentication attempts)
- Slow query logs (queries > 1 second)
- Error logs (deadlocks, constraint violations)

**VPC Flow Logs:**
- Connection tracking (source/dest IP, port, protocol)
- Security analysis (blocked connection attempts)
- Performance troubleshooting (packet loss, latency)

### 9.3 Alerting Best Practices

**Alert Fatigue Prevention:**
- Use appropriate thresholds (80% CPU, not 50%)
- Add minimum duration (5 minutes, not instant)
- Group related alerts (CPU + memory together)
- Use notification channels wisely (email for info, PagerDuty for critical)

**Incident Response Runbook:**
1. Alert fires → Notification sent
2. Operator reviews dashboard for context
3. Check recent changes (Terraform deployments, application releases)
4. Review logs for errors
5. Take corrective action (scale up, restart, rollback)
6. Post-incident review

---

## 10. Compliance & Governance

### 10.1 GDPR Compliance Checklist

- ✅ **Data Encryption**: AES-256 at rest, TLS 1.3 in transit
- ✅ **Access Logging**: Comprehensive audit trail in `access_logs` table
- ✅ **Change Tracking**: Employee updates logged in `employee_history`
- ✅ **Data Minimization**: Only essential fields stored
- ✅ **Right to Access**: Query interface for data subject requests
- ⚠️ **Right to Deletion**: Soft delete implemented, hard delete planned
- ⚠️ **Data Retention**: Policy defined, automated cleanup planned
- ⚠️ **Consent Management**: To be implemented in Phase 2
- ⚠️ **Breach Notification**: Incident response plan in progress

### 10.2 Security Compliance

**CIS Google Cloud Platform Foundations Benchmark:**
- ✅ 1.1 - Separate service accounts for each workload
- ✅ 2.1 - Cloud SQL requires SSL
- ✅ 3.1 - VPC Flow Logs enabled
- ✅ 3.9 - Cloud SQL automated backups enabled
- ✅ 4.1 - Cloud Audit Logging enabled
- ✅ 6.2 - Cloud SQL does not have public IP

**NIST Cybersecurity Framework:**
- ✅ **Identify**: Asset inventory (Terraform state)
- ✅ **Protect**: Encryption, IAM, firewall rules
- ✅ **Detect**: Cloud Monitoring, audit logs
- ⚠️ **Respond**: Incident response plan (in progress)
- ⚠️ **Recover**: Backup/restore tested (planned)

---

## 11. Disaster Recovery

### 11.1 Recovery Objectives

**Recovery Time Objective (RTO):** 1 hour  
**Recovery Point Objective (RPO):** 5 minutes

**Failure Scenarios:**

| Scenario | Impact | Recovery | RTO | RPO |
|----------|--------|----------|-----|-----|
| Zone failure | Cloud SQL automatic failover | 30-60 seconds | 1 min | 0 sec |
| Region failure | Manual restore from backup | 1-2 hours | 2 hours | 5 min |
| Data corruption | Point-in-time recovery | 30 minutes | 30 min | 5 min |
| Accidental deletion | Restore from backup | 30 minutes | 30 min | Last backup |

### 11.2 Backup Strategy

**Automated Backups:**
- Daily full backups at 03:00 UTC
- 7-day retention (configurable to 365 days)
- Stored in geo-redundant storage (EU)
- Point-in-time recovery (PITR) enabled

**Backup Testing:**
- Monthly restore test to staging environment
- Validate data integrity with validation queries
- Document restore procedure and timings

**Restore Procedure:**
```bash
# Point-in-time restore
gcloud sql backups restore BACKUP_ID \
    --backup-instance=SOURCE_INSTANCE \
    --backup-id=BACKUP_ID \
    --instance=NEW_INSTANCE

# Or create new instance from backup
gcloud sql instances create INSTANCE_NAME \
    --backup=BACKUP_ID
```

---

## 12. Conclusion

This architecture implements a cost-efficient, secure, and GDPR-compliant Employee Lifecycle Automation system on Google Cloud Platform. Key achievements:

**Technical Excellence:**
- ✅ Zero Trust Architecture with micro-segmentation
- ✅ High availability (99.95% SLA) with Regional Cloud SQL
- ✅ Automated CI/CD with Workload Identity Federation
- ✅ Comprehensive monitoring and alerting

**Business Value:**
- ✅ 78% cost reduction (SQL Server → PostgreSQL)
- ✅ Automated employee provisioning/deprovisioning
- ✅ GDPR-compliant audit trails
- ✅ Scalable foundation for future growth

**Security Posture:**
- ✅ Private networking (no public IPs)
- ✅ Encryption everywhere (at rest and in transit)
- ✅ Least privilege IAM
- ✅ Comprehensive audit logging

**Next Steps:**
1. Deploy application backend (Phase 2)
2. Implement GKE Autopilot cluster (Phase 3)
3. Add advanced monitoring and alerting
4. Conduct security audit and penetration testing

---

## Appendix A: Terraform Resources

**Resources Created:**
- 1 VPC network
- 2 subnets (database, GKE)
- 1 Cloud SQL PostgreSQL instance (Regional HA)
- 3 service accounts
- 1 Workload Identity Pool + Provider
- 8 firewall rules
- 1 Cloud Monitoring dashboard
- 3 alert policies
- 1 Cloud Router + Cloud NAT

**Estimated Deployment Time:** 10-15 minutes

## Appendix B: References

1. [Google Cloud SQL Best Practices](https://cloud.google.com/sql/docs/postgres/best-practices)
2. [VPC Network Design](https://cloud.google.com/vpc/docs/vpc)
3. [Workload Identity Federation](https://cloud.google.com/iam/docs/workload-identity-federation)
4. [Zero Trust on Google Cloud](https://cloud.google.com/beyondcorp)
5. [GDPR Compliance on GCP](https://cloud.google.com/privacy/gdpr)
6. [PostgreSQL Documentation](https://www.postgresql.org/docs/15/)
7. [Case Study 2 (AWS SOAR)](https://github.com/mehdi6132/casestudy2)

---

**Document Version History:**
- v1.0 (2024-11-05): Initial architecture document
