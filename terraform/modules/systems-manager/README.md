# AWS Systems Manager Module

This Terraform module provides AWS Systems Manager capabilities for workspace management, similar to Microsoft Intune.

## Features

### 1. **Session Manager** (Remote Access)
- Secure remote access to workspace instances without SSH keys
- Session logging to S3 and CloudWatch Logs
- Configurable session timeout
- VPC endpoints for private subnet connectivity

### 2. **Parameter Store** (Secrets Management)
- Centralized configuration management
- Secure storage for sensitive data (JWT secrets, credentials)
- Workspace configuration templates
- KMS encryption for sensitive parameters

### 3. **Patch Manager** (Automated Updates)
- Automated patching schedule (default: Sunday 2 AM UTC)
- Patch baselines for security and bug fixes
- Maintenance windows with controlled rollout
- Automatic reboot if needed

### 4. **State Manager** (Configuration Compliance)
- Automated SSM Agent updates
- Software inventory collection
- Configuration compliance monitoring
- Scheduled associations

## Usage

```hcl
module "systems_manager" {
  source = "./modules/systems-manager"

  cluster_name        = "innovatech-employee-lifecycle"
  namespace           = "workspaces"
  vpc_id              = module.vpc.vpc_id
  private_subnet_ids  = module.vpc.private_subnet_ids

  # Feature flags
  enable_session_manager = true
  enable_patch_manager   = true
  enable_state_manager   = true

  # Configuration
  session_timeout_minutes = 60
  patch_schedule          = "cron(0 2 ? * SUN *)" # Every Sunday at 2 AM UTC

  tags = {
    Environment = "production"
    ManagedBy   = "terraform"
  }
}
```

## Outputs

- `workspace_role_arn` - IAM role ARN for workspace instances
- `workspace_instance_profile_name` - Instance profile name for workspaces
- `session_logs_bucket` - S3 bucket for session logs
- `ssm_endpoints` - VPC endpoint IDs for Systems Manager
- `patch_baseline_id` - Patch baseline ID
- `parameter_store_paths` - Parameter Store paths for configuration

## Remote Access to Workspaces

Once deployed, connect to workspace instances using:

```bash
# Start a session
aws ssm start-session --target <instance-id>

# Execute a command
aws ssm send-command \
  --document-name "AWS-RunShellScript" \
  --targets "Key=tag:Environment,Values=innovatech-employee-lifecycle" \
  --parameters 'commands=["uname -a"]'

# Get parameter
aws ssm get-parameter \
  --name "/innovatech-employee-lifecycle/workspace/config" \
  --with-decryption
```

## Compliance and Patching

- **Patch Schedule**: Automated patching occurs every Sunday at 2 AM UTC
- **Compliance**: View instance compliance in AWS Console > Systems Manager > Compliance
- **Inventory**: Software inventory is collected daily
- **SSM Agent**: Automatically updated every 14 days

## Security

- All session logs encrypted at rest (S3 and CloudWatch)
- Secure parameters use KMS encryption
- VPC endpoints for private subnet access
- IAM roles follow least privilege principle
- Session Manager replaces SSH (no inbound ports required)

## Cost Optimization

- Session Manager: No additional cost (included in Systems Manager)
- Parameter Store: Free tier covers most use cases
- VPC Endpoints: ~$7.20/month per endpoint (~$21.60 total for 3 endpoints)
- CloudWatch Logs: Charged per GB ingested and stored
- S3 Storage: Standard S3 pricing for session logs

## Comparison to Microsoft Intune

| Feature | AWS Systems Manager | Microsoft Intune |
|---------|---------------------|------------------|
| Remote Access | Session Manager | Remote Desktop |
| Patching | Patch Manager | Windows Update for Business |
| Configuration | State Manager | Configuration Profiles |
| Secrets | Parameter Store | Key Vault integration |
| Inventory | Inventory | Device inventory |
| Compliance | Compliance | Compliance policies |

## Requirements

- Terraform >= 1.0
- AWS Provider >= 5.0
- Workspace instances must have SSM Agent installed (pre-installed on Amazon Linux 2)
- Instances must have IAM role with `AmazonSSMManagedInstanceCore` policy
